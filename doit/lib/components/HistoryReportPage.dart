// ignore_for_file: file_names

import 'package:doit/models/EverydayModel.dart';
import 'package:doit/utils/Colors.dart';
import 'package:doit/utils/Database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class HistoryReportPage extends StatefulWidget {
  const HistoryReportPage({super.key});

  @override
  State<HistoryReportPage> createState() => _HistoryReportPageState();
}

class _HistoryReportPageState extends State<HistoryReportPage>
    with WidgetsBindingObserver {
  final AppDatabase _database = AppDatabase.instance;
  late Future<List<String>> _monthsFuture;
  Future<List<EverydayReport>>? _reportsFuture;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshReportData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshReportData();
    }
  }

  void _refreshReportData({String? selectedMonth}) {
    _monthsFuture = _database.getAvailableEverydayReportMonths();
    _reportsFuture = _monthsFuture.then((months) {
      final nextMonth = selectedMonth ??
          (_selectedMonth != null && months.contains(_selectedMonth)
              ? _selectedMonth
              : months.isNotEmpty
                  ? months.first
                  : null);
      _selectedMonth = nextMonth;
      if (nextMonth == null) return <EverydayReport>[];
      return _loadReportsForMonth(nextMonth);
    });

    if (mounted) setState(() {});
  }

  Future<void> _handleRefresh() async {
    _refreshReportData();
    await _reportsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _monthsFuture,
      builder: (context, monthSnapshot) {
        final months = monthSnapshot.data ?? [];

        return FutureBuilder<List<EverydayReport>>(
          future: _reportsFuture,
          builder: (context, reportSnapshot) {
            final reports = reportSnapshot.data ?? [];
            final monthLabel = _selectedMonth == null
                ? 'This Month'
                : DateFormat('MMMM yyyy')
                    .format(DateFormat('yyyy-M').parse(_selectedMonth!));
            final totalCompleted = reports.fold<int>(
                0, (sum, report) => sum + report.completedCount);
            final totalExpected =
                reports.fold<int>(0, (sum, report) => sum + report.totalCount);
            final overallProgress =
                totalExpected == 0 ? 0.0 : totalCompleted / totalExpected;
            final isLoading =
                monthSnapshot.connectionState == ConnectionState.waiting ||
                    reportSnapshot.connectionState == ConnectionState.waiting;

            return Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withValues(alpha: 0.15),
                      const Color(0xFF0A1A0F).withValues(alpha: 0.6),
                    ],
                    stops: const [0.4, 1.0],
                    transform: const GradientRotation(0.1),
                  ),
                ),
                child: RefreshIndicator(
                  color: primaryColor,
                  backgroundColor: surfaceColor,
                  onRefresh: _handleRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        leading: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: textPrimary),
                          onPressed: () => Navigator.pop(context),
                        ),
                        title: Text(
                          'Monthly Report',
                          style: GoogleFonts.nunitoSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: textPrimary,
                          ),
                        ),
                        centerTitle: false,
                        actions: [
                          IconButton(
                            icon: Icon(Icons.refresh_rounded,
                                color: textPrimary.withValues(alpha: 0.85)),
                            onPressed: _refreshReportData,
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_month_rounded,
                                color: primaryColor),
                            onPressed: months.isEmpty
                                ? null
                                : () => _showMonthPicker(months),
                          ),
                        ],
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        sliver: SliverToBoxAdapter(
                          child: _ReportHeroCard(
                            completed: totalCompleted,
                            total: totalExpected,
                            progress: overallProgress,
                            taskCount: reports.length,
                            monthLabel: monthLabel,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 2, 24, 10),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              monthLabel,
                              style: GoogleFonts.nunitoSans(
                                color: primaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child:
                                CircularProgressIndicator(color: primaryColor),
                          ),
                        )
                      else if (reports.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyReportState(monthLabel: monthLabel),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
                          sliver: SliverList.separated(
                            itemCount: reports.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              return _EverydayReportCard(
                                  report: reports[index]);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<EverydayReport>> _loadReportsForMonth(String month) async {
    final reports = await _database.getEverydayReportsForMonth(month);
    final mappedReports =
        reports.map((report) => EverydayReport.fromMap(report)).toList();
    mappedReports.sort((a, b) {
      final progressCompare = a.progress.compareTo(b.progress);
      if (progressCompare != 0) return progressCompare;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return mappedReports;
  }

  void _showMonthPicker(List<String> months) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor.withValues(alpha: 0.98),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Month',
                  style: GoogleFonts.nunitoSans(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ...months.map((month) {
                  final monthLabel = DateFormat('MMMM yyyy')
                      .format(DateFormat('yyyy-M').parse(month));
                  final isSelected = month == _selectedMonth;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _refreshReportData(selectedMonth: month);
                      },
                      leading: Icon(Icons.calendar_today_rounded,
                          color: primaryColor),
                      title: Text(
                        monthLabel,
                        style: GoogleFonts.nunitoSans(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: primaryColor)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;
  final int taskCount;
  final String monthLabel;

  const _ReportHeroCard({
    required this.completed,
    required this.total,
    required this.progress,
    required this.taskCount,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CircularProgressBadge(
                progress: progress,
                label: total == 0 ? '0%' : '${(progress * 100).round()}%',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 10),
                    Text(
                      'Completion Pulse',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunitoSans(
                        color: primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // const SizedBox(height: 18),
                    Text(
                      '$completed/$total everyday tasks completed',
                      style: GoogleFonts.nunitoSans(
                        color: textPrimary.withValues(alpha: 0.76),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularProgressBadge extends StatelessWidget {
  final double progress;
  final String label;

  const _CircularProgressBadge({
    required this.progress,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: progress.clamp(0, 1),
              strokeWidth: 4.5,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunitoSans(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EverydayReportCard extends StatelessWidget {
  final EverydayReport report;

  const _EverydayReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: primaryColor.withValues(alpha: 0.18)),
                ),
                child: Icon(Icons.repeat_rounded, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunitoSans(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: report.progress.clamp(0, 1),
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${report.completedCount}/${report.totalCount}',
                style: GoogleFonts.nunitoSans(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyReportState extends StatelessWidget {
  final String monthLabel;

  const _EmptyReportState({required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/json/EmptyGhost.json',
          width: 240,
          height: 220,
          repeat: true,
        ),
        const SizedBox(height: 18),
        Text(
          'No Tasks In $monthLabel',
          style: GoogleFonts.nunitoSans(
            color: primaryColor,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Text(
            'Everyday task completions for this month will appear here once you add it.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunitoSans(
              color: textPrimary.withValues(alpha: 0.66),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
