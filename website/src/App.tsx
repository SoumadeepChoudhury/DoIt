/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { Navbar } from "./components/Navbar";
import { Hero } from "./components/Hero";
import { Features } from "./components/Features";
import { Screenshots } from "./components/Screenshots";
import { Installation } from "./components/Installation";
import { Testimonials } from "./components/Testimonials";
import { Footer } from "./components/Footer";

import { Reports } from "./components/Reports";

export default function App() {
  return (
    <div className="min-h-screen bg-doit-surface text-doit-text font-sans selection:bg-doit-primary/30 relative overflow-hidden flex flex-col">
      {/* Background Decor */}
      <div className="absolute top-[-100px] right-[-100px] w-[500px] h-[500px] bg-doit-accent rounded-full blur-[150px] opacity-20 pointer-events-none z-0"></div>
      <div className="absolute bottom-[-50px] left-[-50px] w-[300px] h-[300px] bg-doit-primary rounded-full blur-[120px] opacity-10 pointer-events-none z-0"></div>

      <Navbar />
      <main className="flex-1 flex flex-col z-10 w-full">
        <Hero />
        <Features />
        <Screenshots />
        <Reports />
        <Testimonials />
        <Installation />
      </main>
      <Footer />
    </div>
  );
}
