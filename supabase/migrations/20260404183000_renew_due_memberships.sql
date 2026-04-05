create or replace function public.renew_due_memberships()
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_today date := (now() at time zone 'Europe/Madrid')::date;
  v_row record;
  v_new_end_date date;
  v_inserted_count integer := 0;
  v_skipped_count integer := 0;
begin
  for v_row in
    select
      mm.id as membership_id,
      mm.member_id,
      mm.plan_id,
      mm.start_date,
      mm.end_date,
      mm.auto_renew,
      mm.current_period_end,
      mp.plan_type,
      mp.billing_period,
      mp.credits_total,
      mp.is_active
    from public.member_memberships mm
    join public.membership_plans mp on mp.id = mm.plan_id
    where mm.status = 'active'
      and mm.auto_renew = true
      and mm.end_date is not null
      and mm.end_date < v_today
      and mp.is_active = true
      and mp.plan_type <> 'drop_in'
  loop
    if exists (
      select 1
      from public.member_memberships mm2
      where mm2.member_id = v_row.member_id
        and mm2.plan_id = v_row.plan_id
        and mm2.status = 'active'
        and mm2.start_date > v_row.start_date
    ) then
      v_skipped_count := v_skipped_count + 1;
      continue;
    end if;

    v_new_end_date :=
      case
        when v_row.billing_period = 'weekly' then (v_row.end_date + interval '7 days')::date
        when v_row.billing_period = 'monthly' then (v_row.end_date + interval '1 month')::date
        else null
      end;

    update public.member_memberships
    set
      status = 'expired'::public.membership_status,
      updated_at = now()
    where id = v_row.membership_id;

    insert into public.member_memberships (
      member_id,
      plan_id,
      status,
      start_date,
      end_date,
      auto_renew,
      credits_remaining,
      classes_used_current_period,
      current_period_start,
      current_period_end,
      notes
    )
    values (
      v_row.member_id,
      v_row.plan_id,
      'active'::public.membership_status,
      (v_row.end_date + interval '1 day')::date,
      v_new_end_date,
      true,
      case
        when v_row.plan_type = 'class_pack' then v_row.credits_total
        when v_row.plan_type = 'drop_in' then coalesce(v_row.credits_total, 1)
        else null
      end,
      0,
      (v_row.end_date + interval '1 day')::date,
      v_new_end_date,
      'Auto-renewed by system'
    );

    v_inserted_count := v_inserted_count + 1;
  end loop;

  return jsonb_build_object(
    'ok', true,
    'today', v_today,
    'renewed', v_inserted_count,
    'skipped', v_skipped_count
  );
end;
$function$;
