import { useEffect, useState } from 'react';
import { Head, router } from '@inertiajs/react';
import {
    AlertCircle,
    CheckCircle2,
    Clock,
    Search,
    UserX,
} from 'lucide-react';

import Heading from '@/components/heading';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { dashboard } from '@/routes';
import * as arrearsRoutes from '@/routes/arrears';
import type { BreadcrumbItem } from '@/types';
import type { Pagination } from '@/types/kost';

type ArrearsItem = {
    id: number;
    period: string;
    period_label: string;
    amount: number;
    amount_formatted: string;
    due_date: string;
    due_date_formatted: string;
    is_overdue: boolean;
    resident_id: number | null;
    resident_name: string;
    phone: string | null;
    room_number: string;
    room_type: string;
    booking_duration_months?: number;
};

type ArrearsSummary = {
    total_amount: number;
    total_amount_formatted: string;
    total_invoices: number;
    resident_count: number;
    overdue_amount: number;
    overdue_amount_formatted: string;
    overdue_count: number;
};

type Props = {
    invoices: Omit<Pagination<ArrearsItem>, 'per_page'>;
    filters: { q?: string; overdue_only?: string; period?: string };
    summary: ArrearsSummary;
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Data Tunggakan', href: arrearsRoutes.index() },
];

export default function ArrearsIndex({
    invoices,
    filters,
    summary,
}: Props) {
    const [search, setSearch] = useState(filters.q ?? '');
    const isOverdueOnly = filters.overdue_only === '1';

    // Pencarian dengan debounce
    useEffect(() => {
        const timer = setTimeout(() => {
            if (search !== (filters.q ?? '')) {
                applyFilters({ q: search || undefined });
            }
        }, 350);

        return () => clearTimeout(timer);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [search]);

    function applyFilters(next: Record<string, string | undefined>) {
        const merged = { ...filters, ...next };
        const query = Object.fromEntries(
            Object.entries(merged).filter(([, v]) => v !== undefined && v !== ''),
        );

        router.get(arrearsRoutes.index(), query, {
            preserveState: true,
            replace: true,
        });
    }

    return (
        <>
            <Head title="Data Tunggakan Pembayaran" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <Heading
                    title="Data Tunggakan Pembayaran"
                    description="Pantau daftar penghuni yang belum melunasi sewa, cari nama atau kamar, dan lihat total nominal tunggakan."
                />

                {/* Ringkasan metrik tunggakan */}
                <div className="grid gap-4 sm:grid-cols-3">
                    <Card className="py-0">
                        <CardContent className="px-5 py-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                    Total Menunggak
                                </p>
                                <div className="rounded-lg bg-red-500/10 p-2 text-red-600 dark:text-red-400">
                                    <AlertCircle className="size-4" />
                                </div>
                            </div>
                            <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-red-600 dark:text-red-400">
                                {summary.total_amount_formatted}
                            </p>
                            <p className="mt-1 text-xs text-muted-foreground">
                                Dari {summary.total_invoices} tagihan belum lunas
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="py-0">
                        <CardContent className="px-5 py-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                    Penghuni Menunggak
                                </p>
                                <div className="rounded-lg bg-amber-500/10 p-2 text-amber-600 dark:text-amber-400">
                                    <UserX className="size-4" />
                                </div>
                            </div>
                            <p className="mt-2 font-serif text-2xl font-bold tracking-tight">
                                {summary.resident_count}{' '}
                                <span className="text-sm font-normal text-muted-foreground">
                                    orang
                                </span>
                            </p>
                            <p className="mt-1 text-xs text-muted-foreground">
                                Penghuni dengan tagihan terbuka
                            </p>
                        </CardContent>
                    </Card>

                    <Card className="py-0">
                        <CardContent className="px-5 py-4">
                            <div className="flex items-center justify-between">
                                <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                    Lewat Jatuh Tempo
                                </p>
                                <div className="rounded-lg bg-orange-500/10 p-2 text-orange-600 dark:text-orange-400">
                                    <Clock className="size-4" />
                                </div>
                            </div>
                            <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-orange-600 dark:text-orange-400">
                                {summary.overdue_amount_formatted}
                            </p>
                            <p className="mt-1 text-xs text-muted-foreground">
                                {summary.overdue_count} tagihan telah melewati jatuh tempo
                            </p>
                        </CardContent>
                    </Card>
                </div>

                {/* Filter & pencarian */}
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <div className="flex flex-wrap items-center gap-2">
                        <Button
                            variant={!isOverdueOnly ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => applyFilters({ overdue_only: undefined })}
                        >
                            Semua Belum Bayar ({summary.total_invoices})
                        </Button>
                        <Button
                            variant={isOverdueOnly ? 'default' : 'outline'}
                            size="sm"
                            onClick={() => applyFilters({ overdue_only: '1' })}
                        >
                            Lewat Jatuh Tempo ({summary.overdue_count})
                        </Button>
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                        <div className="relative w-full max-w-sm sm:w-72">
                            <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                            <Input
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                placeholder="Cari nama penghuni atau kamar..."
                                className="pl-9 text-sm"
                            />
                        </div>
                    </div>
                </div>

                {/* Tabel Data Tunggakan */}
                <div className="overflow-hidden rounded-xl border bg-card shadow-xs">
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-12">#</TableHead>
                                <TableHead>Penghuni</TableHead>
                                <TableHead>Kamar</TableHead>
                                <TableHead>Periode Tagihan</TableHead>
                                <TableHead>Jatuh Tempo</TableHead>
                                <TableHead className="text-right">Nominal</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {invoices.data.map((item, index) => (
                                <TableRow key={item.id}>
                                    <TableCell className="font-mono text-xs text-muted-foreground">
                                        {index + 1}
                                    </TableCell>
                                    <TableCell>
                                        <p className="font-medium text-foreground">
                                            {item.resident_name}
                                        </p>
                                        {item.phone && (
                                            <p className="font-mono text-xs text-muted-foreground">
                                                {item.phone}
                                            </p>
                                        )}
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant="outline" className="font-medium">
                                            Kamar {item.room_number}
                                        </Badge>
                                        <p className="text-xs text-muted-foreground mt-0.5">
                                            {item.room_type}
                                        </p>
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex items-center gap-2">
                                            <span className="font-medium">
                                                {item.period_label}
                                            </span>
                                            {item.booking_duration_months && (
                                                <Badge variant="secondary" className="text-[0.65rem]">
                                                    Paket {item.booking_duration_months} Bln
                                                </Badge>
                                            )}
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <span className="text-sm">
                                            {item.due_date_formatted}
                                        </span>
                                        {item.is_overdue ? (
                                            <Badge variant="destructive" className="ml-2 text-[0.65rem]">
                                                Terlambat
                                            </Badge>
                                        ) : (
                                            <Badge variant="secondary" className="ml-2 text-[0.65rem]">
                                                Belum Tempo
                                            </Badge>
                                        )}
                                    </TableCell>
                                    <TableCell className="text-right font-serif font-bold text-red-600 dark:text-red-400">
                                        {item.amount_formatted}
                                    </TableCell>
                                </TableRow>
                            ))}

                            {invoices.data.length === 0 && (
                                <TableRow>
                                    <TableCell
                                        colSpan={6}
                                        className="py-12 text-center text-muted-foreground"
                                    >
                                        <div className="flex flex-col items-center justify-center gap-2">
                                            <CheckCircle2 className="size-8 text-teal-600 dark:text-teal-400" />
                                            <p className="font-medium text-foreground">
                                                Tidak ada data tunggakan
                                            </p>
                                            <p className="text-xs">
                                                Semua penghuni sudah melunasi pembayaran sewa atau filter pencarian tidak menemukan hasil.
                                            </p>
                                        </div>
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </div>
            </div>
        </>
    );
}

ArrearsIndex.layout = { breadcrumbs };

