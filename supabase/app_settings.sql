-- Run this in the Supabase SQL editor.
-- Stores remote feature toggles; the iOS app reads them on launch via
-- AppSettingsRepository.fetchAll().

CREATE TABLE IF NOT EXISTS public.app_settings (
    key         TEXT PRIMARY KEY,
    value       TEXT NOT NULL,
    description TEXT,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_settings public read" ON public.app_settings;
CREATE POLICY "app_settings public read"
    ON public.app_settings FOR SELECT
    USING (true);

-- Seed the toggles the app currently knows about. Toggle to 'false' to
-- hide the corresponding button in the next session.
INSERT INTO public.app_settings (key, value, description) VALUES
    ('show_btn_send_media', 'true', 'Send photo/video chip in chat actions'),
    ('show_btn_capture',    'true', 'Capture screenshot chip in chat actions'),
    ('show_btn_dance',      'true', 'Dance chip in chat actions'),
    ('show_btn_voice_call', 'true', 'Mic / voice call button on input bar'),
    ('show_btn_video_call', 'true', 'Video call button on input bar'),
    ('show_btn_bgm',        'true', 'Background music toggle on side rail'),
    ('show_btn_costume',    'true', 'Outfit shortcut on side rail'),
    ('show_btn_background', 'true', 'Background shortcut on side rail'),
    ('show_btn_chat_list',  'true', 'Chat overlay toggle on side rail'),
    ('show_btn_pro',        'true', 'Pink Pro hex button on left rail'),
    ('show_btn_quest',      'false', 'Quest entry (placeholder, hidden by default)')
ON CONFLICT (key) DO NOTHING;
