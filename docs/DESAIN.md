# Aveloria — Dokumen Desain (draf 1)

RPG turn-based 2D top-down pixel art untuk Windows, dibuat dengan Godot 4.7.
Target: game utuh berdurasi 2–3 jam.

## Cerita singkat

Arlen, ksatria muda dari desa kecil di Lembah Hijau, berangkat untuk mengalahkan
Raja Monster yang mengancam dunia Aveloria. Di perjalanan ia bertemu tiga rekan,
dan bersama-sama mereka menembus tiga wilayah menuju Kastil Kelam.

Nama tokoh, wilayah, dan bos di bawah ini masih usulan dan boleh diganti.

## Party

| Tokoh  | Peran    | Gaya bertarung                                   | Bergabung di |
|--------|----------|--------------------------------------------------|--------------|
| Arlen  | Ksatria  | HP dan ATK tinggi, serangan fisik, menahan musuh | Awal         |
| Mira   | Pendeta  | Penyembuh, menaikkan DEF party, sihir cahaya     | Wilayah 1    |
| Selene | Penyihir | Sihir kerusakan besar, melemahkan musuh, HP tipis| Wilayah 2    |
| Kael   | Pemanah  | Paling cepat, kritikal tinggi, serangan menyebar | Wilayah 3    |

## Struktur dunia (semi open world)

Satu peta dunia yang bebas dijelajahi; tiap wilayah berisi kota/desa, area
monster, dan satu sarang semi-bos. Wilayah berikutnya terbuka setelah semi-bos
wilayah sebelumnya kalah.

1. **Lembah Hijau** — desa awal. Semi-bos: Ogre Penjaga.
2. **Hutan Kabut** — Dusun Embun; Selene bergabung di altar tua. Semi-bos: Ratu Laba-laba.
3. **Pegunungan Abu** — Pos Pemburu; Kael bergabung di punggung bukit utara. Semi-bos: Raksasa Lahar.
4. **Kastil Kelam** — Altar Cahaya untuk memulihkan diri; bos utama Raja Monster, lalu adegan penutup dan layar tamat.

## Sistem battle

- Pertemuan acak di area monster; semi-bos dan bos di lokasi tetap.
- Tiap ronde: pilih perintah untuk semua anggota party, lalu semua aksi
  (party dan musuh) dijalankan berurutan menurut AGI.
- Perintah: Serang, Jurus (pakai MP), Bertahan, Kabur. Nanti: Barang.
- Tidak bisa kabur dari semi-bos/bos.

## Progression

- Menang memberi XP dan emas; XP ke level berikutnya = 5·L² + 5·L.
- Naik level menaikkan stat dan membuka jurus baru di level tertentu.
- Nanti: perlengkapan (senjata/zirah) dibeli dengan emas di kota.

## Tahapan pengerjaan

1. [x] Prototipe battle (mesin battle, menu perintah, level, jurus, semi-bos uji)
2. [x] Peta yang bisa dijelajahi + pertemuan acak + perpindahan ke layar battle
3. [x] Vertical slice Wilayah 1: desa, NPC/dialog, Mira bergabung, Ogre Penjaga
4. [ ] Perlengkapan senjata/zirah (sudah ada: penginapan, efek status, save/load, layar judul, barang habis pakai, toko)
5. [x] Wilayah 2, 3, dan 4: cerita bisa dimainkan dari awal sampai tamat
6. [ ] Aset final (sprite, tileset, musik, efek suara), balancing, build .exe

## Struktur proyek

- `scripts/db.gd` — semua data: jurus, tokoh, monster, kelompok musuh (ubah angka di sini untuk balancing)
- `scripts/battle/battle_engine.gd` — aturan battle, tanpa tampilan
- `scripts/battle/battler.gd` — satu petarung dan stat/levelnya
- `scripts/battle/battle_scene.gd` — layar battle
- `scripts/world/world_map.gd` — peta dunia sebagai teks (satu karakter = satu petak) dan jenis medan
- `scripts/world/world.gd` — scene peta (dunia dan desa): gerak, pertemuan acak, NPC, dialog, pindah peta
- `scripts/world/story.gd` — cerita: daftar NPC, dialog mereka, dan adegan yang dipicu peristiwa
- `scripts/game.gd` — keadaan permainan (party, emas, progres, posisi di peta)
- `scripts/ui/bag_view.gd` — tampilan tas (kisi slot berikon), dipakai peta dan battle
- `scripts/audio.gd` — musik dan efek suara; pemetaan kejadian ke file ada di sini
- `assets/audio/KREDIT.md` — sumber dan lisensi semua file audio (musik berlisensi CC-BY, wajib dikreditkan)
- `tools/gen_sprites.gd` — pembuat sprite pixel art; hasilnya di `assets/sprites/` (jalankan ulang setelah mengubah gambar)
- `scripts/tests/sim.gd` — simulasi balancing otomatis
- `scripts/tests/flow.gd` — uji otomatis alur peta -> battle -> peta


## Armory: perlengkapan, bahan, dan tempa

- **Perlengkapan**: 4 slot per tokoh (senjata, kepala, dada, kaki), 3 tingkat. Tiap barang milik satu tokoh, langsung dipakai saat dibeli, dan tidak memakan slot tas. Dijual pandai besi: Garrick (Desa Rindu, tingkat 1), Halvard (Dusun Embun, tingkat 2), Varek (Pos Pemburu, tingkat 3).
- **Kategori monster**: common, rare, super rare (satu per wilayah, peluang muncul 7%, hanya saat party berisi 2 orang atau lebih), ultra rare (semi-bos dan bos).
- **Bahan**: satu bahan per kategori di tiap wilayah (16 macam), disimpan di kantong bahan tanpa batas. Bos selalu menjatuhkan 3 ultra, 2 super, 3 rare, 4 common. Bahan Kastil Kelam tidak dipakai menempa; hanya untuk dijual.
- **Tempa**: +1 sampai +5 dengan emas dan bahan dari wilayah yang sama dengan tingkat barang (+1/+2 common, +3 rare, +4 super rare, +5 ultra rare). Stat andalan naik di tiap tingkat.
- **Sifat**: tiap tempa berpeluang memberi satu efek status (20%, 20%, 35%, 50%, pasti di +5). Di battle sifat aktif dengan peluang 15% (+1) sampai 35% (+5). Senjata: nerf ke musuh yang diserang atau ATK Naik ke pemakai; kepala: Kebal di awal battle; dada: DEF Naik saat terkena serangan; kaki: Cepat di awal battle.
- **Tempa ulang**: mengacak sifat senjata dengan emas dan 1 bahan rare.
- **Keseimbangan**: angka semi-bos dan bos disetel dengan anggapan party memakai perlengkapan wilayahnya (`scripts/tests/sim.gd`).
- Semua angka ada di `scripts/db.gd`; ujinya di `scripts/tests/gear_test.gd`.

## Pemberitahuan versi baru

- Layar judul menampilkan nomor versi (dari `application/config/version` di `project.godot`) dan, pada game hasil ekspor, bertanya ke GitHub rilis terbaru. Kalau ada yang lebih baru, muncul tombol yang membuka halaman unduhan. Tanpa internet tidak terjadi apa-apa.
- Saat merilis: naikkan `config/version` di `project.godot` dan versi di `export_presets.cfg`, lalu beri tag rilis yang sama (mis. `v1.3`).
- Kode di `scripts/update_check.gd`; ujinya `scripts/tests/update_test.gd`. Untuk mencoba dari editor: jalankan dengan `-- --cek-versi`.

## Bahasa (Inggris dan Indonesia)

- Bahasa bawaan **Inggris**; pemain bisa pindah ke **Indonesia** lewat tombol di layar judul atau di menu Esc pada peta. Pilihannya disimpan di `user://settings.json`, terpisah dari simpanan permainan.
- Semua teks sumber di kode dan data tetap ditulis dalam bahasa Indonesia. `Loc.t("...")` (`scripts/loc.gd`) mengembalikan teks itu apa adanya atau padanan Inggrisnya dari kamus `LocEn.TEXT` (`scripts/loc_en.gd`). Teks yang tidak ada di kamus tampil apa adanya, jadi nama diri (Arlen, Garrick) tidak perlu didaftarkan.
- Data (`Db`, `Story`, `WorldMap`) tidak diubah; terjemahan terjadi saat ditampilkan. Nama zona dipakai juga oleh logika (`ZONE_INTROS`), jadi jangan diterjemahkan di data.
- Kalimat dengan angka memakai `Loc.t("... %d ...") % nilai`; di adegan cerita, isi `"args": [..]` pada langkah dialognya.
- Menambah teks baru: tulis dalam bahasa Indonesia, bungkus dengan `Loc.t`, lalu tambahkan padanannya di `loc_en.gd`. `scripts/tests/loc_test.gd` gagal kalau ada teks tampil yang belum punya padanan atau kalau penanda format (`%s`, `%d`) tidak cocok.
- Uji otomatis (dijalankan dengan `-s`) selalu berbahasa Indonesia dan tidak menulis file pengaturan; tambahkan `-- <folder> --lang=en` pada `flow.gd` untuk melihat tangkapan layar versi Inggris.
- Nama tokoh dan NPC memakai nama fantasi yang sama di kedua bahasa (Marla, Finn, Doran, Garrick, Elowen, Osric, Nessa, Halvard, Aldric, Brenna, Tobin, Varek). Gelar ikut diterjemahkan (Tetua -> Elder), begitu juga nama tempat (Desa Rindu -> Willowmere Village).

## Pemulihan MP di pertarungan

- Di akhir tiap ronde, tiap anggota party yang masih berdiri memulihkan `Db.MP_REGEN` (8%) dari MP maksimumnya, minimal 1. Yang memilih **Bertahan** di ronde itu pulih dua kali lipat (`Db.MP_REGEN_DEFEND`).
- Monster tidak memulihkan MP, supaya bos tetap kehabisan jurus di pertarungan panjang.
- Simulasi (`sim.gd -- regen=0.05`) bisa mencoba angka lain. Dengan 8%, peluang menang melawan semi-bos naik sekitar 4-8 poin dibanding tanpa pemulihan, jadi angka bos tidak diubah.

## Giliran di pertarungan

- Tiap ronde, urutan semua petarung diundi sekali di awal (`BattleEngine.round_order()`: SPD x acak 0,75-1,25) dan langsung ditampilkan sebagai deretan nama di atas arena. Efek Cepat/Lambat yang masuk di tengah ronde baru memengaruhi urutan ronde berikutnya.
- Pemain memilih perintah seorang tokoh **saat giliran tokoh itu tiba**, dan perintahnya langsung dijalankan. Monster memutuskan aksinya juga pada gilirannya.
- **Bertahan** berlaku sampai giliran berikutnya tokoh itu (bukan sampai akhir ronde), dan tetap melipatgandakan pemulihan MP ronde itu.
- **Kabur** bisa dicoba di giliran tokoh mana pun; kalau gagal, giliran tokoh itu hangus.
- Akhir ronde tidak berubah: terbakar/racun melukai, durasi efek berkurang, MP pulih.
- Karena pemain kini bisa menanggapi keadaan (menyembuhkan tepat setelah kena), Ratu Laba-laba diperkuat 10% (HP 668, ATK 40, MAG 18). Simulasi dengan perlengkapan wajar: Ogre 76%, Ratu 82%, Lahar 71%, Raja 76%.
- Uji tampilan memakai `_hold` di layar battle supaya perintah hanya dicatat (`_last_cmd`) tanpa dijalankan.

## Dungeon semi-bos dan peti harta

- Tiga semi-bos kini menunggu di ujung dungeon tersendiri: **Gua Ogre** (`gua`), **Sarang Ratu Laba-laba** (`sarang`), dan **Kawah Lahar** (`kawah`). Petak B / Q / N di peta wilayah menjadi pintu masuknya (`"dungeon"` + `"portal"` di `WorldMap.TILES`); syarat rekan dari `Db.BOSS_RULES` diperiksa di pintu itu.
- Tiap dungeon sekitar 50-60 petak lorong dengan cabang dan jalan buntu, monster wilayahnya (tabel `lembah_gua`, `kabut_sarang`, `abu_kawah`, peluang 11% per langkah), dan tidak ada penginapan di dalamnya. Semi-bos tampak berdiri di petaknya sampai dikalahkan. Petak `e` adalah jalan keluar ke peta induk.
- Dinding dungeon memakai bukit batu rendah supaya lorong satu petak tetap terlihat; pohon terlalu tinggi dan menutupi lorong.
- **Peti harta** (petak `x`): isinya di `"chests"` tiap peta, berupa `{"gold"}`, `{"item", "count"}`, atau `{"mats"}`. Menginjak peti membukanya sekali; penandanya `chest_<peta>_<x>_<y>` di `Game.flags`, jadi ikut tersimpan. Peti berisi barang tetap tertutup kalau tas penuh. Ada dua peti di tiap dungeon dan dua di Kastil Kelam.
- Kastil Kelam sudah berbentuk dungeon (aula, ruang dalam, altar), jadi hanya ditambah peti.
- Simulasi: tiga pertarungan dungeon sebelum tiap semi-bos, tanpa menginap di antaranya; kalah berarti mengulang dari pintu masuk. Dengan perlengkapan wajar: Ogre 77%, Ratu 79%, Lahar 79%, Raja 78%, jadi angka bos tidak diubah.

## Peta wilayah diperbesar 1,5x

- Peta dunia (Lembah Hijau + Hutan Kabut) menjadi 66 x 29 petak (dari 44 x 19), dan Pegunungan Abu 54 x 20 (dari 36 x 14). Kastil Kelam dan peta permukiman tidak diubah.
- Caranya meregangkan peta lama: baris dan kolom tertentu digandakan, dipilih yang tidak memuat petak khusus (desa, gerbang, sarang) dan tidak memotong jalan searah, jadi jalan tetap selebar satu petak dan semua tempat tetap tersambung. Bentuk wilayahnya sama, hanya lebih lapang.
- Peluang bertemu monster per langkah diturunkan (padang 8% -> 6,5%, hutan 16% -> 13%, dan setara di wilayah lain), supaya jarak 1,5x hanya menambah pertarungan sekitar 20%.
- Enam peti baru di sudut-sudut wilayah (dua per wilayah). Petak peti di peta wilayah memakai bahan tanah petak tetangganya.
- Posisi Mira, Selene, dan Kael ikut dipindah ke padanan tempat lamanya.
- Simpanan: `SAVE_VERSION` 3. Simpanan versi lama yang posisinya di peta dunia atau Pegunungan Abu dimuat di penginapan terakhir (posisi lama tidak berlaku di peta baru); progres, party, dan barang tetap. Simpanan di permukiman, dungeon, dan kastil tidak terpengaruh.