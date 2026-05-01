import { motion } from "motion/react";
import { Star } from "lucide-react";

export function Testimonials() {
  const reviews = [
    {
      name: "Sarah Jenkins",
      role: "Product Designer",
      text: "The UI is absolutely gorgeous. It's the first to-do list app I don't dread opening in the morning. The green theme is very calming.",
      rating: 5
    },
    {
      name: "Michael Chen",
      role: "Software Developer",
      text: "Clean, fast, and does exactly what it needs to without bloating my phone.",
      rating: 5
    },
    {
      name: "Emily Rodriguez",
      role: "Student",
      text: "DoIt literally saved my finals week. Scheduling my study sessions has never been easier or looked better. Highly recommend!",
      rating: 5
    }
  ];

  return (
    <section className="py-24">
      <div className="container mx-auto px-6">
        <div className="text-center mb-16">
          <h2 className="text-4xl md:text-5xl font-light tracking-tight mb-6 text-white">
            Loved by <span className="font-black italic text-doit-primary">early adopters.</span>
          </h2>
          <p className="text-lg opacity-60">Here's what our community is saying about DoIt.</p>
        </div>

        <div className="grid md:grid-cols-3 gap-6">
          {reviews.map((review, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className="bg-[#1a1a1a] p-8 rounded-2xl border border-white/10 shadow-2xl hover:border-doit-primary/30 transition-all duration-300"
            >
              <div className="flex gap-1 mb-4">
                {[...Array(review.rating)].map((_, i) => (
                  <Star key={i} size={14} fill="#95DB98" stroke="#95DB98" />
                ))}
              </div>
              <p className="text-[13px] italic opacity-70 mb-6 leading-relaxed">"{review.text}"</p>
              <p className="text-[10px] font-bold tracking-[0.15em] text-doit-primary uppercase">
                — {review.name}, {review.role}
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}
