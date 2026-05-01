import React, { useState, useEffect } from 'react';
import { Download, Menu, X } from 'lucide-react';

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <nav className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${scrolled ? 'glass-nav py-4' : 'bg-transparent py-6'}`}>
      <div className="container mx-auto px-6">
        <div className="flex items-center justify-between">
          <a href="#" className="flex items-center gap-3 z-10 group">
            <div className="relative flex items-center justify-center w-10 h-10">
              <div className="absolute inset-0 bg-doit-primary/30 blur-xl rounded-full transition-all duration-500 group-hover:bg-doit-primary/50 group-hover:scale-110"></div>
              <div className="relative w-10 h-10 bg-gradient-to-br from-[#2a2a2a] to-[#121212] rounded-2xl border border-white/10 flex items-center justify-center shadow-xl overflow-hidden">
                <div className="absolute inset-0 bg-gradient-to-tr from-doit-primary/20 via-transparent to-white/5 opacity-50"></div>
                <img src="/images/favicon.png" alt="Logo" />
              </div>
            </div>
            <span className="text-[26px] font-bold tracking-tighter text-white">
              Do<span className="text-doit-primary pr-1 shadow-doit-primary/20 drop-shadow-lg">It</span>
            </span>
          </a>

          {/* Desktop Nav */}
          <div className="hidden md:flex items-center gap-8 z-10">
            <div className="flex items-center gap-8 text-sm font-medium uppercase tracking-widest opacity-70">
              <a href="#features" className="hover:text-doit-primary transition-colors">Features</a>
              <a href="#download" className="hover:text-doit-primary transition-colors">Installation</a>
              <a href="https://github.com/SoumadeepChoudhury/DoIt" target="_blank" rel="noopener noreferrer" className="hover:text-doit-primary transition-colors">Source Code</a>
            </div>
          </div>

          {/* Mobile Menu Toggle */}
          <button
            className="md:hidden text-white"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
          >
            {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
          </button>
        </div>

        {/* Mobile Nav */}
        {mobileMenuOpen && (
          <div className="absolute top-16 right-4 left-4 bg-doit-surface-elevated border border-white/10 rounded-2xl p-6 shadow-2xl flex flex-col gap-4 md:hidden backdrop-blur-xl">
            <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium hover:text-doit-primary">Features</a>
            <a href="#download" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium hover:text-doit-primary">Installation</a>
            <a href="https://github.com/SoumadeepChoudhury/DoIt" target="_blank" rel="noopener noreferrer" className="text-lg font-medium hover:text-doit-primary">Source Code</a>
            <div className="h-px bg-white/10 my-2"></div>
            <a href="#download" onClick={() => setMobileMenuOpen(false)} className="flex items-center justify-center gap-2 px-5 py-3 rounded-full bg-doit-primary text-doit-surface font-semibold">
              <Download size={18} />
              Get APK
            </a>
          </div>
        )}
      </div>
    </nav>
  );
}
