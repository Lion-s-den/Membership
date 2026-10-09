-- ============================================================
-- Supabase schema for Membership LMS
-- Run in Supabase → SQL Editor
-- ============================================================

-- 1. Tables
CREATE TABLE IF NOT EXISTS courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS chapters (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  youtube_url TEXT,
  quiz JSONB DEFAULT '[]'::jsonb,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE chapters ENABLE ROW LEVEL SECURITY;

-- 3. Drop old policies if they exist (safe to re-run)
DROP POLICY IF EXISTS "Anyone can view courses" ON courses;
DROP POLICY IF EXISTS "Anyone can view chapters" ON chapters;
DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
DROP POLICY IF EXISTS "Admins can manage chapters" ON chapters;
DROP POLICY IF EXISTS "Public read courses" ON courses;
DROP POLICY IF EXISTS "Public read chapters" ON chapters;
DROP POLICY IF EXISTS "Admin write courses" ON courses;
DROP POLICY IF EXISTS "Admin write chapters" ON chapters;

-- 4. READ: anyone (students + public)
CREATE POLICY "Public read courses"
  ON courses FOR SELECT
  USING (true);

CREATE POLICY "Public read chapters"
  ON chapters FOR SELECT
  USING (true);

-- 5. WRITE: only users with role = admin in app_metadata
--    app_metadata can only be set by a service role / dashboard admin
--    (users cannot change it themselves — more secure than user_metadata)
CREATE POLICY "Admin write courses"
  ON courses FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

CREATE POLICY "Admin write chapters"
  ON chapters FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

-- ============================================================
-- HOW TO MAKE YOURSELF AN ADMIN
-- ============================================================
-- 1. Supabase Dashboard → Authentication → Users
-- 2. Click your user
-- 3. Open "App Metadata" (NOT User Metadata)
-- 4. Set:
--    {
--      "role": "admin"
--    }
-- 5. Save
-- 6. Log out and log back in so the JWT is refreshed
-- ============================================================
-- ALSO RECOMMENDED:
-- Rotate your anon key if config.js was ever committed with real keys.
-- Dashboard → Project Settings → API → Reset / rotate keys.
-- Then create a local config.js from config.example.js (never commit it).
-- ============================================================
