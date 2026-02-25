# ZenScreen - Detayli Proje Spesifikasyonu

> **Tarih:** 25 Subat 2026
> **Platform:** iOS + Android (Flutter)
> **Hedef:** App Store + Google Play Store
> **Temel:** 6 rakip analizi + 4 konseptten 1. konsept (ZenScreen)

---

## 1. Urun Tanimi

**ZenScreen** -- "Telefonunu bilincli kullan, hayatini geri al."

Mindful friction (bilincli surtunme) yaklasimini temel alan, yetiskinlere yonelik ekran suresi kontrol uygulamasi. Sert engelleme yerine "dur ve dusun" felsefesini benimser. ScreenZen'in surtunme yaklasimi + Opal'in analitik derinligi + ClearSpace'in nefes egzersizi tek uygulamada.

### Hedef Kullanici
- 25-45 yas arasi yetiskinler
- Ekran bagimliliginin farkinda olan profesyoneller
- "Doomscrolling" sorunu yasayan genel kullanicilar
- Irade gucuyle basa cikamayan, yardimci araca ihtiyac duyanlar

### Rekabetci Konum
- ScreenZen'den daha derin (niyet gunlugu + analitik)
- Opal'den daha uygun fiyatli ($44.99/yil vs $99.99/yil)
- ClearSpace'den daha kapsamli (surtunme + analitik + sosyal)

---

## 2. Teknik Altyapi

### Stack
- **Framework:** Flutter 3.x (iOS + Android)
- **State Management:** Riverpod 3.x
- **Navigation:** GoRouter
- **Local Storage:** SharedPreferences + SQLite (sqflite)
- **Architecture:** Feature-first folder structure
- **Theme:** Dark mode (koyu tema, premium his)
- **Fonts:** Inter (body) + JetBrains Mono (metrikler/sayilar)

### Platform Gereksinimleri
- iOS 15+ (Screen Time API, WidgetKit)
- Android 10+ (Digital Wellbeing API, Usage Stats)
- Flutter minimum SDK: 3.22+

### Onemli Teknik Notlar
- Screen Time API (iOS) ve UsageStats API (Android) icin platform-specific implementasyon gerekli
- Method Channel ile native kod koprusu kurulacak
- Uygulama engelleme icin Accessibility Service (Android) / Screen Time API (iOS)
- Arka plan calismasi icin WorkManager (Android) / Background Tasks (iOS)

---

## 3. MVP Ozellikleri (v1.0)

### 3.1 Onboarding (7 adim)

| Adim | Ekran | Aciklama |
|------|-------|----------|
| 1 | Karsilama | App logo + "Telefonunu bilincli kullan" mesaji + 3 slide tanitim |
| 2 | Sok Istatistik | "Ortalama bir kisi gunde 96 kez telefonuna bakar. Sen?" motivasyon |
| 3 | Hedef Secimi | "Amacin ne?" -- Ekran suresini azalt / Bilincli kullanim / Uyku duzeni |
| 4 | Uygulama Secimi | Engellenecek uygulamalari sec (kategoriler: Sosyal, Video, Oyun, Haber) |
| 5 | Surtunme Tercihi | Hangi surtunme turunu tercih ediyorsun? (Bekleme / Nefes / Soru) |
| 6 | Izin Priming | Neden izin gerektigini aciklayan ekran (ClearSpace modeli) |
| 7 | Hazir! | "Harika, ZenScreen aktif!" + ilk ipuclari |

### 3.2 Akilli Surtunme Motoru (Core Ozellik)

Kullanici engelli bir uygulamayi actiginda devreye giren 3 surtunme turu:

#### a) Bekleme Zamanlayicisi
- Ilk acilista 5 saniye bekleme
- Her ardisik acilista +5 saniye artis (5s → 10s → 15s → 20s → max 30s)
- "Gercekten ihtiyacin var mi?" sorusu
- Geri sayim animasyonu + "Vazgec" ve "Yine de Ac" butonlari

#### b) Nefes Egzersizi
- 15 saniyelik nefes al/ver dongusu
- Animasyonlu nefes gorseli (genisleyen/daralan daire)
- Sakinlestirici alintilar ("Bu an gecici, nefesini al")
- Tamamlaninca "Devam Et" veya "Vazgec" secenegi

#### c) Niyet Sorusu
- "Bu uygulamayi neden aciyorsun?" sorusu
- 4 secenek: Is/Iletisim, Sosyallesmek, Can Sikilmasi, Sadece Bakacagim
- Secim kaydedilir (niyet gunlugu verisi)
- Secimden sonra "Devam Et" veya "Aslinda gerek yok" secenegi

**Surtunme Kuralları:**
- Kullanici onboarding'de tercih eder, sonra Settings'den degistirebilir
- Her uygulama grubu icin farkli surtunme turu atanabilir
- Gunluk ilk 3 acilista surtunme yok (grace period), 4. acilistan itibaren aktif

### 3.3 Temel Uygulama Engelleme

#### Zaman Bazli Engelleme
- Baslangic/bitis saati belirleme (orn. 22:00-07:00 gece modu)
- Haftanin gunlerine gore farkli kurallar
- Profiller: Calisma, Gece, Hafta Sonu (3 preset + ozel)

#### Sure Bazli Limitler
- Uygulama/grup basi gunluk sure limiti (orn. Instagram 30dk/gun)
- Limit yaklastiginda uyari (5dk kala bildirim)
- Limit dolunca engelleme ekrani

#### Uygulama Gruplari
- Hazir kategoriler: Sosyal Medya, Video, Oyunlar, Haberler
- Ozel grup olusturma
- Grup bazinda toplu kural atama

### 3.4 Niyet Gunlugu

- Her surtunme aninda kaydedilen "neden aciyorsun?" verileri
- Gunluk/haftalik ozet: "Bu hafta Instagram'i en cok 'can sikilmasi' icin actin (%65)"
- Pasta grafik ile niyet dagilimi gorsellestirmesi
- Trend analizi: "Gecen haftaya gore 'can sikilmasi' acmalar %15 azaldi"

### 3.5 Dijital Saglik Puani

0-100 arasi gunluk puan, su metriklere gore hesaplanir:
- Toplam ekran suresi (hedefin altinda = yuksek puan)
- Uygulama acma sikligi (az acma = yuksek puan)
- Gece kullanimi (gece yok = bonus puan)
- Surtunmede vazgecme orani (cok vazgecme = bonus puan)
- Engelleme bypass sayisi (az bypass = yuksek puan)

Gorsel: Buyuk dairesel progress bar + puan + emoji (😊 80+, 😐 50-79, 😟 <50)

### 3.6 Strict Mode

- Belirli saatlerde geri donusu olmayan tam engelleme
- Baslatmadan once "Bu mod iptal edilemez!" uyarisi
- Aktif oldugunda engelli uygulamalar kesinlikle acilamaz
- Overlay ile "Strict Mode aktif. Kalan: 2s 14dk" mesaji
- Acil durum icin: 60 saniyelik bekleme + "GERCEKTEN acil mi?" onay

### 3.7 Haftalik Rapor

Her Pazartesi push bildirim ile gelen haftalik ozet:
- Toplam ekran suresi (gecen haftaya karsilastirma)
- En cok kullanilan 5 uygulama
- Dijital Saglik Puani ortalamasi + trend
- Niyet dagilimi ozeti
- Surtunmede kac kez vazgecildi
- Motivasyonel mesaj + bir sonraki hafta icin ipucu

### 3.8 Ayarlar

- Genel: Tema (dark/light - varsayilan dark), bildirimler, dil
- Surtunme: Tur secimi, grace period ayari, artan zorluk on/off
- Engelleme: Uygulama/grup yonetimi, zaman profilleri
- Strict Mode: Programlama, acil durum bypass
- Veri: Export (CSV), sifirla, hesap sil
- Hakkinda: Versiyon, gizlilik politikasi, destek

---

## 4. Ekran Listesi (MVP)

| # | Ekran | Tur | Aciklama |
|---|-------|-----|----------|
| 1 | Splash | Tam ekran | Logo + yukleme |
| 2 | Onboarding (7 sayfa) | PageView | Karsilama, istatistik, hedef, uygulama secimi, surtunme, izin, hazir |
| 3 | Ana Sayfa (Dashboard) | Tab ana | Gunluk puan, bugunun ozeti, hizli aksiyonlar |
| 4 | Istatistikler | Tab | Gunluk/haftalik/aylik grafikler, niyet gunlugu |
| 5 | Engelleme Yonetimi | Tab | Uygulama listesi, gruplar, kurallar |
| 6 | Profiller | Ekran | Calisma/Gece/Hafta Sonu profil yonetimi |
| 7 | Strict Mode | Ekran | Strict Mode baslatma/programlama |
| 8 | Surtunme Overlay - Bekleme | Overlay | Geri sayim + soru |
| 9 | Surtunme Overlay - Nefes | Overlay | Nefes animasyonu |
| 10 | Surtunme Overlay - Niyet | Overlay | 4 secenekli niyet sorusu |
| 11 | Engelleme Overlay | Overlay | "Bu uygulama engellendi" ekrani |
| 12 | Haftalik Rapor | Tam ekran | Detayli haftalik ozet |
| 13 | Ayarlar | Ekran | Tum ayarlar |
| 14 | Paywall | Modal | Premium tanitim + satin alma |

---

## 5. Navigasyon Yapisi

```
BottomNavigationBar (3 tab):
├── Dashboard (Ana Sayfa)
│   ├── → Haftalik Rapor
│   └── → Strict Mode
├── Istatistikler
│   ├── → Niyet Gunlugu Detay
│   └── → Uygulama Bazli Detay
└── Ayarlar
    ├── → Engelleme Yonetimi
    │   ├── → Uygulama Secimi
    │   └── → Grup Olusturma
    ├── → Profiller
    ├── → Surtunme Ayarlari
    ├── → Strict Mode Programlama
    └── → Paywall

Overlay'ler (uygulama ustu):
├── Surtunme: Bekleme / Nefes / Niyet
└── Engelleme: Tam engel ekrani
```

---

## 6. Veri Modeli

### AppGroup
```dart
class AppGroup {
  String id;
  String name;
  String icon;
  List<String> appPackageNames;
  FrictionType frictionType; // wait, breath, intention
  int dailyLimitMinutes;
  bool isStrictModeEnabled;
}
```

### DailyStats
```dart
class DailyStats {
  DateTime date;
  int totalScreenTimeMinutes;
  int appOpenCount;
  int frictionShownCount;
  int frictionDismissedCount; // vazgecme
  int frictionBypassedCount; // yine de acma
  int healthScore; // 0-100
  Map<String, int> appUsageMinutes; // app -> dakika
  Map<IntentionType, int> intentionCounts; // niyet dagilimi
}
```

### IntentionLog
```dart
class IntentionLog {
  DateTime timestamp;
  String appPackageName;
  IntentionType intention; // work, social, boredom, justChecking
  bool didProceed; // acti mi vazgecti mi
  int sessionDurationSeconds;
}
```

### UserProfile
```dart
class UserProfile {
  String id;
  String? name;
  int dailyScreenTimeGoalMinutes;
  FrictionType preferredFriction;
  bool isOnboardingComplete;
  bool isPremium;
  DateTime? premiumExpiryDate;
  List<TimeProfile> timeProfiles;
}
```

### TimeProfile
```dart
class TimeProfile {
  String id;
  String name; // "Calisma", "Gece", "Hafta Sonu"
  TimeOfDay startTime;
  TimeOfDay endTime;
  List<int> activeDays; // 1=Pzt, 7=Pzr
  List<String> blockedGroupIds;
  bool isStrictMode;
}
```

---

## 7. Tasarim Dili

### Tema: "Mindful Dark"
- **Arka plan:** #0D0D0F (neredeyse siyah)
- **Yuzey (Surface):** #1A1A1F (koyu gri)
- **Kart:** #242429 (orta koyu gri)
- **Birincil renk:** #6C63FF (mor-mavi, sakinlestirici)
- **Ikincil renk:** #00D9A3 (neon yesil, basari/pozitif)
- **Uyari:** #FF6B6B (yumusak kirmizi)
- **Metin birincil:** #FFFFFF
- **Metin ikincil:** #9898A0
- **Metin ipucu:** #5A5A65

### Tipografi
- **Basliklar:** Inter Bold/SemiBold
- **Govde:** Inter Regular/Medium
- **Metrikler/Sayilar:** JetBrains Mono Medium
- **Boyutlar:** 12/14/16/20/24/32/40

### UI Prensipleri
- Yuvarlatilmis koseler (16-24px border radius)
- Subtle gradient arka planlar
- Glassmorphism efektleri (surtunme overlay'lerde)
- Smooth animasyonlar (300-500ms)
- Haptic geri bildirim (surtunme anlarinda)
- Minimalist ikonografi (outlined style)
- Yatay kaydirma kartlari (dashboard'da)

---

## 8. Monetizasyon

### Ucretsiz Katman
- 5 uygulama engelleme
- Temel surtunme (bekleme zamanlayicisi)
- Niyet gunlugu (son 7 gun)
- Basit Dijital Saglik Puani
- Haftalik rapor (ozet)

### Premium ($44.99/yil, $3.75/ay)
- Sinirsiz uygulama engelleme
- Tum surtunme turleri (nefes + niyet + bekleme)
- Strict Mode
- Detayli Dijital Saglik Puani + trend
- Niyet gunlugu (sinirsiz gecmis)
- Detayli haftalik rapor + CSV export
- Zaman profilleri (3+ profil)
- Oncelikli destek

### Paywall Tetikleyicileri (Feature-Gated)
- 6. uygulamayi eklemek istediginde
- Nefes egzersizi veya niyet sorusunu secmek istediginde
- Strict Mode'u baslatmak istediginde
- 2. zaman profilini eklemek istediginde

### Trial
- 7 gun ucretsiz premium deneme
- Onboarding sonrasi veya ilk paywall tetikleyicisinde sunulur

---

## 9. Proje Fazlari

### Faz 1: Proje Altyapisi
- Flutter projesi olusturma
- Klasor yapisi, tema, navigasyon
- Riverpod 3.x altyapisi
- Temel modeller ve veritabani

### Faz 2: Onboarding
- 7 adimlik onboarding akisi
- Animasyonlar ve gecisler
- Tercih kaydetme

### Faz 3: Dashboard + Istatistikler
- Ana sayfa tasarimi
- Dijital Saglik Puani hesaplama + gorsellestirme
- Gunluk/haftalik istatistik grafikleri
- Niyet gunlugu ekrani

### Faz 4: Engelleme Motoru
- Uygulama/grup yonetimi UI
- Zaman/sure bazli engelleme mantigi
- Platform-specific engelleme (Method Channel)
- Engelleme overlay'i

### Faz 5: Surtunme Motoru
- 3 surtunme turu overlay'leri (bekleme, nefes, niyet)
- Artan zorluk mekanizmasi
- Grace period mantigi
- Niyet kaydetme

### Faz 6: Strict Mode + Profiller
- Strict Mode UI + mantigi
- Zaman profilleri (Calisma/Gece/Hafta Sonu)
- Profil programlama
- Acil durum bypass

### Faz 7: Haftalik Rapor + Bildirimler
- Haftalik rapor olusturma + UI
- Push bildirimler
- Paywall implementasyonu
- In-app purchase entegrasyonu

### Faz 8: Platform Entegrasyonu + Polish
- iOS Screen Time API entegrasyonu
- Android UsageStats/Accessibility entegrasyonu
- Widget (iOS/Android)
- Test, bug fix, performans optimizasyonu
- Store hazırlıkları (screenshots, listing text)

---

## 10. V2 Yol Haritasi (Post-MVP)

- Adaptif surtunme (AI tabanli otomatik seviye ayari)
- GitHub-tarzi heatmap (uzun vadeli gorsel)
- Hesap verebilirlik ortagi (arkadas davet + bildirim)
- Apple Watch widget
- Chrome extension (web engelleme)
- Konum bazli profiller (GPS geofencing)
- Before/After grafikleri
- Paylasilabilir gorsel kartlar (sosyal medya)
- Ayarlar kilidi (PIN korumasi)

---

## 11. Teknik Riskler ve Cozumler

| Risk | Etki | Cozum |
|------|------|-------|
| iOS Screen Time API kisitlamalari | Engelleme gucunu sinirlar | Family Controls framework + MDM profili arastir |
| Android Accessibility Service Play Store red riski | Uygulama yayinlanamaz | Google'in accessibility policy'sine uygun deklarasyon hazirla |
| Arka plan sureci sonlandirilmasi | Engelleme/izleme durur | Foreground service (Android) + Background App Refresh (iOS) |
| Pil tuketimi sikayetleri | Kullanici memnuniyetsizligi | Optimum polling araliklarini test et, batch processing |
| RevenueCat/StoreKit 2 entegrasyon karmasikligi | Odeme sorunlari | RevenueCat SDK kullan, test ortaminda kapsamli test |

---

> **Not:** Bu spec, 01_product_analysis.md, 02_ux_ui_analysis.md, 03_monetization_synthesis.md ve 04_app_concepts.md dosyalarindan sentezlenmistir. MVP kapsami minimumda tutulmus, V2 ozellikleri ayrilmistir.
