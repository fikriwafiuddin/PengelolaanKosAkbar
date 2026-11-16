import { Head, Link } from '@inertiajs/react';
import {
    AlertTriangle,
    BedDouble,
    Clock,
    KeyRound,
    UserCheck,
    UserMinus,
    UserPlus,
    UserRound,
} from 'lucide-react';
import Heading from '@/components/heading';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { cn } from '@/lib/utils';
import { dashboard as dashboardRoute } from '@/routes';
import * as paymentsRoutes from '@/routes/payments';
import { formatDate } from '@/lib/format';
import type { BreadcrumbItem } from '@/types';
import type { ResidentStats, RoomStats, TrendPoint, OverdueUnpaid } from '@/types/kost';

type Props = {
    overview: {
        rooms: RoomStats;
        occupancy: number;
        residents: ResidentStats;
        trend: TrendPoint[];
        overdue_unpaid: OverdueUnpaid[];
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

const rupiah = (value: number) =>
    'Rp ' + value.toLocaleString('id-ID', { maximumFractionDigits: 0 });

export default function Dashboard({ overview }: Props) {
    const {
        rooms: roomStats,
        occupancy,
        residents,
        trend,
        overdue_unpaid: overdueUnpaid,
        latest_residents: latestResidents,
    } = overview;

    const maxTrend = Math.max(
        ...trend.map((t) => Math.max(t.income, t.expense)),
        1,
    );
    const currentMonth = new Date().toISOString().slice(0, 7);

    return (
        <>
            <Head title="Dashboard" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <Heading
                    title="Dashboard Kost Akbar"
                    description="Ringkasan okupansi kamar, keuangan, dan aktivitas penghuni."
                />

                {/* ── Kartu ringkasan ── */}
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
                    {/* Okupansi */}
                    <Card className="gap-3 xl:col-span-2">
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

                    {/* Penghuni aktif */}
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
                                {residents.belum_bayar} belum bayar
                            </p>
                        </CardContent>
                    </Card>

                    {/* Calon penghuni — Rev-5 */}
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between">
                            <CardTitle className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
                                Calon Penghuni
                            </CardTitle>
                            <div className="rounded-full bg-secondary p-2">
                                <UserPlus className="size-4 text-primary" />
                            </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-3xl font-serif font-semibold">
                                {residents.calon_penghuni}
                                <span className="text-lg text-muted-foreground">
                                    {' '}orang
                                </span>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Sudah divalidasi, belum punya kamar.
                            </p>
                        </CardContent>
                    </Card>

                    {/* Penghuni keluar — Rev-5 */}
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between">
                            <CardTitle className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
                                Sudah Keluar
                            </CardTitle>
                            <div className="rounded-full bg-secondary p-2">
                                <UserMinus className="size-4 text-primary" />
                            </div>
                        </CardHeader>
                        <CardContent className="space-y-2">
                            <div className="text-3xl font-serif font-semibold">
                                {residents.sudah_keluar}
                                <span className="text-lg text-muted-foreground">
                                    {' '}orang
                                </span>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                Penghuni yang sudah selesai sewa.
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* ── Grafik tren keuangan 6 bulan (Rev-3) + Belum bayar (Rev-4) ── */}
                <div className="grid gap-4 lg:grid-cols-5">
                    {/* Tren keuangan */}
                    <Card className="py-0 lg:col-span-3">
                        <CardContent className="px-6 py-5">
                            <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Tren Keuangan 6 Bulan
                            </p>
                            <div className="mt-4 flex items-end justify-between gap-2">
                                {trend.map((point) => (
                                    <div
                                        key={point.month}
                                        className="flex flex-1 flex-col items-center gap-1.5"
                                        title={`${point.month_label}: ${rupiah(point.income)} masuk · ${rupiah(point.expense)} keluar · laba ${rupiah(point.profit)}`}
                                    >
                                        <div className="flex h-28 w-full items-end justify-center gap-1">
                                            <div
                                                className="w-5/12 rounded-t bg-teal-600/80"
                                                style={{
                                                    height: `${Math.max(
                                                        (point.income / maxTrend) * 100,
                                                        2,
                                                    )}%`,
                                                }}
                                            />
                                            <div
                                                className="w-5/12 rounded-t bg-red-400/70"
                                                style={{
                                                    height: `${Math.max(
                                                        (point.expense / maxTrend) * 100,
                                                        2,
                                                    )}%`,
                                                }}
                                            />
                                        </div>
                                        <span
                                            className={cn(
                                                'text-[0.65rem]',
                                                point.month === currentMonth
                                                    ? 'font-bold text-foreground'
                                                    : 'text-muted-foreground',
                                            )}
                                        >
                                            {point.month_label}
                                        </span>
                                    </div>
                                ))}
                            </div>
                            <div className="mt-3 flex items-center gap-4 text-xs text-muted-foreground">
                                <span className="flex items-center gap-1.5">
                                    <span className="size-2.5 rounded-sm bg-teal-600/80" />
                                    Pemasukan
                                </span>
                                <span className="flex items-center gap-1.5">
                                    <span className="size-2.5 rounded-sm bg-red-400/70" />
                                    Pengeluaran
                                </span>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Penghuni belum bayar — Rev-4 */}
                    <Card className="lg:col-span-2">
                        <CardHeader className="flex-row items-center justify-between pb-2">
                            <CardTitle className="font-serif text-base">
                                Belum Bayar (Jatuh Tempo)
                            </CardTitle>
                            <AlertTriangle className="size-4 text-amber-500" />
                        </CardHeader>
                        <CardContent className="space-y-2">
                            {overdueUnpaid.length === 0 ? (
                                <div className="flex items-center gap-2 rounded-lg border border-green-200 bg-green-50 px-3 py-3 dark:border-green-900 dark:bg-green-950/30">
                                    <UserCheck className="size-4 shrink-0 text-green-600 dark:text-green-400" />
                                    <p className="text-sm text-green-700 dark:text-green-400">
                                        Semua penghuni sudah membayar tepat waktu.
                                    </p>
                                </div>
                            ) : (
                                <div className="max-h-56 space-y-2 overflow-y-auto">
                                    {overdueUnpaid.map((item) => (
                                        <div
                                            key={item.invoice_id}
                                            className="flex items-start justify-between gap-2 rounded-lg border border-amber-200 bg-amber-50/60 px-3 py-2 dark:border-amber-900 dark:bg-amber-950/20"
                                        >
                                            <div className="min-w-0">
                                                <p className="truncate text-sm font-medium">
                                                    {item.resident_name}
                                                </p>
                                                <p className="text-xs text-muted-foreground">
                                                    Kamar {item.room_number} ·{' '}
                                                    {item.period_label}
                                                </p>
                                                <p className="mt-0.5 flex items-center gap-1 text-xs text-amber-600 dark:text-amber-400">
                                                    <Clock className="size-3" />
                                                    Jatuh tempo {item.due_date_formatted}
                                                </p>
                                            </div>
                                            <span className="shrink-0 text-sm font-semibold text-red-600 dark:text-red-400">
                                                {item.amount_formatted}
                                            </span>
                                        </div>
                                    ))}
                                </div>
                            )}
                            {overdueUnpaid.length > 0 && (
                                <Link
                                    href={paymentsRoutes.index()}
                                    className="mt-1 block text-center text-xs text-primary hover:underline"
                                >
                                    Lihat semua di Verifikasi Pembayaran →
                                </Link>
                            )}
                        </CardContent>
                    </Card>
                </div>

                {/* ── Okupansi per tipe kamar ── */}
                <Card>
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

                {/* ── Penghuni terbaru ── */}
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
            </div>
        </>
    );
}

Dashboard.layout = { breadcrumbs };
