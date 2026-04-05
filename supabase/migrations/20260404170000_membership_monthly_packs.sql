create or replace function public.assign_membership_plan(
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
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  if not public.is_admin() then
    raise exception 'Only admins can assign memberships';
  end if;

  select *
  into v_plan
  from public.membership_plans
  where id = p_plan_id;

  if not found then
    raise exception 'Plan not found';
  end if;

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
    p_auto_renew,
    case
      when p_credits_remaining is not null then p_credits_remaining
      when v_plan.plan_type = 'class_pack' then v_plan.credits_total
      when v_plan.plan_type = 'drop_in' then coalesce(v_plan.credits_total, 1)
      else null
    end,
    0,
    p_start_date,
    v_resolved_end_date
  )
  returning * into v_row;

  return v_row;
end;
$function$;

create or replace function public.can_member_book_class(
  p_member_id uuid,
  p_class_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_class record;
  v_membership record;
  v_existing record;
  v_overlap_exists boolean := false;
  v_class_local_date date;
begin
  select
    c.id,
    c.status,
    c.starts_at,
    c.duration_minutes,
    c.max_spots
  into v_class
  from public.classes c
  where c.id = p_class_id;

  if v_class.id is null then
    return jsonb_build_object(
      'can_book', false,
      'message', 'Class not found'
    );
  end if;

  if v_class.status is distinct from 'scheduled'::public.class_status then
    return jsonb_build_object(
      'can_book', false,
      'message', 'Class is not open for booking'
    );
  end if;

  if v_class.starts_at <= now() then
    return jsonb_build_object(
      'can_book', false,
      'message', 'This class has already started'
    );
  end if;

  v_class_local_date := (v_class.starts_at at time zone 'Europe/Madrid')::date;

  select
    mm.id,
    mm.member_id,
    mm.plan_id,
    mm.status,
    mm.start_date,
    mm.end_date,
    mm.auto_renew,
    mm.credits_remaining,
    mm.classes_used_current_period,
    mm.current_period_start,
    mm.current_period_end,
    mm.assigned_by,
    mm.notes,
    mm.created_at,
    mm.updated_at,
    mp.name as plan_name,
    mp.plan_type,
    mp.billing_period,
    mp.classes_per_period,
    mp.credits_total,
    mp.booking_window_days
  into v_membership
  from public.member_memberships mm
  join public.membership_plans mp on mp.id = mm.plan_id
  where mm.member_id = p_member_id
    and mm.status = 'active'
    and mm.start_date <= v_class_local_date
    and (mm.end_date is null or mm.end_date >= v_class_local_date)
  order by mm.created_at desc
  limit 1;

  if v_membership.id is null then
    return jsonb_build_object(
      'can_book', false,
      'message', 'No active membership for this class date'
    );
  end if;

  if coalesce(v_membership.booking_window_days, 0) > 0 then
    if v_class_local_date > ((now() at time zone 'Europe/Madrid')::date + v_membership.booking_window_days) then
      return jsonb_build_object(
        'can_book', false,
        'message', 'This class is outside your booking window'
      );
    end if;
  end if;

  select *
  into v_existing
  from public.class_bookings cb
  where cb.class_id = p_class_id
    and cb.member_id = p_member_id
  limit 1;

  if v_existing.id is not null
     and v_existing.status in ('booked'::public.booking_status, 'attended'::public.booking_status) then
    return jsonb_build_object(
      'can_book', false,
      'message', 'You already booked this class'
    );
  end if;

  select exists (
    select 1
    from public.class_bookings cb
    join public.classes c_existing on c_existing.id = cb.class_id
    where cb.member_id = p_member_id
      and cb.class_id <> p_class_id
      and cb.status in ('booked'::public.booking_status, 'attended'::public.booking_status)
      and c_existing.status = 'scheduled'::public.class_status
      and c_existing.starts_at < (v_class.starts_at + make_interval(mins => coalesce(v_class.duration_minutes, 60)))
      and (c_existing.starts_at + make_interval(mins => coalesce(c_existing.duration_minutes, 60))) > v_class.starts_at
  )
  into v_overlap_exists;

  if v_overlap_exists then
    return jsonb_build_object(
      'can_book', false,
      'message', 'You already have another class booked at this time'
    );
  end if;

  if v_membership.plan_type = 'weekly_limit' then
    return jsonb_build_object(
      'can_book', false,
      'message', 'This legacy plan type is no longer supported. Please assign a monthly class pack.'
    );
  end if;

  if v_membership.plan_type in ('class_pack', 'drop_in') then
    if coalesce(v_membership.credits_remaining, 0) <= 0 then
      return jsonb_build_object(
        'can_book', false,
        'message', 'You have no credits remaining'
      );
    end if;
  end if;

  return jsonb_build_object(
    'can_book', true,
    'message', 'OK'
  );
end;
$function$;

create or replace function public.book_class_for_member(
  p_class_id uuid,
  p_member_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_class record;
  v_existing record;
  v_existing_found boolean := false;
  v_booked_count integer;
  v_can_book jsonb;
  v_membership record;
  v_class_local_date date;
begin
  select
    c.id,
    c.status,
    c.max_spots,
    c.starts_at
  into v_class
  from public.classes c
  where c.id = p_class_id;

  if v_class.id is null then
    return jsonb_build_object(
      'ok', false,
      'message', 'Class not found'
    );
  end if;

  if v_class.status is distinct from 'scheduled'::public.class_status then
    return jsonb_build_object(
      'ok', false,
      'message', 'Class is not open for booking'
    );
  end if;

  v_can_book := public.can_member_book_class(p_member_id, p_class_id);

  if coalesce((v_can_book->>'can_book')::boolean, false) = false then
    return jsonb_build_object(
      'ok', false,
      'message', coalesce(v_can_book->>'message', 'Could not book class')
    );
  end if;

  v_class_local_date := (v_class.starts_at at time zone 'Europe/Madrid')::date;

  select
    mm.id,
    mp.plan_type
  into v_membership
  from public.member_memberships mm
  join public.membership_plans mp on mp.id = mm.plan_id
  where mm.member_id = p_member_id
    and mm.status = 'active'
    and mm.start_date <= v_class_local_date
    and (mm.end_date is null or mm.end_date >= v_class_local_date)
  order by mm.created_at desc
  limit 1;

  select *
  into v_existing
  from public.class_bookings cb
  where cb.class_id = p_class_id
    and cb.member_id = p_member_id
  limit 1;

  v_existing_found := v_existing.id is not null;

  select count(*)
  into v_booked_count
  from public.class_bookings cb
  where cb.class_id = p_class_id
    and cb.status in ('booked'::public.booking_status, 'attended'::public.booking_status);

  if v_booked_count >= coalesce(v_class.max_spots, 0) then
    return jsonb_build_object(
      'ok', false,
      'message', 'Class is full'
    );
  end if;

  if v_existing_found then
    if v_existing.status = 'cancelled' then
      update public.class_bookings
      set
        status = 'booked'::public.booking_status,
        booked_at = now(),
        cancelled_at = null,
        cancellation_reason = null,
        attended_at = null,
        updated_at = now()
      where id = v_existing.id;

      if v_membership.plan_type in ('class_pack', 'drop_in') then
        update public.member_memberships
        set
          credits_remaining = coalesce(credits_remaining, 0) - 1,
          updated_at = now()
        where id = v_membership.id;
      end if;
    end if;

    return jsonb_build_object(
      'ok', true,
      'message', 'Class booked',
      'booking_id', v_existing.id
    );
  end if;

  insert into public.class_bookings (
    class_id,
    member_id,
    status
  )
  values (
    p_class_id,
    p_member_id,
    'booked'::public.booking_status
  )
  returning id into v_existing.id;

  if v_membership.plan_type in ('class_pack', 'drop_in') then
    update public.member_memberships
    set
      credits_remaining = coalesce(credits_remaining, 0) - 1,
      updated_at = now()
    where id = v_membership.id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'message', 'Class booked',
    'booking_id', v_existing.id
  );
end;
$function$;

create or replace function public.cancel_my_booking(
  p_booking_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_booking record;
  v_membership record;
  v_booking_local_date date;
begin
  if auth.uid() is null then
    return jsonb_build_object(
      'ok', false,
      'reason_code', 'not_authenticated',
      'message', 'Not authenticated'
    );
  end if;

  select
    cb.*,
    c.starts_at
  into v_booking
  from public.class_bookings cb
  join public.classes c on c.id = cb.class_id
  where cb.id = p_booking_id
    and cb.member_id = auth.uid();

  if not found then
    return jsonb_build_object(
      'ok', false,
      'reason_code', 'booking_not_found',
      'message', 'Booking not found'
    );
  end if;

  if v_booking.status <> 'booked' then
    return jsonb_build_object(
      'ok', false,
      'reason_code', 'booking_not_cancellable',
      'message', 'Only booked classes can be cancelled'
    );
  end if;

  if v_booking.starts_at <= now() then
    return jsonb_build_object(
      'ok', false,
      'reason_code', 'booking_already_started',
      'message', 'Cannot cancel after class has started'
    );
  end if;

  v_booking_local_date := (v_booking.starts_at at time zone 'Europe/Madrid')::date;

  select
    mm.id,
    mp.plan_type
  into v_membership
  from public.member_memberships mm
  join public.membership_plans mp on mp.id = mm.plan_id
  where mm.member_id = auth.uid()
    and mm.status = 'active'
    and mm.start_date <= v_booking_local_date
    and (mm.end_date is null or mm.end_date >= v_booking_local_date)
  order by mm.created_at desc
  limit 1;

  update public.class_bookings
  set
    status = 'cancelled',
    cancelled_at = now(),
    updated_at = now()
  where id = p_booking_id;

  if v_membership.id is not null and v_membership.plan_type in ('class_pack', 'drop_in') then
    update public.member_memberships
    set
      credits_remaining = coalesce(credits_remaining, 0) + 1,
      updated_at = now()
    where id = v_membership.id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'message', 'Booking cancelled'
  );
end;
$function$;
