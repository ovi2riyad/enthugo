import { useEffect } from 'react';

export default function FullscreenModal({ open, onClose, title, children }) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => e.key === 'Escape' && onClose?.();
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[100]">
      <div
        className="absolute inset-0 bg-black/70 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />
      <div className="absolute inset-0 overflow-auto">
        <div className="mx-auto flex min-h-full max-w-4xl items-center justify-center px-4 py-10">
          <div className="w-full rounded-3xl border border-white/10 bg-zinc-950 p-6 shadow-[0_0_60px_rgba(34,211,238,0.12)]">
            <div className="flex items-start justify-between gap-4">
              <div>
                <div className="text-xs uppercase tracking-widest text-cyan-300/70">Service detail</div>
                <h3 className="mt-1 text-xl font-semibold tracking-tight text-white">{title}</h3>
              </div>
              <button
                onClick={onClose}
                className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-sm text-zinc-200 hover:bg-white/10"
              >
                Close
              </button>
            </div>
            <div className="mt-5 text-zinc-200">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
