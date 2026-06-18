# PRODUCT REQUIREMENT DOCUMENT (PRD)
## Educational Ticketing Mobile Application (EduTick)

| Informasi Proyek | Deskripsi |
| :--- | :--- |
| **Platform** | Flutter (iOS & Android) |
| **Versi API** | 1.0.0 (Educational Ticketing API) |
| **Status Dokumen** | Proposed / Review |
| **Target Rilis** | Sesuai Milestone Kuliah Pemrograman Mobile |
| **Penulis / Pemilik** | Tim Pengembang Flutter / Mahasiswa Informatika ITG |

---

## 1. Latar Belakang & Tujuan
Dokumen ini disusun sebagai acuan teknis pengembangan aplikasi mobile berbasis Flutter menggunakan backend **Educational Ticketing API**[cite: 1]. Aplikasi ini ditujukan sebagai alat pembelajaran komprehensif untuk memahami arsitektur aplikasi mobile, manajemen state, integrasi REST API menggunakan JWT token, serta penanganan alur transaksi *e-commerce/ticketing* secara *end-to-end*[cite: 1].

Tujuan utama proyek ini adalah membangun aplikasi client mobile yang andal, aman, berkinerja tinggi, dan memiliki antarmuka pengguna (UI/UX) yang modern, bersih, serta intuitif untuk melayani pembelian tiket acara edukasi.

---

## 2. Arsitektur & Teknologi Utama
* **Framework Mobile:** Flutter (Stable Version Terbaru).
* **Manajemen State:** BLoC / Riverpod / Provider (Disarankan menggunakan BLoC untuk standarisasi skala enterprise).
* **Arsitektur Kode:** *Clean Architecture* (Data, Domain, Presentation Layers) atau *Feature-First Layering*.
* **Network Client:** `dio` atau `http` package dengan implementasi *Interceptor* untuk penanganan JWT Bearer Token secara otomatis[cite: 1].
* **Penyimpanan Lokal:** `flutter_secure_storage` untuk menyimpan JWT token secara aman dan `shared_preferences` untuk data konfigurasi aplikasi non-sensitif[cite: 1].

---

## 3. Pengguna Aplikasi (Aktor)
Berdasarkan analisis file `openapi.yaml`, aplikasi ini hanya melayani **1 Aktor Utama**, yaitu[cite: 1]:
* **Customer / End-User:** Pengguna umum yang mendaftar akun, menjelajahi katalog event, memesan tiket, melakukan pembayaran mandiri, serta menyimpan tiket digital berbentuk QR Code di dalam aplikasi[cite: 1].

---

## 4. Kebutuhan Fungsional & Matriks Fitur (MoSCoW)

| Fitur Utama | Prioritas | Deskripsi Kebutuhan | Endpoint API Terkait |
| :--- | :---: | :--- | :--- |
| **Sistem Autentikasi** | **MUST** | - Registrasi user baru (Nama, Email, Password).<br>- Login user & penyimpanan token JWT secara aman.<br>- Auto-login jika session masih valid.<br>- Logout untuk menghapus token lokal & server session. | `POST /api/v1/auth/register`<br>`POST /api/v1/auth/login`<br>`POST /api/v1/auth/logout`[cite: 1] |
| **Manajemen Profil** | **MUST** | - Menampilkan profil pengguna aktif (ID, Nama, Email).<br>- Mengubah Nama Profil langsung dari aplikasi. | `GET /api/v1/me`<br>`PATCH /api/v1/me`[cite: 1] |
| **Eksplorasi Katalog** | **MUST** | - Menampilkan daftar kategori event.<br>- Menampilkan list event dengan sistem pagination, pencarian teks, dan filter kategori/kota.<br>- Menampilkan Detail Event (Deskripsi, Poster, Lokasi, Sisa Kuota, & Jenis Tiket). | `GET /api/v1/categories`<br>`GET /api/v1/events`<br>`GET /api/v1/events/{id}`[cite: 1] |
| **Pemesanan & Alur Transaksi** | **MUST** | - Membuat pesanan baru (1 tipe tiket per order, qty 1-10).<br>- Menampilkan daftar riwayat pesanan (Pagination).<br>- Menampilkan detail pesanan khusus milik pengguna.<br>- Membatalkan pesanan yang berstatus *Pending* sebelum expired. | `POST /api/v1/orders`<br>`GET /api/v1/orders`<br>`GET /api/v1/orders/{id}`<br>`POST /api/v1/orders/{id}/cancel`[cite: 1] |
| **Simulasi Pembayaran** | **MUST** | - Memilih metode pembayaran (Bank Transfer, E-Wallet, VA).<br>- Melakukan simulasi eksekusi pembayaran pesanan pending untuk mengaktifkan tiket. | `POST /api/v1/orders/{id}/pay`[cite: 1] |
| **Dompet Tiket (My Tickets)** | **MUST** | - Menampilkan daftar tiket aktif, terpakai, atau batal.<br>- Menampilkan detail tiket lengkap dengan data holder serta **QR Code Generator** berdasarkan data string `qr_code_value` dari API. | `GET /api/v1/tickets`<br>`GET /api/v1/tickets/{id}`[cite: 1] |
| **Health Status** | **SHOULD** | - Halaman status konektivitas/pemeliharaan server untuk menguji apakah backend lokal berjalan dengan baik. | `GET /health`[cite: 1] |

> ⚠️ **ATURAN BISNIS PENTING:** 
> Aplikasi Flutter **tidak boleh** menampilkan tiket langsung setelah pengguna menekan tombol "Pesan"[cite: 1]. Aplikasi wajib mengarahkan pengguna ke halaman Pembayaran (*Payment Pending Page*)[cite: 1]. Tiket hanya akan digenerate oleh server dan berstatus `active` di menu My Tickets setelah endpoint `/pay` berhasil dieksekusi dengan status sukses[cite: 1].

---

## 5. Struktur Halaman Aplikasi (Sitemap)
1. **Splash & Auth Screen**
   * Splash Screen (Pengecekan validitas token lokal).
   * Login Screen.
   * Register Screen.
2. **Main Navigation Wrapper (Bottom Navigation Bar)**
   * **Home Tab:** Banner promosi, Grid Kategori, List Event Terpopuler/Terbaru, Search & Filter Bar[cite: 1].
   * **Orders Tab:** Daftar riwayat transaksi (Tab khusus untuk memisahkan status *Pending* dan *Selesai/Batal*)[cite: 1].
   * **My Tickets Tab:** Grid/List tiket aktif yang memuat QR Code bawaan[cite: 1].
   * **Profile Tab:** Informasi akun, tombol Edit Nama Profil, informasi Developer, dan tombol Logout[cite: 1].
3. **Sub-Screen / Detail Pages**
   * Event Detail Screen (Deskripsi event, list tipe tiket, & tombol "Pesan Sekarang")[cite: 1].
   * Order Checkout Screen (Pemilihan jumlah tiket dan konfirmasi pembuatan order)[cite: 1].
   * Payment Screen (Pemilihan metode simulasi pembayaran & countdown timer sebelum order expired)[cite: 1].
   * Ticket Detail Screen (Tampilan kartu tiket premium lengkap dengan QR Code berukuran besar untuk di-scan)[cite: 1].

---

## 6. Spesifikasi UI/UX & Tema
* **Aesthetic Style:** *Modern Glassmorphism* & *Minimalist Dark/Light Mode*. Sudut komponen menggunakan border-radius yang halus (12-16dp).
* **Warna Utama (Primary Accent):** Deep Navy Blue (`#1a365d`) atau Vibrant Indigo untuk mencerminkan platform edukasi tepercaya, dipadukan dengan aksen Amber/Gold untuk elemen bernilai komersial seperti harga tiket.
* **Tata Letak Konten:** Memprioritaskan keterbacaan poster event, status pesanan yang kontras (Merah untuk expired/batal, Kuning untuk pending, Hijau untuk sukses), serta kemudahan akses navigasi satu tangan[cite: 1].

---

## 7. Kebutuhan Non-Fungsional (Non-Functional Requirements)
* **Performa:** Gambar poster harus di-cache menggunakan package `cached_network_image` untuk mencegah pemborosan kuota internet dan flickering saat scrolling[cite: 1].
* **Keamanan:** Token JWT wajib disimpan di media enkripsi hardware (Keychain di iOS dan Keystore di Android) menggunakan `flutter_secure_storage`[cite: 1]. Logs tidak boleh menampilkan token utuh pada mode Production.
* **Penanganan Error (Exception Handling):** Aplikasi harus menangani error kode HTTP secara elegan (401: otomatis redirect ke login, 422: menampilkan pesan validasi field spesifik di bawah textfield, 404: menampilkan ilustrasi data kosong)[cite: 1].
* **Kondisi Offline:** Menampilkan info state internet mati menggunakan library `connectivity_plus` agar aplikasi tidak crash saat kehilangan sinyal.