import { NavBar } from "@/components/NavBar";
import { HeroSection } from "@/components/HeroSection";
import { TickerMarquee } from "@/components/TickerMarquee";
import { AboutSection } from "@/components/AboutSection";
import { GuideSection } from "@/components/GuideSection";
import { CommandsSection } from "@/components/CommandsSection";
import { SecuritySection } from "@/components/SecuritySection";
import { LiveFeed } from "@/components/LiveFeed";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <main className="min-h-screen bg-black text-wire-cyan overflow-x-hidden page-enter">
      <NavBar />
      <HeroSection />
      <TickerMarquee />
      <AboutSection />
      <GuideSection />
      <CommandsSection />
      <SecuritySection />
      <LiveFeed />
      <Footer />
    </main>
  );
}
