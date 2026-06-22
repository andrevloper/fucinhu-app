-- ══════════════════════════════════════════════════════════════════
-- FUCINHO.CO — Setup do painel administrativo
-- Execute no Supabase → SQL Editor → New Query
-- ══════════════════════════════════════════════════════════════════

-- ── 1. Adicionar coluna is_admin na tabela profiles ───────────────
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

-- ── 2. Adicionar coluna service_* extras na tabela favorites ──────
--    (caso não existam — usadas pelo favorites_service.dart)
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_name     TEXT DEFAULT '';
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_category TEXT DEFAULT '';
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_address  TEXT DEFAULT '';
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_rating   NUMERIC DEFAULT 0;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_is_open  BOOLEAN DEFAULT TRUE;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_lat      NUMERIC DEFAULT 0;
ALTER TABLE favorites ADD COLUMN IF NOT EXISTS service_lng      NUMERIC DEFAULT 0;

-- ── 3. RPC: verificar se o usuário atual é admin ──────────────────
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM public.profiles WHERE id = auth.uid()),
    FALSE
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ── 4. Políticas admin: profiles ─────────────────────────────────
DROP POLICY IF EXISTS "admin_read_all_profiles" ON profiles;
CREATE POLICY "admin_read_all_profiles" ON profiles
  FOR SELECT USING (public.is_current_user_admin());

-- ── 5. Políticas admin: pets ──────────────────────────────────────
DROP POLICY IF EXISTS "admin_read_all_pets" ON pets;
CREATE POLICY "admin_read_all_pets" ON pets
  FOR SELECT USING (public.is_current_user_admin());

-- ── 6. Políticas admin: favorites ────────────────────────────────
DROP POLICY IF EXISTS "admin_read_all_favorites" ON favorites;
CREATE POLICY "admin_read_all_favorites" ON favorites
  FOR SELECT USING (public.is_current_user_admin());

-- ── 7. Promover um usuário a admin ───────────────────────────────
-- Substitua o e-mail abaixo e execute:
--
-- UPDATE profiles
-- SET is_admin = TRUE
-- WHERE id = (
--   SELECT id FROM auth.users WHERE email = 'seu-email@admin.com'
-- );

SELECT 'Admin setup concluído! Lembre de promover seu usuário com UPDATE profiles.' AS status;
