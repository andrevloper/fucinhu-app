-- ============================================================
-- SEED — Cria usuário admin inicial
-- Supabase SQL Editor → New Query → Run
-- ============================================================

DO $$
DECLARE
  v_uid UUID;
BEGIN

  -- Reaproveita se o e-mail já existir
  SELECT id INTO v_uid
  FROM auth.users
  WHERE email = 'admin@fucinhu.co';

  -- ── 1. Criar em auth.users ────────────────────────────────
  IF v_uid IS NULL THEN
    v_uid := gen_random_uuid();

    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_uid,
      'authenticated',
      'authenticated',
      'admin@fucinhu.co',
      crypt('fucinhu123', gen_salt('bf')),
      NOW(),                                        -- e-mail já confirmado
      '{"provider":"email","providers":["email"]}',
      '{"name":"Admin Fucinho"}',
      NOW(),
      NOW(),
      '', '', '', ''
    );

    -- ── 2. Identity para login e-mail / senha ──────────────
    INSERT INTO auth.identities (
      id,
      user_id,
      provider_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) VALUES (
      gen_random_uuid(),
      v_uid,
      'admin@fucinhu.co',
      json_build_object('sub', v_uid::text, 'email', 'admin@fucinhu.co'),
      'email',
      NOW(), NOW(), NOW()
    );

  END IF;

  -- ── 3. Perfil com is_admin = TRUE ─────────────────────────
  INSERT INTO public.profiles (id, name, is_admin)
  VALUES (v_uid, 'Admin Fucinho', TRUE)
  ON CONFLICT (id) DO UPDATE SET is_admin = TRUE;

  RAISE NOTICE 'Admin OK — uuid: %', v_uid;

END;
$$;
