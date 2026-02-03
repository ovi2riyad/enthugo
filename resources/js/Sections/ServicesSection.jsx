import { useMemo, useState } from 'react';
import FullscreenModal from '@/Components/FullscreenModal';
import Button from '@/Components/Button';

export default function ServicesSection() {
  const services = useMemo(
    () => [
      {
        key: 'webapps',
        title: 'Web Apps',
        blurb: 'Fast, modern, scalable web applications.',
        body: (
          <>
            <p className="leading-relaxed text-zinc-300">
              Full-stack builds with Laravel + Inertia + React. Clean architecture, smooth UX, and production stability.
            </p>
            <ul className="mt-4 grid gap-2 text-sm text-zinc-300 sm:grid-cols-2">
              <li className="rounded-xl border border-white/10 bg-white/5 p-3">Inertia SPA experience</li>
              <li className="rounded-xl border border-white/10 bg-white/5 p-3">Vite optimized bundles</li>
              <li className="rounded-xl border border-white/10 bg-white/5 p-3">Tailwind design systems</li>
              <li className="rounded-xl border border-white/10 bg-white/5 p-3">Testing + maintainability</li>
            </ul>
          </>
        ),
      },
      {
        key: 'uiux',
        title: 'UI Systems',
        blurb: 'Reusable components, consistent design language.',
        body: (
          <p className="leading-relaxed text-zinc-300">
            Component-first UI that stays consistent across pages. Mobile-first layouts that don’t break.
          </p>
        ),
      },
      {
        key: 'performance',
        title: 'Performance',
        blurb: 'No lag. No jank. Smooth interactions.',
        body: (
          <p className="leading-relaxed text-zinc-300">
            Smart rendering, minimal reflows, and optimized routes. Less JavaScript, more speed.
          </p>
        ),
      },
    ],
    []
  );

  const [active, setActive] = useState(null);
  const current = services.find((s) => s.key === active);

  return (
    <section className="mt-14">
      <div className="flex items-end justify-between gap-6">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Services</h2>
          <p className="mt-2 max-w-2xl text-sm text-zinc-400">
            Futuristic builds with clean code, speed, and a polished UI system.
          </p>
        </div>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {services.map((s) => (
          <div
            key={s.key}
            className="group rounded-3xl border border-white/10 bg-gradient-to-b from-white/5 to-transparent p-5 transition hover:border-cyan-400/20 hover:shadow-[0_0_50px_rgba(34,211,238,0.10)]"
          >
            <div className="flex items-center gap-3">
              <div className="h-2 w-2 rounded-full bg-cyan-400/80 shadow-[0_0_24px_rgba(34,211,238,0.45)]" />
              <h3 className="font-semibold tracking-tight">{s.title}</h3>
            </div>
            <p className="mt-3 text-sm text-zinc-400">{s.blurb}</p>
            <div className="mt-5">
              <Button variant="ghost" onClick={() => setActive(s.key)}>
                Open
              </Button>
            </div>
          </div>
        ))}
      </div>

      <FullscreenModal
        open={!!current}
        onClose={() => setActive(null)}
        title={current?.title}
      >
        {current?.body}
        <div className="mt-6 rounded-2xl border border-cyan-400/10 bg-cyan-400/5 p-4 text-sm text-cyan-100">
          Want this service? Use the Contact page and send a quick message.
        </div>
      </FullscreenModal>
    </section>
  );
}
