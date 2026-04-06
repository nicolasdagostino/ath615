create or replace function public.assign_membership_plan_internal(
  p_member_id uuid,
  p_plan_id uuid,
  p_status text,
  p_start_date date,
  p_end_date date default null,
  p_auto_renew boolean default true,
  p_credits_remaining integer default null,
  p_classes_used_current_period integer default 0
)
returns public.member_memberships
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_plan record;
  v_row public.member_memberships;
  v_resolved_end_date date;
  v_resolved_auto_renew boolean;
begin
  select *
  into v_plan
  from public.membership_plans
  where id = p_plan_id;

  if not found then
    raise exception 'Plan not found';
  end if;

  v_resolved_auto_renew :=
    case
      when v_plan.plan_type = 'unlimited' then true
      when v_plan.plan_type in ('class_pack', 'drop_in') then false
      else coalesce(p_auto_renew, false)
    end;

  v_resolved_end_date :=
    coalesce(
      p_end_date,
      case
        when v_plan.plan_type = 'drop_in' then p_start_date
        when v_plan.billing_period = 'weekly' then (p_start_date + interval '7 days')::date
        when v_plan.billing_period = 'monthly' then (p_start_date + interval '1 month')::date
        else null
      end
    );

  update public.member_memberships
  set
    status = 'expired'::public.membership_status,
    end_date = coalesce(end_date, current_date),
    updated_at = now()
  where member_id = p_member_id
    and status = 'active'::public.membership_status;

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
    current_period_end
  )
  values (
    p_member_id,
    p_plan_id,
    p_status::public.membership_status,
    p_start_date,
    v_resolved_end_date,
    v_resolved_auto_renew,
    case
      when p_credits_remaining is not null then p_credits_remaining
      when v_plan.plan_type = 'class_pack' then v_plan.credits_total
      when v_plan.plan_type = 'drop_in' then coalesce(v_plan.credits_total, 1)
      else null
    end,
    coalesce(p_classes_used_current_period, 0),
    p_start_date,
    v_resolved_end_date
  )
  returning * into v_row;

  return v_row;
end;
$function$;