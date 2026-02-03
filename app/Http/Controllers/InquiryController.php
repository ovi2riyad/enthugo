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
