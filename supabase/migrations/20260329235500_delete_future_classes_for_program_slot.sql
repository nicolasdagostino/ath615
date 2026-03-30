create or replace function public.admin_delete_future_classes_for_program_slot(
  p_class_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_class record;
  v_deleted_count integer := 0;
begin
  select
    c.id,
    c.gym_id,
    c.program_id,
    c.starts_at,
    (c.starts_at at time zone 'Europe/Madrid')::date as local_date,
    to_char(c.starts_at at time zone 'Europe/Madrid', 'HH24:MI') as local_time
  into v_class
  from public.classes c
  where c.id = p_class_id;

  if v_class.id is null then
    return jsonb_build_object(
      'ok', false,
      'message', 'Class not found'
    );
  end if;

  delete from public.classes c
  where c.gym_id = v_class.gym_id
    and c.program_id = v_class.program_id
    and c.starts_at >= v_class.starts_at
    and to_char(c.starts_at at time zone 'Europe/Madrid', 'HH24:MI') = v_class.local_time;

  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  return jsonb_build_object(
    'ok', true,
    'deleted_count', v_deleted_count,
    'program_id', v_class.program_id,
    'slot_time', v_class.local_time
  );
end;
$$;

grant execute on function public.admin_delete_future_classes_for_program_slot(uuid) to authenticated;
