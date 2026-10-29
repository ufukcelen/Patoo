<p align="center">
  <img src="Patoo.png" alt="Patoo Logo" width="180" />
</p>

<h1 align="center">Patoo — macOS Medya İşleme ve Otomasyon Uygulaması</h1>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14.0%2B-blue" alt="macOS 14.0+" />
  <img src="https://img.shields.io/badge/Swift-5.0%20%2F%206.0-orange" alt="Swift 6" />
  <img src="https://img.shields.io/badge/SwiftUI-Dark%20HUD-cyan" alt="SwiftUI" />
  <img src="https://img.shields.io/badge/Engine-FFmpeg%20%2F%20FFprobe-green" alt="FFmpeg" />
  <img src="https://img.shields.io/badge/Version-v0.0.1-purple" alt="Version v0.0.1" />
</p>

**Patoo**, karmaşık FFmpeg komut satırı argümanlarına gerek kalmadan, video ve ses dosyalarını profesyonel, hızlı ve güvenilir bir görsel kontrol merkezi üzerinden dönüştürmenizi, sıkıştırmanızı ve işlemenizi sağlayan yerel bir macOS masaüstü uygulamasıdır.

Adını geniş gözleriyle gece avlanan keskin bakışlı **Potoo** kuşundan alan uygulama; koyu lacivert tonları, elektrik mavisi/cyan ve neon mor vurguları, teknik HUD göstergeleri ve Apple Silicon donanım hızlandırma desteği ile modern macOS geliştiricileri ve video üreticileri için tasarlanmıştır.

---

## 🌟 Öne Çıkan Özellikler

### 1. 🔍 Medya Analizi (FFprobe Entegrasyonu)
- Video veya ses dosyasını sürükleyip bırakarak veya dosya seçiciyle anında içe aktarın.
- **FFprobe** ile mikro saniye düzeyinde süre, dosya boyutu, konteyner formatı, video kodeki, çözünürlük, kare hızı (FPS), piksel formatı, ses kodeki, kanal sayısı ve örnekleme hızını okuyup teknik HUD kartlarında gösterir.
- Hatalı veya desteklenmeyen formatları çökmeye neden olmadan zarifçe raporlar.

### 2. 🔄 Video Dönüştürme (Convert)
- **Konteynerler**: MP4, MOV, MKV, WebM
- **Video Kodekleri**: 
  - `H.264 (Apple Silicon H/W - VideoToolbox)` (Ultra hızlı GPU kodlama)
  - `H.264 / AVC (libx264 - CPU)`
  - `HEVC / H.265 (Apple Silicon H/W - VideoToolbox)`
  - `HEVC / H.265 (libx265 - CPU)`
  - `Apple ProRes (ProRes 422 HQ)`
  - `VP9`
  - `Orijinal Akışı Koru (Stream Copy)`
- **Çözünürlük Ölçekleme**: Orijinal, 4K UHD (3840×2160), 1080p FHD (1920×1080), 720p HD (1280×720), 480p SD (854×480)
- **Kare Hızı Ayarı**: Orijinal, 24 fps (Sinema), 25 fps (PAL), 30 fps, 60 fps
- **Ses Kodekleri**: AAC, MP3, Opus, FLAC veya Orijinal Sesi Koru

### 3. 📉 Video Sıkıştırma (Compress)
- Boyut ile kalite dengesini optimize eden 3 hazır profil + Özel ayar:
  - **Küçük Dosya**: Web ve anlık mesajlaşma için (%50 - %70 boyut küçültme)
  - **Dengeli**: Görsel netlik ve boyut arasında optimum denge (%30 - %50 küçültme)
  - **Yüksek Kalite**: Arşivleme için minimum kayıplı sıkıştırma (%10 - %25 küçültme)
  - **Özel**: CRF kalite çarpanını (16-36) el ile belirleyin
- **Akıllı Ölçekleme**: 4K/2K videoları otomatik 1080p'ye küçültme seçeneği.
- **Apple Silicon Donanım Hızlandırma**: VideoToolbox entegrasyonu ile dakikalar süren işlemleri saniyeler içinde bitirir.

### 4. 🎵 Videodan Ses Çıkarma (Audio Extract)
- MP3, AAC (M4A), WAV (Kayıpsız PCM) ve FLAC formatlarında dışa aktarma.
- **Akıllı Passthrough (Stream Copy)**: Kaynak ses formatı hedef formatla uyuştuğunda (örn. MP4 içindeki AAC ses -> M4A), yeniden kodlama yapmadan sıfır kayıp ve sıfır gecikmeyle doğrudan ayıklar.
- Ses akışı içermeyen video dosyalarında net uyarı ve koruma mekanizması.

### 5. 📋 Merkezi İşlem Kuyruğu (Queue)
- Sıralı ve güvenli iş çalıştırma mimarisi.
- `-progress pipe:1` akışından okunan gerçek zamanlı ilerleme yüzdesi, FPS, hız çarpanı (örn: `4.5x`) ve tahmini kalan süre.
- İşlemi anında iptal edebilme ve arkadaki süreci güvenle sonlandırma.
- Hata durumunda ham hata detaylarını ve FFmpeg günlük çıktısını görüntüleme (`doc.text.magnifyingglass` modal penceresi).
- Tamamlanan dosyayı doğrudan **Finder'da Göster** butonu.
- Dosyaların yanlışlıkla üzerine yazılmasını engelleyen güvenli adlandırma mekanizması (`video_converted_1.mp4`).

### 6. ⚙️ Akıllı Motor Tespiti & Ayarlar
- `/opt/homebrew/bin`, `/usr/local/bin`, `/opt/local/bin` ve `PATH` üzerinden FFmpeg ve FFprobe'u otomatik algılar.
- Bulunamadığında kullanıcıya `brew install ffmpeg` talimatını ve özel ikili dosya yolu seçebilme imkanı sunar.

---

## 🏗️ Mimari Yapı

Patoo, temiz **MVVM** mimarisi ve Swift 6 / modern Swift Concurrency (`actor`, `async/await`, `@Observable`) standartlarına göre inşa edilmiştir:

```
Patoo/
├── App/
│   ├── PatooApp.swift               # Giriş noktası ve pencere konfigürasyonu
│   └── ContentView.swift            # Ana navigasyon ve toast bildirim katmanı
├── Models/
│   ├── AppState.swift               # Global navigasyon ve sistem durumu
│   ├── MediaMetadata.swift          # FFprobe JSON çıktı modelleri ve akış bilgileri
│   ├── ConversionConfig.swift       # Konteyner, video/ses kodekleri ve ölçekleme
│   ├── CompressionConfig.swift      # Sıkıştırma profilleri ve donanım ayarları
│   ├── AudioExtractionConfig.swift  # Ses formatları ve akış kopyalama ayarları
│   └── Job.swift                    # Kuyruk görev durumu ve modelleri
├── Services/
│   ├── FFmpegLocator.swift          # FFmpeg & FFprobe otomatik tespit servisi
│   ├── FFprobeService.swift         # Asenkron medya analiz servisi
│   ├── FFmpegCommandBuilder.swift   # Tip güvenli, bağımsız test edilebilir komut üretici
│   ├── FFmpegProgressParser.swift   # pipe:1 çıktı ayrıştırıcı ve kalan süre tahmincisi
│   ├── FFmpegProcessRunner.swift    # Process aktörü, akış okuma ve iptal yöneticisi
│   ├── QueueManager.swift           # Sıralı kuyruk yürütme yöneticisi
│   └── CoreLogicTests.swift         # Dahili otomatik birim test paketi
├── Theme/
│   ├── PatooTheme.swift             # Renk paleti, koyu lacivert & neon cyan/violet teması
│   └── Components/
│       ├── PatooButton.swift        # Neon glow ve hover efektli düğmeler
│       ├── TechnicalHUD.swift       # Dairesel HUD göstergeleri, durum rozetleri
│       └── FileDropZone.swift       # Drag & drop ve dosya seçim alanı
└── Views/
    ├── Sidebar/                     # Yan navigasyon menüsü
    ├── Overview/                    # Gösterge paneli ve hızlı aksiyonlar
    ├── Convert/                     # Dönüştürme ekranı
    ├── Compress/                    # Sıkıştırma ekranı
    ├── AudioExtract/                # Ses çıkarma ekranı
    ├── Trim/                        # Kırpma yol haritası ekranı
    ├── Queue/                       # İşlem kuyruğu ve günlük görüntüleyici
    └── Settings/                    # FFmpeg konum ve tercih ayarları
```

---

## 🚀 Gereksinimler ve Kurulum

### Gereksinimler
- **macOS 14.0** veya üzeri (Apple Silicon ve Intel desteklenir)
- **Xcode 15.0+** veya **Xcode 16+**
- **FFmpeg & FFprobe**:
  ```bash
  brew install ffmpeg
  ```

### Projeyi Derleme ve Çalıştırma
1. Depoyu klonlayın:
   ```bash
   git clone git@github.com:ufukcelen/Patoo.git
   cd Patoo
   ```
2. Xcode ile projeyi açın:
   ```bash
   open Patoo.xcodeproj
   ```
3. Hedef olarak **My Mac** seçin ve `Cmd + R` ile derleyip çalıştırın.

---

## 🧪 Dahili Birim Testleri (Unit Tests)

Uygulama, temel mantıkların doğrulanması için otomatik test paketi (`CoreLogicTests`) içerir. Proje Debug modunda derlendiğinde veya test edildiğinde şu bileşenler otomatik doğrulanır:
- Süre biçimlendirme (`formatDuration`)
- Çıktı dosya çakışmalarını önleyen güvenli hedef URL üretimi
- Dönüştürme argüman dizilimi (VideoToolbox / libx264 / filtreler)
- Sıkıştırma profilleri ve CRF değerleri
- Ses çıkarma ve kodek bazlı stream copy doğrulaması
- `-progress pipe:1` ayrıştırıcı ve ilerleme hesaplaması
- FFprobe JSON serileştirmesi ve model haritalaması

---

## 📄 Lisans
Bu proje MIT lisansı ile lisanslanmıştır. FFmpeg motoru bağımsız bir CLI ikilisi olarak sistemde çalıştırılır ve telif hakları ilgili FFmpeg geliştiricilerine aittir.
