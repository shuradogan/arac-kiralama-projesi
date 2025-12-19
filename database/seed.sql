BEGIN;

-- =========================
-- 1) ŞUBE
-- =========================
INSERT INTO public.sube (sube_id, ad, sehir, adres) VALUES
(3, 'Havalimanı', 'İstanbul', 'İstanbul Havalimanı İç Hatlar Katı'),
(4, 'Kızılay',    'Ankara',   'Kızılay Meydanı No:5'),
(5, 'Alsancak',   'İzmir',    'Alsancak Mah. No:12')
ON CONFLICT (sube_id) DO NOTHING;

-- =========================
-- 2) KİŞİ (müşteri + çalışan havuzu)
-- =========================
INSERT INTO public.kisi (kisi_id, ad, soyad, telefon, eposta, olusturma_tarihi) VALUES
(4,  'Elif',   'Aydın',   '05550000004', 'elif.aydin@example.com',   '2025-12-16 14:32:42.079028'),
(5,  'Can',    'Koç',     '05550000005', 'can.koc@example.com',      '2025-12-16 14:32:42.079028'),
(6,  'Zeynep', 'Şahin',   '05550000006', 'zeynep.sahin@example.com', '2025-12-16 14:32:42.079028'),
(7,  'Mert',   'Yıldız',  '05550000007', 'mert.yildiz@example.com',  '2025-12-16 14:32:42.079028'),
(8,  'Ece',    'Çelik',   '05550000008', 'ece.celik@example.com',    '2025-12-16 14:32:42.079028'),
(9,  'Burak',  'Arslan',  '05550000009', 'burak.arslan@example.com', '2025-12-16 14:32:42.079028'),
(10, 'Sena',   'Kurt',    '05550000010', 'sena.kurt@example.com',    '2025-12-16 14:32:42.079028'),
(11, 'Oğuz',   'Demirtaş','05550000011', 'oguz.demirtas@example.com','2025-12-16 14:32:42.079028'),
(12, 'İrem',   'Kara',    '05550000012', 'irem.kara@example.com',    '2025-12-16 14:32:42.079028'),
(13, 'Hakan',  'Aksoy',   '05550000013', 'hakan.aksoy@example.com',  '2025-12-16 14:32:42.079028'),
(14, 'Derya',  'Öztürk',  '05550000014', 'derya.ozturk@example.com', '2025-12-16 14:32:42.079028'),
(15, 'Deniz',  'Ergin',   '05550000015', 'deniz.ergin@example.com',  '2025-12-16 14:32:42.079028')
ON CONFLICT (kisi_id) DO NOTHING;

-- =========================
-- 3) MÜŞTERİ
-- =========================
INSERT INTO public.musteri (kisi_id, ehliyet_no, dogum_tarihi) VALUES
(4,  'EH234567', '2001-03-14'),
(5,  'EH345678', '1998-11-02'),
(6,  'EH456789', '2000-07-21'),
(7,  'EH567890', '1999-01-09'),
(8,  'EH678901', '2003-09-30'),
(9,  'EH789012', '1997-05-18'),
(10, 'EH890123', '2002-12-12'),
(11, 'EH901234', '1996-08-25')
ON CONFLICT (kisi_id) DO NOTHING;

-- =========================
-- 4) ÇALIŞAN
-- (Mevcutta kişi_id=2 çalışan var, ek olarak birkaç tane daha)
-- =========================
INSERT INTO public.calisan (kisi_id, sube_id, gorev_unvani) VALUES
(12, 3, 'gorevli'),
(13, 4, 'mudur'),
(14, 5, 'gorevli')
ON CONFLICT (kisi_id) DO NOTHING;

-- =========================
-- 5) EK HİZMET (var olan GPS + Bebek Koltuğu var, birkaç tane daha ekleyelim)
-- =========================
INSERT INTO public.ek_hizmet (ek_hizmet_id, ad, gunluk_fiyat, aktif_mi) VALUES
(3, 'Kasko',         120.00, true),
(4, 'WiFi',           70.00, true),
(5, 'Zincir',         40.00, true),
(6, 'Ek Sürücü',      90.00, true)
ON CONFLICT (ek_hizmet_id) DO NOTHING;

-- =========================
-- 6) İNDİRİM KUPONU (YENI10 var, birkaç tane daha)
-- =========================
INSERT INTO public.indirim_kuponu (kupon_id, kod, indirim_yuzde, aktif_mi, son_kullanma_tarihi) VALUES
(2, 'KIS15',   15, true, '2026-02-28'),
(3, 'OGRENCI5', 5, true, '2026-06-30'),
(4, 'HAFTA20', 20, true, '2026-01-31')
ON CONFLICT (kupon_id) DO NOTHING;

-- =========================
-- 7) ARAÇLAR (otomobil + motosiklet)
-- Not: arac_turu 'otomobil' ise otomobil tablosuna, 'motosiklet' ise motosiklet tablosuna ekliyoruz.
-- =========================
INSERT INTO public.arac (arac_id, sube_id, plaka, marka, model, yil, gunluk_ucret, durum, arac_turu, olusturma_tarihi) VALUES
(3,  1, '34ABC123', 'Renault', 'Clio',      2021,  950.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(4,  1, '06ANK606', 'Fiat',    'Egea',      2022, 1050.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(5,  2, '35IZM353', 'Hyundai', 'i20',       2020,  900.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(6,  2, '41KOC414', 'Ford',    'Focus',     2019, 1100.00, 'kirada', 'otomobil',   '2025-12-16 14:32:42.079028'),
(7,  3, '34IST777', 'Volkswagen','Polo',    2021, 1200.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(8,  3, '34IST888', 'Toyota',  'Yaris',     2022, 1300.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(9,  4, '06ANK111', 'Honda',   'Civic',     2020, 1500.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(10, 4, '06ANK222', 'Skoda',   'Octavia',   2018, 1450.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(11, 5, '35IZM101', 'Peugeot', '3008',      2021, 1900.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028'),
(12, 5, '35IZM202', 'Opel',    'Corsa',     2019,  980.00, 'kirada', 'otomobil',   '2025-12-16 14:32:42.079028'),
(13, 1, '34MOTO34', 'Yamaha',  'R25',       2020,  650.00, 'musait', 'motosiklet', '2025-12-16 14:32:42.079028'),
(14, 2, '54MOTO12', 'Kawasaki','Ninja400',  2021,  800.00, 'musait', 'motosiklet', '2025-12-16 14:32:42.079028'),
(15, 3, '34MOTO78', 'Honda',   'PCX',       2022,  450.00, 'musait', 'motosiklet', '2025-12-16 14:32:42.079028'),
(16, 4, '06MOTO06', 'Suzuki',  'GSX',       2019,  750.00, 'kirada', 'motosiklet', '2025-12-16 14:32:42.079028'),
(17, 5, '35MOTO35', 'BMW',     'G310R',     2020,  900.00, 'musait', 'motosiklet', '2025-12-16 14:32:42.079028'),
(18, 1, '34ABC999', 'Tesla',   'Model 3',   2023, 2600.00, 'musait', 'otomobil',   '2025-12-16 14:32:42.079028')
ON CONFLICT (arac_id) DO NOTHING;

-- Otomobil detayları
INSERT INTO public.otomobil (arac_id, kapi_sayisi, bagaj_litre) VALUES
(3,  5, 300),
(4,  4, 480),
(5,  5, 310),
(6,  4, 470),
(7,  5, 280),
(8,  5, 286),
(9,  4, 519),
(10, 4, 590),
(11, 5, 520),
(12, 4, 309),
(18, 4, 425)
ON CONFLICT (arac_id) DO NOTHING;

-- Motosiklet detayları
INSERT INTO public.motosiklet (arac_id, motor_hacmi_cc) VALUES
(13, 250),
(14, 400),
(15, 125),
(16, 750),
(17, 310)
ON CONFLICT (arac_id) DO NOTHING;

-- =========================
-- 8) BAKIM (birkaç bakım kaydı)
-- =========================
INSERT INTO public.bakim (bakim_id, arac_id, baslangic_tarihi, bitis_tarihi, aciklama) VALUES
(1, 4,  '2025-11-10', '2025-11-12', 'Periyodik bakım'),
(2, 11, '2025-12-01', '2025-12-03', 'Lastik değişimi')
ON CONFLICT (bakim_id) DO NOTHING;

-- =========================
-- 9) KİRALAMA (dolu gözüksün diye çeşitli kayıtlar)
-- =========================
INSERT INTO public.kiralama (kiralama_id, musteri_id, arac_id, sube_id, baslangic_tarihi, bitis_tarihi, durum, kupon_id, toplam_tutar) VALUES
(7,  4, 3,  1, '2025-12-20', '2025-12-22', 'aktif',  1, 1710.00),
(8,  5, 4,  1, '2025-12-18', '2025-12-19', 'aktif',  NULL, 1050.00),
(9,  6, 5,  2, '2025-12-05', '2025-12-08', 'iptal',  2, 2295.00),
(10, 7, 6,  2, '2025-12-10', '2025-12-12', 'aktif',  NULL, 2200.00),
(11, 8, 7,  3, '2025-11-22', '2025-11-25', 'aktif',  3, 3420.00),
(12, 9, 8,  3, '2025-10-01', '2025-10-03', 'iptal',  NULL, 2600.00),
(13, 10,9,  4, '2025-09-14', '2025-09-16', 'aktif',  4, 2400.00),
(14, 11,10, 4, '2025-08-02', '2025-08-05', 'aktif',  NULL, 4350.00),
(15, 1, 11, 5, '2025-07-10', '2025-07-13', 'aktif',  2, 4845.00),
(16, 4, 12, 5, '2025-06-20', '2025-06-22', 'iptal',  NULL, 1960.00),
(17, 5, 13, 1, '2025-12-21', '2025-12-23', 'aktif',  NULL, 1300.00),
(18, 6, 14, 2, '2025-12-02', '2025-12-04', 'aktif',  1, 1440.00),
(19, 7, 15, 3, '2025-11-05', '2025-11-06', 'aktif',  NULL, 450.00),
(20, 8, 16, 4, '2025-12-17', '2025-12-18', 'aktif',  NULL, 750.00),
(21, 9, 17, 5, '2025-10-20', '2025-10-22', 'aktif',  3, 1710.00),
(22, 10,18, 1, '2025-12-24', '2025-12-26', 'aktif',  4, 4160.00),
(23, 11,3,  1, '2025-01-10', '2025-01-12', 'iptal',  NULL, 1900.00),
(24, 6, 8,  3, '2025-02-01', '2025-02-04', 'aktif',  NULL, 3900.00)
ON CONFLICT (kiralama_id) DO NOTHING;

-- =========================
-- 10) ÖDEME (bazı aktif kiralamalar için)
-- =========================
INSERT INTO public.odeme (odeme_id, kiralama_id, tutar, yontem, odeme_tarihi, durum) VALUES
(2,  7,  1710.00, 'kart',  '2025-12-20 10:05:00', 'odendi'),
(3,  8,  1050.00, 'nakit', '2025-12-18 09:10:00', 'odendi'),
(4,  10, 2200.00, 'kart',  '2025-12-10 12:00:00', 'odendi'),
(5,  11, 3420.00, 'kart',  '2025-11-22 14:30:00', 'odendi'),
(6,  13, 2400.00, 'kart',  '2025-09-14 08:15:00', 'odendi'),
(7,  15, 4845.00, 'kart',  '2025-07-10 11:40:00', 'odendi'),
(8,  22, 4160.00, 'kart',  '2025-12-24 16:20:00', 'odendi')
ON CONFLICT (odeme_id) DO NOTHING;

-- =========================
-- 11) KİRALAMA - EK HİZMET (bazı kiralamalara hizmet ekleyelim)
-- =========================
INSERT INTO public.kiralama_ek_hizmet (kiralama_id, ek_hizmet_id, adet) VALUES
(7,  1, 1),  -- GPS
(7,  3, 1),  -- Kasko
(10, 2, 1),  -- Bebek Koltuğu
(11, 4, 1),  -- WiFi
(15, 3, 1),  -- Kasko
(22, 1, 1),  -- GPS
(22, 4, 1)   -- WiFi
ON CONFLICT DO NOTHING;

-- =========================
-- 12) ARAÇ DURUM GEÇMİŞİ (demo amaçlı birkaç satır)
-- =========================
INSERT INTO public.arac_durum_gecmisi (gecmis_id, arac_id, eski_durum, yeni_durum, degisiklik_tarihi, degistiren_calisan_id) VALUES
(7,  6,  'musait', 'kirada', '2025-12-10 09:00:00', 2),
(8,  12, 'musait', 'kirada', '2025-06-20 08:45:00', 2),
(9,  16, 'musait', 'kirada', '2025-12-17 09:05:00', 12)
ON CONFLICT (gecmis_id) DO NOTHING;

-- =========================
-- 13) Sayaçları (identity/seq) güncelle
-- =========================
SELECT pg_catalog.setval('public.sube_sube_id_seq',                 (SELECT COALESCE(MAX(sube_id),1) FROM public.sube), true);
SELECT pg_catalog.setval('public.kisi_kisi_id_seq',                 (SELECT COALESCE(MAX(kisi_id),1) FROM public.kisi), true);
SELECT pg_catalog.setval('public.arac_arac_id_seq',                 (SELECT COALESCE(MAX(arac_id),1) FROM public.arac), true);
SELECT pg_catalog.setval('public.bakim_bakim_id_seq',               (SELECT COALESCE(MAX(bakim_id),1) FROM public.bakim), true);
SELECT pg_catalog.setval('public.ek_hizmet_ek_hizmet_id_seq',        (SELECT COALESCE(MAX(ek_hizmet_id),1) FROM public.ek_hizmet), true);
SELECT pg_catalog.setval('public.indirim_kuponu_kupon_id_seq',       (SELECT COALESCE(MAX(kupon_id),1) FROM public.indirim_kuponu), true);
SELECT pg_catalog.setval('public.kiralama_kiralama_id_seq',          (SELECT COALESCE(MAX(kiralama_id),1) FROM public.kiralama), true);
SELECT pg_catalog.setval('public.odeme_odeme_id_seq',               (SELECT COALESCE(MAX(odeme_id),1) FROM public.odeme), true);
SELECT pg_catalog.setval('public.arac_durum_gecmisi_gecmis_id_seq',  (SELECT COALESCE(MAX(gecmis_id),1) FROM public.arac_durum_gecmisi), true);

COMMIT;
