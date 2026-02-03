import { Link, usePage } from '@inertiajs/react';

export default function AdminLayout({ children }) {
  const { url } = usePage();
  const nav = [
    { href: '/admin', label: 'Dashboard' },
    { href: '/admin/projects', label: 'Projects' },
    { href: '/admin/inquiries', label: 'Inquiries' },
  ];

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-zinc-950/80 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
          <div className="flex items-center gap-3">
            <div className="h-2 w-2 rounded-full bg-cyan-400 shadow-[0_0_24px_rgba(34,211,238,0.6)]" />
            <span className="font-semibold tracking-tight">Enthugo Admin</span>
          </div>
          <nav className="flex items-center gap-3">
            {nav.map((item) => {
              const active = url.startsWith(item.href);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={[
                    'rounded-full px-3 py-1 text-sm transition',
                    active ? 'bg-white/10 text-white' : 'text-zinc-300 hover:bg-white/5 hover:text-white',
                  ].join(' ')}
                >
                  {item.label}
                </Link>
              );
            })}
          </nav>
        </div>
      </header>

      <main className="mx-auto w-full max-w-6xl px-4 pb-16 pt-8 sm:px-6 lg:px-8">
        {children}
      </main>
    </div>
  );
}
