const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({ mesaj: "API ayakta ✅" });
});


// PostgreSQL bağlantı
// Kendi bilgilerine göre düzenle:
const pool = new Pool({
  host: "localhost",
  port: 5432,
  user: "postgres",
  password: "bukalemun123",
  database: "Arac_Kiralama_DB",
});

// 1) ARAMA: uygun araçlar
app.get("/araclar/uygun", async (req, res) => {
  try {
    const { sube_id, baslangic, bitis } = req.query;
    const result = await pool.query(
      "SELECT * FROM fn_uygun_araclari_ara($1,$2,$3);",
      [sube_id, baslangic, bitis]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(400).json({ hata: err.message });
  }
});

// 2) EKLEME: kiralama oluştur
app.post("/kiralama", async (req, res) => {
  try {
    const { musteri_id, arac_id, sube_id, baslangic, bitis, kupon_kod } = req.body;
    const result = await pool.query(
      "SELECT fn_kiralama_olustur($1,$2,$3,$4,$5,$6) AS kiralama_id;",
      [musteri_id, arac_id, sube_id, baslangic, bitis, kupon_kod || null]
    );
    res.json({ kiralama_id: result.rows[0].kiralama_id });
  } catch (err) {
    res.status(400).json({ hata: err.message });
  }
});

// 3) SİLME: kiralama iptal (soft silme)
app.delete("/kiralama/:id", async (req, res) => {
  try {
    const id = req.params.id;
    await pool.query("SELECT fn_kiralama_iptal_et($1);", [id]);
    res.json({ mesaj: "Kiralama iptal edildi." });
  } catch (err) {
    res.status(400).json({ hata: err.message });
  }
});

// 4) GÜNCELLEME: araç fiyatını güncelle (basit CRUD)
app.put("/arac/:id/fiyat", async (req, res) => {
  try {
    const id = req.params.id;
    const { gunluk_ucret } = req.body;
    await pool.query("UPDATE arac SET gunluk_ucret=$1 WHERE arac_id=$2;", [gunluk_ucret, id]);
    res.json({ mesaj: "Güncellendi." });
  } catch (err) {
    res.status(400).json({ hata: err.message });
  }
});
// index.js dosyasına şu kodu ekle (satır 74'ten sonra):

app.get("/musteri/:id/gecmis", async (req, res) => {
  try {
    const musteri_id = req.params.id;
    const result = await pool.query(
      "SELECT * FROM fn_musteri_kiralama_gecmisi($1);",
      [musteri_id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(400).json({ hata: err.message });
  }
});

// Backend'i yeniden başlat: node index.js
// Ek: kiralamaları listelemek (ekran için kolaylık)
app.get("/kiralamalar", async (req, res) => {
  const r = await pool.query(
    `SELECT kiralama_id, musteri_id, arac_id, baslangic_tarihi, bitis_tarihi, durum, toplam_tutar
     FROM kiralama ORDER BY kiralama_id DESC LIMIT 50;`
  );
  res.json(r.rows);
});

app.listen(3000, () => console.log("API çalışıyor: http://localhost:3000"));
