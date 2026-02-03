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
