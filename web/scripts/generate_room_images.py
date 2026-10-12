"""
Buat gambar placeholder untuk 29 kamar Kost Akbar.

Menghasilkan PNG sederhana (label "Kamar N" + tipe + warna per lantai)
di web/storage/app/public/rooms/room-N.png. Dijalankan sekali sebelum
`php artisan migrate:fresh --seed`; aman dijalankan ulang (menimpa).

Pemakaian:  python scripts/generate_room_images.py
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

TOTAL_ROOMS = 29
SIZE = (800, 500)

# Warna dasar per lantai (latar, aksen).
FLOORS = {
    1: ((250, 243, 236), (176, 69, 27)),   # Lantai 1 - AC      : krem + terakota
    2: ((240, 247, 244), (15, 118, 110)),  # Lantai 2 - Reguler : mint + teal
    3: ((247, 240, 233), (139, 58, 42)),   # Lantai 3 - Reguler : krem + maroon
}


def floor_of(room_number: int) -> int:
    if room_number <= 9:
        return 1
    if room_number <= 19:
        return 2
    return 3


def type_of(room_number: int) -> str:
    return {1: 'Lantai 1 - AC', 2: 'Lantai 2 - Reguler', 3: 'Lantai 3 - Reguler'}[floor_of(room_number)]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in (
        r'C:\Windows\Fonts\arialbd.ttf',
        r'C:\Windows\Fonts\arial.ttf',
        '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    ):
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default(size=size)


def room_image(number: int) -> Image.Image:
    background, accent = FLOORS[floor_of(number)]
    image = Image.new('RGB', SIZE, background)
    draw = ImageDraw.Draw(image)

    # Bingkai aksen + blok "jendela" dekoratif.
    draw.rounded_rectangle((24, 24, SIZE[0] - 24, SIZE[1] - 24), radius=28, outline=accent, width=6)
    draw.rounded_rectangle((80, 90, 330, 260), radius=16, fill=accent)

    # Ilustrasi ranjang sederhana.
    draw.rounded_rectangle((380, 190, 700, 280), radius=12, fill=accent)
    draw.rectangle((380, 160, 410, 200), fill=accent)

    title_font = load_font(72)
    sub_font = load_font(30)
    title = f'Kamar {number}'

    draw.text((80, 320), title, font=title_font, fill=(43, 33, 28))
    draw.text((80, 412), type_of(number), font=sub_font, fill=(122, 106, 95))

    return image


def main() -> None:
    out_dir = Path(__file__).resolve().parent.parent / 'storage' / 'app' / 'public' / 'rooms'
    out_dir.mkdir(parents=True, exist_ok=True)

    for number in range(1, TOTAL_ROOMS + 1):
        room_image(number).save(out_dir / f'room-{number}.png', 'PNG')

    print(f'{TOTAL_ROOMS} gambar kamar dibuat di {out_dir}')


if __name__ == '__main__':
    main()
