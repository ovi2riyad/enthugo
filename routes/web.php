<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;

use App\Http\Controllers\ProjectController;
use App\Http\Controllers\InquiryController;

use App\Http\Controllers\Admin\ProjectController as AdminProjectController;
use App\Http\Controllers\Admin\InquiryController as AdminInquiryController;

Route::get('/', fn () => Inertia::render('Home'))->name('home');
Route::get('/projects', [ProjectController::class, 'index'])->name('projects.index');
Route::get('/contact', fn () => Inertia::render('Contact'))->name('contact');
Route::post('/inquiries', [InquiryController::class, 'store'])->name('inquiries.store');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/dashboard', fn () => Inertia::render('Dashboard'))->name('dashboard');

    Route::middleware(['admin'])->prefix('admin')->name('admin.')->group(function () {
        Route::get('/', fn () => Inertia::render('Admin/Dashboard'))->name('dashboard');

        Route::resource('projects', AdminProjectController::class)->except(['show']);
        Route::get('inquiries', [AdminInquiryController::class, 'index'])->name('inquiries.index');
        Route::delete('inquiries/{inquiry}', [AdminInquiryController::class, 'destroy'])->name('inquiries.destroy');
    });
});

require __DIR__.'/auth.php';
