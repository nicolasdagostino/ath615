alter table public.membership_payments
  drop constraint if exists membership_payments_payment_method_check;

update public.membership_payments
set payment_method = 'card'
where payment_method in ('stripe_checkout', 'stripe_subscription');

alter table public.membership_payments
  add constraint membership_payments_payment_method_check
  check (payment_method in ('cash', 'card', 'bank_transfer'));

alter table public.membership_payments
  add column if not exists failure_reason text null;

create unique index if not exists membership_payments_stripe_payment_intent_uidx
  on public.membership_payments (stripe_payment_intent_id)
  where stripe_payment_intent_id is not null and btrim(stripe_payment_intent_id) <> '';

create unique index if not exists membership_payments_stripe_checkout_session_uidx
  on public.membership_payments (stripe_checkout_session_id)
  where stripe_checkout_session_id is not null and btrim(stripe_checkout_session_id) <> '';

create unique index if not exists membership_payments_stripe_subscription_uidx
  on public.membership_payments (stripe_subscription_id)
  where stripe_subscription_id is not null and btrim(stripe_subscription_id) <> '';