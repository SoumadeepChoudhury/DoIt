import { motion, useScroll, useTransform } from "motion/react";
import { useRef } from "react";

export function Screenshots() {
  const containerRef = useRef(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start end", "end start"]
  });

  // Parallax effects for the different phones
  const ySide = useTransform(scrollYProgress, [0, 1], [100, -100]);
  const yCenter = useTransform(scrollYProgress, [0, 1], [0, -150]);

  // Beautiful green/dark themed abstract Unsplash images as placeholders
  const images = [
    "/images/history.png",
    "/images/home.png",
    "/images/levels.png"
  ];

  return (
    <section ref={containerRef} className="py-24 md:py-40 border-y border-white/5 relative overflow-hidden bg-doit-surface">
      {/* Background ambient glow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[100vw] h-[100vw] md:w-[60vw] md:h-[60vw] bg-doit-primary/5 rounded-full blur-[100px] md:blur-[150px] -z-10 pointer-events-none"></div>

      <div className="container mx-auto px-6 mb-24 text-center relative z-20">
        <h2 className="text-5xl md:text-7xl font-light tracking-tight mb-6 text-white leading-none">
          A visually <br className="hidden md:block" /><span className="font-black italic text-doit-primary">stunning experience.</span>
        </h2>
        <p className="text-lg md:text-2xl opacity-60 max-w-2xl mx-auto font-medium leading-relaxed">
          Every pixel crafted with intention. No unneeded borders. Just your tasks, beautifully presented in an immersive interface.
        </p>
      </div>

      <div className="relative h-[600px] md:h-[900px] w-full max-w-6xl mx-auto flex items-center justify-center mt-10 md:mt-20 group">

        <div className="absolute inset-0 transition-transform duration-1000 ease-[cubic-bezier(0.23,1,0.32,1)] group-hover:scale-[1.04] flex items-center justify-center">
          {/* Left Phone (Behind) */}
          <motion.div
            style={{ y: ySide, rotate: -12 }}
            className="absolute left-[5%] md:left-[12%] z-10 w-[180px] md:w-[300px] opacity-80 will-change-transform"
          >
            <div className="relative rounded-[2.5rem] md:rounded-[4rem] bg-[#1a1a1a] border-[6px] md:border-[10px] border-[#2a2a2a] ring-1 ring-doit-primary/20 shadow-[0_30px_60px_rgba(0,0,0,0.8)] overflow-hidden flex flex-col items-center aspect-[9/19.5]">
              <div className="absolute top-0 right-0 left-0 h-6 md:h-10 bg-gradient-to-b from-black/80 to-transparent z-20 pointer-events-none"></div>
              <div className="absolute top-3 md:top-5 w-12 md:w-20 h-1.5 md:h-2 bg-black/90 rounded-full z-20"></div>

              <img src={images[0]} alt="App interface design 1" className="w-full h-full object-cover z-10 opacity-80" />
              <div className="absolute inset-0 bg-[#121212]/40 z-10 pointer-events-none"></div>

              <div className="absolute inset-0 bg-gradient-to-tr from-white/10 via-transparent to-white/5 z-20 pointer-events-none"></div>
            </div>
          </motion.div>

          {/* Right Phone (Behind) */}
          <motion.div
            style={{ y: ySide, rotate: 12 }}
            className="absolute right-[5%] md:right-[12%] z-10 w-[180px] md:w-[300px] opacity-80 will-change-transform"
          >
            <div className="relative rounded-[2.5rem] md:rounded-[4rem] bg-[#1a1a1a] border-[6px] md:border-[10px] border-[#2a2a2a] ring-1 ring-doit-primary/20 shadow-[0_30px_60px_rgba(0,0,0,0.8)] overflow-hidden flex flex-col items-center aspect-[9/19.5]">
              <div className="absolute top-0 right-0 left-0 h-6 md:h-10 bg-gradient-to-b from-black/80 to-transparent z-20 pointer-events-none"></div>
              <div className="absolute top-3 md:top-5 w-12 md:w-20 h-1.5 md:h-2 bg-black/90 rounded-full z-20"></div>

              <img src={images[2]} alt="App interface design 2" className="w-full h-full object-cover z-10 opacity-80" />
              <div className="absolute inset-0 bg-[#121212]/40 z-10 pointer-events-none"></div>

              <div className="absolute inset-0 bg-gradient-to-tr from-white/10 via-transparent to-white/5 z-20 pointer-events-none"></div>
            </div>
          </motion.div>

          {/* Center Phone (Hero, Front) */}
          <motion.div
            style={{ y: yCenter }}
            className="absolute z-30 w-[240px] md:w-[400px] will-change-transform"
          >
            <div className="relative rounded-[3rem] md:rounded-[4.5rem] bg-[#1a1a1a] border-[8px] md:border-[12px] border-[#222] ring-2 ring-doit-primary/40 shadow-[0_40px_100px_rgba(0,0,0,0.95)] overflow-hidden flex flex-col items-center aspect-[9/19.5]">
              <div className="absolute top-0 right-0 left-0 h-8 md:h-12 bg-gradient-to-b from-black/80 to-transparent z-20 pointer-events-none"></div>
              <div className="absolute top-4 md:top-6 w-16 md:w-24 h-1.5 md:h-2.5 bg-black/90 rounded-full z-20 shadow-inner"></div>

              <img src={images[1]} alt="App main interface" className="w-full h-full object-cover z-10" />

              {/* Subtle green tint overlay */}
              <div className="absolute inset-0 bg-doit-primary/5 z-10 pointer-events-none"></div>

              {/* Strong glass reflection */}
              <div className="absolute inset-0 bg-gradient-to-tr from-white/20 via-transparent to-white/5 z-20 pointer-events-none opacity-60"></div>
              <div className="absolute -inset-1/2 top-0 bg-gradient-to-b from-white/10 to-transparent rotate-[-45deg] z-20 pointer-events-none transform -translate-y-1/2"></div>
            </div>
          </motion.div>
        </div>

      </div>
    </section>
  );
}
