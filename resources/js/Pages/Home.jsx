import AppLayout from '@/Layouts/AppLayout';
import { Head, Link } from '@inertiajs/react';
import ServicesSection from '@/Sections/ServicesSection';
import AboutSection from '@/Sections/AboutSection';
import FeaturedProjectsSection from '@/Sections/FeaturedProjectsSection';
import CTASection from '@/Sections/CTASection';
import Button from '@/Components/Button';

export default function Home({ featuredProjects = [] }) {
  return (
    <AppLayout>
      <Head title="Home" />

      <section className="pt-4">
        <div className="rounded-3xl border border-white/10 bg-gradient-to-b from-white/5 to-transparent p-6 sm:p-10">
          <div className="max-w-2xl">
            <div className="text-xs uppercase tracking-widest text-cyan-300/70">Enthugo</div>
            <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">
              Futuristic web experiences — clean, fast, and production-ready.
            </h1>
            <p className="mt-4 text-sm leading-relaxed text-zinc-300">
              Laravel 12 + Inertia + React + Vite + Tailwind. Modular structure. Mobile-first. Smooth UI.
            </p>

            <div className="mt-6 flex flex-wrap gap-3">
              <Link href="/projects">
                <Button>View Projects</Button>
              </Link>
              <Link href="/contact">
                <Button variant="ghost">Contact</Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      <AboutSection />
      <FeaturedProjectsSection projects={featuredProjects} />
      <ServicesSection />
      <CTASection />
    </AppLayout>
  );
}
