-- ============================================================
-- MIGRAÇÃO 003 — Admin Activities + colunas faltantes
-- Idempotente: seguro de rodar em banco existente ou zerado.
-- Supabase SQL Editor → New Query → Run
-- ============================================================

-- ============================================================
-- 1. COLUNAS FALTANTES — profiles
-- ============================================================

-- Email (sincronizado do auth.users via trigger)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS email TEXT NOT NULL DEFAULT '';

-- Status da conta (admin pode desativar)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Plano Pro
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_pro BOOLEAN NOT NULL DEFAULT FALSE;

-- Backfill: copia e-mail do auth.users para profiles
UPDATE public.profiles p
SET email = COALESCE(u.email, '')
FROM auth.users u
WHERE p.id = u.id
  AND (p.email IS NULL OR p.email = '');

-- ============================================================
-- 2. COLUNAS FALTANTES — services
-- ============================================================

-- Destaque na seção "Indicação Fucinhu" do app
ALTER TABLE public.services
  ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT FALSE;

-- ============================================================
-- 2b. COLUNAS FALTANTES — favorites
-- ============================================================

-- Fotos do estabelecimento (salvas junto com o favorito para exibição offline)
ALTER TABLE public.favorites
  ADD COLUMN IF NOT EXISTS service_photo_urls TEXT[] NOT NULL DEFAULT '{}';

-- ============================================================
-- 3. TABELA admin_activities
-- ============================================================

CREATE TABLE IF NOT EXISTS public.admin_activities (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id    UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  action      TEXT        NOT NULL,
  entity_type TEXT        NOT NULL DEFAULT '',
  entity_id   TEXT,
  entity_name TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índices para consultas rápidas na tela de atividades
CREATE INDEX IF NOT EXISTS admin_activities_created_at_idx
  ON public.admin_activities (created_at DESC);

CREATE INDEX IF NOT EXISTS admin_activities_admin_id_idx
  ON public.admin_activities (admin_id);

-- ============================================================
-- 4. RLS — admin_activities
-- ============================================================

ALTER TABLE public.admin_activities ENABLE ROW LEVEL SECURITY;

-- Admins podem ler todas as atividades
DROP POLICY IF EXISTS "admin_activities: admin read" ON public.admin_activities;
CREATE POLICY "admin_activities: admin read"
ON public.admin_activities FOR SELECT
USING (public.is_current_user_admin());

-- Qualquer usuário autenticado pode inserir (usado pelo service role via supabaseAdmin)
-- O service role bypassa RLS de qualquer jeito, mas esta policy permite inserts via anon também
DROP POLICY IF EXISTS "admin_activities: insert" ON public.admin_activities;
CREATE POLICY "admin_activities: insert"
ON public.admin_activities FOR INSERT
WITH CHECK (TRUE);

-- ============================================================
-- 5. ATUALIZAR TRIGGER — sincroniza email no signup
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

SELECT 'Migração 003 concluída: admin_activities, is_featured, is_active, is_pro, email' AS status;
