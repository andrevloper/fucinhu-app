-- ============================================================
-- SCHEMA COMPLETO — Fucinho.co
-- Idempotente: seguro de rodar em banco existente ou zerado.
-- Supabase SQL Editor → New Query → Run
-- ============================================================

-- ============================================================
-- EXTENSÕES
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. TABELAS
-- ============================================================

-- ── profiles ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.profiles (
  id         UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  phone      TEXT,
  photo_url  TEXT,
  email      TEXT        NOT NULL DEFAULT '',
  is_admin   BOOLEAN     NOT NULL DEFAULT FALSE,
  is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
  is_pro     BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Adiciona colunas caso a tabela já existia sem elas
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_admin   BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_active  BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_pro     BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email      TEXT    NOT NULL DEFAULT '';

-- ── pets ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pets (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  species    TEXT        NOT NULL,
  breed      TEXT        NOT NULL,
  age_months INT         NOT NULL DEFAULT 12,
  photo_url  TEXT,
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── favorites ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.favorites (
  id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID         NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  service_id       TEXT         NOT NULL,
  service_name     TEXT         NOT NULL DEFAULT '',
  service_category TEXT         NOT NULL DEFAULT '',
  service_address  TEXT         NOT NULL DEFAULT '',
  service_rating   NUMERIC(3,1) NOT NULL DEFAULT 0,
  service_is_open  BOOLEAN      NOT NULL DEFAULT TRUE,
  service_lat      FLOAT8       NOT NULL DEFAULT 0,
  service_lng      FLOAT8       NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ  DEFAULT NOW(),
  UNIQUE(user_id, service_id)
);

-- Adiciona colunas de detalhe caso a tabela já existia sem elas
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS service_name     TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS service_category TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS service_address  TEXT         NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS service_rating   NUMERIC(3,1) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS service_is_open  BOOLEAN      NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS service_lat      FLOAT8       NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS service_lng      FLOAT8       NOT NULL DEFAULT 0;

-- ── pet_vaccines ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pet_vaccines (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id     UUID        NOT NULL REFERENCES public.pets(id) ON DELETE CASCADE,
  name       TEXT        NOT NULL,
  applied_at DATE        NOT NULL,
  next_at    DATE,
  vet        TEXT,
  notes      TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── services (estabelecimentos cadastrados pelo admin) ────────
CREATE TABLE IF NOT EXISTS public.services (
  id           UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT         NOT NULL,
  category     TEXT         NOT NULL,
  address      TEXT         NOT NULL DEFAULT '',
  lat          FLOAT8       NOT NULL DEFAULT 0,
  lng          FLOAT8       NOT NULL DEFAULT 0,
  rating       NUMERIC(3,1) NOT NULL DEFAULT 0,
  review_count INT          NOT NULL DEFAULT 0,
  phone        TEXT         NOT NULL DEFAULT '',
  whatsapp     TEXT         NOT NULL DEFAULT '',
  description  TEXT         NOT NULL DEFAULT '',
  photo_urls   TEXT[]       NOT NULL DEFAULT '{}',
  hours        JSONB        NOT NULL DEFAULT '{}',
  is_open      BOOLEAN      NOT NULL DEFAULT TRUE,
  is_featured  BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- Adiciona is_featured caso a tabela já existia sem ela
ALTER TABLE public.services ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT FALSE;

-- ── admin_activities ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_activities (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action      TEXT        NOT NULL,
  entity_type TEXT        NOT NULL DEFAULT '',
  entity_id   TEXT,
  entity_name TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS admin_activities_created_at_idx ON public.admin_activities (created_at DESC);
CREATE INDEX IF NOT EXISTS admin_activities_admin_id_idx   ON public.admin_activities (admin_id);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-photos', 'pet-photos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE public.profiles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pets             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pet_vaccines     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_activities ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- 3. FUNÇÕES RPC (SECURITY DEFINER)
-- ============================================================

-- Verifica se o usuário logado tem is_admin = true
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND is_admin = TRUE
  );
END;
$$;

-- Verifica se um e-mail já está cadastrado (usado no signup)
CREATE OR REPLACE FUNCTION public.check_email_exists(email_to_check TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users
    WHERE email = lower(trim(email_to_check))
  );
END;
$$;

-- ============================================================
-- 4. POLICIES
-- ============================================================

-- ── profiles ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "profiles: own" ON public.profiles;
CREATE POLICY "profiles: own"
ON public.profiles FOR ALL
USING     (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admin pode ler todos os perfis (necessário para admin_service)
DROP POLICY IF EXISTS "profiles: admin read" ON public.profiles;
CREATE POLICY "profiles: admin read"
ON public.profiles FOR SELECT
USING (public.is_current_user_admin());

-- ── pets ─────────────────────────────────────────────────────
DROP POLICY IF EXISTS "pets: own" ON public.pets;
CREATE POLICY "pets: own"
ON public.pets FOR ALL
USING     (auth.uid() = owner_id)
WITH CHECK (auth.uid() = owner_id);

-- Admin pode ler todos os pets
DROP POLICY IF EXISTS "pets: admin read" ON public.pets;
CREATE POLICY "pets: admin read"
ON public.pets FOR SELECT
USING (public.is_current_user_admin());

-- ── favorites ────────────────────────────────────────────────
DROP POLICY IF EXISTS "favorites: own" ON public.favorites;
CREATE POLICY "favorites: own"
ON public.favorites FOR ALL
USING     (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Admin pode ler todos os favoritos
DROP POLICY IF EXISTS "favorites: admin read" ON public.favorites;
CREATE POLICY "favorites: admin read"
ON public.favorites FOR SELECT
USING (public.is_current_user_admin());

-- ── pet_vaccines ──────────────────────────────────────────────
DROP POLICY IF EXISTS "pet_vaccines: own" ON public.pet_vaccines;
CREATE POLICY "pet_vaccines: own"
ON public.pet_vaccines FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.pets
    WHERE pets.id = pet_vaccines.pet_id
      AND pets.owner_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.pets
    WHERE pets.id = pet_vaccines.pet_id
      AND pets.owner_id = auth.uid()
  )
);

-- ── services ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "services_read_all"    ON public.services;
DROP POLICY IF EXISTS "services_write_admin" ON public.services;

-- Qualquer um (inclusive anon) pode ler
CREATE POLICY "services_read_all"
ON public.services FOR SELECT
USING (TRUE);

-- Apenas admins podem criar / editar / excluir
CREATE POLICY "services_write_admin"
ON public.services FOR ALL
USING      (public.is_current_user_admin())
WITH CHECK (public.is_current_user_admin());

-- ── admin_activities ─────────────────────────────────────────
DROP POLICY IF EXISTS "admin_activities: admin read" ON public.admin_activities;
CREATE POLICY "admin_activities: admin read"
ON public.admin_activities FOR SELECT
USING (public.is_current_user_admin());

DROP POLICY IF EXISTS "admin_activities: insert" ON public.admin_activities;
CREATE POLICY "admin_activities: insert"
ON public.admin_activities FOR INSERT
WITH CHECK (TRUE);

-- ============================================================
-- STORAGE POLICIES — pet-photos
-- ============================================================

DROP POLICY IF EXISTS "Pet photos are public"                    ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload pet photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update pet photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete pet photos" ON storage.objects;

CREATE POLICY "Pet photos are public"
ON storage.objects FOR SELECT USING (bucket_id = 'pet-photos');

CREATE POLICY "Authenticated users can upload pet photos"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'pet-photos');

CREATE POLICY "Authenticated users can update pet photos"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'pet-photos');

CREATE POLICY "Authenticated users can delete pet photos"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'pet-photos');

-- ============================================================
-- STORAGE POLICIES — profile-photos
-- ============================================================

DROP POLICY IF EXISTS "Profile photos are public"                       ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload profile photos"   ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update profile photos"   ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete profile photos"   ON storage.objects;

CREATE POLICY "Profile photos are public"
ON storage.objects FOR SELECT USING (bucket_id = 'profile-photos');

CREATE POLICY "Authenticated users can upload profile photos"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'profile-photos');

CREATE POLICY "Authenticated users can update profile photos"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'profile-photos');

CREATE POLICY "Authenticated users can delete profile photos"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'profile-photos');

-- ============================================================
-- 5. TRIGGER — cria profile automaticamente após signup
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, name, phone, photo_url, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email, 'Usuário'),
    NEW.raw_user_meta_data->>'phone',
    NEW.raw_user_meta_data->>'photo_url',
    COALESCE(NEW.email, '')
  )
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email
    WHERE public.profiles.email = '';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 6. BACKFILL — cria perfil para usuários já existentes
-- ============================================================

INSERT INTO public.profiles (id, name)
SELECT
  id,
  COALESCE(raw_user_meta_data->>'name', email, 'Usuário')
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- PARA TORNAR UM USUÁRIO ADMIN:
--   UPDATE public.profiles
--   SET is_admin = TRUE
--   WHERE id = '<uuid-do-usuario>';
-- ============================================================
