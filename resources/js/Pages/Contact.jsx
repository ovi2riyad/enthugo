import AppLayout from '@/Layouts/AppLayout';
import { Head, useForm, usePage } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function Contact() {
  const flash = usePage().props.flash || {};
  const { data, setData, post, processing, errors, reset } = useForm({
    name: '',
    email: '',
    message: '',
    website: '', // honeypot
  });

  const submit = (e) => {
    e.preventDefault();
    post(route('inquiries.store'), {
      onSuccess: () => reset('message', 'website'),
    });
  };

  return (
    <AppLayout>
      <Head title="Contact" />
      <h1 className="text-2xl font-semibold tracking-tight">Contact</h1>
      <p className="mt-2 text-sm text-zinc-400">Send an inquiry — you’ll get a reply soon.</p>

      {flash.success && (
        <div className="mt-4 rounded-2xl border border-cyan-400/20 bg-cyan-400/10 p-4 text-sm text-cyan-100">
          {flash.success}
        </div>
      )}

      <form onSubmit={submit} className="mt-6 max-w-xl space-y-4">
        {/* Honeypot - keep hidden */}
        <div className="hidden">
          <label>Website</label>
          <input value={data.website} onChange={(e) => setData('website', e.target.value)} />
        </div>

        <Field label="Name" error={errors.name}>
          <input
            value={data.name}
            onChange={(e) => setData('name', e.target.value)}
            className={inputCls}
            placeholder="Your name"
          />
        </Field>

        <Field label="Email" error={errors.email}>
          <input
            value={data.email}
            onChange={(e) => setData('email', e.target.value)}
            className={inputCls}
            placeholder="you@example.com"
          />
        </Field>

        <Field label="Message" error={errors.message}>
          <textarea
            value={data.message}
            onChange={(e) => setData('message', e.target.value)}
            className={textareaCls}
            placeholder="Tell me what you want to build…"
          />
        </Field>

        <Button disabled={processing}>
          {processing ? 'Sending…' : 'Send Inquiry'}
        </Button>

        <div className="text-xs text-zinc-500">
          Spam protected (rate limit + honeypot).
        </div>
      </form>
    </AppLayout>
  );
}

function Field({ label, error, children }) {
  return (
    <div>
      <div className="mb-2 text-sm text-zinc-200">{label}</div>
      {children}
      {error && <div className="mt-2 text-xs text-rose-300">{error}</div>}
    </div>
  );
}

const inputCls =
  'w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm outline-none focus:border-cyan-400/30';
const textareaCls =
  'min-h-[140px] w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm outline-none focus:border-cyan-400/30';
