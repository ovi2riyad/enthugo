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
