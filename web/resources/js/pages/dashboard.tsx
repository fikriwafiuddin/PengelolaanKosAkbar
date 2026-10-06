import { Head } from '@inertiajs/react';
import { BedDouble, KeyRound, TrendingUp, UserRound } from 'lucide-react';
import Heading from '@/components/heading';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { dashboard as dashboardRoute } from '@/routes';
import { formatDate, formatRupiah } from '@/lib/format';
import type { BreadcrumbItem } from '@/types';
import type { ResidentStats, RoomStats } from '@/types/kost';

type Props = {
    overview: {
        rooms: RoomStats;
        occupancy: number;
        residents: ResidentStats;
        vacant_rooms: {
            id: number;
            room_number: string;
            type: string;
            price_monthly: number;
        }[];
        latest_residents: {
            name: string;
            room: string | null;
            start_date: string | null;
        }[];
    };
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboardRoute() },
];

export default function Dashboard({ overview }: Props) {
    const { rooms: roomStats, occupancy, residents, vacant_rooms: vacantRooms, latest_residents: latestResidents } = overview;

    return (
        <>
            <Head title="Dashboard" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <Heading
                    title="Dashboard Kost Akbar"
                    description="Ringkasan okupansi kamar dan aktivitas penghuni."
                />

                {/* Kartu ringkasan */}
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between">
                            <CardTitle className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
                                Okupansi Kamar
                            </CardTitle>
                            <div className="rounded-full bg-secondary p-2">
                                <BedDouble className="size-4 text-primary" />
                            </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-3xl font-serif font-semibold">
                                {roomStats.terisi}
                                <span className="text-lg text-muted-foreground">
                                    {' '}/ {roomStats.total} kamar
                                </span>
                            </div>
                            <Progress value={occupancy} />
                            <p className="text-xs text-muted-foreground">
                                Terisi {occupancy}% ·{' '}
                                <span className="font-medium text-primary">
                                    {roomStats.kosong} kamar kosong
                                </span>
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between">
                            <CardTitle className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
                                Penghuni Aktif
                            </CardTitle>
                            <div className="rounded-full bg-secondary p-2">
                                <UserRound className="size-4 text-primary" />
                            </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-3xl font-serif font-semibold">
                                {residents.total}
                                <span className="text-lg text-muted-foreground">
                                    {' '}orang
                                </span>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                {residents.lunas} lunas ·{' '}
                                {residents.menunggu_verifikasi} menunggu
                                verifikasi · {residents.belum_bayar} belum bayar
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between">
                            <CardTitle className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
                                Kamar Kosong
                            </CardTitle>
                            <div className="rounded-full bg-secondary p-2">
                                <KeyRound className="size-4 text-primary" />
                            </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-3xl font-serif font-semibold">
                                {roomStats.kosong}
                                <span className="text-lg text-muted-foreground">
                                    {' '}kamar
                                </span>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Siap huni dan dapat dipesan calon penghuni.
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between">
                            <CardTitle className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
                                Terbooking
                            </CardTitle>
                            <div className="rounded-full bg-secondary p-2">
                                <TrendingUp className="size-4 text-primary" />
                            </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-3xl font-serif font-semibold">
                                {roomStats.terbooking}
                                <span className="text-lg text-muted-foreground">
                                    {' '}kamar
                                </span>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Menunggu konfirmasi pemesanan (Sprint 2).
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* Okupansi per tipe + daftar */}
                <div className="grid gap-4 lg:grid-cols-3">
                    <Card className="lg:col-span-2">
                        <CardHeader>
                            <CardTitle className="font-serif">
                                Okupansi per Tipe Kamar
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-5">
                            {roomStats.by_type.map((stat) => {
                                const occupied = stat.total - stat.kosong;
                                const percent =
                                    stat.total > 0
                                        ? Math.round((occupied / stat.total) * 100)
                                        : 0;

                                return (
                                    <div key={stat.type} className="space-y-1.5">
                                        <div className="flex items-center justify-between text-sm">
                                            <span className="font-medium">
                                                {stat.type}
                                            </span>
                                            <span className="text-muted-foreground">
                                                {occupied}/{stat.total} terisi ·{' '}
                                                {stat.kosong} kosong
                                            </span>
                                        </div>
                                        <Progress value={percent} />
                                    </div>
                                );
                            })}
                        </CardContent>
                    </Card>

                    <Card>
                        <CardHeader>
                            <CardTitle className="font-serif">
                                Kamar Siap Huni
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-3">
                            {vacantRooms.map((room) => (
                                <div
                                    key={room.id}
                                    className="flex items-center justify-between rounded-lg border border-border/70 px-3 py-2"
                                >
                                    <div>
                                        <p className="text-sm font-medium">
                                            Kamar {room.room_number}
                                        </p>
                                        <p className="text-xs text-muted-foreground">
                                            {room.type}
                                        </p>
                                    </div>
                                    <span className="text-sm font-semibold text-primary">
                                        {formatRupiah(room.price_monthly)}
                                    </span>
                                </div>
                            ))}
                        </CardContent>
                    </Card>
                </div>

                {/* Penghuni terbaru */}
                <Card>
                    <CardHeader className="flex-row items-center justify-between">
                        <CardTitle className="font-serif">
                            Penghuni Terbaru
                        </CardTitle>
                        <Badge variant="secondary" className="font-normal">
                            Lihat semua di menu Data Penghuni
                        </Badge>
                    </CardHeader>
                    <CardContent>
                        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
                            {latestResidents.map((item) => (
                                <div
                                    key={item.name}
                                    className="flex items-center justify-between rounded-lg border border-border/70 px-3 py-2"
                                >
                                    <div>
                                        <p className="text-sm font-medium">
                                            {item.name}
                                        </p>
                                        <p className="text-xs text-muted-foreground">
                                            Mulai sewa{' '}
                                            {formatDate(item.start_date)}
                                        </p>
                                    </div>
                                    {item.room && (
                                        <Badge variant="outline">
                                            Kamar {item.room}
                                        </Badge>
                                    )}
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>

                <p className="text-xs text-muted-foreground">
                    Grafik tren pemasukan & pengeluaran akan hadir pada menu
                    Laporan Keuangan (Sprint 4).
                </p>
            </div>
        </>
    );
}

Dashboard.layout = { breadcrumbs };
