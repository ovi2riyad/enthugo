import AdminLayout from '@/Layouts/AdminLayout';
import { Head, router } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function AdminInquiries({ inquiries }) {
  return (
    <AdminLayout>
      <Head title="Inquiries" />
      <h1 className="text-2xl font-semibold tracking-tight">Inquiries</h1>
      <p className="mt-2 text-sm text-zinc-400">Messages submitted from the Contact page.</p>

      <div className="mt-6 grid gap-4">
        {inquiries.map((q) => (
          <div key={q.id} className="rounded-3xl border border-white/10 bg-white/5 p-5">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <div className="text-sm text-white">{q.name}</div>
                <div className="text-xs text-zinc-400">{q.email}</div>
              </div>
              <Button variant="danger" onClick={() => router.delete(`/admin/inquiries/${q.id}`)}>
                Delete
              </Button>
            </div>
            <p className="mt-4 whitespace-pre-wrap text-sm text-zinc-200">{q.message}</p>
          </div>
        ))}

        {inquiries.length === 0 && (
          <div className="rounded-3xl border border-white/10 bg-white/5 p-6 text-sm text-zinc-400">
            No inquiries yet.
          </div>
        )}
      </div>
    </AdminLayout>
  );
}
