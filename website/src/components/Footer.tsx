export function Footer() {
  return (
    <footer className="py-12 border-t border-white/5 mt-12 bg-doit-surface">
      <div className="container mx-auto px-6">
        <div className="grid md:grid-cols-4 gap-8 mb-12">
          <div className="md:col-span-2">
            <a href="#" className="flex items-center gap-3 mb-6 inline-flex group">
              <div className="relative flex items-center justify-center w-10 h-10">
                <div className="absolute inset-0 bg-doit-primary/20 blur-xl rounded-full transition-all duration-500 group-hover:bg-doit-primary/40 group-hover:scale-110"></div>
                <div className="relative w-10 h-10 bg-gradient-to-br from-[#2a2a2a] to-[#121212] rounded-2xl border border-white/10 flex items-center justify-center shadow-xl overflow-hidden">
                  <div className="absolute inset-0 bg-gradient-to-tr from-doit-primary/20 via-transparent to-white/5 opacity-50"></div>
                  <img src="/images/favicon.png" alt="Logo" />
                </div>
              </div>
              <span className="text-[26px] font-bold tracking-tighter text-white">
                Do<span className="text-doit-primary pr-1 shadow-doit-primary/20 drop-shadow-lg">It</span>
              </span>
            </a>
            <p className="text-lg opacity-60 max-w-sm leading-relaxed text-white">
              Master your daily schedule with a precision-engineered management tool. Experience fluid design meeting peak utility.
            </p>
          </div>

          <div>
            <h4 className="font-bold opacity-80 mb-4 uppercase tracking-widest text-[11px] text-white">Navigation</h4>
            <ul className="space-y-3 text-[13px] opacity-60 font-medium">
              <li><a href="#" className="hover:text-doit-primary transition-colors text-white">Home</a></li>
              <li><a href="#features" className="hover:text-doit-primary transition-colors text-white">Features</a></li>
              <li><a href="#download" className="hover:text-doit-primary transition-colors text-white">Installation</a></li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold opacity-80 mb-4 uppercase tracking-widest text-[11px] text-white">Legal & Support</h4>
            <ul className="space-y-3 text-[13px] opacity-60 font-medium">
              <li><a href="https://github.com/SoumadeepChoudhury/DoIt" target="_blank" rel="noopener noreferrer" className="hover:text-doit-primary transition-colors text-white">GitHub Repository</a></li>
              <li><a href="#" className="hover:text-doit-primary transition-colors text-white">Privacy Policy</a></li>
              <li><a href="#" className="hover:text-doit-primary transition-colors text-white">Terms of Service</a></li>
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-white/5 flex flex-col md:flex-row justify-between items-center gap-4 text-[10px] font-medium tracking-[0.2em] uppercase opacity-40">
          <div>&copy; {new Date().getFullYear()} Soumadeep Choudhury. ALL RIGHTS RESERVED.</div>
          <div className="flex flex-wrap justify-center gap-4 md:gap-8">
            <span>OPEN SOURCE</span>
            <span>MIT LICENSE</span>
            <a href="https://github.com/SoumadeepChoudhury/DoIt" className="hover:text-doit-primary transition-colors">GITHUB REPOSITORY</a>
          </div>
        </div>
      </div>
    </footer>
  );
}
