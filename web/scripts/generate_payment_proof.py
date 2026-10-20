"""
Buat gambar placeholder bukti transfer untuk data demo Kost Akbar.

Menghasilkan PNG bergaya struk transfer mobile banking di
web/storage/app/public/bukti/demo-transfer.png. Dijalankan sekali
sebelum `php artisan migrate:fresh --seed`; aman dijalankan ulang.

Pemakaian:  python scripts/generate_payment_proof.py
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

SIZE = (720, 1020)
NAVY = (0, 54, 153)      # aksen bank
BG = (247, 249, 252)
INK = (35, 31, 32)
MUTED = (120, 128, 138)


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in (
        r'C:\Windows\Fonts\arialbd.ttf',
        r'C:\Windows\Fonts\arial.ttf',
        '/usr/share/fonts/truetype/dejavu/DeVuSans-Bold.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    ):
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default(size=size)


def main() -> None:
    image = Image.new('RGB', SIZE, BG)
    draw = ImageDraw.Draw(image)

    # Bilah atas bank.
    draw.rectangle((0, 0, SIZE[0], 120), fill=NAVY)
    draw.text((40, 34), 'm-Transfer Kost Akbar', font=load_font(34), fill=(255, 255, 255))
    draw.text((40, 78), 'BUKTI TRANSFER BERHASIL', font=load_font(22), fill=(212, 220, 236))

    # Kartu rincian transaksi.
    card = (40, 170, SIZE[0] - 40, SIZE[1] - 40)
    draw.rounded_rectangle(card, radius=24, fill=(255, 255, 255), outline=(222, 228, 236), width=2)

    rows = [
        ('Jenis Transaksi', 'Transfer antar bank'),
        ('Bank Tujuan', 'Bank Kost Akbar'),
        ('No. Rekening Tujuan', '123 456 7890'),
        ('Nama Penerima', 'Ririn Yudarina (Pengelola)'),
        ('Nama Pengirim', 'Satria Wibowo'),
        ('No. Referensi', 'TRF20261025K25'),
        ('Tanggal', '25 Oktober 2026 09:41 WIB'),
    ]
    y = 230
    for label, value in rows:
        draw.text((80, y), label, font=load_font(24), fill=MUTED)
        draw.text((80, y + 30), value, font=load_font(28), fill=INK)
        y += 88

    # Nominal besar.
    draw.line((80, y + 6, card[2] - 80, y + 6), fill=(233, 237, 242), width=2)
    draw.text((80, y + 28), 'Nominal Transfer', font=load_font(24), fill=MUTED)
    draw.text((80, y + 62), 'Rp 450.000', font=load_font(44), fill=NAVY)

    # Stempel "BERHASIL".
    draw.rounded_rectangle(
        (SIZE[0] - 300, y + 40, card[2] - 60, y + 110),
        radius=14, outline=(13, 148, 90), width=4,
    )
    draw.text((SIZE[0] - 275, y + 58), 'BERHASIL', font=load_font(30), fill=(13, 148, 90))

    draw.text((80, card[3] - 70), 'Bukti demo untuk keperluan pengujian verifikasi admin.',
              font=load_font(20), fill=MUTED)

    out_dir = Path(__file__).resolve().parent.parent / 'storage' / 'app' / 'public' / 'bukti'
    out_dir.mkdir(parents=True, exist_ok=True)
    image.save(out_dir / 'demo-transfer.png', 'PNG')

    print(f'Bukti transfer demo dibuat di {out_dir / "demo-transfer.png"}')


if __name__ == '__main__':
    main()
