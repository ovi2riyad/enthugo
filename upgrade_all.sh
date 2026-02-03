#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Guard: must be Laravel root
# -----------------------------
if [[ ! -f artisan ]]; then
  echo "❌ Run from Laravel root (where artisan exists)."
  exit 1
fi

PHP_BIN="${PHP_BIN:-php}"

echo "==> 0) Ensure env + deps exist"
cp -n .env.example .env || true
npm install >/dev/null 2>&1 || true

echo "==> 1) Add MAIL_TO_ADDRESS to .env.example (for inquiry notification emails)"
grep -q '^MAIL_TO_ADDRESS=' .env.example || cat >> .env.example <<'ENV'

# Where contact inquiries should be sent
MAIL_TO_ADDRESS=you@example.com
MAIL_TO_NAME="Enthugo"
ENV

echo "==> 2) Add project image support (migration + model + controllers)"
# Create migration file
${PHP_BIN} artisan make:migration add_image_path_to_projects_table --table=projects >/dev/null
MIG_FILE="$(ls database/migrations/*_add_image_path_to_projects_table.php | tail -n 1)"

cat > "$MIG_FILE" <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('projects', function (Blueprint $table) {
            $table->string('image_path')->nullable()->after('url');
        });
    }

    public function down(): void
    {
        Schema::table('projects', function (Blueprint $table) {
            $table->dropColumn('image_path');
        });
    }
};
PHP

# Update Project model fillable/casts
cat > app/Models/Project.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    protected $fillable = [
        'title',
        'slug',
        'excerpt',
        'description',
        'stack',
        'url',
        'image_path',
        'is_featured',
        'sort_order',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'stack' => 'array',
        'sort_order' => 'integer',
    ];
}
PHP

echo "==> 3) Add inquiry email notification + spam protection"
# Add config/mail.php "to" target without breaking defaults
# We'll patch by inserting a 'to' config near the top-level return array.
if ! grep -q "'to' =>" config/mail.php; then
  perl -0777 -i -pe 's/return \[\n/return [\n    \x27to\x27 => [\n        \x27address\x27 => env(\x27MAIL_TO_ADDRESS\x27),\n        \x27name\x27 => env(\x27MAIL_TO_NAME\x27, \x27Enthugo\x27),\n    ],\n\n/s' config/mail.php
fi

# Create Mailable
mkdir -p app/Mail resources/views/emails
cat > app/Mail/InquiryReceived.php <<'PHP'
<?php

namespace App\Mail;

use App\Models\Inquiry;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class InquiryReceived extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public Inquiry $inquiry) {}

    public function build()
    {
        return $this->subject('New inquiry from '.$this->inquiry->name)
            ->view('emails.inquiry_received', [
                'inquiry' => $this->inquiry,
            ]);
    }
}
PHP

cat > resources/views/emails/inquiry_received.blade.php <<'BLADE'
<!doctype html>
<html>
  <body style="font-family: ui-sans-serif, system-ui; line-height:1.5;">
    <h2>New Inquiry</h2>
    <p><strong>Name:</strong> {{ $inquiry->name }}</p>
    <p><strong>Email:</strong> {{ $inquiry->email }}</p>
    <p><strong>Message:</strong></p>
    <pre style="white-space: pre-wrap; background:#f6f6f6; padding:12px; border-radius:10px;">{{ $inquiry->message }}</pre>
    <p style="color:#666; font-size:12px;">Sent from Enthugo contact form.</p>
  </body>
</html>
BLADE

# Update InquiryController (honeypot + email notification)
cat > app/Http/Controllers/InquiryController.php <<'PHP'
<?php

namespace App\Http\Controllers;

use App\Mail\InquiryReceived;
use App\Models\Inquiry;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class InquiryController extends Controller
{
    public function store(Request $request)
    {
        // Honeypot field: bots often fill it, humans won't see it
        $data = $request->validate([
            'name' => ['required','string','max:80'],
            'email' => ['required','email','max:120'],
            'message' => ['required','string','max:2000'],
            'website' => ['nullable','string','max:200'], // honeypot
        ]);

        if (!empty($data['website'])) {
            // Silently pretend success to avoid bot feedback loops
            return back()->with('success', 'Thanks! I will reply soon.');
        }

        unset($data['website']);

        $inquiry = Inquiry::create($data);

        $to = config('mail.to.address');
        if ($to) {
            Mail::to($to)->send(new InquiryReceived($inquiry));
        }

        return back()->with('success', 'Thanks! I will reply soon.');
    }
}
PHP

echo "==> 4) Improve controllers for Home + Admin project image upload + quick updates"

# Home now includes featured projects
cat > routes/web.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

use App\Models\Project;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\InquiryController;

use App\Http\Controllers\Admin\ProjectController as AdminProjectController;
use App\Http\Controllers\Admin\InquiryController as AdminInquiryController;

Route::get('/', function () {
    $featured = Project::query()
        ->where('is_featured', true)
        ->orderBy('sort_order')
        ->orderByDesc('id')
        ->take(6)
        ->get(['id','title','slug','excerpt','stack','url','image_path','is_featured','sort_order']);

    return Inertia::render('Home', [
        'featuredProjects' => $featured,
    ]);
})->name('home');

Route::get('/projects', [ProjectController::class, 'index'])->name('projects.index');
Route::get('/contact', fn () => Inertia::render('Contact'))->name('contact');

/**
 * Spam protection: limit inquiry posts (10 per minute per IP).
 */
Route::post('/inquiries', [InquiryController::class, 'store'])
    ->middleware('throttle:10,1')
    ->name('inquiries.store');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/dashboard', fn () => Inertia::render('Dashboard'))->name('dashboard');

    Route::middleware(['admin'])->prefix('admin')->name('admin.')->group(function () {
        Route::get('/', fn () => Inertia::render('Admin/Dashboard'))->name('dashboard');

        Route::resource('projects', AdminProjectController::class)->except(['show']);
        Route::patch('projects/{project}/quick', [AdminProjectController::class, 'quick'])
            ->name('projects.quick');

        Route::get('inquiries', [AdminInquiryController::class, 'index'])->name('inquiries.index');
        Route::delete('inquiries/{inquiry}', [AdminInquiryController::class, 'destroy'])->name('inquiries.destroy');
    });
});

require __DIR__.'/auth.php';
PHP

# Public projects controller include image_path
cat > app/Http/Controllers/ProjectController.php <<'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\Project;
use Inertia\Inertia;

class ProjectController extends Controller
{
    public function index()
    {
        $projects = Project::query()
            ->orderByDesc('is_featured')
            ->orderBy('sort_order')
            ->orderByDesc('id')
            ->get([
                'id','title','slug','excerpt','stack','url','image_path','is_featured','sort_order'
            ]);

        return Inertia::render('Projects/Index', [
            'projects' => $projects,
        ]);
    }
}
PHP

# Admin projects controller: handle image upload + quick updates (featured/sort)
cat > app/Http/Controllers/Admin/ProjectController.php <<'PHP'
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Inertia\Inertia;

class ProjectController extends Controller
{
    public function index()
    {
        return Inertia::render('Admin/Projects/Index', [
            'projects' => Project::orderBy('sort_order')->orderByDesc('id')->get(),
        ]);
    }

    public function create()
    {
        return Inertia::render('Admin/Projects/Create');
    }

    public function store(Request $request)
    {
        $data = $this->validateProject($request);

        if (empty($data['slug'])) {
            $data['slug'] = Str::slug($data['title']);
        }

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('projects', 'public');
        }

        Project::create($data);

        return redirect()->route('admin.projects.index')->with('success', 'Project created.');
    }

    public function edit(Project $project)
    {
        return Inertia::render('Admin/Projects/Edit', [
            'project' => $project,
        ]);
    }

    public function update(Request $request, Project $project)
    {
        $data = $this->validateProject($request);

        if (empty($data['slug'])) {
            $data['slug'] = Str::slug($data['title']);
        }

        if ($request->hasFile('image')) {
            // delete old
            if ($project->image_path) {
                Storage::disk('public')->delete($project->image_path);
            }
            $data['image_path'] = $request->file('image')->store('projects', 'public');
        }

        $project->update($data);

        return redirect()->route('admin.projects.index')->with('success', 'Project updated.');
    }

    public function destroy(Project $project)
    {
        if ($project->image_path) {
            Storage::disk('public')->delete($project->image_path);
        }
        $project->delete();

        return back()->with('success', 'Project deleted.');
    }

    /**
     * Quick inline updates from Admin list:
     * - is_featured toggle
     * - sort_order change
     */
    public function quick(Request $request, Project $project)
    {
        $data = $request->validate([
            'is_featured' => ['nullable', 'boolean'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:9999'],
        ]);

        $project->update(array_filter($data, fn ($v) => $v !== null));

        return back()->with('success', 'Updated.');
    }

    private function validateProject(Request $request): array
    {
        return $request->validate([
            'title' => ['required','string','max:140'],
            'slug' => ['nullable','string','max:160'],
            'excerpt' => ['nullable','string','max:240'],
            'description' => ['nullable','string','max:4000'],
            'stack' => ['nullable'],
            'url' => ['nullable','url','max:255'],
            'image' => ['nullable','file','mimes:jpg,jpeg,png,webp','max:4096'],
            'is_featured' => ['boolean'],
            'sort_order' => ['nullable','integer','min:0','max:9999'],
        ]);
    }
}
PHP

echo "==> 5) Frontend upgrades: Home (About + Featured + CTA), Projects thumbnails, Admin search/toggles, Contact honeypot"

# New sections
mkdir -p resources/js/Sections

cat > resources/js/Sections/AboutSection.jsx <<'JSX'
export default function AboutSection() {
  return (
    <section className="mt-10">
      <div className="rounded-3xl border border-white/10 bg-white/5 p-6 sm:p-8">
        <div className="text-xs uppercase tracking-widest text-cyan-300/70">About</div>
        <h2 className="mt-2 text-2xl font-semibold tracking-tight">I build fast, modern web experiences.</h2>
        <p className="mt-3 max-w-3xl text-sm leading-relaxed text-zinc-300">
          Enthugo is built with Laravel 12 + Inertia + React + Vite + Tailwind. Clean structure, mobile-first UI,
          and performance-focused components — no lag, no layout breaking.
        </p>

        <div className="mt-5 grid gap-3 sm:grid-cols-3">
          <Chip title="Clean architecture" desc="Layouts / Pages / Components" />
          <Chip title="Performance" desc="Minimal jank, smooth UX" />
          <Chip title="Production-ready" desc="CI + modular codebase" />
        </div>
      </div>
    </section>
  );
}

function Chip({ title, desc }) {
  return (
    <div className="rounded-2xl border border-white/10 bg-black/20 p-4">
      <div className="text-sm font-semibold text-white">{title}</div>
      <div className="mt-1 text-xs text-zinc-400">{desc}</div>
    </div>
  );
}
JSX

cat > resources/js/Sections/FeaturedProjectsSection.jsx <<'JSX'
import { Link } from '@inertiajs/react';

export default function FeaturedProjectsSection({ projects = [] }) {
  if (!projects.length) return null;

  return (
    <section className="mt-10">
      <div className="flex items-end justify-between gap-6">
        <div>
          <h2 className="text-2xl font-semibold tracking-tight">Featured Projects</h2>
          <p className="mt-2 text-sm text-zinc-400">A few highlighted builds.</p>
        </div>
        <Link
          href="/projects"
          className="rounded-full border border-white/10 bg-white/5 px-4 py-2 text-sm text-zinc-200 hover:bg-white/10"
        >
          View all
        </Link>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {projects.map((p) => (
          <a
            key={p.id}
            href={p.url || '/projects'}
            target={p.url ? '_blank' : undefined}
            rel={p.url ? 'noreferrer' : undefined}
            className="group overflow-hidden rounded-3xl border border-white/10 bg-white/5 transition hover:border-cyan-400/20"
          >
            <Thumb image_path={p.image_path} title={p.title} />
            <div className="p-5">
              <div className="flex items-center justify-between gap-3">
                <h3 className="font-semibold text-white">{p.title}</h3>
                <span className="rounded-full border border-cyan-400/20 bg-cyan-400/10 px-2 py-0.5 text-xs text-cyan-100">
                  Featured
                </span>
              </div>
              {p.excerpt && <p className="mt-2 text-sm text-zinc-300">{p.excerpt}</p>}
              {Array.isArray(p.stack) && p.stack.length > 0 && (
                <div className="mt-4 flex flex-wrap gap-2">
                  {p.stack.slice(0, 5).map((t) => (
                    <span key={t} className="rounded-full bg-black/30 px-2 py-0.5 text-xs text-zinc-300">
                      {t}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </a>
        ))}
      </div>
    </section>
  );
}

function Thumb({ image_path, title }) {
  const src = image_path ? `/storage/${image_path}` : null;
  return (
    <div className="relative aspect-[16/9] w-full bg-gradient-to-b from-cyan-400/10 to-transparent">
      {src ? (
        <img src={src} alt={title} className="h-full w-full object-cover opacity-95" loading="lazy" />
      ) : (
        <div className="flex h-full w-full items-center justify-center text-xs text-zinc-400">
          No image
        </div>
      )}
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
    </div>
  );
}
JSX

cat > resources/js/Sections/CTASection.jsx <<'JSX'
import { Link } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function CTASection() {
  return (
    <section className="mt-10">
      <div className="rounded-3xl border border-cyan-400/15 bg-gradient-to-b from-cyan-400/10 to-transparent p-6 sm:p-10">
        <div className="text-xs uppercase tracking-widest text-cyan-300/70">Let’s build</div>
        <h2 className="mt-2 text-2xl font-semibold tracking-tight">Have a project idea?</h2>
        <p className="mt-3 max-w-2xl text-sm text-zinc-300">
          Send a message and I’ll reply with a plan, timeline, and stack recommendation.
        </p>
        <div className="mt-6">
          <Link href="/contact">
            <Button>Contact</Button>
          </Link>
        </div>
      </div>
    </section>
  );
}
JSX

# Update Home page to include About + Featured + CTA
cat > resources/js/Pages/Home.jsx <<'JSX'
import AppLayout from '@/Layouts/AppLayout';
import { Head, Link } from '@inertiajs/react';
import ServicesSection from '@/Sections/ServicesSection';
import AboutSection from '@/Sections/AboutSection';
import FeaturedProjectsSection from '@/Sections/FeaturedProjectsSection';
import CTASection from '@/Sections/CTASection';
import Button from '@/Components/Button';

export default function Home({ featuredProjects = [] }) {
  return (
    <AppLayout>
      <Head title="Home" />

      <section className="pt-4">
        <div className="rounded-3xl border border-white/10 bg-gradient-to-b from-white/5 to-transparent p-6 sm:p-10">
          <div className="max-w-2xl">
            <div className="text-xs uppercase tracking-widest text-cyan-300/70">Enthugo</div>
            <h1 className="mt-3 text-3xl font-semibold tracking-tight sm:text-4xl">
              Futuristic web experiences — clean, fast, and production-ready.
            </h1>
            <p className="mt-4 text-sm leading-relaxed text-zinc-300">
              Laravel 12 + Inertia + React + Vite + Tailwind. Modular structure. Mobile-first. Smooth UI.
            </p>

            <div className="mt-6 flex flex-wrap gap-3">
              <Link href="/projects">
                <Button>View Projects</Button>
              </Link>
              <Link href="/contact">
                <Button variant="ghost">Contact</Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      <AboutSection />
      <FeaturedProjectsSection projects={featuredProjects} />
      <ServicesSection />
      <CTASection />
    </AppLayout>
  );
}
JSX

# Update Projects page to show thumbnails
cat > resources/js/Pages/Projects/Index.jsx <<'JSX'
import AppLayout from '@/Layouts/AppLayout';
import { Head } from '@inertiajs/react';

export default function ProjectsIndex({ projects }) {
  return (
    <AppLayout>
      <Head title="Projects" />
      <h1 className="text-2xl font-semibold tracking-tight">Projects</h1>
      <p className="mt-2 text-sm text-zinc-400">A curated set of builds.</p>

      <div className="mt-6 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {projects.map((p) => (
          <a
            key={p.id}
            href={p.url || '#'}
            target={p.url ? '_blank' : undefined}
            rel={p.url ? 'noreferrer' : undefined}
            className="group overflow-hidden rounded-3xl border border-white/10 bg-white/5 transition hover:border-cyan-400/20"
          >
            <Thumb image_path={p.image_path} title={p.title} />

            <div className="p-5">
              <div className="flex items-center justify-between gap-4">
                <h3 className="font-semibold">{p.title}</h3>
                {p.is_featured && (
                  <span className="rounded-full border border-cyan-400/20 bg-cyan-400/10 px-2 py-0.5 text-xs text-cyan-100">
                    Featured
                  </span>
                )}
              </div>

              {p.excerpt && <p className="mt-2 text-sm text-zinc-300">{p.excerpt}</p>}

              {Array.isArray(p.stack) && p.stack.length > 0 && (
                <div className="mt-4 flex flex-wrap gap-2">
                  {p.stack.slice(0, 6).map((t) => (
                    <span key={t} className="rounded-full bg-black/30 px-2 py-0.5 text-xs text-zinc-300">
                      {t}
                    </span>
                  ))}
                </div>
              )}
            </div>
          </a>
        ))}
      </div>
    </AppLayout>
  );
}

function Thumb({ image_path, title }) {
  const src = image_path ? `/storage/${image_path}` : null;
  return (
    <div className="relative aspect-[16/9] w-full bg-gradient-to-b from-cyan-400/10 to-transparent">
      {src ? (
        <img src={src} alt={title} className="h-full w-full object-cover opacity-95" loading="lazy" />
      ) : (
        <div className="flex h-full w-full items-center justify-center text-xs text-zinc-400">No image</div>
      )}
      <div className="pointer-events-none absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
    </div>
  );
}
JSX

# Contact honeypot field (hidden) + clearer UI
cat > resources/js/Pages/Contact.jsx <<'JSX'
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
JSX

# Admin Projects UI: search + featured toggle + inline sort order
cat > resources/js/Pages/Admin/Projects/Index.jsx <<'JSX'
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
JSX

# Admin Create/Edit: add image upload (forceFormData)
cat > resources/js/Pages/Admin/Projects/Create.jsx <<'JSX'
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
    image: null,
    is_featured: false,
    sort_order: 0,
  });

  const submit = (e) => {
    e.preventDefault();
    post('/admin/projects', { forceFormData: true });
  };

  return (
    <AdminLayout>
      <Head title="Create Project" />
      <h1 className="text-2xl font-semibold tracking-tight">Create Project</h1>

      <form onSubmit={submit} className="mt-6 max-w-2xl space-y-4">
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

        <Field label="Image (jpg/png/webp)" error={errors.image}>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            className="block w-full text-sm text-zinc-200"
            onChange={(e) => setData('image', e.target.files?.[0] || null)}
          />
          <div className="mt-2 text-xs text-zinc-500">Recommended: 1600×900</div>
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
    </AdminLayout>
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
JSX

cat > resources/js/Pages/Admin/Projects/Edit.jsx <<'JSX'
import AdminLayout from '@/Layouts/AdminLayout';
import { Head, useForm } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function EditProject({ project }) {
  const { data, setData, post, processing, errors } = useForm({
    title: project.title || '',
    slug: project.slug || '',
    excerpt: project.excerpt || '',
    description: project.description || '',
    stack: project.stack || [],
    url: project.url || '',
    image: null,
    is_featured: !!project.is_featured,
    sort_order: project.sort_order ?? 0,
  });

  const submit = (e) => {
    e.preventDefault();
    post(`/admin/projects/${project.id}`, {
      forceFormData: true,
      data: { ...data, _method: 'PUT' },
    });
  };

  const currentImg = project.image_path ? `/storage/${project.image_path}` : null;

  return (
    <AdminLayout>
      <Head title="Edit Project" />
      <h1 className="text-2xl font-semibold tracking-tight">Edit Project</h1>

      <form onSubmit={submit} className="mt-6 max-w-2xl space-y-4">
        <Field label="Title" error={errors.title}>
          <input className={inputCls} value={data.title} onChange={(e) => setData('title', e.target.value)} />
        </Field>

        <Field label="Slug" error={errors.slug}>
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

        <Field label="Current image">
          {currentImg ? (
            <img src={currentImg} alt="Current" className="mt-2 w-full max-w-sm rounded-2xl border border-white/10" />
          ) : (
            <div className="text-sm text-zinc-400">No image uploaded.</div>
          )}
        </Field>

        <Field label="Replace image (optional)" error={errors.image}>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp"
            className="block w-full text-sm text-zinc-200"
            onChange={(e) => setData('image', e.target.files?.[0] || null)}
          />
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

        <Button disabled={processing}>{processing ? 'Saving…' : 'Save Changes'}</Button>
      </form>
    </AdminLayout>
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
JSX

echo "==> 6) Ensure storage symlink exists for /storage/* thumbnails"
${PHP_BIN} artisan storage:link >/dev/null 2>&1 || true

echo "==> 7) Migrate + build to verify"
${PHP_BIN} artisan migrate --force
npm run build

echo ""
echo "✅ Upgrade complete!"
echo ""
echo "Next:"
echo "  php artisan serve --host 0.0.0.0 --port 8000"
echo "  # (Optional dev server) npm run dev -- --host 0.0.0.0 --port 5173 --strictPort"
echo ""
echo "Remember to set in .env:"
echo "  MAIL_TO_ADDRESS=your@email.com"
echo "  MAIL_TO_NAME=Your Name"
