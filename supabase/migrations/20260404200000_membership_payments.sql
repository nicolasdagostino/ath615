create table if not exists public.membership_payments (
  id uuid primary key default gen_random_uuid(),

  member_id uuid not null references public.profiles(id) on delete restrict,
  membership_id uuid null references public.member_memberships(id) on delete set null,
  plan_id uuid not null references public.membership_plans(id) on delete restrict,

  payment_method text not null
    check (payment_method in ('cash', 'stripe_checkout', 'stripe_subscription', 'bank_transfer')),
  payment_status text not null
    check (payment_status in ('pending', 'paid', 'failed', 'refunded', 'cancelled')),

  amount numeric(10,2) not null,
  currency text not null default 'EUR',

  stripe_customer_id text null,
  stripe_checkout_session_id text null,
  stripe_payment_intent_id text null,
  stripe_invoice_id text null,
  stripe_subscription_id text null,

  paid_at timestamptz null,
  created_by uuid null references public.profiles(id) on delete set null,
  notes text null,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists membership_payments_member_id_idx
  on public.membership_payments(member_id);

create index if not exists membership_payments_plan_id_idx
  on public.membership_payments(plan_id);

create index if not exists membership_payments_membership_id_idx
  on public.membership_payments(membership_id);

create index if not exists membership_payments_payment_status_idx
  on public.membership_payments(payment_status);

create index if not exists membership_payments_payment_method_idx
  on public.membership_payments(payment_method);

alter table public.membership_payments enable row level security;

drop policy if exists "Admins can read membership payments" on public.membership_payments;
create policy "Admins can read membership payments"
on public.membership_payments
for select
to authenticated
using (public.is_admin());

drop policy if exists "Admins can insert membership payments" on public.membership_payments;
create policy "Admins can insert membership payments"
on public.membership_payments
for insert
to authenticated
with check (public.is_admin());

drop policy if exists "Admins can update membership payments" on public.membership_payments;
create policy "Admins can update membership payments"
on public.membership_payments
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());
