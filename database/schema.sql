-- Tablolar

CREATE TABLE public.sube (
  sube_id bigint NOT NULL,
  ad character varying(100) NOT NULL,
  sehir character varying(60) NOT NULL,
  adres character varying(200) NOT NULL
);

CREATE TABLE public.kisi (
  kisi_id bigint NOT NULL,
  ad character varying(60) NOT NULL,
  soyad character varying(60) NOT NULL,
  telefon character varying(25),
  eposta character varying(120) NOT NULL,
  olusturma_tarihi timestamp without time zone DEFAULT now() NOT NULL,
  CONSTRAINT kisi_eposta_check CHECK (((eposta)::text ~~ '%@%'::text))
);

CREATE TABLE public.musteri (
  kisi_id bigint NOT NULL,
  ehliyet_no character varying(30) NOT NULL,
  dogum_tarihi date
);

CREATE TABLE public.calisan (
  kisi_id bigint NOT NULL,
  sube_id bigint NOT NULL,
  gorev_unvani character varying(80) NOT NULL
);

CREATE TABLE public.arac (
  arac_id bigint NOT NULL,
  sube_id bigint NOT NULL,
  plaka character varying(15) NOT NULL,
  marka character varying(60) NOT NULL,
  model character varying(60) NOT NULL,
  yil integer,
  gunluk_ucret numeric(10,2) NOT NULL,
  durum character varying(15) DEFAULT 'musait'::character varying NOT NULL,
  arac_turu character varying(15) NOT NULL,
  olusturma_tarihi timestamp without time zone DEFAULT now() NOT NULL,
  CONSTRAINT arac_arac_turu_check CHECK (((arac_turu)::text = ANY ((ARRAY['otomobil'::character varying, 'motosiklet'::character varying])::text[]))),
  CONSTRAINT arac_durum_check CHECK (((durum)::text = ANY ((ARRAY['musait'::character varying, 'kirada'::character varying, 'bakimda'::character varying])::text[]))),
  CONSTRAINT arac_gunluk_ucret_check CHECK ((gunluk_ucret >= (0)::numeric)),
  CONSTRAINT arac_yil_check CHECK (((yil IS NULL) OR ((yil >= 1950) AND (yil <= 2100))))
);

CREATE TABLE public.otomobil (
  arac_id bigint NOT NULL,
  kapi_sayisi integer NOT NULL,
  bagaj_litre integer,
  CONSTRAINT otomobil_bagaj_litre_check CHECK (((bagaj_litre IS NULL) OR (bagaj_litre >= 0))),
  CONSTRAINT otomobil_kapi_sayisi_check CHECK (((kapi_sayisi >= 2) AND (kapi_sayisi <= 6)))
);

CREATE TABLE public.motosiklet (
  arac_id bigint NOT NULL,
  motor_hacmi_cc integer NOT NULL,
  CONSTRAINT motosiklet_motor_hacmi_cc_check CHECK (((motor_hacmi_cc >= 50) AND (motor_hacmi_cc <= 2500)))
);

CREATE TABLE public.arac_durum_gecmisi (
  gecmis_id bigint NOT NULL,
  arac_id bigint NOT NULL,
  eski_durum character varying(15) NOT NULL,
  yeni_durum character varying(15) NOT NULL,
  degisiklik_tarihi timestamp without time zone DEFAULT now() NOT NULL,
  degistiren_calisan_id bigint,
  CONSTRAINT arac_durum_gecmisi_eski_durum_check CHECK (((eski_durum)::text = ANY ((ARRAY['musait'::character varying, 'kirada'::character varying, 'bakimda'::character varying])::text[]))),
  CONSTRAINT arac_durum_gecmisi_yeni_durum_check CHECK (((yeni_durum)::text = ANY ((ARRAY['musait'::character varying, 'kirada'::character varying, 'bakimda'::character varying])::text[])))
);

CREATE TABLE public.bakim (
  bakim_id bigint NOT NULL,
  arac_id bigint NOT NULL,
  baslangic_tarihi date NOT NULL,
  bitis_tarihi date NOT NULL,
  aciklama character varying(250),
  CONSTRAINT bakim_check CHECK ((baslangic_tarihi <= bitis_tarihi))
);

CREATE TABLE public.indirim_kuponu (
  kupon_id bigint NOT NULL,
  kod character varying(30) NOT NULL,
  indirim_yuzde integer NOT NULL,
  aktif_mi boolean DEFAULT true NOT NULL,
  son_kullanma_tarihi date,
  CONSTRAINT indirim_kuponu_indirim_yuzde_check CHECK (((indirim_yuzde >= 0) AND (indirim_yuzde <= 100)))
);

CREATE TABLE public.kiralama (
  kiralama_id bigint NOT NULL,
  musteri_id bigint NOT NULL,
  arac_id bigint NOT NULL,
  sube_id bigint NOT NULL,
  baslangic_tarihi date NOT NULL,
  bitis_tarihi date NOT NULL,
  durum character varying(15) DEFAULT 'aktif'::character varying NOT NULL,
  kupon_id bigint,
  toplam_tutar numeric(10,2) DEFAULT 0 NOT NULL,
  CONSTRAINT kiralama_check CHECK ((baslangic_tarihi <= bitis_tarihi)),
  CONSTRAINT kiralama_durum_check CHECK (((durum)::text = ANY ((ARRAY['aktif'::character varying, 'tamamlandi'::character varying, 'iptal'::character varying])::text[])))
);

CREATE TABLE public.odeme (
  odeme_id bigint NOT NULL,
  kiralama_id bigint NOT NULL,
  tutar numeric(10,2) NOT NULL,
  yontem character varying(15) NOT NULL,
  odeme_tarihi timestamp without time zone DEFAULT now() NOT NULL,
  durum character varying(15) DEFAULT 'odendi'::character varying NOT NULL,
  CONSTRAINT odeme_durum_check CHECK (((durum)::text = ANY ((ARRAY['odendi'::character varying, 'iptal'::character varying])::text[]))),
  CONSTRAINT odeme_tutar_check CHECK ((tutar >= (0)::numeric)),
  CONSTRAINT odeme_yontem_check CHECK (((yontem)::text = ANY ((ARRAY['nakit'::character varying, 'kart'::character varying, 'havale'::character varying])::text[])))
);

CREATE TABLE public.ek_hizmet (
  ek_hizmet_id bigint NOT NULL,
  ad character varying(60) NOT NULL,
  gunluk_fiyat numeric(10,2) NOT NULL,
  aktif_mi boolean DEFAULT true NOT NULL,
  CONSTRAINT ek_hizmet_gunluk_fiyat_check CHECK ((gunluk_fiyat >= (0)::numeric))
);

CREATE TABLE public.kiralama_ek_hizmet (
  kiralama_id bigint NOT NULL,
  ek_hizmet_id bigint NOT NULL,
  adet integer DEFAULT 1 NOT NULL,
  CONSTRAINT kiralama_ek_hizmet_adet_check CHECK ((adet >= 1))
);

CREATE TABLE public.kiralama_ek_surucu (
  kiralama_id bigint NOT NULL,
  kisi_id bigint NOT NULL,
  surucu_rolu character varying(30) DEFAULT 'ek_surucu'::character varying NOT NULL
);

CREATE TABLE public.degisiklik_kaydi (
  kayit_id bigint NOT NULL,
  tablo_adi character varying(60) NOT NULL,
  islem_turu character varying(15) NOT NULL,
  kayit_anahtari character varying(80) NOT NULL,
  degisiklik_tarihi timestamp without time zone DEFAULT now() NOT NULL,
  degistiren_kisi_id bigint,
  eski_veri jsonb,
  yeni_veri jsonb,
  CONSTRAINT degisiklik_kaydi_islem_turu_check CHECK (((islem_turu)::text = ANY ((ARRAY['ekleme'::character varying, 'guncelleme'::character varying, 'silme'::character varying])::text[])))
);

-- Identity (otomatik artan id) ayarları
ALTER TABLE public.sube ALTER COLUMN sube_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.sube_sube_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.kisi ALTER COLUMN kisi_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.kisi_kisi_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.arac ALTER COLUMN arac_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.arac_arac_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.arac_durum_gecmisi ALTER COLUMN gecmis_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.arac_durum_gecmisi_gecmis_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.bakim ALTER COLUMN bakim_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.bakim_bakim_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.indirim_kuponu ALTER COLUMN kupon_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.indirim_kuponu_kupon_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.kiralama ALTER COLUMN kiralama_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.kiralama_kiralama_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.odeme ALTER COLUMN odeme_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.odeme_odeme_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.ek_hizmet ALTER COLUMN ek_hizmet_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.ek_hizmet_ek_hizmet_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);
ALTER TABLE public.degisiklik_kaydi ALTER COLUMN kayit_id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.degisiklik_kaydi_kayit_id_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1);

-- Primary key, unique kısıtları
ALTER TABLE ONLY public.sube ADD CONSTRAINT sube_pkey PRIMARY KEY (sube_id);

ALTER TABLE ONLY public.kisi ADD CONSTRAINT kisi_pkey PRIMARY KEY (kisi_id);
ALTER TABLE ONLY public.kisi ADD CONSTRAINT kisi_eposta_key UNIQUE (eposta);

ALTER TABLE ONLY public.musteri ADD CONSTRAINT musteri_pkey PRIMARY KEY (kisi_id);
ALTER TABLE ONLY public.musteri ADD CONSTRAINT musteri_ehliyet_no_key UNIQUE (ehliyet_no);

ALTER TABLE ONLY public.calisan ADD CONSTRAINT calisan_pkey PRIMARY KEY (kisi_id);

ALTER TABLE ONLY public.arac ADD CONSTRAINT arac_pkey PRIMARY KEY (arac_id);
ALTER TABLE ONLY public.arac ADD CONSTRAINT arac_plaka_key UNIQUE (plaka);

ALTER TABLE ONLY public.otomobil ADD CONSTRAINT otomobil_pkey PRIMARY KEY (arac_id);
ALTER TABLE ONLY public.motosiklet ADD CONSTRAINT motosiklet_pkey PRIMARY KEY (arac_id);

ALTER TABLE ONLY public.arac_durum_gecmisi ADD CONSTRAINT arac_durum_gecmisi_pkey PRIMARY KEY (gecmis_id);

ALTER TABLE ONLY public.bakim ADD CONSTRAINT bakim_pkey PRIMARY KEY (bakim_id);

ALTER TABLE ONLY public.indirim_kuponu ADD CONSTRAINT indirim_kuponu_pkey PRIMARY KEY (kupon_id);
ALTER TABLE ONLY public.indirim_kuponu ADD CONSTRAINT indirim_kuponu_kod_key UNIQUE (kod);

ALTER TABLE ONLY public.kiralama ADD CONSTRAINT kiralama_pkey PRIMARY KEY (kiralama_id);

ALTER TABLE ONLY public.odeme ADD CONSTRAINT odeme_pkey PRIMARY KEY (odeme_id);
ALTER TABLE ONLY public.odeme ADD CONSTRAINT odeme_kiralama_id_key UNIQUE (kiralama_id);

ALTER TABLE ONLY public.ek_hizmet ADD CONSTRAINT ek_hizmet_pkey PRIMARY KEY (ek_hizmet_id);
ALTER TABLE ONLY public.ek_hizmet ADD CONSTRAINT ek_hizmet_ad_key UNIQUE (ad);

ALTER TABLE ONLY public.kiralama_ek_hizmet ADD CONSTRAINT kiralama_ek_hizmet_pkey PRIMARY KEY (kiralama_id, ek_hizmet_id);
ALTER TABLE ONLY public.kiralama_ek_surucu ADD CONSTRAINT kiralama_ek_surucu_pkey PRIMARY KEY (kiralama_id, kisi_id);

ALTER TABLE ONLY public.degisiklik_kaydi ADD CONSTRAINT degisiklik_kaydi_pkey PRIMARY KEY (kayit_id);

-- Indexler (hızlandırıcı)
CREATE INDEX idx_bakim_arac ON public.bakim USING btree (arac_id);
CREATE INDEX idx_durum_gecmisi_arac ON public.arac_durum_gecmisi USING btree (arac_id);
CREATE INDEX idx_kiralama_arac ON public.kiralama USING btree (arac_id);
CREATE INDEX idx_kiralama_musteri ON public.kiralama USING btree (musteri_id);

-- Foreign key ilişkileri (tablolar arası bağlar)
ALTER TABLE ONLY public.arac
  ADD CONSTRAINT arac_sube_id_fkey FOREIGN KEY (sube_id) REFERENCES public.sube(sube_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.musteri
  ADD CONSTRAINT musteri_kisi_id_fkey FOREIGN KEY (kisi_id) REFERENCES public.kisi(kisi_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.calisan
  ADD CONSTRAINT calisan_kisi_id_fkey FOREIGN KEY (kisi_id) REFERENCES public.kisi(kisi_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.calisan
  ADD CONSTRAINT calisan_sube_id_fkey FOREIGN KEY (sube_id) REFERENCES public.sube(sube_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.otomobil
  ADD CONSTRAINT otomobil_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.motosiklet
  ADD CONSTRAINT motosiklet_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.bakim
  ADD CONSTRAINT bakim_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.kiralama
  ADD CONSTRAINT kiralama_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.kiralama
  ADD CONSTRAINT kiralama_musteri_id_fkey FOREIGN KEY (musteri_id) REFERENCES public.musteri(kisi_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.kiralama
  ADD CONSTRAINT kiralama_sube_id_fkey FOREIGN KEY (sube_id) REFERENCES public.sube(sube_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.kiralama
  ADD CONSTRAINT kiralama_kupon_id_fkey FOREIGN KEY (kupon_id) REFERENCES public.indirim_kuponu(kupon_id) ON DELETE SET NULL;

ALTER TABLE ONLY public.odeme
  ADD CONSTRAINT odeme_kiralama_id_fkey FOREIGN KEY (kiralama_id) REFERENCES public.kiralama(kiralama_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.kiralama_ek_hizmet
  ADD CONSTRAINT kiralama_ek_hizmet_kiralama_id_fkey FOREIGN KEY (kiralama_id) REFERENCES public.kiralama(kiralama_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.kiralama_ek_hizmet
  ADD CONSTRAINT kiralama_ek_hizmet_ek_hizmet_id_fkey FOREIGN KEY (ek_hizmet_id) REFERENCES public.ek_hizmet(ek_hizmet_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.kiralama_ek_surucu
  ADD CONSTRAINT kiralama_ek_surucu_kiralama_id_fkey FOREIGN KEY (kiralama_id) REFERENCES public.kiralama(kiralama_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.kiralama_ek_surucu
  ADD CONSTRAINT kiralama_ek_surucu_kisi_id_fkey FOREIGN KEY (kisi_id) REFERENCES public.kisi(kisi_id) ON DELETE RESTRICT;

ALTER TABLE ONLY public.arac_durum_gecmisi
  ADD CONSTRAINT arac_durum_gecmisi_arac_id_fkey FOREIGN KEY (arac_id) REFERENCES public.arac(arac_id) ON DELETE CASCADE;

ALTER TABLE ONLY public.arac_durum_gecmisi
  ADD CONSTRAINT arac_durum_gecmisi_degistiren_calisan_id_fkey FOREIGN KEY (degistiren_calisan_id) REFERENCES public.calisan(kisi_id) ON DELETE SET NULL;
