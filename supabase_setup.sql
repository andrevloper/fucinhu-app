-- ══════════════════════════════════════════════════════════════════
-- FUCINHO.CO — Setup completo do banco de dados
-- Execute no Supabase → SQL Editor → New Query
-- ══════════════════════════════════════════════════════════════════

-- ── 1. Tabela de perfis ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL DEFAULT '',
  phone       TEXT DEFAULT '',
  photo_url   TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 2. Tabela de pets ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  species     TEXT NOT NULL DEFAULT 'Cachorro',
  breed       TEXT NOT NULL DEFAULT '',
  age_months  INT NOT NULL DEFAULT 12,
  photo_url   TEXT,
  notes       TEXT DEFAULT '',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ── 3. Tabela de favoritos ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS favorites (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  service_id  TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, service_id)
);

-- ── 4. Habilitar RLS ─────────────────────────────────────────────
ALTER TABLE profiles  ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets       ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites  ENABLE ROW LEVEL SECURITY;

-- ── 5. Políticas de segurança ─────────────────────────────────────
-- Profiles: usuário acessa apenas seu próprio perfil
DROP POLICY IF EXISTS "profiles_own" ON profiles;
CREATE POLICY "profiles_own" ON profiles
  FOR ALL USING (auth.uid() = id);

-- Pets: usuário acessa apenas seus próprios pets
DROP POLICY IF EXISTS "pets_own" ON pets;
CREATE POLICY "pets_own" ON pets
  FOR ALL USING (auth.uid() = owner_id);

-- Favorites: usuário acessa apenas seus favoritos
DROP POLICY IF EXISTS "favorites_own" ON favorites;
CREATE POLICY "favorites_own" ON favorites
  FOR ALL USING (auth.uid() = user_id);

-- ── 6. Trigger: cria perfil automaticamente no cadastro ──────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'phone', '')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ── 7. Storage: bucket para fotos de pets ────────────────────────
-- Execute separadamente se necessário:
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('pet-photos', 'pet-photos', true)
-- ON CONFLICT (id) DO NOTHING;

-- Política de storage (anon pode ler, dono pode escrever)
-- DROP POLICY IF EXISTS "pet_photos_read" ON storage.objects;
-- CREATE POLICY "pet_photos_read" ON storage.objects
--   FOR SELECT USING (bucket_id = 'pet-photos');

-- DROP POLICY IF EXISTS "pet_photos_write" ON storage.objects;
-- CREATE POLICY "pet_photos_write" ON storage.objects
--   FOR INSERT WITH CHECK (
--     bucket_id = 'pet-photos' AND auth.uid()::text = (storage.foldername(name))[1]
--   );

SELECT 'Setup concluído!' AS status;
