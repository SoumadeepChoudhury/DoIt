import { motion } from "motion/react";
import { Download, ShieldCheck, Settings, Smartphone } from "lucide-react";
import { useState, useEffect } from "react";

interface Release {
  tag_name: string;
  name: string;
  assets: {
    name: string;
    size: number;
    browser_download_url: string;
  }[];
}

export function Installation() {
  const [release, setRelease] = useState<Release | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch("https://api.github.com/repos/SoumadeepChoudhury/DoIt/releases/latest")
      .then((res) => res.json())
      .then((data) => {
        setRelease(data);
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, []);

  const version = release?.tag_name?.replace("v", "") || "2.1.0";
  const apkUrl = release?.assets?.[0]?.browser_download_url || "#";
  const apkSize = release?.assets?.[0]?.size
    ? `${(release.assets[0].size / (1024 * 1024)).toFixed(1)} MB`
    : "14.2 MB";
  const steps = [
    {
      icon: <Download className="text-doit-primary" size={24} />,
      title: "Download the APK",
      desc: "Tap the download button below to save the latest DoIt.apk file to your device's downloads folder."
    },
    {
      icon: <Settings className="text-doit-primary" size={24} />,
      title: "Allow Unknown Sources",
      desc: "Go to your Android Settings > Security (or Biometrics and Security), and enable 'Install Unknown Apps' for your browser or file manager."
    },
    {
      icon: <Smartphone className="text-doit-primary" size={24} />,
      title: "Install the App",
      desc: "Open the downloaded DoIt.apk file and tap 'Install'. Once finished, you're ready to master your day!"
    }
  ];

  return (
    <section id="download" className="py-24 relative">
      <div className="container mx-auto px-6">
        <div className="bg-[#1a1a1a] border border-white/10 rounded-[3rem] p-8 md:p-16 relative overflow-hidden shadow-2xl">
          <div className="absolute top-0 left-0 w-full h-[1px] bg-gradient-to-r from-transparent via-doit-primary/50 to-transparent"></div>

          <div className="grid lg:grid-cols-2 gap-16 items-center">
            <div>
              <h2 className="text-4xl md:text-5xl font-light tracking-tight mb-6 text-white">
                Ready to <span className="font-black italic text-doit-primary">organize your life?</span>
              </h2>
              <p className="text-lg opacity-60 mb-8 leading-relaxed">
                DoIt is currently an independent app available directly from our secure servers. Follow these simple steps to install it on your Android device.
              </p>

              <div className="space-y-8 mb-10">
                {steps.map((step, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: -20 }}
                    whileInView={{ opacity: 1, x: 0 }}
                    viewport={{ once: true }}
                    transition={{ delay: i * 0.1 }}
                    className="flex gap-4"
                  >
                    <div className="flex-shrink-0 w-12 h-12 rounded-xl bg-[#242424] flex items-center justify-center border border-white/5 text-doit-primary font-bold text-xl">
                      0{i + 1}
                    </div>
                    <div>
                      <h4 className="text-[13px] font-bold uppercase tracking-wide opacity-90 mb-1 text-white">{step.title}</h4>
                      <p className="text-[11px] opacity-60 font-medium leading-relaxed">{step.desc}</p>
                    </div>
                  </motion.div>
                ))}
              </div>

              <div className="flex flex-col sm:flex-row gap-4 items-center">
                <a
                  href={apkUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-4 bg-doit-primary text-[#121212] font-bold text-lg rounded-xl hover:shadow-[0_0_25px_rgba(149,219,152,0.4)] transition-all"
                >
                  <Download size={20} />
                  Download DoIt v{version}
                </a>
                <div className="flex items-center gap-2 text-xs opacity-60 font-medium px-4">
                  <ShieldCheck size={16} className="text-doit-primary" />
                  <span>VERIFIED SAFE</span>
                </div>
              </div>
            </div>

            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              className="relative rounded-3xl bg-doit-surface border border-white/5 p-8 flex items-center justify-center aspect-square"
            >
              <div className="absolute inset-0 bg-doit-primary/5 rounded-3xl animate-pulse"></div>

              {/* Representation of an APK file */}
              <div className="relative z-10 flex flex-col items-center">
                <div className="w-32 h-32 rounded-3xl bg-doit-accent border border-doit-primary border-b-[6px] flex items-center justify-center mb-6 shadow-2xl relative overflow-hidden">
                  <div className="absolute inset-0 bg-gradient-to-t from-black/20 to-transparent"></div>
                  <Download size={48} className="text-white relative z-10" />
                </div>
                <div className="text-xl font-bold mb-1">DoIt_v{version}.apk</div>
                <div className="text-doit-text-muted text-sm mb-4">Size: {apkSize}</div>
                <div className="px-3 py-1 rounded-full bg-doit-primary/10 text-doit-primary text-xs font-medium border border-doit-primary/20 animate-bounce">
                  {loading ? "Checking..." : `Latest: v${version}`}
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>
    </section>
  );
}
