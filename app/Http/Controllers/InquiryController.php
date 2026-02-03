<?php

namespace App\Http\Controllers;

use App\Models\Inquiry;
use Illuminate\Http\Request;

class InquiryController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required','string','max:80'],
            'email' => ['required','email','max:120'],
            'message' => ['required','string','max:2000'],
        ]);

        Inquiry::create($data);

        return back()->with('success', 'Thanks! I will reply soon.');
    }
}
