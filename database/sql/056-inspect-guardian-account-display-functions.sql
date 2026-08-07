-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 056-inspect-guardian-account-display-functions.sql
--
-- PURPOSE:
-- - Melihat struktur fungsi detail wali
-- - Melihat struktur fungsi daftar wali
-- - Menjadi dasar penambahan profiles.login_id
--
-- READ-ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================

with function_definitions as (
    select
        pg_get_functiondef(
            'public.get_admin_guardian_detail(uuid)'
                ::regprocedure
        ) as guardian_detail_function,

        pg_get_functiondef(
            'public.get_admin_guardian_list(text,boolean,text,integer,integer)'
                ::regprocedure
        ) as guardian_list_function
),

account_samples as (
    select
        guardian.id
            as guardian_id,

        guardian.legacy_guardian_id,
        guardian.full_name,
        guardian.profile_id,

        profile.login_id,

        auth_user.email::text
            as internal_auth_email,

        profile.is_active
            as account_is_active

    from public.guardians as guardian

    left join public.profiles as profile
        on profile.id =
           guardian.profile_id

    left join auth.users as auth_user
        on auth_user.id =
           profile.id

    order by
        guardian.created_at,
        guardian.id
)

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Fungsi tampilan akun wali berhasil diperiksa',

        'inspected_at',
        now(),

        'guardian_detail_function',
        (
            select
                guardian_detail_function

            from function_definitions
        ),

        'guardian_list_function',
        (
            select
                guardian_list_function

            from function_definitions
        ),

        'account_samples',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'guardian_id',
                        sample.guardian_id,

                        'legacy_guardian_id',
                        sample.legacy_guardian_id,

                        'full_name',
                        sample.full_name,

                        'profile_id',
                        sample.profile_id,

                        'login_id',
                        sample.login_id,

                        'internal_auth_email',
                        sample.internal_auth_email,

                        'account_is_active',
                        sample.account_is_active
                    )

                    order by
                        sample.full_name,
                        sample.guardian_id
                ),
                '[]'::jsonb
            )

            from account_samples as sample
        )
    )
) as guardian_account_display_inspection;