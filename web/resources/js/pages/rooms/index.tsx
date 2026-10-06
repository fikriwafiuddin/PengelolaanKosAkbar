import { useEffect, useState } from 'react';
import { Head, router, usePage } from '@inertiajs/react';
import { BedDouble, DoorOpen, Printer, Search } from 'lucide-react';
import { toast } from 'sonner';

import Heading from '@/components/heading';
import { DeleteRoomButton } from '@/components/rooms/delete-room-button';
import { RoomFormDialog } from '@/components/rooms/room-form-dialog';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { cn } from '@/lib/utils';
import { formatRupiah } from '@/lib/format';
import { dashboard } from '@/routes';
import * as roomsRoutes from '@/routes/rooms';
import type { BreadcrumbItem } from '@/types';
import type {
    Facility,
    Pagination,
    Room,
    RoomStats,
    RoomStatus,
} from '@/types/kost';

type Props = {
    rooms: Pagination<Room>;
    filters: { q?: string; type?: string; status?: string };
    facilities: Facility[];
    types: string[];
    stats: RoomStats;
};

const STATUS_BADGE: Record<RoomStatus, string> = {
    kosong: 'bg-teal-600 text-white',
    terisi: 'bg-amber-500 text-white',
    terbooking: 'bg-violet-500 text-white',
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Data Kamar', href: roomsRoutes.index() },
];

export default function RoomsIndex({ rooms: roomPagination, filters, facilities, types, stats }: Props) {
    const { flash } = usePage().props;
    const [search, setSearch] = useState(filters.q ?? '');

    // Notifikasi hasil aksi CRUD (flash message dari controller).
    useEffect(() => {
        if (flash?.success) {
            toast.success(flash.success);
        }
        if (flash?.error) {
            toast.error(flash.error);
        }
    }, [flash]);

    // Pencarian: kirim ke server setelah penghenti mengetik (debounce).
    useEffect(() => {
        const timer = setTimeout(() => {
            if (search !== (filters.q ?? '')) {
                applyFilters({ q: search || undefined });
            }
        }, 350);

        return () => clearTimeout(timer);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [search]);

    /**
     * Kirim kombinasi filter aktif ke server via Inertia visit.
     */
    function applyFilters(next: Record<string, string | undefined>) {
        const merged = { ...filters, ...next };
        const query = Object.fromEntries(
            Object.entries(merged).filter(([, v]) => v),
        );

        router.get(roomsRoutes.index(), query, {
            preserveState: true,
            replace: true,
        });
    }

    return (
        <>
            <Head title="Data Kamar" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <div className="flex flex-wrap items-center justify-between gap-4">
                    <Heading
                        title="Data Kamar"
                        description="Kelola informasi kamar, ketersediaan, fasilitas, dan tarif sewa Kost Akbar secara terpadu."
                    />
                    <div className="flex items-center gap-2">
                        <Button variant="outline" asChild>
                            <a href={roomsRoutes.print.url()} target="_blank">
                                <Printer className="size-4" /> Cetak Katalog
                            </a>
                        </Button>
                        <RoomFormDialog facilities={facilities} types={types} />
                    </div>
                </div>

                {/* Kartu ringkasan */}
                <div className="grid gap-4 sm:grid-cols-3">
                    <Card>
                        <CardContent className="flex items-center justify-between">
                            <div>
                                <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
                                    Total Inventaris
                                </p>
                                <p className="mt-1 text-3xl font-serif font-semibold">
                                    {stats.total}
                                </p>
                                <p className="text-xs text-muted-foreground">
                                    Kapasitas total {stats.total} orang
                                </p>
                            </div>
                            <div className="rounded-full bg-secondary p-3">
                                <BedDouble className="size-5 text-primary" />
                            </div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="flex items-center justify-between">
                            <div>
                                <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
                                    Kamar Terisi
                                </p>
                                <p className="mt-1 text-3xl font-serif font-semibold text-teal-700 dark:text-teal-400">
                                    {stats.terisi}
                                </p>
                                <p className="text-xs text-muted-foreground">
                                    dari {stats.total} kamar
                                </p>
                            </div>
                            <div className="rounded-full bg-secondary p-3">
                                <BedDouble className="size-5 text-teal-700 dark:text-teal-400" />
                            </div>
                        </CardContent>
                    </Card>
                    <Card>
                        <CardContent className="flex items-center justify-between">
                            <div>
                                <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
                                    Kamar Kosong
                                </p>
                                <p className="mt-1 text-3xl font-serif font-semibold text-primary">
                                    {stats.kosong}
                                </p>
                                <p className="text-xs text-muted-foreground">
                                    siap huni untuk calon penghuni
                                </p>
                            </div>
                            <div className="rounded-full bg-secondary p-3">
                                <DoorOpen className="size-5 text-primary" />
                            </div>
                        </CardContent>
                    </Card>
                </div>

                {/* Filter tipe */}
                <div className="flex flex-wrap gap-2">
                    <Button
                        size="sm"
                        variant={!filters.type ? 'default' : 'secondary'}
                        className={cn(!filters.type && 'font-medium')}
                        onClick={() => applyFilters({ type: undefined })}
                    >
                        Semua Kamar ({stats.total})
                    </Button>
                    {types.map((type) => (
                        <Button
                            key={type}
                            size="sm"
                            variant={filters.type === type ? 'default' : 'secondary'}
                            onClick={() => applyFilters({ type })}
                        >
                            {type}
                        </Button>
                    ))}
                </div>

                {/* Pencarian & filter status */}
                <div className="flex flex-wrap items-center gap-3">
                    <div className="relative w-full max-w-sm">
                        <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                        <Input
                            className="pl-9"
                            placeholder="Cari nomor kamar, tipe, atau fasilitas..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                    <Select
                        value={filters.status ?? 'semua'}
                        onValueChange={(v) =>
                            applyFilters({
                                status: v === 'semua' ? undefined : v,
                            })
                        }
                    >
                        <SelectTrigger className="w-48">
                            <SelectValue placeholder="Semua Status" />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="semua">Semua Status</SelectItem>
                            <SelectItem value="kosong">Kosong</SelectItem>
                            <SelectItem value="terisi">Terisi</SelectItem>
                            <SelectItem value="terbooking">Terbooking</SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                {/* Tabel kamar */}
                <Card className="py-0">
                    <CardContent className="px-0">
                        <Table>
                            <TableHeader>
                                <TableRow className="hover:bg-transparent">
                                    <TableHead className="pl-6">No. Kamar</TableHead>
                                    <TableHead>Tipe / Lantai</TableHead>
                                    <TableHead>Harga</TableHead>
                                    <TableHead>Fasilitas</TableHead>
                                    <TableHead>Status</TableHead>
                                    <TableHead className="text-right pr-6">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {roomPagination.data.map((room) => (
                                    <TableRow key={room.id}>
                                        <TableCell className="pl-6 font-medium">
                                            Kamar {room.room_number}
                                            {room.description && (
                                                <p className="max-w-56 truncate text-xs font-normal text-muted-foreground">
                                                    {room.description}
                                                </p>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            <Badge variant="outline">
                                                {room.type}
                                            </Badge>
                                        </TableCell>
                                        <TableCell className="font-semibold text-primary">
                                            {formatRupiah(room.price_monthly)}
                                            <span className="block text-xs font-normal text-muted-foreground">
                                                /bulan
                                            </span>
                                        </TableCell>
                                        <TableCell className="max-w-56">
                                            <div className="flex flex-wrap gap-1">
                                                {room.facilities.map((f) => (
                                                    <Badge
                                                        key={f.id}
                                                        variant="secondary"
                                                        className="font-normal"
                                                    >
                                                        {f.name}
                                                    </Badge>
                                                ))}
                                            </div>
                                        </TableCell>
                                        <TableCell>
                                            <span
                                                className={cn(
                                                    'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
                                                    STATUS_BADGE[room.status],
                                                )}
                                            >
                                                {room.status_label}
                                            </span>
                                        </TableCell>
                                        <TableCell className="pr-6">
                                            <div className="flex items-center justify-end gap-1">
                                                <RoomFormDialog
                                                    facilities={facilities}
                                                    types={types}
                                                    room={room}
                                                />
                                                <DeleteRoomButton room={room} />
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))}

                                {roomPagination.data.length === 0 && (
                                    <TableRow>
                                        <TableCell
                                            colSpan={6}
                                            className="py-10 text-center text-muted-foreground"
                                        >
                                            Tidak ada kamar yang cocok dengan
                                            pencarian / filter.
                                        </TableCell>
                                    </TableRow>
                                )}
                            </TableBody>
                        </Table>
                    </CardContent>
                </Card>

                {/* Paginasi */}
                <div className="flex items-center justify-between text-sm text-muted-foreground">
                    <span>
                        Menampilkan {roomPagination.from ?? 0}–
                        {roomPagination.to ?? 0} dari {roomPagination.total}{' '}
                        kamar
                    </span>
                    <div className="flex items-center gap-2">
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={roomPagination.current_page <= 1}
                            onClick={() =>
                                router.get(
                                    roomsRoutes.index(),
                                    {
                                        page: roomPagination.current_page - 1,
                                        ...filters,
                                    },
                                    { preserveState: true },
                                )
                            }
                        >
                            Sebelumnya
                        </Button>
                        <span>
                            {roomPagination.current_page} /{' '}
                            {roomPagination.last_page}
                        </span>
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={
                                roomPagination.current_page >=
                                roomPagination.last_page
                            }
                            onClick={() =>
                                router.get(
                                    roomsRoutes.index(),
                                    {
                                        page: roomPagination.current_page + 1,
                                        ...filters,
                                    },
                                    { preserveState: true },
                                )
                            }
                        >
                            Berikutnya
                        </Button>
                    </div>
                </div>
            </div>
        </>
    );
}

RoomsIndex.layout = { breadcrumbs };
