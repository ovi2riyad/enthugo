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
