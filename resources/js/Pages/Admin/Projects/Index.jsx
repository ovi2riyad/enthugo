import AdminLayout from '@/Layouts/AdminLayout';
import { Head, Link, router } from '@inertiajs/react';
import { useMemo, useState } from 'react';
import Button from '@/Components/Button';

export default function AdminProjectsIndex({ projects }) {
  const [q, setQ] = useState('');

  const filtered = useMemo(() => {
    const s = q.trim().toLowerCase();
    if (!s) return projects;
    return projects.filter((p) => {
      const stack = Array.isArray(p.stack) ? p.stack.join(' ') : '';
      return (
        (p.title || '').toLowerCase().includes(s) ||
        (p.slug || '').toLowerCase().includes(s) ||
        (p.excerpt || '').toLowerCase().includes(s) ||
        stack.toLowerCase().includes(s)
      );
    });
  }, [q, projects]);

  const toggleFeatured = (p) => {
    router.patch(`/admin/projects/${p.id}/quick`, { is_featured: !p.is_featured }, { preserveScroll: true });
  };

  const updateSort = (p, value) => {
    const n = Number(value);
    if (Number.isNaN(n)) return;
    router.patch(`/admin/projects/${p.id}/quick`, { sort_order: n }, { preserveScroll: true });
  };

  return (
    <AdminLayout>
      <Head title="Admin Projects" />

      <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Projects</h1>
          <p className="mt-2 text-sm text-zinc-400">Search, toggle featured, and sort without opening edit.</p>
        </div>

        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            className="w-full rounded-2xl border border-white/10 bg-white/5 px-4 py-2 text-sm outline-none focus:border-cyan-400/30 sm:w-80"
            placeholder="Search projects…"
          />
          <Link href="/admin/projects/create">
            <Button>Create</Button>
          </Link>
        </div>
      </div>

      <div className="mt-6 overflow-hidden rounded-3xl border border-white/10">
        <table className="w-full text-left text-sm">
          <thead className="bg-white/5 text-zinc-300">
            <tr>
              <th className="px-4 py-3">Preview</th>
              <th className="px-4 py-3">Title</th>
              <th className="px-4 py-3">Featured</th>
              <th className="px-4 py-3">Sort</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/10">
            {filtered.map((p) => (
              <tr key={p.id} className="bg-zinc-950">
                <td className="px-4 py-3">
                  <Thumb image_path={p.image_path} title={p.title} />
                </td>

                <td className="px-4 py-3">
                  <div className="font-medium text-white">{p.title}</div>
                  <div className="text-xs text-zinc-400">{p.slug}</div>
                </td>

                <td className="px-4 py-3">
                  <button
                    onClick={() => toggleFeatured(p)}
                    className={[
                      'rounded-full border px-3 py-1 text-xs transition',
                      p.is_featured
                        ? 'border-cyan-400/25 bg-cyan-400/10 text-cyan-100 hover:bg-cyan-400/15'
                        : 'border-white/10 bg-white/5 text-zinc-200 hover:bg-white/10',
                    ].join(' ')}
                  >
                    {p.is_featured ? 'Featured' : 'Not featured'}
                  </button>
                </td>

                <td className="px-4 py-3">
                  <input
                    type="number"
                    defaultValue={p.sort_order ?? 0}
                    onBlur={(e) => updateSort(p, e.target.value)}
                    className="w-24 rounded-xl border border-white/10 bg-white/5 px-3 py-2 text-sm outline-none focus:border-cyan-400/30"
                  />
                </td>

                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-2">
                    <Link href={`/admin/projects/${p.id}/edit`}>
                      <Button variant="ghost">Edit</Button>
                    </Link>
                    <Button variant="danger" onClick={() => router.delete(`/admin/projects/${p.id}`)}>
                      Delete
                    </Button>
                  </div>
                </td>
              </tr>
            ))}

            {filtered.length === 0 && (
              <tr>
                <td className="px-4 py-6 text-zinc-400" colSpan={5}>
                  No projects found.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}

function Thumb({ image_path, title }) {
  const src = image_path ? `/storage/${image_path}` : null;
  return (
    <div className="h-14 w-24 overflow-hidden rounded-xl border border-white/10 bg-white/5">
      {src ? (
        <img src={src} alt={title} className="h-full w-full object-cover" loading="lazy" />
      ) : (
        <div className="flex h-full w-full items-center justify-center text-[10px] text-zinc-500">No image</div>
      )}
    </div>
  );
}
