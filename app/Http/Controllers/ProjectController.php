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
                'id','title','slug','excerpt','stack','url','is_featured'
            ]);

        return Inertia::render('Projects/Index', [
            'projects' => $projects,
        ]);
    }
}
