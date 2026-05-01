import { motion } from "motion/react";
import { Download, CheckCircle2, ChevronRight, Star, ArrowRight } from "lucide-react";
import { useState, useEffect } from "react";

interface Release {
  tag_name: string;
  assets: {
    browser_download_url: string;
  }[];
}

export function Hero() {
  const [release, setRelease] = useState<Release | null>(null);

  useEffect(() => {
    fetch("https://api.github.com/repos/SoumadeepChoudhury/DoIt/releases/latest")
      .then((res) => res.json())
      .then((data) => setRelease(data))
      .catch(() => { });
  }, []);

  const version = release?.tag_name?.replace("v", "") || "2.1.0";
  const apkUrl = release?.assets?.[0]?.browser_download_url || "#";
  return (
    <section className="relative min-h-screen flex items-center justify-center pt-20 overflow-hidden">
      <div className="hero-glow"></div>

      <div className="container mx-auto px-6 grid lg:grid-cols-2 gap-12 items-center z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="max-w-2xl lg:pr-12"
        >
          <div className="mb-4">
            <span className="px-3 py-1 border border-doit-accent text-doit-primary text-[10px] font-bold uppercase tracking-[0.2em] rounded-full">
              The New Standard in Tasking
            </span>
          </div>

          <h1 className="text-6xl md:text-7xl font-light leading-none mb-6 tracking-tight text-white">
            Productivity, <br className="hidden md:block" /><span className="font-black italic text-doit-primary">Redefined.</span>
          </h1>

          <p className="text-lg opacity-60 mb-8 max-w-md leading-relaxed">
            Master your daily schedule with a precision-engineered management tool. Experience fluid design meeting peak utility.
          </p>

          <div className="flex flex-col sm:flex-row items-center gap-6 mb-12">
            <a
              href={apkUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="bg-doit-primary text-[#121212] px-8 py-4 rounded-xl font-bold text-lg hover:shadow-[0_0_25px_rgba(149,219,152,0.4)] transition-all flex items-center justify-center w-full sm:w-auto"
            >
              Download v{version} (APK)
            </a>
            <div className="text-xs opacity-40 text-center sm:text-left">
              Requires Android 9.0+
              <br />Direct APK Installation
            </div>
          </div>

          {/* Mini Installation Guide */}
          <div className="grid grid-cols-3 gap-4 border-t border-white/10 pt-8">
            <div className="space-y-1">
              <span className="text-doit-primary text-xs font-bold">01.</span>
              <p className="text-[11px] font-semibold opacity-80 uppercase tracking-widest">Get the APK</p>
              <p className="text-[10px] opacity-40">Safe, verified download</p>
            </div>
            <div className="space-y-1">
              <span className="text-doit-primary text-xs font-bold">02.</span>
              <p className="text-[11px] font-semibold opacity-80 uppercase tracking-widest">Enable Source</p>
              <p className="text-[10px] opacity-40">Allow unknown installs</p>
            </div>
            <div className="space-y-1">
              <span className="text-doit-primary text-xs font-bold">03.</span>
              <p className="text-[11px] font-semibold opacity-80 uppercase tracking-widest">Stay Organized</p>
              <p className="text-[10px] opacity-40">Launch and dominate</p>
            </div>
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1, ease: "easeOut", delay: 0.2 }}
          className="relative mx-auto w-full max-w-sm lg:max-w-md flex items-center justify-center min-h-[600px]"
        >
          {/* Abstract Glass Background */}
          <div className="absolute w-full h-[500px] bg-white/5 border border-white/10 rounded-[40px] rotate-[-6deg] backdrop-blur-xl shadow-2xl"></div>

          {/* Main Device Mockup */}
          <div className="relative z-20 w-[280px] h-[580px] bg-[#1a1a1a] rounded-[48px] border-[8px] border-[#2a2a2a] shadow-[0_30px_60px_rgba(0,0,0,0.8)] overflow-hidden flex flex-col items-center ring-2 ring-doit-primary/20">
            {/* Top notch/camera island */}
            <div className="absolute top-0 right-0 left-0 h-8 bg-gradient-to-b from-black/80 to-transparent z-20 pointer-events-none"></div>
            <div className="absolute top-4 w-16 h-1.5 bg-black/90 rounded-full z-20 shadow-inner"></div>

            {/* Replace the src below with your actual screenshot path */}
            <img
              src="/images/home.png"
              alt="DoIt App Screenshot Placeholder"
              className="w-full h-full object-cover z-10"
            />

            {/* Subtle glass reflection */}
            <div className="absolute inset-0 bg-gradient-to-tr from-white/10 via-transparent to-white/5 z-20 pointer-events-none opacity-50"></div>

            {/* Bottom Indicator */}
            <div className="absolute bottom-3 mx-auto w-16 h-1 bg-white/30 rounded-full z-30"></div>
          </div>

          {/* Floating Feedback Card */}
          <div className="absolute bottom-10 -right-4 md:-right-10 z-30 w-[240px] bg-[#1a1a1a] p-4 rounded-2xl border border-white/10 shadow-2xl hidden sm:block">
            <div className="flex gap-1 mb-2">
              <Star size={12} fill="#95DB98" stroke="#95DB98" /><Star size={12} fill="#95DB98" stroke="#95DB98" /><Star size={12} fill="#95DB98" stroke="#95DB98" /><Star size={12} fill="#95DB98" stroke="#95DB98" /><Star size={12} fill="#95DB98" stroke="#95DB98" />
            </div>
            <p className="text-[11px] italic opacity-70 mb-2 leading-relaxed">"The UI is incredible. Finally, a task manager that feels as premium as my devices."</p>
            <p className="text-[10px] font-bold tracking-[0.15em] text-doit-primary uppercase">— ALEX R., SR. ARCHITECT</p>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
