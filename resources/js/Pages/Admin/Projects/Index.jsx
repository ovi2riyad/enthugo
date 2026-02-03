import AdminLayout from '@/Layouts/AdminLayout';
import { Head, Link, router } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function AdminProjectsIndex({ projects }) {
  return (
    <AdminLayout>
      <Head title="Admin Projects" />

      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Projects</h1>
          <p className="mt-2 text-sm text-zinc-400">Create and edit projects shown publicly.</p>
        </div>
        <Link href="/admin/projects/create">
          <Button>Create</Button>
        </Link>
      </div>

      <div className="mt-6 overflow-hidden rounded-3xl border border-white/10">
        <table className="w-full text-left text-sm">
          <thead className="bg-white/5 text-zinc-300">
            <tr>
              <th className="px-4 py-3">Title</th>
              <th className="px-4 py-3">Featured</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/10">
            {projects.map((p) => (
              <tr key={p.id} className="bg-zinc-950">
                <td className="px-4 py-3">{p.title}</td>
                <td className="px-4 py-3">{p.is_featured ? 'Yes' : 'No'}</td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap gap-2">
                    <Link href={`/admin/projects/${p.id}/edit`}>
                      <Button variant="ghost">Edit</Button>
                    </Link>
                    <Button
                      variant="danger"
                      onClick={() => router.delete(`/admin/projects/${p.id}`)}
                    >
                      Delete
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
            {projects.length === 0 && (
              <tr>
                <td className="px-4 py-6 text-zinc-400" colSpan={3}>
                  No projects yet.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </AdminLayout>
  );
}
