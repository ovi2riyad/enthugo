import AppLayout from '@/Layouts/AppLayout';
import { Head } from '@inertiajs/react';

export default function ProjectsIndex({ projects }) {
  return (
    <AppLayout>
      <Head title="Projects" />
      <h1 className="text-2xl font-semibold tracking-tight">Projects</h1>
      <p className="mt-2 text-sm text-zinc-400">A curated set of builds.</p>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {projects.map((p) => (
          <a
            key={p.id}
            href={p.url || '#'}
            target={p.url ? '_blank' : undefined}
            rel={p.url ? 'noreferrer' : undefined}
            className="rounded-3xl border border-white/10 bg-white/5 p-5 transition hover:border-cyan-400/20 hover:bg-white/6"
          >
            <div className="flex items-center justify-between gap-4">
              <h3 className="font-semibold">{p.title}</h3>
              {p.is_featured && (
                <span className="rounded-full border border-cyan-400/20 bg-cyan-400/10 px-2 py-0.5 text-xs text-cyan-100">
                  Featured
                </span>
              )}
            </div>

            {p.excerpt && <p className="mt-2 text-sm text-zinc-300">{p.excerpt}</p>}

            {Array.isArray(p.stack) && p.stack.length > 0 && (
              <div className="mt-4 flex flex-wrap gap-2">
                {p.stack.slice(0, 6).map((t) => (
                  <span key={t} className="rounded-full bg-black/30 px-2 py-0.5 text-xs text-zinc-300">
                    {t}
                  </span>
                ))}
              </div>
            )}
          </a>
        ))}
      </div>
    </AppLayout>
  );
}
