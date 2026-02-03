import AdminLayout from '@/Layouts/AdminLayout';
import { Head, useForm } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function CreateProject() {
  const { data, setData, post, processing, errors } = useForm({
    title: '',
    slug: '',
    excerpt: '',
    description: '',
    stack: [],
    url: '',
    is_featured: false,
    sort_order: 0,
  });

  const submit = (e) => {
    e.preventDefault();
    post('/admin/projects');
  };

  return (
    <AdminLayout>
      <Head title="Create Project" />
      <h1 className="text-2xl font-semibold tracking-tight">Create Project</h1>

      <ProjectForm
        data={data}
        setData={setData}
        errors={errors}
        processing={processing}
        onSubmit={submit}
      />
    </AdminLayout>
  );
}

function ProjectForm({ data, setData, errors, processing, onSubmit }) {
  return (
    <form onSubmit={onSubmit} className="mt-6 max-w-2xl space-y-4">
      <Field label="Title" error={errors.title}>
        <input className={inputCls} value={data.title} onChange={(e) => setData('title', e.target.value)} />
      </Field>

      <Field label="Slug (optional)" error={errors.slug}>
        <input className={inputCls} value={data.slug} onChange={(e) => setData('slug', e.target.value)} />
      </Field>

      <Field label="Excerpt" error={errors.excerpt}>
        <input className={inputCls} value={data.excerpt} onChange={(e) => setData('excerpt', e.target.value)} />
      </Field>

      <Field label="Description" error={errors.description}>
        <textarea className={textareaCls} value={data.description} onChange={(e) => setData('description', e.target.value)} />
      </Field>

      <Field label="Stack (comma separated)" error={errors.stack}>
        <input
          className={inputCls}
          value={data.stack.join(', ')}
          onChange={(e) =>
            setData(
              'stack',
              e.target.value
                .split(',')
                .map((s) => s.trim())
                .filter(Boolean)
            )
          }
        />
      </Field>

      <Field label="URL" error={errors.url}>
        <input className={inputCls} value={data.url} onChange={(e) => setData('url', e.target.value)} />
      </Field>

      <div className="flex flex-wrap items-center gap-4">
        <label className="flex items-center gap-2 text-sm text-zinc-200">
          <input
            type="checkbox"
            checked={data.is_featured}
            onChange={(e) => setData('is_featured', e.target.checked)}
          />
          Featured
        </label>

        <div className="flex items-center gap-2 text-sm text-zinc-200">
          <span>Sort</span>
          <input
            type="number"
            className="w-24 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm outline-none"
            value={data.sort_order}
            onChange={(e) => setData('sort_order', Number(e.target.value))}
          />
        </div>
      </div>

      <Button disabled={processing}>{processing ? 'Saving…' : 'Save'}</Button>
    </form>
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
