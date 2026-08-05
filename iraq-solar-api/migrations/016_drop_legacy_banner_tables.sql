-- Migration 016: Drop legacy home_banners and store_banners tables

DROP TABLE IF EXISTS store_banners CASCADE;
DROP TABLE IF EXISTS home_banners CASCADE;
