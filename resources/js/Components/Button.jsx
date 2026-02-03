export default function Button({ className = '', variant = 'primary', ...props }) {
  const base =
    'inline-flex items-center justify-center rounded-full px-4 py-2 text-sm font-medium transition focus:outline-none focus:ring-2 focus:ring-cyan-400/60';
  const variants = {
    primary: 'bg-cyan-400/15 text-cyan-100 hover:bg-cyan-400/20 border border-cyan-400/20',
    ghost: 'bg-white/5 text-zinc-100 hover:bg-white/10 border border-white/10',
    danger: 'bg-rose-500/10 text-rose-100 hover:bg-rose-500/15 border border-rose-500/20',
  };
  return <button className={[base, variants[variant], className].join(' ')} {...props} />;
}
