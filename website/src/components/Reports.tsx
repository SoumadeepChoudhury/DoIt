import { motion } from "motion/react";
import { Activity, TrendingUp, Clock, CalendarDays, CheckCircle } from "lucide-react";

export function Reports() {
    return (
        <section className="py-24 relative z-20 border-t border-white/5 bg-doit-surface overflow-hidden">
            <div className="absolute top-1/2 left-0 w-[500px] h-[500px] bg-doit-primary/5 rounded-full blur-[120px] -translate-y-1/2 -translate-x-1/2 pointer-events-none"></div>

            <div className="container mx-auto px-6">
                <div className="flex flex-col lg:flex-row gap-16 items-center">

                    {/* Left Text / Info */}
                    <div className="lg:w-1/2">
                        <motion.div
                            initial={{ opacity: 0, y: 30 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            viewport={{ once: true }}
                            className="max-w-xl mx-auto lg:mx-0"
                        >
                            <div className="mb-6 flex items-center gap-3">
                                <div className="w-10 h-10 rounded-full bg-doit-primary/10 flex items-center justify-center text-doit-primary border border-doit-primary/20">
                                    <Activity size={18} />
                                </div>
                                <span className="text-doit-primary text-[11px] font-bold uppercase tracking-[0.2em]">
                                    Deep Analytics
                                </span>
                            </div>

                            <h2 className="text-4xl md:text-6xl font-light tracking-tight mb-6 text-white leading-none">
                                Data that <br /><span className="font-black italic text-doit-primary">drives action.</span>
                            </h2>

                            <p className="text-lg md:text-xl opacity-60 mb-8 leading-relaxed font-medium">
                                Stop guessing where your time goes. Turn your daily habits into actionable insights with beautiful, easy-to-read reports that help you identify your peak performance.
                            </p>

                            <ul className="space-y-4 text-sm font-medium opacity-70">
                                <li className="flex items-center gap-3">
                                    <div className="w-1.5 h-1.5 rounded-full bg-doit-primary"></div>
                                    Track your completion velocity over time.
                                </li>
                                <li className="flex items-center gap-3">
                                    <div className="w-1.5 h-1.5 rounded-full bg-doit-primary"></div>
                                    Identify tasks taking up the most focus.
                                </li>
                                <li className="flex items-center gap-3">
                                    <div className="w-1.5 h-1.5 rounded-full bg-doit-primary"></div>
                                    Celebrate your most productive days.
                                </li>
                            </ul>
                        </motion.div>
                    </div>

                    {/* Right Screenshot Mockup */}
                    <div className="lg:w-1/2 w-full flex justify-center mt-16 lg:mt-0 relative">
                        <motion.div
                            initial={{ opacity: 0, scale: 0.9, y: 40 }}
                            whileInView={{ opacity: 1, scale: 1, y: 0 }}
                            viewport={{ once: true }}
                            transition={{ duration: 0.8, ease: "easeOut" }}
                            className="relative group perspective-[1000px] z-10"
                        >
                            {/* Main Device Mockup */}
                            <div className="relative z-20 w-[260px] md:w-[320px] aspect-[9/19.5] bg-[#1a1a1a] rounded-[40px] md:rounded-[48px] border-[6px] md:border-[10px] border-[#2a2a2a] shadow-[0_40px_80px_rgba(0,0,0,0.8)] overflow-hidden flex flex-col items-center ring-1 ring-doit-primary/20 rotate-[-4deg] group-hover:rotate-0 transition-transform duration-700 ease-[cubic-bezier(0.23,1,0.32,1)]">
                                {/* Top notch/camera island */}
                                <div className="absolute top-0 right-0 left-0 h-6 md:h-10 bg-gradient-to-b from-black/80 to-transparent z-20 pointer-events-none"></div>
                                <div className="absolute top-3 md:top-4 w-14 md:w-20 h-1.5 bg-black/90 rounded-full z-20 shadow-inner"></div>

                                {/* Replace the src below with your actual screenshot path */}
                                <img
                                    src="/images/reports.png"
                                    alt="Reports Screenshot Mockup"
                                    className="w-full h-full object-cover z-10 opacity-90 transition-all duration-700 group-hover:opacity-100 group-hover:scale-105"
                                />

                                {/* Subtle glass reflection */}
                                <div className="absolute inset-0 bg-gradient-to-tr from-white/10 via-transparent to-white/5 z-20 pointer-events-none opacity-50"></div>

                                {/* Bottom Indicator */}
                                <div className="absolute bottom-2 md:bottom-4 mx-auto w-12 md:w-16 h-1 bg-white/30 rounded-full z-30"></div>
                            </div>

                            {/* Floating Element 1 - Top Left */}
                            <motion.div
                                initial={{ opacity: 0, x: 10, y: 10 }}
                                whileInView={{ opacity: 1, x: 0, y: -60 }}
                                viewport={{ once: true }}
                                transition={{ duration: 0.8, delay: 0.3, ease: "easeOut" }}
                                className="absolute top-12 -left-12 md:-left-24 z-30 bg-[#242424]/90 backdrop-blur-xl border border-white/10 p-3 md:p-4 rounded-2xl md:rounded-3xl shadow-2xl group-hover:-translate-y-2 transition-transform duration-500"
                            >
                                <div className="flex items-center gap-3">
                                    <div className="hidden md:flex w-10 h-10 rounded-full bg-doit-primary/20 items-center justify-center text-doit-primary border border-doit-primary/20">
                                        <CheckCircle size={16} />
                                    </div>
                                    <div>
                                        <div className="flex items-center gap-1.5 mb-1">
                                            <div className="w-1.5 h-1.5 rounded-full bg-doit-primary animate-pulse"></div>
                                            <p className="text-[9px] uppercase tracking-[0.2em] opacity-60 font-bold">Morning Run</p>
                                        </div>
                                        <p className="text-sm md:text-base font-black text-white">28 / 31 Days</p>
                                    </div>
                                </div>
                            </motion.div>

                            {/* Floating Element 2 - Bottom Right */}
                            <motion.div
                                initial={{ opacity: 0, x: -20, y: -20 }}
                                whileInView={{ opacity: 1, x: 0, y: 0 }}
                                viewport={{ once: true }}
                                transition={{ duration: 0.8, delay: 0.5, ease: "easeOut" }}
                                className="absolute bottom-16 -right-8 md:-right-16 z-30 bg-[#242424]/90 backdrop-blur-xl border border-white/10 p-3 md:p-4 rounded-2xl md:rounded-3xl shadow-2xl group-hover:translate-y-2 group-hover:translate-x-2 transition-transform duration-500"
                            >
                                <div className="flex flex-col gap-2 min-w-[120px]">
                                    <p className="text-[9px] uppercase tracking-[0.2em] opacity-60 font-bold mb-0.5">Read 10 Pages</p>
                                    <div className="flex items-center gap-2">
                                        <CalendarDays size={14} className="text-doit-primary" />
                                        <p className="text-sm md:text-base font-black text-white">20 / 31 Done</p>
                                    </div>
                                </div>
                            </motion.div>

                            {/* Decorative Background Card */}
                            <div className="absolute -z-10 -top-4 -right-4 md:-right-8 w-full h-full bg-white/5 border border-white/10 rounded-[30px] md:rounded-[48px] rotate-[8deg] backdrop-blur-sm group-hover:rotate-[12deg] group-hover:translate-x-4 transition-transform duration-700 opacity-60"></div>

                            {/* Decorative Glow */}
                            <div className="absolute -z-20 top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[120%] h-[120%] bg-doit-primary/10 blur-[60px] md:blur-[80px] rounded-full opacity-60 group-hover:opacity-100 transition-opacity duration-700 pointer-events-none"></div>
                        </motion.div>
                    </div>

                </div>
            </div>
        </section>
    );
}
