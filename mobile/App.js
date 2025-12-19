import React, { useState, useEffect } from "react";
import { SafeAreaView, Text, TextInput, Button, FlatList, View, Alert, ScrollView } from "react-native";

const API = "http://10.49.74.178:3000"; // örn: http://192.168.1.50:3000

export default function App() {
  // ARAMA
  const [subeId, setSubeId] = useState("1");
  const [baslangic, setBaslangic] = useState("2025-06-01");
  const [bitis, setBitis] = useState("2025-06-05");
  const [uygunAraclar, setUygunAraclar] = useState([]);

  // EKLEME
  const [musteriId, setMusteriId] = useState("1");
  const [aracId, setAracId] = useState("1");
  const [kuponKod, setKuponKod] = useState("");

  // SİLME
  const [silKiralamaId, setSilKiralamaId] = useState("");

  // GÜNCELLEME
  const [guncelleAracId, setGuncelleAracId] = useState("1");
  const [yeniFiyat, setYeniFiyat] = useState("1500");

  // *** YENİ: MÜŞTERİ GEÇMİŞİ ***
  const [gecmisMusteriId, setGecmisMusteriId] = useState("1");
  const [musteriGecmisi, setMusteriGecmisi] = useState([]);

  // Liste
  const [kiralamalar, setKiralamalar] = useState([]);

  const kiralamaListele = async () => {
    const r = await fetch(`${API}/kiralamalar`);
    setKiralamalar(await r.json());
  };

  useEffect(() => {
    kiralamaListele();
  }, []);

  const uygunAra = async () => {
    const url = `${API}/araclar/uygun?sube_id=${subeId}&baslangic=${baslangic}&bitis=${bitis}`;
    const r = await fetch(url);
    const data = await r.json();
    if (data.hata) return Alert.alert("Hata", data.hata);
    setUygunAraclar(data);
  };

  const kiralamaOlustur = async () => {
    const r = await fetch(`${API}/kiralama`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        musteri_id: Number(musteriId),
        arac_id: Number(aracId),
        sube_id: Number(subeId),
        baslangic,
        bitis,
        kupon_kod: kuponKod || null,
      }),
    });
    const data = await r.json();
    if (data.hata) return Alert.alert("Hata", data.hata);
    Alert.alert("Başarılı", `Kiralama ID: ${data.kiralama_id}`);
    kiralamaListele();
  };

  const kiralamaIptal = async () => {
    const r = await fetch(`${API}/kiralama/${silKiralamaId}`, { method: "DELETE" });
    const data = await r.json();
    if (data.hata) return Alert.alert("Hata", data.hata);
    Alert.alert("Tamam", data.mesaj);
    kiralamaListele();
  };

  const aracFiyatGuncelle = async () => {
    const r = await fetch(`${API}/arac/${guncelleAracId}/fiyat`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ gunluk_ucret: Number(yeniFiyat) }),
    });
    const data = await r.json();
    if (data.hata) return Alert.alert("Hata", data.hata);
    Alert.alert("Tamam", data.mesaj);
  };

  // *** YENİ: MÜŞTERİ GEÇMİŞİ GÖRÜNTÜLE ***
  const musteriGecmisiGetir = async () => {
    const url = `${API}/musteri/${gecmisMusteriId}/gecmis`;
    const r = await fetch(url);
    const data = await r.json();
    if (data.hata) return Alert.alert("Hata", data.hata);
    setMusteriGecmisi(data);
  };

  return (
    <ScrollView style={{ flex: 1 }}>
      <SafeAreaView style={{ padding: 14, gap: 12 }}>
        <Text style={{ fontSize: 18, fontWeight: "700" }}>Araç Kiralama</Text>

        {/* ARAMA */}
        <View style={{ gap: 6, marginBottom: 16 }}>
          <Text style={{ fontWeight: "700" }}>Arama (uygun araç)</Text>
          <TextInput placeholder="Şube ID" value={subeId} onChangeText={setSubeId} style={{ borderWidth: 1, padding: 8 }} />
          <TextInput placeholder="Başlangıç (YYYY-AA-GG)" value={baslangic} onChangeText={setBaslangic} style={{ borderWidth: 1, padding: 8 }} />
          <TextInput placeholder="Bitiş (YYYY-AA-GG)" value={bitis} onChangeText={setBitis} style={{ borderWidth: 1, padding: 8 }} />
          <Button title="Uygun araçları ara" onPress={uygunAra} />
          <FlatList
            data={uygunAraclar}
            keyExtractor={(item) => String(item.arac_id)}
            renderItem={({ item }) => <Text>- {item.plaka} | {item.marka} {item.model} | {item.gunluk_ucret}</Text>}
          />
        </View>

        {/* EKLEME */}
        <View style={{ gap: 6, marginBottom: 16 }}>
          <Text style={{ fontWeight: "700" }}>Ekleme (kiralama oluştur)</Text>
          <TextInput placeholder="Müşteri ID" value={musteriId} onChangeText={setMusteriId} style={{ borderWidth: 1, padding: 8 }} />
          <TextInput placeholder="Araç ID" value={aracId} onChangeText={setAracId} style={{ borderWidth: 1, padding: 8 }} />
          <TextInput placeholder="Kupon Kodu (opsiyonel)" value={kuponKod} onChangeText={setKuponKod} style={{ borderWidth: 1, padding: 8 }} />
          <Button title="Kiralama oluştur" onPress={kiralamaOlustur} />
        </View>

        {/* SİLME */}
        <View style={{ gap: 6, marginBottom: 16 }}>
          <Text style={{ fontWeight: "700" }}>Silme (kiralama iptal)</Text>
          <TextInput placeholder="Kiralama ID" value={silKiralamaId} onChangeText={setSilKiralamaId} style={{ borderWidth: 1, padding: 8 }} />
          <Button title="İptal et" onPress={kiralamaIptal} />
        </View>

        {/* GÜNCELLEME */}
        <View style={{ gap: 6, marginBottom: 16 }}>
          <Text style={{ fontWeight: "700" }}>Güncelleme (araç fiyat)</Text>
          <TextInput placeholder="Araç ID" value={guncelleAracId} onChangeText={setGuncelleAracId} style={{ borderWidth: 1, padding: 8 }} />
          <TextInput placeholder="Yeni günlük ücret" value={yeniFiyat} onChangeText={setYeniFiyat} style={{ borderWidth: 1, padding: 8 }} />
          <Button title="Fiyatı güncelle" onPress={aracFiyatGuncelle} />
        </View>

        {/* *** YENİ: MÜŞTERİ GEÇMİŞİ *** */}
        <View style={{ gap: 6, marginBottom: 16, backgroundColor: '#f0f8ff', padding: 12, borderRadius: 8 }}>
          <Text style={{ fontWeight: "700", color: '#0066cc' }}>Müşteri Kiralama Geçmişi</Text>
          <TextInput 
            placeholder="Müşteri ID" 
            value={gecmisMusteriId} 
            onChangeText={setGecmisMusteriId} 
            style={{ borderWidth: 1, padding: 8, backgroundColor: 'white' }} 
          />
          <Button title="Geçmişi Görüntüle" onPress={musteriGecmisiGetir} color="#0066cc" />
          {musteriGecmisi.length > 0 && (
            <View style={{ marginTop: 8 }}>
              <Text style={{ fontWeight: "600", marginBottom: 4 }}>
                Toplam {musteriGecmisi.length} kiralama bulundu:
              </Text>
              <FlatList
                data={musteriGecmisi}
                keyExtractor={(item) => String(item.kiralama_id)}
                renderItem={({ item }) => (
                  <View style={{ 
                    padding: 8, 
                    marginVertical: 4, 
                    backgroundColor: 'white', 
                    borderRadius: 6,
                    borderLeftWidth: 3,
                    borderLeftColor: item.durum === 'aktif' ? '#22c55e' : item.durum === 'iptal' ? '#ef4444' : '#94a3b8'
                  }}>
                    <Text style={{ fontWeight: '600' }}>#{item.kiralama_id} - {item.arac_marka} {item.arac_model}</Text>
                    <Text>Plaka: {item.arac_plaka}</Text>
                    <Text>Tarih: {item.baslangic_tarihi} - {item.bitis_tarihi} ({item.gun_sayisi} gün)</Text>
                    <Text>Durum: {item.durum} | Tutar: {item.toplam_tutar} TL</Text>
                  </View>
                )}
              />
            </View>
          )}
        </View>

        <View style={{ gap: 6, marginBottom: 16 }}>
          <Text style={{ fontWeight: "700" }}>Son Kiralamalar</Text>
          <Button title="Yenile" onPress={kiralamaListele} />
          <FlatList
            data={kiralamalar}
            keyExtractor={(item) => String(item.kiralama_id)}
            renderItem={({ item }) => (
              <Text>
                #{item.kiralama_id} | arac:{item.arac_id} | {item.baslangic_tarihi} - {item.bitis_tarihi} | {item.durum} | {item.toplam_tutar}
              </Text>
            )}
          />
        </View>
      </SafeAreaView>
    </ScrollView>
  );
}