import React, { useEffect, useMemo, useState } from "react";
import {
  SafeAreaView,
  Text,
  TextInput,
  Button,
  FlatList,
  View,
  Alert,
  Platform,
  Pressable,
  ActivityIndicator,
} from "react-native";

const API =
  Platform.OS === "web"
    ? "http://localhost:3000"
    : "http://10.0.2.2:3000";

/* -------------------- DATE HELPERS -------------------- */

// GG-AA-YYYY -> YYYY-AA-GG (API için)
const toApiDate = (ddmmyyyy) => {
  const s = String(ddmmyyyy || "").trim();
  if (!s) return "";
  const parts = s.includes("-") ? s.split("-") : s.split("/");
  if (parts.length !== 3) return s;
  const [dd, mm, yyyy] = parts;
  if (!dd || !mm || !yyyy) return s;
  return `${yyyy}-${mm}-${dd}`;
};

// YYYY-AA-GG -> GG-AA-YYYY (ekranda göstermek için)
const toTrDate = (yyyymmdd) => {
  const s = String(yyyymmdd || "").trim();
  if (!s) return "";
  const core = s.length >= 10 ? s.slice(0, 10) : s;
  const parts = core.split("-");
  if (parts.length !== 3) return s;
  const [yyyy, mm, dd] = parts;
  if (!dd || !mm || !yyyy) return s;
  return `${dd}-${mm}-${yyyy}`;
};

// Tarih inputu için otomatik GG-AA-YYYY formatı
const formatDateInput = (text) => {
  const digits = String(text || "").replace(/\D/g, "").slice(0, 8);
  if (digits.length <= 2) return digits;
  if (digits.length <= 4) return `${digits.slice(0, 2)}-${digits.slice(2)}`;
  return `${digits.slice(0, 2)}-${digits.slice(2, 4)}-${digits.slice(4)}`;
};

const isLeapYear = (y) => (y % 4 === 0 && y % 100 !== 0) || (y % 400 === 0);

const validateTrDate = (ddmmyyyy) => {
  const s = String(ddmmyyyy || "").trim();
  if (!s) return { ok: false, msg: "Tarih boş olamaz." };

  const parts = s.split("-");
  if (parts.length !== 3) return { ok: false, msg: "Tarih formatı GG-AA-YYYY olmalı." };

  const [ddS, mmS, yyS] = parts;

  if (ddS.length !== 2 || mmS.length !== 2 || yyS.length !== 4) {
    return { ok: false, msg: "Tarih formatı GG-AA-YYYY olmalı (ör: 05-01-2026)." };
  }

  if (!/^\d+$/.test(ddS + mmS + yyS)) {
    return { ok: false, msg: "Tarih sadece rakam içermeli." };
  }

  const dd = Number(ddS);
  const mm = Number(mmS);
  const yy = Number(yyS);


  
  // sunum için makul aralık (istersen genişlet)
  if (yy < 1900 || yy > 2100) return { ok: false, msg: "Yıl 1900 ile 2100 arasında olmalı." };
  if (mm < 1 || mm > 12) return { ok: false, msg: "Ay 01 ile 12 arasında olmalı." };

  const daysInMonth = [31, isLeapYear(yy) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  const maxDay = daysInMonth[mm - 1];

  if (dd < 1 || dd > maxDay) {
    return { ok: false, msg: `Gün 01 ile ${String(maxDay).padStart(2, "0")} arasında olmalı.` };
  }

  return { ok: true, msg: "" };
};

// kıyas için YYYYMMDD
const toComparable = (ddmmyyyy) => {
  const api = toApiDate(ddmmyyyy); // YYYY-AA-GG
  const core = api.slice(0, 10);
  return Number(core.replaceAll("-", ""));
};

/* -------------------- INPUT HELPERS -------------------- */

const onlyDigits = (t) => String(t || "").replace(/\D/g, "");

/* -------------------- UI HELPERS -------------------- */

function Section({ title, subtitle, children }) {
  return (
    <View
      style={{
        gap: 10,
        padding: 14,
        borderWidth: 1,
        borderColor: "#E5E7EB",
        borderRadius: 14,
        backgroundColor: "#FFFFFF",
      }}
    >
      <View style={{ gap: 2 }}>
        <Text style={{ fontSize: 15, fontWeight: "800" }}>{title}</Text>
        {subtitle ? <Text style={{ opacity: 0.7 }}>{subtitle}</Text> : null}
      </View>
      {children}
    </View>
  );
}

function Label({ children }) {
  return <Text style={{ fontWeight: "700", opacity: 0.8 }}>{children}</Text>;
}

function Field({ label, ...props }) {
  return (
    <View style={{ gap: 6 }}>
      {label ? <Label>{label}</Label> : null}
      <TextInput
        {...props}
        style={[
          {
            borderWidth: 1,
            borderColor: "#D1D5DB",
            paddingVertical: 10,
            paddingHorizontal: 12,
            borderRadius: 12,
            backgroundColor: "#FAFAFA",
          },
          props.style,
        ]}
      />
    </View>
  );
}

function PrimaryButton({ title, onPress, loading }) {
  return (
    <Pressable
      onPress={loading ? null : onPress}
      style={{
        borderRadius: 12,
        paddingVertical: 12,
        paddingHorizontal: 14,
        backgroundColor: loading ? "#9CA3AF" : "#111827",
        alignItems: "center",
        justifyContent: "center",
      }}
    >
      {loading ? (
        <View style={{ flexDirection: "row", gap: 10, alignItems: "center" }}>
          <ActivityIndicator />
          <Text style={{ color: "white", fontWeight: "800" }}>İşleniyor…</Text>
        </View>
      ) : (
        <Text style={{ color: "white", fontWeight: "800" }}>{title}</Text>
      )}
    </Pressable>
  );
}

function Divider() {
  return <View style={{ height: 1, backgroundColor: "#E5E7EB" }} />;
}

/* -------------------- MAIN -------------------- */

export default function Index() {
  // ARAMA
  const [subeId, setSubeId] = useState("");
  const [baslangic, setBaslangic] = useState(""); // GG-AA-YYYY
  const [bitis, setBitis] = useState(""); // GG-AA-YYYY
  const [uygunAraclar, setUygunAraclar] = useState([]);

  // EKLEME
  const [musteriId, setMusteriId] = useState("");
  const [aracId, setAracId] = useState("");
  const [kuponKod, setKuponKod] = useState("");

  // SİLME
  const [silKiralamaId, setSilKiralamaId] = useState("");

  // GÜNCELLEME
  const [guncelleAracId, setGuncelleAracId] = useState("");
  const [yeniFiyat, setYeniFiyat] = useState("");

  // LİSTE
  const [kiralamalar, setKiralamalar] = useState([]);

  // Loading states (mantık hatası: çift istek önleme)
  const [loadingAra, setLoadingAra] = useState(false);
  const [loadingEkle, setLoadingEkle] = useState(false);
  const [loadingSil, setLoadingSil] = useState(false);
  const [loadingGuncelle, setLoadingGuncelle] = useState(false);
  const [loadingListe, setLoadingListe] = useState(false);

  const rangeCheckMsg = useMemo(() => {
    // sadece ikisi de dolu ve ikisi de valid ise aralık mesajı üret
    if (!baslangic.trim() || !bitis.trim()) return "";
    const v1 = validateTrDate(baslangic);
    const v2 = validateTrDate(bitis);
    if (!v1.ok || !v2.ok) return "";
    if (toComparable(baslangic) > toComparable(bitis)) return "Bitiş, başlangıçtan önce olamaz.";
    return "";
  }, [baslangic, bitis]);

  const validateRangeOrAlert = () => {
    const v1 = validateTrDate(baslangic);
    if (!v1.ok) {
      Alert.alert("Geçersiz tarih", `Başlangıç: ${v1.msg}`);
      return false;
    }

    const v2 = validateTrDate(bitis);
    if (!v2.ok) {
      Alert.alert("Geçersiz tarih", `Bitiş: ${v2.msg}`);
      return false;
    }

    if (toComparable(baslangic) > toComparable(bitis)) {
      Alert.alert("Geçersiz tarih aralığı", "Bitiş tarihi, başlangıç tarihinden önce olamaz.");
      return false;
    }

    return true;
  };

  const kiralamaListele = async (showAlert = false) => {
    if (loadingListe) return;
    setLoadingListe(true);
    try {
      const r = await fetch(`${API}/kiralamalar`);
      const data = await r.json();
      if (data?.hata) return Alert.alert("Hata", data.hata);

      setKiralamalar(Array.isArray(data) ? data : []);
      if (showAlert) Alert.alert("Tamam", "Kiralama listesi yenilendi.");
    } catch (e) {
      Alert.alert("Bağlantı hatası", String(e));
    } finally {
      setLoadingListe(false);
    }
  };

  useEffect(() => {
    kiralamaListele(false);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const uygunAra = async () => {
    if (loadingAra) return;
    try {
      if (!subeId.trim() || !baslangic.trim() || !bitis.trim()) {
        return Alert.alert("Uyarı", "Şube ID, başlangıç ve bitiş tarihini gir.");
      }
      if (!validateRangeOrAlert()) return;

      setLoadingAra(true);

      const url = `${API}/araclar/uygun?sube_id=${encodeURIComponent(
        subeId
      )}&baslangic=${encodeURIComponent(toApiDate(baslangic))}&bitis=${encodeURIComponent(
        toApiDate(bitis)
      )}`;

      const r = await fetch(url);
      const data = await r.json();
      if (data?.hata) return Alert.alert("Hata", data.hata);

      const list = Array.isArray(data) ? data : [];
      setUygunAraclar(list);

      Alert.alert("Arama tamam", list.length === 0 ? "Uygun araç bulunamadı." : `${list.length} araç bulundu.`);
    } catch (e) {
      Alert.alert("Bağlantı hatası", String(e));
    } finally {
      setLoadingAra(false);
    }
  };

  const kiralamaOlustur = async () => {
    if (loadingEkle) return;
    try {
      if (!musteriId.trim() || !aracId.trim() || !subeId.trim() || !baslangic.trim() || !bitis.trim()) {
        return Alert.alert("Uyarı", "Müşteri ID, Araç ID, Şube ID ve tarihleri doldur.");
      }
      if (!validateRangeOrAlert()) return;

      setLoadingEkle(true);

      const r = await fetch(`${API}/kiralama`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          musteri_id: Number(musteriId),
          arac_id: Number(aracId),
          sube_id: Number(subeId),
          baslangic: toApiDate(baslangic),
          bitis: toApiDate(bitis),
          kupon_kod: kuponKod?.trim() ? kuponKod.trim() : null,
        }),
      });

      const data = await r.json();
      if (data?.hata) return Alert.alert("Hata", data.hata);

      Alert.alert("Eklendi", `Kiralama oluşturuldu. ID: ${data.kiralama_id}`);

      // küçük UX: kuponu temizle (ID alanlarını istersen temizletmem)
      setKuponKod("");

      kiralamaListele(false);
    } catch (e) {
      Alert.alert("Bağlantı hatası", String(e));
    } finally {
      setLoadingEkle(false);
    }
  };

  const kiralamaIptal = async () => {
    if (loadingSil) return;
    try {
      const id = silKiralamaId.trim();
      if (!id) return Alert.alert("Uyarı", "Kiralama ID gir.");

      setLoadingSil(true);

      const r = await fetch(`${API}/kiralama/${encodeURIComponent(id)}`, { method: "DELETE" });
      const data = await r.json();
      if (data?.hata) return Alert.alert("Hata", data.hata);

      Alert.alert("Silindi", data.mesaj || "Kiralama iptal edildi.");
      setSilKiralamaId("");
      kiralamaListele(false);
    } catch (e) {
      Alert.alert("Bağlantı hatası", String(e));
    } finally {
      setLoadingSil(false);
    }
  };

  const aracFiyatGuncelle = async () => {
    if (loadingGuncelle) return;
    try {
      const id = guncelleAracId.trim();
      if (!id) return Alert.alert("Uyarı", "Araç ID gir.");
      if (!yeniFiyat.trim()) return Alert.alert("Uyarı", "Yeni fiyat gir.");

      setLoadingGuncelle(true);

      const r = await fetch(`${API}/arac/${encodeURIComponent(id)}/fiyat`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ gunluk_ucret: Number(yeniFiyat) }),
      });

      const data = await r.json();
      if (data?.hata) return Alert.alert("Hata", data.hata);

      Alert.alert("Güncellendi", data.mesaj || "Araç fiyatı güncellendi.");
    } catch (e) {
      Alert.alert("Bağlantı hatası", String(e));
    } finally {
      setLoadingGuncelle(false);
    }
  };

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: "#F3F4F6" }}>
      <FlatList
        data={kiralamalar}
        keyExtractor={(i) => String(i.kiralama_id)}
        ListHeaderComponent={
          <View style={{ padding: 14, gap: 14 }}>
            <View style={{ gap: 4 }}>
              <Text style={{ fontSize: 20, fontWeight: "900" }}>Araç Kiralama</Text>
              <Text style={{ opacity: 0.7 }}>
                Şube, tarih aralığına göre uygun araçları bul ve kiralama işlemleri yap.
              </Text>
            </View>

            {/* ARAMA */}
            <Section
              title="Arama"
              subtitle="Tarihleri GG-AA-YYYY formatında gir. (Örn: 05-01-2026)"
            >
              <Field
                label="Şube ID"
                value={subeId}
                onChangeText={(t) => setSubeId(onlyDigits(t))}
                placeholder="örn: 1"
                keyboardType="numeric"
              />

              <View style={{ flexDirection: "row", gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <Field
                    label="Başlangıç"
                    value={baslangic}
                    onChangeText={(t) => setBaslangic(formatDateInput(t))}
                    onBlur={() => {
                      if (!baslangic.trim()) return;
                      const v = validateTrDate(baslangic);
                      if (!v.ok) Alert.alert("Geçersiz tarih", `Başlangıç: ${v.msg}`);
                      // Aralık kontrolü (iki tarih de validse)
                      if (bitis.trim()) {
                        const vb = validateTrDate(bitis);
                        if (v.ok && vb.ok && toComparable(baslangic) > toComparable(bitis)) {
                          Alert.alert("Geçersiz tarih aralığı", "Bitiş tarihi, başlangıç tarihinden önce olamaz.");
                        }
                      }
                    }}
                    placeholder="GG-AA-YYYY"
                    keyboardType="numeric"
                  />
                </View>

                <View style={{ flex: 1 }}>
                  <Field
                    label="Bitiş"
                    value={bitis}
                    onChangeText={(t) => setBitis(formatDateInput(t))}
                    onBlur={() => {
                      if (!bitis.trim()) return;
                      const v = validateTrDate(bitis);
                      if (!v.ok) {
                        Alert.alert("Geçersiz tarih", `Bitiş: ${v.msg}`);
                        return;
                      }
                      if (baslangic.trim()) {
                        const vb = validateTrDate(baslangic);
                        if (vb.ok && toComparable(bitis) < toComparable(baslangic)) {
                          Alert.alert("Geçersiz tarih aralığı", "Bitiş tarihi, başlangıç tarihinden önce olamaz.");
                        }
                      }
                    }}
                    placeholder="GG-AA-YYYY"
                    keyboardType="numeric"
                  />
                </View>
              </View>

              {rangeCheckMsg ? <Text style={{ color: "#B91C1C", fontWeight: "700" }}>{rangeCheckMsg}</Text> : null}

              <PrimaryButton title="Uygun araçları ara" onPress={uygunAra} loading={loadingAra} />

              <Divider />

              <View style={{ gap: 8 }}>
                <Text style={{ fontWeight: "800" }}>Uygun Araçlar</Text>
                <Text style={{ fontWeight: "800", opacity: 0.75 }}>
                  AraçID | Plaka | Marka Model | Günlük Ücret
                </Text>

                {uygunAraclar.length === 0 ? (
                  <Text style={{ opacity: 0.7 }}>Sonuç yok.</Text>
                ) : (
                  uygunAraclar.map((a) => (
                    <Text key={String(a.arac_id)} style={{ paddingVertical: 2 }}>
                      {a.arac_id} | {a.plaka} | {a.marka} {a.model} | {a.gunluk_ucret}
                    </Text>
                  ))
                )}
              </View>
            </Section>

            {/* EKLEME */}
            <Section title="Ekleme" subtitle="Kiralama oluşturur (POST /kiralama).">
              <View style={{ flexDirection: "row", gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <Field
                    label="Müşteri ID"
                    value={musteriId}
                    onChangeText={(t) => setMusteriId(onlyDigits(t))}
                    placeholder="örn: 1"
                    keyboardType="numeric"
                  />
                </View>
                <View style={{ flex: 1 }}>
                  <Field
                    label="Araç ID"
                    value={aracId}
                    onChangeText={(t) => setAracId(onlyDigits(t))}
                    placeholder="örn: 5"
                    keyboardType="numeric"
                  />
                </View>
              </View>

              <Field
                label="Kupon (opsiyonel)"
                value={kuponKod}
                onChangeText={setKuponKod}
                placeholder="örn: INDIRIM10"
              />

              <PrimaryButton title="Kiralama oluştur" onPress={kiralamaOlustur} loading={loadingEkle} />
            </Section>

            {/* SİLME */}
            <Section title="Silme" subtitle="Kiralama iptal eder (DELETE /kiralama/:id).">
              <Field
                label="Kiralama ID"
                value={silKiralamaId}
                onChangeText={(t) => setSilKiralamaId(onlyDigits(t))}
                placeholder="örn: 12"
                keyboardType="numeric"
              />
              <PrimaryButton title="İptal et" onPress={kiralamaIptal} loading={loadingSil} />
            </Section>

            {/* GÜNCELLEME */}
            <Section title="Güncelleme" subtitle="Araç günlük ücretini günceller (PUT /arac/:id/fiyat).">
              <View style={{ flexDirection: "row", gap: 10 }}>
                <View style={{ flex: 1 }}>
                  <Field
                    label="Araç ID"
                    value={guncelleAracId}
                    onChangeText={(t) => setGuncelleAracId(onlyDigits(t))}
                    placeholder="örn: 3"
                    keyboardType="numeric"
                  />
                </View>
                <View style={{ flex: 1 }}>
                  <Field
                    label="Yeni günlük ücret"
                    value={yeniFiyat}
                    onChangeText={(t) => setYeniFiyat(onlyDigits(t))}
                    placeholder="örn: 1500"
                    keyboardType="numeric"
                  />
                </View>
              </View>

              <PrimaryButton title="Fiyatı güncelle" onPress={aracFiyatGuncelle} loading={loadingGuncelle} />
            </Section>

            {/* LİSTE BAŞLIĞI */}
            <Section title="Son Kiralamalar" subtitle="Listeyi yenileyip en güncel kayıtları gör.">
              <View style={{ gap: 10 }}>
                <PrimaryButton title="Yenile" onPress={() => kiralamaListele(true)} loading={loadingListe} />

                <Text style={{ fontWeight: "800", opacity: 0.75 }}>
                  KiralamaID | AraçID | Başlangıç - Bitiş | Durum | Tutar
                </Text>
              </View>
            </Section>
          </View>
        }
        renderItem={({ item }) => (
          <View style={{ paddingHorizontal: 14, paddingBottom: 10 }}>
            <View
              style={{
                backgroundColor: "white",
                borderWidth: 1,
                borderColor: "#E5E7EB",
                borderRadius: 14,
                padding: 12,
                gap: 6,
              }}
            >
              <Text style={{ fontWeight: "900" }}>
                #{item.kiralama_id} • Araç: {item.arac_id}
              </Text>

              <Text style={{ opacity: 0.85 }}>
                {toTrDate(item.baslangic_tarihi)} → {toTrDate(item.bitis_tarihi)}
              </Text>

              <Text style={{ opacity: 0.85 }}>
                Durum: {item.durum} • Tutar: {item.toplam_tutar}
              </Text>
            </View>
          </View>
        )}
        ListEmptyComponent={
          <Text style={{ paddingHorizontal: 14, paddingVertical: 10, opacity: 0.7 }}>
            Kiralama yok.
          </Text>
        }
      />
    </SafeAreaView>
  );
}
