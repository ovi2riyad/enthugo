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
