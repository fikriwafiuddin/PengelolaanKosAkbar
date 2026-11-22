import { Head, Link } from '@inertiajs/react';
import {
    AlertCircle,
    ArrowDownRight,
    ArrowUpRight,
    BedDouble,
    KeyRound,
    TrendingDown,
    TrendingUp,
    UserCheck,
    UserMinus,
    UserPlus,
    UserRound,
    Wallet,
} from 'lucide-react';
import Heading from '@/components/heading';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { cn } from '@/lib/utils';
import { dashboard as dashboardRoute } from '@/routes';
import * as arrearsRoutes from '@/routes/arrears';
import * as financeRoutes from '@/routes/finance';
import * as paymentsRoutes from '@/routes/payments';
import * as roomsRoutes from '@/routes/rooms';
import * as residentsRoutes from '@/routes/residents';
import type { BreadcrumbItem } from '@/types';
import type { ResidentStats, RoomStats, TrendPoint } from '@/types/kost';

type FinanceSummary = {
    month: string;
    month_label: string;
    income: number;
    previous_income: number;
    income_change: number | null;
    expense: number;
    previous_expense: number;
    profit: number;
    previous_profit: number;
};

type ArrearsSummary = {
    total_amount: number;
    total_amount_formatted: string;
    total_invoices: number;
    resident_count: number;
};

type Props = {
    overview: {
        rooms: RoomStats;
        occupancy: number;
        residents: ResidentStats;
        finance_summary: FinanceSummary;
        trend: TrendPoint[];
        arrears_summary: ArrearsSummary;
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
        finance_summary: financeSummary,
        trend,
        arrears_summary: arrearsSummary,
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
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <Heading
                        title="Dashboard Kost Akbar"
                        description="Ringkasan okupansi kamar, keuangan kos, dan status penghuni."
                    />
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" asChild>
                            <Link href={financeRoutes.index()}>
                                <Wallet className="size-4" />
                                Laporan Keuangan
                            </Link>
                        </Button>
                        <Button variant="outline" size="sm" asChild>
                            <Link href={arrearsRoutes.index()}>
                                <AlertCircle className="size-4 text-red-500" />
                                Data Tunggakan
                            </Link>
                        </Button>
                    </div>
                </div>

                {/* ── BAGIAN 1: Ringkasan Keuangan Kos (Bulan Berjalan) ── */}
                <div>
                    <div className="mb-3 flex items-center justify-between">
                        <h2 className="text-sm font-semibold tracking-wide text-muted-foreground uppercase">
                            Ringkasan Keuangan — {financeSummary.month_label}
                        </h2>
                        <Link
                            href={financeRoutes.index()}
                            className="text-xs text-primary hover:underline"
                        >
                            Kelola di Laporan Keuangan →
                        </Link>
                    </div>
                    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
                        {/* Pemasukan Sewa */}
                        <Card className="py-0">
                            <CardContent className="px-5 py-4">
                                <div className="flex items-center justify-between">
                                    <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                        Pemasukan Sewa
                                    </p>
                                    <div className="rounded-lg bg-teal-500/10 p-2 text-teal-600 dark:text-teal-400">
                                        <ArrowUpRight className="size-4" />
                                    </div>
                                </div>
                                <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-teal-600 dark:text-teal-400">
                                    {rupiah(financeSummary.income)}
                                </p>
                                {financeSummary.income_change !== null && (
                                    <p className="mt-1 text-xs text-muted-foreground">
                                        {financeSummary.income_change >= 0 ? '▲' : '▼'}{' '}
                                        {Math.abs(financeSummary.income_change)}% vs bulan lalu
                                    </p>
                                )}
                            </CardContent>
                        </Card>

                        {/* Pengeluaran Operasional */}
                        <Card className="py-0">
                            <CardContent className="px-5 py-4">
                                <div className="flex items-center justify-between">
                                    <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                        Pengeluaran
                                    </p>
                                    <div className="rounded-lg bg-red-500/10 p-2 text-red-600 dark:text-red-400">
                                        <ArrowDownRight className="size-4" />
                                    </div>
                                </div>
                                <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-red-600 dark:text-red-400">
                                    {rupiah(financeSummary.expense)}
                                </p>
                                <p className="mt-1 text-xs text-muted-foreground">
                                    Biaya operasional kos
                                </p>
                            </CardContent>
                        </Card>

                        {/* Laba Bersih */}
                        <Card className="py-0">
                            <CardContent className="px-5 py-4">
                                <div className="flex items-center justify-between">
                                    <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                        Laba Bersih
                                    </p>
                                    <div className="rounded-lg bg-amber-500/10 p-2 text-amber-600 dark:text-amber-400">
                                        <TrendingUp className="size-4" />
                                    </div>
                                </div>
                                <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-amber-600 dark:text-amber-400">
                                    {rupiah(financeSummary.profit)}
                                </p>
                                <p className="mt-1 text-xs text-muted-foreground">
                                    Kas masuk setelah pengeluaran
                                </p>
                            </CardContent>
                        </Card>

                        {/* Total Uang Menunggak */}
                        <Card className="py-0 border-red-200 dark:border-red-900/50">
                            <CardContent className="px-5 py-4">
                                <div className="flex items-center justify-between">
                                    <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                        Total Menunggak
                                    </p>
                                    <div className="rounded-lg bg-red-500/15 p-2 text-red-600 dark:text-red-400">
                                        <AlertCircle className="size-4" />
                                    </div>
                                </div>
                                <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-red-600 dark:text-red-400">
                                    {arrearsSummary.total_amount_formatted}
                                </p>
                                <p className="mt-1 text-xs text-muted-foreground">
                                    {arrearsSummary.resident_count} penghuni ({arrearsSummary.total_invoices} tagihan)
                                </p>
                            </CardContent>
                        </Card>
                    </div>
                </div>

                {/* ── BAGIAN 2: Ringkasan Okupansi Kamar & Penghuni ── */}
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                    {/* Okupansi Kamar */}
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between pb-2">
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
                                <Link
                                    href={roomsRoutes.index()}
                                    className="font-medium text-primary hover:underline"
                                >
                                    {roomStats.kosong} kamar kosong
                                </Link>
                            </p>
                        </CardContent>
                    </Card>

                    {/* Penghuni Aktif */}
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between pb-2">
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
                                <span className="text-red-500 font-medium">
                                    {residents.belum_bayar} belum bayar
                                </span>
                            </p>
                        </CardContent>
                    </Card>

                    {/* Calon Penghuni */}
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between pb-2">
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
                                Akun divalidasi, belum memesan kamar.
                            </p>
                        </CardContent>
                    </Card>

                    {/* Penghuni yang Sudah Keluar */}
                    <Card className="gap-3">
                        <CardHeader className="flex-row items-center justify-between pb-2">
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
                                Penghuni yang telah menyelesaikan sewa.
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* ── BAGIAN 3: Grafik Tren Keuangan & Okupansi per Tipe Kamar ── */}
                <div className="grid gap-6 lg:grid-cols-5">
                    {/* Grafik Tren Keuangan 6 Bulan */}
                    <Card className="py-0 lg:col-span-3">
                        <CardContent className="px-6 py-5">
                            <div className="flex items-center justify-between pb-2">
                                <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                    Grafik Tren Keuangan 6 Bulan (Pemasukan vs Pengeluaran)
                                </p>
                                <Badge variant="secondary" className="font-normal text-xs">
                                    Sprint 4
                                </Badge>
                            </div>
                            <div className="mt-4 flex items-end justify-between gap-3">
                                {trend.map((point) => (
                                    <div
                                        key={point.month}
                                        className="flex flex-1 flex-col items-center gap-1.5"
                                        title={`${point.month_label}: ${rupiah(point.income)} masuk · ${rupiah(point.expense)} keluar · laba ${rupiah(point.profit)}`}
                                    >
                                        <div className="flex h-36 w-full items-end justify-center gap-1.5">
                                            <div
                                                className="w-5/12 rounded-t bg-teal-600/80 transition-all hover:bg-teal-600"
                                                style={{
                                                    height: `${Math.max(
                                                        (point.income / maxTrend) * 100,
                                                        3,
                                                    )}%`,
                                                }}
                                            />
                                            <div
                                                className="w-5/12 rounded-t bg-red-400/70 transition-all hover:bg-red-400"
                                                style={{
                                                    height: `${Math.max(
                                                        (point.expense / maxTrend) * 100,
                                                        3,
                                                    )}%`,
                                                }}
                                            />
                                        </div>
                                        <span
                                            className={cn(
                                                'text-[0.7rem]',
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
                            <div className="mt-4 flex items-center justify-between border-t pt-3 text-xs text-muted-foreground">
                                <div className="flex items-center gap-4">
                                    <span className="flex items-center gap-1.5">
                                        <span className="size-2.5 rounded-sm bg-teal-600/80" />
                                        Pemasukan
                                    </span>
                                    <span className="flex items-center gap-1.5">
                                        <span className="size-2.5 rounded-sm bg-red-400/70" />
                                        Pengeluaran
                                    </span>
                                </div>
                                <Link
                                    href={financeRoutes.index()}
                                    className="text-primary hover:underline"
                                >
                                    Rincian Laporan Kas →
                                </Link>
                            </div>
                        </CardContent>
                    </Card>

                    {/* Ringkasan Okupansi per Tipe Kamar */}
                    <Card className="lg:col-span-2">
                        <CardHeader className="pb-3">
                            <CardTitle className="font-serif text-base">
                                Okupansi per Tipe Kamar
                            </CardTitle>
                        </CardHeader>
                        <CardContent className="space-y-4">
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
                                            <span className="text-xs text-muted-foreground">
                                                {occupied}/{stat.total} terisi ({percent}%)
                                            </span>
                                        </div>
                                        <Progress value={percent} />
                                    </div>
                                );
                            })}
                            <div className="pt-2">
                                <Button variant="outline" size="sm" asChild className="w-full">
                                    <Link href={roomsRoutes.index()}>
                                        Kelola Data Kamar →
                                    </Link>
                                </Button>
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>
        </>
    );
}

Dashboard.layout = { breadcrumbs };
