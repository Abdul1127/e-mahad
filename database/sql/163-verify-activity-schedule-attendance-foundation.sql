-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 163-verify-activity-schedule-attendance-foundation.sql
--
-- Semua data test di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FOUNDATION
-- =========================================================

select
    to_regclass(
        'public.activity_schedules'
    ) is not null
        as schedules_table_exists,

    to_regclass(
        'public.activity_attendances'
    ) is not null
        as attendances_table_exists,

    to_regprocedure(
        'public.create_pengasuh_activity_schedule(uuid,date,time without time zone,time without time zone,text,text,text)'
    ) is not null
        as create_function_exists,

    to_regprocedure(
        'public.get_pengasuh_activity_schedule_list(date,date)'
    ) is not null
        as list_function_exists,

    to_regprocedure(
        'public.get_pengasuh_activity_schedule_detail(uuid)'
    ) is not null
        as detail_function_exists,

    to_regprocedure(
        'public.save_pengasuh_activity_attendance(uuid,jsonb)'
    ) is not null
        as attendance_function_exists;


-- =========================================================
-- 2. TEST TRANSACTION
-- =========================================================

begin;


do $verification$
declare
    v_pengasuh_profile_id uuid;
    v_pengasuh_email text;
    v_pengasuh_staff_id uuid;

    v_non_pengasuh_profile_id uuid;
    v_non_pengasuh_email text;

    v_group_id uuid;

    v_schedule_id uuid;

    v_student_id uuid;
    v_unlinked_student_id uuid;

    v_result jsonb;

    v_entries jsonb;

    v_eligible_count integer;

    v_recorded_count integer;

    v_schedule_status text;

    v_suffix text;
begin

    v_suffix :=
        upper(
            substr(
                replace(
                    gen_random_uuid()::text,
                    '-',
                    ''
                ),
                1,
                8
            )
        );


    -- =====================================================
    -- A. FIND ACTIVE PENGASUH + GROUP
    -- =====================================================

    select
        profile.id,
        auth_user.email,
        staff.id,
        care_group.id

    into
        v_pengasuh_profile_id,
        v_pengasuh_email,
        v_pengasuh_staff_id,
        v_group_id

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.staff
        as staff

        on staff.profile_id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    inner join public.caregiver_assignments
        as assignment

        on assignment.staff_id =
           staff.id

    inner join public.care_groups
        as care_group

        on care_group.id =
           assignment.care_group_id

    inner join public.academic_years
        as academic_year

        on academic_year.id =
           care_group.academic_year_id

    where role.code =
          'pengasuh'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

      and assignment.is_active =
          true

      and assignment.assigned_at <=
          current_date

      and (
          assignment.ended_at
              is null

          or assignment.ended_at >=
             current_date
      )

      and care_group.is_active =
          true

      and academic_year.is_current =
          true

      and exists (
          select 1

          from public.care_group_members
              as membership

          inner join public.students
              as student

              on student.id =
                 membership.student_id

          where membership.care_group_id =
                care_group.id

            and membership.joined_at <=
                current_date

            and (
                membership.left_at
                    is null

                or membership.left_at >=
                   current_date
            )

            and student.status =
                'active'

            and student.deleted_at
                is null
      )

    order by
        staff.full_name,
        care_group.name

    limit 1;


    if v_pengasuh_profile_id is null then
        raise exception
            'Pengasuh aktif dengan kelompok tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. LOGIN PENGASUH
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_pengasuh_email
        )::text,
        true
    );


    -- =====================================================
    -- C. CREATE SCHEDULE TODAY
    -- =====================================================

    v_result :=
        public.create_pengasuh_activity_schedule(
            p_care_group_id =>
                v_group_id,

            p_activity_date =>
                current_date,

            p_start_time =>
                '18:30'::time,

            p_end_time =>
                '19:30'::time,

            p_activity_name =>
                'Verification Kegiatan ' ||
                v_suffix,

            p_location =>
                'Asrama',

            p_notes =>
                'Verification Jadwal dan Absensi'
        );


    v_schedule_id :=
        (
            v_result
            #>> '{schedule,id}'
        )::uuid;


    if v_schedule_id is null then
        raise exception
            'Schedule verification gagal dibuat.';
    end if;


    raise notice
        'PENGASUH CREATE SCHEDULE SUCCESS';


    -- =====================================================
    -- D. LIST INTEGRATION
    -- =====================================================

    v_result :=
        public.get_pengasuh_activity_schedule_list(
            current_date,
            current_date
        );


    if not exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        )
            as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_schedule_id
    ) then
        raise exception
            'Jadwal verification tidak muncul di list.';
    end if;


    raise notice
        'PENGASUH SCHEDULE LIST SUCCESS';


    -- =====================================================
    -- E. DETAIL
    -- =====================================================

    v_result :=
        public.get_pengasuh_activity_schedule_detail(
            v_schedule_id
        );


    v_eligible_count :=
        (
            v_result
            #>> '{summary,eligible_count}'
        )::integer;


    if v_eligible_count <=
       0
    then
        raise exception
            'Jadwal tidak mempunyai santri eligible.';
    end if;


    raise notice
        'PENGASUH SCHEDULE DETAIL SUCCESS';


    -- =====================================================
    -- F. BUILD FULL ATTENDANCE
    --
    -- Semua santri dibuat hadir untuk verification.
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'student_id',
                    student.id,

                    'status',
                    'present',

                    'notes',
                    null
                )

                order by
                    student.full_name,
                    student.id
            ),
            '[]'::jsonb
        )

    into
        v_entries

    from public.care_group_members
        as membership

    inner join public.students
        as student

        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_group_id

      and membership.joined_at <=
          current_date

      and (
          membership.left_at
              is null

          or membership.left_at >=
             current_date
      )

      and student.status =
          'active'

      and student.deleted_at
          is null;


    -- =====================================================
    -- G. SAVE FULL ATTENDANCE
    -- =====================================================

    v_result :=
        public.save_pengasuh_activity_attendance(
            v_schedule_id,
            v_entries
        );


    v_recorded_count :=
        (
            v_result
            #>> '{summary,recorded_count}'
        )::integer;


    if v_recorded_count <>
       v_eligible_count
    then
        raise exception
            'Jumlah absensi tercatat tidak sesuai jumlah santri.';
    end if;


    if (
        v_result
        #>> '{summary,present_count}'
    )::integer <>
       v_eligible_count
    then
        raise exception
            'Jumlah hadir tidak sesuai jumlah santri.';
    end if;


    if (
        v_result
        #>> '{schedule,status}'
    ) <>
       'completed'
    then
        raise exception
            'Jadwal seharusnya completed setelah seluruh absensi terisi.';
    end if;


    raise notice
        'PENGASUH FULL ATTENDANCE SAVE SUCCESS';


    -- =====================================================
    -- H. UPDATE ONE ATTENDANCE
    --
    -- Ubah satu santri dari present → sick.
    -- =====================================================

    select
        student.id

    into
        v_student_id

    from public.care_group_members
        as membership

    inner join public.students
        as student

        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_group_id

      and membership.joined_at <=
          current_date

      and (
          membership.left_at
              is null

          or membership.left_at >=
             current_date
      )

      and student.status =
          'active'

      and student.deleted_at
          is null

    order by
        student.full_name,
        student.id

    limit 1;


    v_result :=
        public.save_pengasuh_activity_attendance(
            v_schedule_id,

            jsonb_build_array(
                jsonb_build_object(
                    'student_id',
                    v_student_id,

                    'status',
                    'sick',

                    'notes',
                    'Verification sakit'
                )
            )
        );


    if (
        v_result
        #>> '{summary,sick_count}'
    )::integer <>
       1
    then
        raise exception
            'Update status sakit tidak berhasil.';
    end if;


    if (
        v_result
        #>> '{summary,present_count}'
    )::integer <>
       (
           v_eligible_count - 1
       )
    then
        raise exception
            'Jumlah hadir setelah koreksi salah.';
    end if;


    raise notice
        'PENGASUH ATTENDANCE UPDATE SUCCESS';


    -- =====================================================
    -- I. UNLINKED STUDENT MUST FAIL
    -- =====================================================

    select
        student.id

    into
        v_unlinked_student_id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null

      and not exists (
          select 1

          from public.care_group_members
              as membership

          where membership.care_group_id =
                v_group_id

            and membership.student_id =
                student.id

            and membership.joined_at <=
                current_date

            and (
                membership.left_at
                    is null

                or membership.left_at >=
                   current_date
            )
      )

    order by
        student.full_name,
        student.id

    limit 1;


    if v_unlinked_student_id is not null then

        begin

            perform
                public.save_pengasuh_activity_attendance(
                    v_schedule_id,

                    jsonb_build_array(
                        jsonb_build_object(
                            'student_id',
                            v_unlinked_student_id,

                            'status',
                            'present'
                        )
                    )
                );


            raise exception
                'EXPECTED_UNLINKED_STUDENT_FAILURE';

        exception
            when others then

                if sqlerrm =
                   'EXPECTED_UNLINKED_STUDENT_FAILURE'
                then
                    raise;
                end if;


                if sqlerrm not ilike
                   '%bukan anggota kelompok%'
                then
                    raise;
                end if;

        end;


        raise notice
            'UNLINKED STUDENT ATTENDANCE PROTECTION SUCCESS';

    end if;


    -- =====================================================
    -- J. FUTURE ATTENDANCE MUST FAIL
    -- =====================================================

    if current_date + 1 <= (
        select
            academic_year.end_date

        from public.academic_years
            as academic_year

        where academic_year.is_current =
              true

        limit 1
    ) then

        v_result :=
            public.create_pengasuh_activity_schedule(
                p_care_group_id =>
                    v_group_id,

                p_activity_date =>
                    current_date + 1,

                p_start_time =>
                    '18:30'::time,

                p_end_time =>
                    '19:30'::time,

                p_activity_name =>
                    'Future Verification ' ||
                    v_suffix,

                p_location =>
                    'Asrama',

                p_notes =>
                    null
            );


        begin

            perform
                public.save_pengasuh_activity_attendance(
                    (
                        v_result
                        #>> '{schedule,id}'
                    )::uuid,

                    jsonb_build_array(
                        jsonb_build_object(
                            'student_id',
                            v_student_id,

                            'status',
                            'present'
                        )
                    )
                );


            raise exception
                'EXPECTED_FUTURE_ATTENDANCE_FAILURE';

        exception
            when others then

                if sqlerrm =
                   'EXPECTED_FUTURE_ATTENDANCE_FAILURE'
                then
                    raise;
                end if;


                if sqlerrm not ilike
                   '%belum berlangsung%'
                then
                    raise;
                end if;

        end;


        raise notice
            'FUTURE ATTENDANCE PROTECTION SUCCESS';

    end if;


    -- =====================================================
    -- K. NON-PENGASUH MUST FAIL
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_pengasuh_profile_id,
        v_non_pengasuh_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    where profile.is_active =
          true

      and not exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role

              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pengasuh'

            and role.is_active =
                true
      )

    order by
        profile.id

    limit 1;


    if v_non_pengasuh_profile_id is null then
        raise exception
            'Akun non-Pengasuh tidak ditemukan.';
    end if;


    perform set_config(
        'request.jwt.claim.sub',
        v_non_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_pengasuh_email
        )::text,
        true
    );


    begin

        perform
            public.get_pengasuh_activity_schedule_list(
                current_date,
                current_date
            );


        raise exception
            'EXPECTED_NON_PENGASUH_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_PENGASUH_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses jadwal Pengasuh ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PENGASUH SCHEDULE PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'ACTIVITY SCHEDULE ATTENDANCE VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Jadwal dan Absensi Pengasuh berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;