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
4. **Kastil Kelam** — Bos utama: Raja Monster.

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
5. [ ] Wilayah 4: Kastil Kelam dan Raja Monster (Wilayah 2 dan 3 sudah selesai; party lengkap berempat)
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
