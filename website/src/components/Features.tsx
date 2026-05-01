import { motion } from "motion/react";
import { CheckCircle, Calendar, Leaf, Zap, SunMoon, TrendingUp } from "lucide-react";

export function Features() {
  const features = [
    {
      icon: <CheckCircle className="text-doit-primary" size={24} />,
      title: "Task Management",
      description: "Intuitive task creation, organization, and completion with satisfying interactions."
    },
    {
      icon: <Calendar className="text-doit-primary" size={24} />,
      title: "Daily Schedules",
      description: "Plan your day with precision. Set times, reminders, and block out your focused work sessions."
    },
    {
      icon: <Leaf className="text-doit-primary" size={24} />,
      title: "Distraction-Free",
      description: "A clean, minimalist environment that removes the noise so you can strictly focus on the task at hand."
    },
    {
      icon: <SunMoon className="text-doit-primary" size={24} />,
      title: "Dark/Light Modes",
      description: "A gorgeous interface that adapts to your environment, featuring our signature peaceful green."
    },
    {
      icon: <TrendingUp className="text-doit-primary" size={24} />,
      title: "Progress Tracking",
      description: "Visualize your productivity streaks and stay motivated with beautiful insights."
    },
    {
      icon: <Zap className="text-doit-primary" size={24} />,
      title: "Instant Sync",
      description: "Everything saves instantly. Focus on your work, we'll handle keeping it safe."
    }
  ];

  return (
    <section id="features" className="py-24 relative">
      <div className="container mx-auto px-6">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <motion.h2 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-4xl md:text-5xl font-light mb-6 tracking-tight text-white"
          >
            Everything you need for <span className="font-black italic text-doit-primary">peaceful focus.</span>
          </motion.h2>
          <motion.p 
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ delay: 0.1 }}
            className="text-lg opacity-60 leading-relaxed"
          >
            DoIt is designed to be unobtrusive and highly responsive. We stripped away the convoluted methodologies to give you exactly what works.
          </motion.p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className="bg-[#1a1a1a] border border-white/10 p-8 rounded-3xl hover:border-doit-primary/30 hover:shadow-[0_0_30px_rgba(149,219,152,0.05)] transition-all duration-300"
            >
              <div className="w-12 h-12 rounded-2xl bg-[#242424] flex items-center justify-center mb-6 border border-white/5 shadow-inner text-doit-primary">
                {feature.icon}
              </div>
              <h3 className="text-xl font-bold mb-3 text-white">{feature.title}</h3>
              <p className="text-[13px] opacity-60 leading-relaxed font-medium">
                {feature.description}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
