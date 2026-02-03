import { Link } from '@inertiajs/react';
import Button from '@/Components/Button';

export default function CTASection() {
  return (
    <section className="mt-10">
      <div className="rounded-3xl border border-cyan-400/15 bg-gradient-to-b from-cyan-400/10 to-transparent p-6 sm:p-10">
        <div className="text-xs uppercase tracking-widest text-cyan-300/70">Let’s build</div>
        <h2 className="mt-2 text-2xl font-semibold tracking-tight">Have a project idea?</h2>
        <p className="mt-3 max-w-2xl text-sm text-zinc-300">
          Send a message and I’ll reply with a plan, timeline, and stack recommendation.
        </p>
        <div className="mt-6">
          <Link href="/contact">
            <Button>Contact</Button>
          </Link>
        </div>
      </div>
    </section>
  );
}
