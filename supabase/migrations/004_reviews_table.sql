-- ============================================================
-- MIGRAÇÃO 004 — Tabela de avaliações (reviews)
-- Idempotente: seguro de rodar em banco existente ou zerado.
-- Supabase SQL Editor → New Query → Run
-- ============================================================

-- ── Tabela de avaliações ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  service_id  TEXT        NOT NULL,
  user_id     UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating      INT         NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment     TEXT        NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(service_id, user_id)
);

CREATE INDEX IF NOT EXISTS reviews_service_id_idx ON public.reviews (service_id);
CREATE INDEX IF NOT EXISTS reviews_user_id_idx    ON public.reviews (user_id);
CREATE INDEX IF NOT EXISTS reviews_created_at_idx ON public.reviews (created_at DESC);

-- ── RLS ───────────────────────────────────────────────────────
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Qualquer um pode ler avaliações
DROP POLICY IF EXISTS "reviews: read all" ON public.reviews;
CREATE POLICY "reviews: read all"
ON public.reviews FOR SELECT
USING (TRUE);

-- Usuário autenticado pode inserir sua própria avaliação
DROP POLICY IF EXISTS "reviews: insert own" ON public.reviews;
CREATE POLICY "reviews: insert own"
ON public.reviews FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Usuário pode editar sua própria avaliação
DROP POLICY IF EXISTS "reviews: update own" ON public.reviews;
CREATE POLICY "reviews: update own"
ON public.reviews FOR UPDATE TO authenticated
USING     (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Usuário pode deletar sua própria avaliação
DROP POLICY IF EXISTS "reviews: delete own" ON public.reviews;
CREATE POLICY "reviews: delete own"
ON public.reviews FOR DELETE TO authenticated
USING (auth.uid() = user_id);

SELECT 'Migração 004 concluída: tabela reviews criada com RLS' AS status;
