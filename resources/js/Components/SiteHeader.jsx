import { Link, usePage } from '@inertiajs/react';

export default function SiteHeader() {
  const { url, props } = usePage();
  const authed = !!props?.auth?.user;

  const links = [
    { href: '/', label: 'Home' },
    { href: '/projects', label: 'Projects' },
    { href: '/contact', label: 'Contact' },
  ];

  return (
    <header className="sticky top-0 z-50 border-b border-white/10 bg-zinc-950/80 backdrop-blur">
      <div className="mx-auto flex max-w-6xl items-center justify-between px-4 py-4 sm:px-6 lg:px-8">
        <Link href="/" className="flex items-center gap-3">
          <div className="h-2 w-2 rounded-full bg-cyan-400 shadow-[0_0_28px_rgba(34,211,238,0.7)]" />
          <span className="font-semibold tracking-tight">Enthugo</span>
        </Link>

        <nav className="flex items-center gap-2">
          {links.map((l) => {
            const active = url === l.href;
            return (
              <Link
                key={l.href}
                href={l.href}
                className={[
                  'rounded-full px-3 py-1 text-sm transition',
                  active ? 'bg-white/10 text-white' : 'text-zinc-300 hover:bg-white/5 hover:text-white',
                ].join(' ')}
              >
                {l.label}
              </Link>
            );
          })}

          <div className="ml-2 hidden sm:block">
            {authed ? (
              <Link href="/dashboard" className="rounded-full bg-cyan-400/10 px-3 py-1 text-sm text-cyan-200 hover:bg-cyan-400/15">
                Dashboard
              </Link>
            ) : (
              <Link href="/login" className="rounded-full bg-white/5 px-3 py-1 text-sm text-zinc-200 hover:bg-white/10">
                Login
              </Link>
            )}
          </div>
        </nav>
      </div>
    </header>
  );
}
