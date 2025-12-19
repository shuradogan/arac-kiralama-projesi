-- İş fonksiyonları (4 adet)

CREATE FUNCTION public.fn_aylik_gelir(p_yil integer, p_ay integer) RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  v_toplam NUMERIC;
BEGIN
  IF p_ay < 1 OR p_ay > 12 THEN
    RAISE EXCEPTION 'Ay 1-12 arasinda olmali.';
  END IF;

  SELECT COALESCE(SUM(o.tutar), 0)
  INTO v_toplam
  FROM odeme o
  WHERE o.durum = 'odendi'
    AND EXTRACT(YEAR FROM o.odeme_tarihi) = p_yil
    AND EXTRACT(MONTH FROM o.odeme_tarihi) = p_ay;

  RETURN v_toplam;
END;
$$;

ALTER FUNCTION public.fn_aylik_gelir(p_yil integer, p_ay integer) OWNER TO postgres;


CREATE FUNCTION public.fn_kiralama_iptal_et(p_kiralama_id bigint) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE kiralama
  SET durum = 'iptal'
  WHERE kiralama_id = p_kiralama_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Kiralama bulunamadi: %', p_kiralama_id;
  END IF;
END;
$$;

ALTER FUNCTION public.fn_kiralama_iptal_et(p_kiralama_id bigint) OWNER TO postgres;


CREATE FUNCTION public.fn_kiralama_olustur(
  p_musteri_id bigint,
  p_arac_id bigint,
  p_sube_id bigint,
  p_baslangic date,
  p_bitis date,
  p_kupon_kod character varying DEFAULT NULL::character varying
) RETURNS bigint
LANGUAGE plpgsql
AS $$
DECLARE
  v_gun_sayisi INT;
  v_gunluk_ucret NUMERIC(10,2);
  v_brut NUMERIC(10,2);
  v_indirim_yuzde INT;
  v_net NUMERIC(10,2);
  v_kupon_id BIGINT;
  v_yeni_kiralama_id BIGINT;
BEGIN
  IF p_baslangic > p_bitis THEN
    RAISE EXCEPTION 'Baslangic tarihi bitis tarihinden buyuk olamaz.';
  END IF;

  SELECT a.gunluk_ucret
  INTO v_gunluk_ucret
  FROM arac a
  WHERE a.arac_id = p_arac_id
    AND a.sube_id = p_sube_id;

  IF v_gunluk_ucret IS NULL THEN
    RAISE EXCEPTION 'Arac bulunamadi veya verilen subeye ait degil.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM bakim b
    WHERE b.arac_id = p_arac_id
      AND (p_baslangic, p_bitis) OVERLAPS (b.baslangic_tarihi, b.bitis_tarihi)
  ) THEN
    RAISE EXCEPTION 'Arac bu tarihlerde bakimda. Kiralama olusturulamaz.';
  END IF;

  IF EXISTS (
    SELECT 1 FROM kiralama k
    WHERE k.arac_id = p_arac_id
      AND k.durum <> 'iptal'
      AND (p_baslangic, p_bitis) OVERLAPS (k.baslangic_tarihi, k.bitis_tarihi)
  ) THEN
    RAISE EXCEPTION 'Arac bu tarihlerde baska bir kiralamada. Tarih cakismasi var.';
  END IF;

  v_gun_sayisi := (p_bitis - p_baslangic) + 1;
  v_brut := v_gun_sayisi * v_gunluk_ucret;

  v_indirim_yuzde := 0;
  v_kupon_id := NULL;

  IF p_kupon_kod IS NOT NULL AND length(trim(p_kupon_kod)) > 0 THEN
    SELECT kupon_id, indirim_yuzde
    INTO v_kupon_id, v_indirim_yuzde
    FROM indirim_kuponu
    WHERE kod = p_kupon_kod
      AND aktif_mi = TRUE
      AND (son_kullanma_tarihi IS NULL OR son_kullanma_tarihi >= CURRENT_DATE);

    IF v_kupon_id IS NULL THEN
      RAISE EXCEPTION 'Kupon gecersiz / pasif / suresi dolmus.';
    END IF;
  END IF;

  v_net := v_brut - (v_brut * v_indirim_yuzde / 100.0);

  INSERT INTO kiralama (
    musteri_id, arac_id, sube_id,
    baslangic_tarihi, bitis_tarihi,
    durum, kupon_id, toplam_tutar
  )
  VALUES (
    p_musteri_id, p_arac_id, p_sube_id,
    p_baslangic, p_bitis,
    'aktif', v_kupon_id, v_net
  )
  RETURNING kiralama_id INTO v_yeni_kiralama_id;

  RETURN v_yeni_kiralama_id;
END;
$$;

ALTER FUNCTION public.fn_kiralama_olustur(
  p_musteri_id bigint,
  p_arac_id bigint,
  p_sube_id bigint,
  p_baslangic date,
  p_bitis date,
  p_kupon_kod character varying
) OWNER TO postgres;


CREATE FUNCTION public.fn_uygun_araclari_ara(p_sube_id bigint, p_baslangic date, p_bitis date)
RETURNS TABLE(arac_id bigint, plaka character varying, marka character varying, model character varying, gunluk_ucret numeric, arac_turu character varying, durum character varying)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_baslangic > p_bitis THEN
    RAISE EXCEPTION 'Baslangic tarihi bitis tarihinden buyuk olamaz.';
  END IF;

  RETURN QUERY
  SELECT a.arac_id, a.plaka, a.marka, a.model, a.gunluk_ucret, a.arac_turu, a.durum
  FROM arac a
  WHERE a.sube_id = p_sube_id
    AND a.durum = 'musait'
    AND NOT EXISTS (
      SELECT 1
      FROM bakim b
      WHERE b.arac_id = a.arac_id
        AND (p_baslangic, p_bitis) OVERLAPS (b.baslangic_tarihi, b.bitis_tarihi)
    )
    AND NOT EXISTS (
      SELECT 1
      FROM kiralama k
      WHERE k.arac_id = a.arac_id
        AND k.durum <> 'iptal'
        AND (p_baslangic, p_bitis) OVERLAPS (k.baslangic_tarihi, k.bitis_tarihi)
    )
  ORDER BY a.gunluk_ucret, a.marka, a.model;

END;
$$;

ALTER FUNCTION public.fn_uygun_araclari_ara(p_sube_id bigint, p_baslangic date, p_bitis date) OWNER TO postgres;


-- Trigger fonksiyonları (tetikleyicilerin çağırdığı mini programlar)

CREATE FUNCTION public.trg_degisim_kaydi_yaz() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_pk TEXT;
  v_new JSONB;
  v_old JSONB;
BEGIN
  IF TG_OP = 'INSERT' THEN
    v_new := to_jsonb(NEW);
    v_pk := COALESCE(v_new->>'kiralama_id', v_new->>'arac_id', v_new->>'odeme_id', 'bilinmiyor');

    INSERT INTO degisiklik_kaydi(tablo_adi, islem_turu, kayit_anahtari, eski_veri, yeni_veri)
    VALUES (TG_TABLE_NAME, 'ekleme', v_pk, NULL, v_new);

    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    v_new := to_jsonb(NEW);
    v_old := to_jsonb(OLD);
    v_pk := COALESCE(v_new->>'kiralama_id', v_new->>'arac_id', v_new->>'odeme_id', 'bilinmiyor');

    INSERT INTO degisiklik_kaydi(tablo_adi, islem_turu, kayit_anahtari, eski_veri, yeni_veri)
    VALUES (TG_TABLE_NAME, 'guncelleme', v_pk, v_old, v_new);

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    v_old := to_jsonb(OLD);
    v_pk := COALESCE(v_old->>'kiralama_id', v_old->>'arac_id', v_old->>'odeme_id', 'bilinmiyor');

    INSERT INTO degisiklik_kaydi(tablo_adi, islem_turu, kayit_anahtari, eski_veri, yeni_veri)
    VALUES (TG_TABLE_NAME, 'silme', v_pk, v_old, NULL);

    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

ALTER FUNCTION public.trg_degisim_kaydi_yaz() OWNER TO postgres;


CREATE FUNCTION public.trg_kiralama_arac_durum_guncelle() RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_eski VARCHAR(15);
  v_yeni VARCHAR(15);
BEGIN
  SELECT durum INTO v_eski FROM arac WHERE arac_id = NEW.arac_id FOR UPDATE;

  IF NEW.durum = 'aktif' THEN
    v_yeni := 'kirada';
  ELSE
    v_yeni := 'musait';
  END IF;

  UPDATE arac
  SET durum = v_yeni
  WHERE arac_id = NEW.arac_id;

  INSERT INTO arac_durum_gecmisi(arac_id, eski_durum, yeni_durum, degistiren_calisan_id)
  VALUES (NEW.arac_id, v_eski, v_yeni, NULL);

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.trg_kiralama_arac_durum_guncelle() OWNER TO postgres;


CREATE FUNCTION public.trg_kiralama_bakim_kontrol() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.durum <> 'iptal' THEN
    IF EXISTS (
      SELECT 1
      FROM bakim b
      WHERE b.arac_id = NEW.arac_id
        AND (NEW.baslangic_tarihi, NEW.bitis_tarihi) OVERLAPS (b.baslangic_tarihi, b.bitis_tarihi)
    ) THEN
      RAISE EXCEPTION 'Bakim engeli: Arac bu tarihlerde bakimda.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.trg_kiralama_bakim_kontrol() OWNER TO postgres;


CREATE FUNCTION public.trg_kiralama_tarih_cakisma_kontrol() RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.baslangic_tarihi > NEW.bitis_tarihi THEN
    RAISE EXCEPTION 'Baslangic tarihi bitis tarihinden buyuk olamaz.';
  END IF;

  IF NEW.durum <> 'iptal' THEN
    IF EXISTS (
      SELECT 1
      FROM kiralama k
      WHERE k.arac_id = NEW.arac_id
        AND k.durum <> 'iptal'
        AND k.kiralama_id <> COALESCE(NEW.kiralama_id, -1)
        AND (NEW.baslangic_tarihi, NEW.bitis_tarihi) OVERLAPS (k.baslangic_tarihi, k.bitis_tarihi)
    ) THEN
      RAISE EXCEPTION 'Tarih cakismasi: Arac bu tarihlerde baska kiralamada.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.trg_kiralama_tarih_cakisma_kontrol() OWNER TO postgres;
