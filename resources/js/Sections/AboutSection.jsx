export default function AboutSection() {
  return (
    <section className="mt-10">
      <div className="rounded-3xl border border-white/10 bg-white/5 p-6 sm:p-8">
        <div className="text-xs uppercase tracking-widest text-cyan-300/70">About</div>
        <h2 className="mt-2 text-2xl font-semibold tracking-tight">I build fast, modern web experiences.</h2>
        <p className="mt-3 max-w-3xl text-sm leading-relaxed text-zinc-300">
          Enthugo is built with Laravel 12 + Inertia + React + Vite + Tailwind. Clean structure, mobile-first UI,
          and performance-focused components — no lag, no layout breaking.
        </p>

        <div className="mt-5 grid gap-3 sm:grid-cols-3">
          <Chip title="Clean architecture" desc="Layouts / Pages / Components" />
          <Chip title="Performance" desc="Minimal jank, smooth UX" />
          <Chip title="Production-ready" desc="CI + modular codebase" />
        </div>
      </div>
    </section>
  );
}

function Chip({ title, desc }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
      <div className="text-sm font-semibold text-white">{title}</div>
      <div className="mt-1 text-xs text-zinc-400">{desc}</div>
    </div>
  );
}
