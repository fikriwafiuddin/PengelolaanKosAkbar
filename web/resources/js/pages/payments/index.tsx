import { useEffect, useState } from 'react';
import { Head, router, usePage } from '@inertiajs/react';
import { CheckCircle2, ReceiptText, Search, XCircle } from 'lucide-react';
import { toast } from 'sonner';

import Heading from '@/components/heading';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { cn } from '@/lib/utils';
import { dashboard } from '@/routes';
import * as paymentsRoutes from '@/routes/payments';
import * as paymentsVerification from '@/routes/payments/verification';
import type { BreadcrumbItem } from '@/types';
import type { Pagination, Payment } from '@/types/kost';

type Props = {
    payments: Omit<Pagination<Payment>, 'per_page'>;
    filters: { status?: string; q?: string; month?: string };
    statusCounts: Record<string, number>;
    verifiedTotal: number;
};

/**
 * Tab status pembayaran + badge warnanya.
 */
const STATUS_TABS: { value: string; label: string; className: string }[] = [
    {
        value: 'pending',
        label: 'Menunggu Verifikasi',
        className: 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    },
    {
        value: 'terverifikasi',
        label: 'Terverifikasi',
        className: 'bg-teal-600/10 text-teal-700 dark:text-teal-400',
    },
    {
        value: 'ditolak',
        label: 'Ditolak',
        className: 'bg-red-500/10 text-red-700 dark:text-red-400',
    },
];

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Verifikasi Pembayaran', href: paymentsRoutes.index() },
];

export default function PaymentsIndex({
    payments: paymentPagination,
    filters,
    statusCounts,
    verifiedTotal,
}: Props) {
    const { flash } = usePage().props;
    const [search, setSearch] = useState(filters.q ?? '');
    const [proofPayment, setProofPayment] = useState<Payment | null>(null);

    const activeStatus = filters.status ?? 'pending';

    // Notifikasi hasil verifikasi (flash message dari controller).
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

        router.get(paymentsRoutes.index(), query, {
            preserveState: true,
            replace: true,
        });
    }

    /**
     * Aksi admin: terima / tolak pembayaran penghuni.
     */
    function verifyPayment(payment: Payment, status: 'terverifikasi' | 'ditolak') {
        const label = status === 'terverifikasi' ? 'menerima' : 'menolak';

        if (
            !window.confirm(
                `Yakin ${label} pembayaran ${payment.resident_name ?? 'penghuni ini'} sebesar ${payment.amount_formatted}?`,
            )
        ) {
            return;
        }

        router.put(
            paymentsVerification.update({ payment: payment.id }),
            { status },
            { preserveScroll: true },
        );
    }

    return (
        <>
            <Head title="Verifikasi Pembayaran" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <Heading
                    title="Verifikasi Pembayaran"
                    description="Periksa nominal dan bukti bayar penghuni, terbitkan kuitansi saat diterima."
                />

                {/* Tab status + filter periode + pencarian */}
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <div className="flex flex-wrap items-center gap-2">
                        {[
                            ...STATUS_TABS,
                            {
                                value: 'semua',
                                label: 'Semua Transaksi',
                                className: 'bg-secondary text-secondary-foreground',
                            },
                        ].map((tab) => {
                            const isActive = activeStatus === tab.value;

                            return (
                                <button
                                    key={tab.value}
                                    type="button"
                                    onClick={() =>
                                        applyFilters({ status: tab.value })
                                    }
                                    className={cn(
                                        'inline-flex items-center gap-2 rounded-full border px-3.5 py-1.5 text-sm font-medium transition-colors',
                                        isActive
                                            ? 'border-primary bg-primary text-primary-foreground'
                                            : 'bg-background text-muted-foreground hover:bg-muted',
                                    )}
                                >
                                    {tab.label}
                                    <span
                                        className={cn(
                                            'rounded-full px-1.5 text-xs font-semibold',
                                            isActive
                                                ? 'bg-primary-foreground/20'
                                                : 'bg-muted',
                                        )}
                                    >
                                        {tab.value === 'semua'
                                            ? Object.values(statusCounts).reduce(
                                                  (sum, count) => sum + count,
                                                  0,
                                              )
                                            : (statusCounts[tab.value] ?? 0)}
                                    </span>
                                </button>
                            );
                        })}
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                        <Input
                            type="month"
                            className="w-44"
                            value={filters.month ?? ''}
                            onChange={(e) =>
                                applyFilters({
                                    month: e.target.value || undefined,
                                })
                            }
                            title="Filter periode tagihan"
                        />
                        <div className="relative w-full max-w-sm sm:w-auto">
                            <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                            <Input
                                className="w-full pl-9 sm:w-72"
                                placeholder="Cari nama penghuni / nomor kamar..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                            />
                        </div>
                    </div>
                </div>

                {/* Total transaksi terverifikasi sesuai filter */}
                <div className="-mt-2 flex items-center gap-2 text-sm text-muted-foreground">
                    <ReceiptText className="size-4 text-teal-600" />
                    <span>
                        Total pembayaran terverifikasi pada filter ini:{' '}
                        <strong className="text-foreground">
                            Rp{' '}
                            {verifiedTotal.toLocaleString('id-ID', {
                                maximumFractionDigits: 0,
                            })}
                        </strong>
                    </span>
                </div>

                {/* Tabel pembayaran */}
                <Card className="py-0">
                    <CardContent className="px-0">
                        <Table>
                            <TableHeader>
                                <TableRow className="hover:bg-transparent">
                                    <TableHead className="pl-6">Penghuni</TableHead>
                                    <TableHead>Tagihan</TableHead>
                                    <TableHead>Nominal</TableHead>
                                    <TableHead>Bukti Bayar</TableHead>
                                    <TableHead>Waktu Bayar</TableHead>
                                    <TableHead>Status</TableHead>
                                    <TableHead className="pr-6 text-right">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {paymentPagination.data.map((payment) => (
                                    <TableRow key={payment.id}>
                                        <TableCell className="pl-6">
                                            <p className="font-medium">
                                                {payment.resident_name ?? '-'}
                                            </p>
                                            <p className="text-xs text-muted-foreground">
                                                Kamar {payment.room_number ?? '-'} ·{' '}
                                                {payment.method_label}
                                            </p>
                                        </TableCell>
                                        <TableCell>
                                            <p className="text-sm font-medium">
                                                {payment.invoice?.period_label ??
                                                    payment.invoice?.period}
                                            </p>
                                            <p className="text-xs text-muted-foreground">
                                                Jatuh tempo{' '}
                                                {payment.invoice?.due_date_formatted}
                                            </p>
                                        </TableCell>
                                        <TableCell className="font-semibold">
                                            {payment.amount_formatted}
                                        </TableCell>
                                        <TableCell>
                                            {payment.proof_url ? (
                                                <button
                                                    type="button"
                                                    className="overflow-hidden rounded-md border transition-opacity hover:opacity-80"
                                                    onClick={() =>
                                                        setProofPayment(payment)
                                                    }
                                                >
                                                    <img
                                                        src={payment.proof_url}
                                                        alt={`Bukti bayar ${payment.resident_name ?? ''}`}
                                                        className="h-10 w-14 object-cover"
                                                    />
                                                </button>
                                            ) : (
                                                <span className="text-xs text-muted-foreground">
                                                    Tunai (tanpa bukti)
                                                </span>
                                            )}
                                        </TableCell>
                                        <TableCell className="text-sm text-muted-foreground">
                                            {payment.paid_at_formatted ?? '-'}
                                        </TableCell>
                                        <TableCell>
                                            <Badge
                                                variant="secondary"
                                                className={cn(
                                                    'whitespace-nowrap',
                                                    STATUS_TABS.find(
                                                        (tab) =>
                                                            tab.value ===
                                                            payment.status,
                                                    )?.className,
                                                )}
                                            >
                                                {payment.status_label}
                                            </Badge>
                                            {payment.status === 'terverifikasi' && (
                                                <p className="mt-1 font-mono text-[0.65rem] text-muted-foreground">
                                                    {payment.receipt_no}
                                                </p>
                                            )}
                                            {payment.status === 'ditolak' &&
                                                payment.verified_at_formatted && (
                                                    <p className="mt-1 text-[0.65rem] text-muted-foreground">
                                                        {payment.verified_at_formatted}
                                                    </p>
                                                )}
                                        </TableCell>
                                        <TableCell className="pr-6">
                                            {payment.status === 'pending' ? (
                                                <div className="flex items-center justify-end gap-1">
                                                    <Button
                                                        size="sm"
                                                        className="h-8"
                                                        onClick={() =>
                                                            verifyPayment(
                                                                payment,
                                                                'terverifikasi',
                                                            )
                                                        }
                                                    >
                                                        <CheckCircle2 className="size-3.5" />
                                                        Terima
                                                    </Button>
                                                    <Button
                                                        size="sm"
                                                        variant="outline"
                                                        className="h-8 text-destructive hover:text-destructive"
                                                        onClick={() =>
                                                            verifyPayment(
                                                                payment,
                                                                'ditolak',
                                                            )
                                                        }
                                                    >
                                                        <XCircle className="size-3.5" />
                                                        Tolak
                                                    </Button>
                                                </div>
                                            ) : payment.status ===
                                              'terverifikasi' ? (
                                                <Button
                                                    size="sm"
                                                    variant="outline"
                                                    className="h-8"
                                                    asChild
                                                >
                                                    <a
                                                        href={paymentsRoutes.receipt.url(
                                                            { payment: payment.id },
                                                        )}
                                                    >
                                                        <ReceiptText className="size-3.5" />
                                                        Kuitansi
                                                    </a>
                                                </Button>
                                            ) : (
                                                <span className="block text-right text-xs text-muted-foreground">
                                                    -
                                                </span>
                                            )}
                                        </TableCell>
                                    </TableRow>
                                ))}

                                {paymentPagination.data.length === 0 && (
                                    <TableRow>
                                        <TableCell
                                            colSpan={7}
                                            className="py-10 text-center text-muted-foreground"
                                        >
                                            Tidak ada pembayaran pada status ini.
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
                        Menampilkan {paymentPagination.from ?? 0}–
                        {paymentPagination.to ?? 0} dari {paymentPagination.total}{' '}
                        pembayaran
                    </span>
                    <div className="flex items-center gap-2">
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={paymentPagination.current_page <= 1}
                            onClick={() =>
                                router.get(
                                    paymentsRoutes.index(),
                                    {
                                        page:
                                            paymentPagination.current_page - 1,
                                        ...filters,
                                    },
                                    { preserveState: true },
                                )
                            }
                        >
                            Sebelumnya
                        </Button>
                        <span>
                            {paymentPagination.current_page} /{' '}
                            {paymentPagination.last_page}
                        </span>
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={
                                paymentPagination.current_page >=
                                paymentPagination.last_page
                            }
                            onClick={() =>
                                router.get(
                                    paymentsRoutes.index(),
                                    {
                                        page:
                                            paymentPagination.current_page + 1,
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

            {/* Pratinjau bukti bayar */}
            <Dialog
                open={proofPayment !== null}
                onOpenChange={(open) => !open && setProofPayment(null)}
            >
                <DialogContent className="sm:max-w-lg">
                    <DialogHeader>
                        <DialogTitle>
                            Bukti Bayar — {proofPayment?.resident_name}
                        </DialogTitle>
                        <DialogDescription>
                            Tagihan {proofPayment?.invoice?.period_label} ·{' '}
                            {proofPayment?.amount_formatted} ·{' '}
                            {proofPayment?.method_label}
                        </DialogDescription>
                    </DialogHeader>
                    {proofPayment?.proof_url && (
                        <img
                            src={proofPayment.proof_url}
                            alt="Bukti pembayaran"
                            className="max-h-[60vh] w-full rounded-md border object-contain"
                        />
                    )}
                </DialogContent>
            </Dialog>
        </>
    );
}

PaymentsIndex.layout = { breadcrumbs };
