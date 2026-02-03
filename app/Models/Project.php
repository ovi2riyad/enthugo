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
