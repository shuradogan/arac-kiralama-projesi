CREATE TRIGGER t1_kiralama_tarih_cakisma
BEFORE INSERT OR UPDATE ON public.kiralama
FOR EACH ROW
EXECUTE FUNCTION public.trg_kiralama_tarih_cakisma_kontrol();

CREATE TRIGGER t2_kiralama_bakim
BEFORE INSERT OR UPDATE ON public.kiralama
FOR EACH ROW
EXECUTE FUNCTION public.trg_kiralama_bakim_kontrol();

CREATE TRIGGER t3_kiralama_arac_durum
AFTER INSERT OR UPDATE OF durum ON public.kiralama
FOR EACH ROW
EXECUTE FUNCTION public.trg_kiralama_arac_durum_guncelle();

CREATE TRIGGER t4_kiralama_audit
AFTER INSERT OR DELETE OR UPDATE ON public.kiralama
FOR EACH ROW
EXECUTE FUNCTION public.trg_degisim_kaydi_yaz();
