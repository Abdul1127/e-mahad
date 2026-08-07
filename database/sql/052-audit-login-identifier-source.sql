-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 052-audit-login-identifier-source.sql
--
-- PURPOSE:
-- - Audit sumber ID login staf dan wali
-- - Menampilkan legacy_staff_id
-- - Menampilkan legacy_guardian_id
-- - Menampilkan NIS/ID anak yang terhubung
-- - Membuat kandidat login ID
-- - Memeriksa potensi kandidat duplikat
--
-- READ-ONLY
-- TIDAK MENGUBAH DATA ATAU AKUN
-- =========================================================


with profile_roles as (
    select
        user_role.user_id,

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'code',
                    role.code,

                    'name',
                    role.name
                )

                order by role.code
            ),
            '[]'::jsonb
        ) as roles,

        bool_or(
            role.code = 'admin'
        ) as has_admin_role

    from public.user_roles as user_role

    inner join public.roles as role
        on role.id =
           user_role.role_id

    group by
        user_role.user_id
),


guardian_children as (
    select
        guardian.id
            as guardian_id,

        min(
            student.legacy_student_id
        ) filter (
            where student.legacy_student_id
                  is not null

              and btrim(
                  student.legacy_student_id
              ) <> ''
        ) as login_student_seed,

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'student_id',
                    student.id,

                    'legacy_student_id',
                    student.legacy_student_id,

                    'full_name',
                    student.full_name,

                    'is_primary_contact',
                    guardian_student.is_primary_contact,

                    'relationship_type',
                    guardian_student.relationship_type
                )

                order by
                    student.legacy_student_id,
                    student.full_name
            ) filter (
                where student.id is not null
            ),
            '[]'::jsonb
        ) as children

    from public.guardians as guardian

    left join public.guardian_students
        as guardian_student
        on guardian_student.guardian_id =
           guardian.id

    left join public.students as student
        on student.id =
           guardian_student.student_id

    group by
        guardian.id
),


guardian_ranked as (
    select
        guardian.id,
        guardian.profile_id,
        guardian.legacy_guardian_id,
        guardian.full_name,
        guardian.phone,
        guardian.email,
        guardian.is_active,
        guardian.created_at,

        guardian_children.login_student_seed,
        guardian_children.children,

        case
            when guardian_children.login_student_seed
                 is not null
                then row_number() over (
                    partition by
                        guardian_children.login_student_seed

                    order by
                        guardian.created_at,
                        guardian.id
                )

            else null
        end as guardian_order_for_student

    from public.guardians as guardian

    left join guardian_children
        on guardian_children.guardian_id =
           guardian.id
),


guardian_candidates as (
    select
        guardian.id
            as guardian_id,

        guardian.profile_id,
        guardian.legacy_guardian_id,
        guardian.full_name,
        guardian.phone,
        guardian.email,
        guardian.is_active,
        guardian.login_student_seed,
        guardian.children,

        case
            when guardian.login_student_seed
                 is not null
                then concat(
                    'ORT-',

                    trim(
                        both '-'
                        from regexp_replace(
                            upper(
                                btrim(
                                    guardian.login_student_seed
                                )
                            ),
                            '[^A-Z0-9]+',
                            '-',
                            'g'
                        )
                    ),

                    '-',

                    lpad(
                        guardian.guardian_order_for_student::text,
                        2,
                        '0'
                    )
                )

            when guardian.legacy_guardian_id
                 is not null

                 and btrim(
                     guardian.legacy_guardian_id
                 ) <> ''
                then concat(
                    'ORT-',

                    trim(
                        both '-'
                        from regexp_replace(
                            upper(
                                btrim(
                                    guardian.legacy_guardian_id
                                )
                            ),
                            '[^A-Z0-9]+',
                            '-',
                            'g'
                        )
                    )
                )

            else concat(
                'ORT-',

                upper(
                    left(
                        guardian.id::text,
                        8
                    )
                )
            )
        end as candidate_login_id

    from guardian_ranked as guardian
),


staff_candidates as (
    select
        staff.id
            as staff_id,

        staff.profile_id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.phone,
        staff.is_active,

        case
            when staff.legacy_staff_id
                 is not null

                 and btrim(
                     staff.legacy_staff_id
                 ) <> ''
                then concat(
                    'STF-',

                    trim(
                        both '-'
                        from regexp_replace(
                            upper(
                                btrim(
                                    staff.legacy_staff_id
                                )
                            ),
                            '[^A-Z0-9]+',
                            '-',
                            'g'
                        )
                    )
                )

            else concat(
                'STF-',

                upper(
                    left(
                        staff.id::text,
                        8
                    )
                )
            )
        end as candidate_login_id

    from public.staff as staff
),


existing_accounts as (
    select
        profile.id
            as profile_id,

        profile.full_name,
        profile.phone,
        profile.is_active,

        auth_user.email::text
            as current_auth_email,

        coalesce(
            profile_roles.roles,
            '[]'::jsonb
        ) as roles,

        staff.staff_id,
        staff.legacy_staff_id,

        guardian.guardian_id,
        guardian.legacy_guardian_id,

        case
            when guardian.guardian_id
                 is not null
                then guardian.candidate_login_id

            when staff.staff_id
                 is not null
                then staff.candidate_login_id

            when coalesce(
                profile_roles.has_admin_role,
                false
            )
                then 'ADM-001'

            else concat(
                'USR-',

                upper(
                    left(
                        profile.id::text,
                        8
                    )
                )
            )
        end as candidate_login_id

    from public.profiles as profile

    inner join auth.users as auth_user
        on auth_user.id =
           profile.id

    left join profile_roles
        on profile_roles.user_id =
           profile.id

    left join staff_candidates as staff
        on staff.profile_id =
           profile.id

    left join guardian_candidates
        as guardian
        on guardian.profile_id =
           profile.id
),


all_candidates as (
    select
        'existing_account'
            as source_type,

        existing_account.profile_id
            as source_id,

        existing_account.full_name,

        existing_account.candidate_login_id

    from existing_accounts
        as existing_account


    union all


    select
        'staff'
            as source_type,

        staff.staff_id
            as source_id,

        staff.full_name,

        staff.candidate_login_id

    from staff_candidates as staff

    where staff.profile_id is null


    union all


    select
        'guardian'
            as source_type,

        guardian.guardian_id
            as source_id,

        guardian.full_name,

        guardian.candidate_login_id

    from guardian_candidates
        as guardian

    where guardian.profile_id is null
),


candidate_duplicates as (
    select
        lower(
            candidate.candidate_login_id
        ) as normalized_login_id,

        count(*)::integer
            as duplicate_count,

        jsonb_agg(
            jsonb_build_object(
                'source_type',
                candidate.source_type,

                'source_id',
                candidate.source_id,

                'full_name',
                candidate.full_name,

                'candidate_login_id',
                candidate.candidate_login_id
            )

            order by
                candidate.source_type,
                candidate.full_name
        ) as records

    from all_candidates as candidate

    group by
        lower(
            candidate.candidate_login_id
        )

    having count(*) > 1
)


select jsonb_pretty(
    jsonb_build_object(
        'audit_status',
        'Audit sumber login ID selesai',

        'audited_at',
        now(),

        'recommended_format',
        jsonb_build_object(
            'admin',
            'ADM-001',

            'staff',
            'STF-{legacy_staff_id}',

            'guardian',
            'ORT-{NIS_ANAK}-{URUTAN_WALI}',

            'internal_auth_email',
            '{login_id_lowercase}@login.emahad.id'
        ),

        'existing_accounts',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'profile_id',
                        account.profile_id,

                        'full_name',
                        account.full_name,

                        'phone',
                        account.phone,

                        'is_active',
                        account.is_active,

                        'current_auth_email',
                        account.current_auth_email,

                        'roles',
                        account.roles,

                        'staff_id',
                        account.staff_id,

                        'legacy_staff_id',
                        account.legacy_staff_id,

                        'guardian_id',
                        account.guardian_id,

                        'legacy_guardian_id',
                        account.legacy_guardian_id,

                        'candidate_login_id',
                        account.candidate_login_id
                    )

                    order by
                        account.full_name,
                        account.profile_id
                ),
                '[]'::jsonb
            )

            from existing_accounts
                as account
        ),

        'staff_candidates',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'staff_id',
                        staff.staff_id,

                        'profile_id',
                        staff.profile_id,

                        'legacy_staff_id',
                        staff.legacy_staff_id,

                        'full_name',
                        staff.full_name,

                        'phone',
                        staff.phone,

                        'is_active',
                        staff.is_active,

                        'candidate_login_id',
                        staff.candidate_login_id
                    )

                    order by
                        staff.full_name,
                        staff.staff_id
                ),
                '[]'::jsonb
            )

            from staff_candidates as staff
        ),

        'guardian_candidates',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'guardian_id',
                        guardian.guardian_id,

                        'profile_id',
                        guardian.profile_id,

                        'legacy_guardian_id',
                        guardian.legacy_guardian_id,

                        'full_name',
                        guardian.full_name,

                        'phone',
                        guardian.phone,

                        'email_contact',
                        guardian.email,

                        'is_active',
                        guardian.is_active,

                        'login_student_seed',
                        guardian.login_student_seed,

                        'children',
                        guardian.children,

                        'candidate_login_id',
                        guardian.candidate_login_id
                    )

                    order by
                        guardian.full_name,
                        guardian.guardian_id
                ),
                '[]'::jsonb
            )

            from guardian_candidates
                as guardian
        ),

        'candidate_duplicates',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'normalized_login_id',
                        duplicate.normalized_login_id,

                        'duplicate_count',
                        duplicate.duplicate_count,

                        'records',
                        duplicate.records
                    )

                    order by
                        duplicate.normalized_login_id
                ),
                '[]'::jsonb
            )

            from candidate_duplicates
                as duplicate
        ),

        'counts',
        jsonb_build_object(
            'existing_accounts',
            (
                select count(*)::integer
                from existing_accounts
            ),

            'staff_records',
            (
                select count(*)::integer
                from staff_candidates
            ),

            'guardian_records',
            (
                select count(*)::integer
                from guardian_candidates
            ),

            'duplicate_candidates',
            (
                select count(*)::integer
                from candidate_duplicates
            )
        )
    )
) as login_identifier_source_audit;