import AdminLayout from '@/Layouts/AdminLayout';
import { Head } from '@inertiajs/react';

export default function AdminDashboard() {
  return (
    <AdminLayout>
      <Head title="Admin" />
      <h1 className="text-2xl font-semibold tracking-tight">Admin Dashboard</h1>
      <p className="mt-2 text-sm text-zinc-400">Manage projects and inquiries.</p>
    </AdminLayout>
  );
}
