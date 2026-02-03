import { Link } from '@inertiajs/react';

export default function FeaturedProjectsSection({ projects = [] }) {
  if (!projects.length) return null;

  return (
    <section className="mt-10">
      <div className="flex items-end justify-between gap-6">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Featured Projects</h2>
          <p className="mt-2 text-sm text-zinc-400">A few highlighted builds.</p>
        </div>
        <Link
          href="/projects"
          className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-zinc-200 hover:bg-white/10"
        >
          View all
        </Link>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {projects.map((p) => (
          <a
            key={p.id}
            href={p.url || '/projects'}
            target={p.url ? '_blank' : undefined}
            rel={p.url ? 'noreferrer' : undefined}
            className="group overflow-hidden rounded-3xl border border-white/10 bg-white/5 transition hover:border-cyan-400/20"
          >
            <Thumb image_path={p.image_path} title={p.title} />
            <div className="p-5">
              <div className="flex items-center justify-between gap-3">
                <h3 className="font-semibold text-white">{p.title}</h3>
                <span className="rounded-full border border-cyan-400/20 bg-cyan-400/10 px-2 py-0.5 text-xs text-cyan-100">
                  Featured
                </span>
              </div>
              {p.excerpt && <p className="mt-2 text-sm text-zinc-300">{p.excerpt}</p>}
              {Array.isArray(p.stack) && p.stack.length > 0 && (
                <div className="mt-4 flex flex-wrap gap-2">
                  {p.stack.slice(0, 5).map((t) => (
                    <span key={t} className="rounded-full bg-black/30 px-2 py-0.5 text-xs text-zinc-300">
                      {t}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </a>
        ))}
      </div>
    </section>
  );
}

function Thumb({ image_path, title }) {
  const src = image_path ? `/storage/${image_path}` : null;
  return (
    <div className="relative aspect-[16/9] w-full bg-gradient-to-b from-cyan-400/10 to-transparent">
      {src ? (
        <img src={src} alt={title} className="h-full w-full object-cover opacity-95" loading="lazy" />
      ) : (
        <div className="flex h-full w-full items-center justify-center text-xs text-zinc-400">
          No image
        </div>
      )}
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
    </div>
  );
}
