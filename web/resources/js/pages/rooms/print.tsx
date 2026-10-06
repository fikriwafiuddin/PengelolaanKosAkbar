import { useEffect } from 'react';
import { Head } from '@inertiajs/react';
import { Printer } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { formatRupiah } from '@/lib/format';
import * as roomsRoutes from '@/routes/rooms';
import type { BreadcrumbItem } from '@/types';
import type { Room } from '@/types/kost';

type Props = {
    rooms: Room[];
    printed_at: string;
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Data Kamar', href: roomsRoutes.index() },
    { title: 'Cetak Katalog', href: roomsRoutes.print() },
];

/**
 * Halaman cetak katalog kamar — daftar referensi fasilitas & harga
 * untuk calon penghuni (mengikuti activity diagram Sprint 1).
 */
export default function RoomsPrint({ rooms: allRooms, printed_at }: Props) {
    // Buka dialog cetak browser otomatis saat halaman dibuka.
    useEffect(() => {
        const timer = setTimeout(() => window.print(), 400);

        return () => clearTimeout(timer);
    }, []);

    const grouped = allRooms.reduce<Record<string, Room[]>>(
        (acc, room) => {
            (acc[room.type] ??= []).push(room);

            return acc;
        },
        {},
    );

    return (
        <>
            <Head title="Cetak Katalog Kamar" />

            <div className="flex h-full flex-1 flex-col gap-6 bg-white p-8 print:p-0">
                <div className="flex items-center justify-between print:hidden">
                    <Button variant="outline" asChild>
                        <a href={roomsRoutes.index.url()}>← Kembali ke Data Kamar</a>
                    </Button>
                    <Button onClick={() => window.print()}>
                        <Printer className="size-4" /> Cetak Sekarang
                    </Button>
                </div>

                {/* Kop katalog — ikut tercetak */}
                <div className="space-y-1 text-center">
                    <h1 className="font-serif text-2xl font-bold tracking-tight">
                        Katalog Kamar Kost Akbar
                    </h1>
                    <p className="text-sm text-neutral-600">
                        Jl. Mastrip No.130, Sukorame, Kec. Mojoroto, Kota
                        Kediri, Jawa Timur 64114
                    </p>
                    <p className="text-xs text-neutral-500">
                        Dicetak: {printed_at} · {allRooms.length} kamar
                    </p>
                </div>

                {Object.entries(grouped).map(([type, roomsInType]) => (
                    <section
                        key={type}
                        className="break-inside-avoid space-y-2"
                    >
                        <h2 className="border-b-2 border-neutral-800 pb-1 font-serif text-lg font-semibold">
                            {type}{' '}
                            <span className="text-sm font-normal text-neutral-600">
                                ({roomsInType.length} kamar)
                            </span>
                        </h2>
                        <table className="w-full border-collapse text-sm">
                            <thead>
                                <tr className="border-b border-neutral-300 text-left">
                                    <th className="px-2 py-1.5 w-10">No.</th>
                                    <th className="px-2 py-1.5">Kamar</th>
                                    <th className="px-2 py-1.5">Fasilitas</th>
                                    <th className="px-2 py-1.5">Status</th>
                                    <th className="px-2 py-1.5 text-right">
                                        Harga / Bulan
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                {roomsInType.map((room, i) => (
                                    <tr
                                        key={room.id}
                                        className="border-b border-neutral-200 align-top"
                                    >
                                        <td className="px-2 py-1.5">{i + 1}.</td>
                                        <td className="px-2 py-1.5 font-medium">
                                            Kamar {room.room_number}
                                        </td>
                                        <td className="px-2 py-1.5 text-neutral-700">
                                            {room.facilities
                                                .map((f) => f.name)
                                                .join(', ')}
                                        </td>
                                        <td className="px-2 py-1.5">
                                            {room.status_label}
                                        </td>
                                        <td className="px-2 py-1.5 text-right font-semibold">
                                            {formatRupiah(room.price_monthly)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </section>
                ))}

                <p className="pt-4 text-center text-xs text-neutral-500">
                    Harga dapat berubah sewaktu-waktu. Hubungi pengelola untuk
                                    pemesanan kamar.
                </p>
            </div>
        </>
    );
}

RoomsPrint.layout = { breadcrumbs };
