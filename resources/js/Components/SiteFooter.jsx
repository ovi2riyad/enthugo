export default function SiteFooter() {
  const year = new Date().getFullYear();
  return (
    <footer className="border-t border-white/10 bg-zinc-950">
      <div className="mx-auto max-w-6xl px-4 py-10 text-sm text-zinc-400 sm:px-6 lg:px-8">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>© {year} Enthugo. All rights reserved.</div>
          <div className="text-zinc-500">
            Built with Laravel + Inertia + React
          </div>
        </div>
      </div>
    </footer>
  );
}
