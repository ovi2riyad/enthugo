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
