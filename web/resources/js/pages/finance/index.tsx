import { Head, router } from '@inertiajs/react';
import {
    ArrowDownRight,
    ArrowUpRight,
    Download,
    TrendingUp,
    Wallet,
} from 'lucide-react';

import Heading from '@/components/heading';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { dashboard } from '@/routes';
import * as financeRoutes from '@/routes/finance';
import * as expensesRoutes from '@/routes/expenses';
import type { BreadcrumbItem } from '@/types';

type MonthOption = { value: string; label: string };

type Summary = {
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

type TrendPoint = {
    month: string;
    month_label: string;
    income: number;
    expense: number;
    profit: number;
};

type PaymentReportRow = {
    id: number;
    resident_name: string;
    room_number: string | null;
    period: string;
    amount: number;
    method_label: string;
    receipt_no: string | null;
    paid_at_formatted: string | null;
};

type Props = {
    month: string;
    summary: Summary;
    months: MonthOption[];
    trend: TrendPoint[];
    paymentReport: PaymentReportRow[];
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Laporan Keuangan', href: financeRoutes.index() },
];

const rupiah = (value: number) =>
    'Rp ' + value.toLocaleString('id-ID', { maximumFractionDigits: 0 });

/**
 * Laporan Keuangan: ringkasan pemasukan-pengeluaran-laba,
 * tren 6 bulan, laporan pembayaran sewa, dan ekspor CSV.
 * Pencatatan pengeluaran dipindah ke halaman /expenses (Rev-2).
 */
export default function FinanceIndex({
    month,
    summary,
    months,
    trend,
    paymentReport,
}: Props) {
    function changeMonth(next: string) {
        router.get(
            financeRoutes.index(),
            { month: next },
            { preserveState: true },
        );
    }

    const maxTrend = Math.max(...trend.map((t) => Math.max(t.income, t.expense)), 1);

    return (
        <>
            <Head title="Laporan Keuangan" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <Heading
                        title="Laporan Keuangan"
                        description="Rekap kas pemasukan sewa, pengeluaran operasional, dan laba bulanan."
                    />
                    <div className="flex flex-wrap items-center gap-2">
                        <select
                            value={month}
                            onChange={(e) => changeMonth(e.target.value)}
                            className="h-9 rounded-md border border-input bg-background px-3 text-sm"
                        >
                            {months.map((option) => (
                                <option key={option.value} value={option.value}>
                                    {option.label}
                                </option>
                            ))}
                        </select>
                        <Button variant="outline" asChild>
                            <a
                                href={financeRoutes.exportMethod.url({
                                    query: { type: 'pembayaran', month },
                                })}
                            >
                                <Download className="size-4" />
                                Ekspor Pembayaran
                            </a>
                        </Button>
                        <Button variant="outline" asChild>
                            <a
                                href={financeRoutes.exportMethod.url({
                                    query: { type: 'kas', month },
                                })}
                            >
                                <Download className="size-4" />
                                Ekspor Kas
                            </a>
                        </Button>
                        {/* <Button variant="outline" asChild>
                            <a href={expensesRoutes.index.url()}>
                                <Wallet className="size-4" />
                                Pengeluaran
                            </a>
                        </Button> */}
                    </div>
                </div>

                {/* Kartu ringkasan */}
                <div className="grid gap-4 md:grid-cols-3">
                    <SummaryCard
                        label="Pemasukan Sewa"
                        value={summary.income}
                        change={summary.income_change}
                        icon={<ArrowUpRight className="size-4" />}
                        tone="income"
                    />
                    <SummaryCard
                        label="Pengeluaran"
                        value={summary.expense}
                        change={
                            summary.previous_expense > 0
                                ? Math.round(
                                    ((summary.expense - summary.previous_expense) /
                                        summary.previous_expense) *
                                    100 *
                                    10,
                                ) / 10
                                : null
                        }
                        icon={<ArrowDownRight className="size-4" />}
                        tone="expense"
                    />
                    <SummaryCard
                        label={`Laba ${summary.month_label}`}
                        value={summary.profit}
                        change={
                            summary.previous_profit !== 0
                                ? Math.round(
                                    ((summary.profit - summary.previous_profit) /
                                        Math.abs(summary.previous_profit)) *
                                    100 *
                                    10,
                                ) / 10
                                : null
                        }
                        icon={<TrendingUp className="size-4" />}
                        tone="profit"
                    />
                </div>

                {/* Tren 6 bulan */}
                {/* <Card className="py-0">
                    <CardContent className="px-6 py-5">
                        <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                            Tren 6 Bulan (pemasukan vs pengeluaran)
                        </p>
                        <div className="mt-4 flex items-end justify-between gap-3">
                            {trend.map((point) => (
                                <div
                                    key={point.month}
                                    className="flex flex-1 flex-col items-center gap-1.5"
                                    title={`${point.month_label}: ${rupiah(point.income)} masuk · ${rupiah(point.expense)} keluar · laba ${rupiah(point.profit)}`}
                                >
                                    <div className="flex h-32 w-full items-end justify-center gap-1.5">
                                        <div
                                            className="w-1/3 rounded-t bg-teal-600/80"
                                            style={{
                                                height: `${Math.max((point.income / maxTrend) * 100, 2)}%`,
                                            }}
                                        />
                                        <div
                                            className="w-1/3 rounded-t bg-red-400/70"
                                            style={{
                                                height: `${Math.max((point.expense / maxTrend) * 100, 2)}%`,
                                            }}
                                        />
                                    </div>
                                    <span
                                        className={cn(
                                            'text-[0.7rem]',
                                            point.month === month
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
                </Card> */}

                {/* Laporan pembayaran sewa */}
                <Card className="py-0">
                    <CardContent className="px-0 py-5">
                        <p className="px-6 pb-3 text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                            Laporan Pembayaran Sewa — {summary.month_label} (
                            {paymentReport.length} transaksi)
                        </p>
                        <div className="max-h-96 overflow-y-auto">
                            <table className="w-full text-sm">
                                <thead className="sticky top-0 bg-card">
                                    <tr className="border-b text-left text-xs text-muted-foreground">
                                        <th className="px-6 py-2 font-medium">
                                            Penghuni
                                        </th>
                                        <th className="px-3 py-2 font-medium">
                                            Kamar
                                        </th>
                                        <th className="px-3 py-2 font-medium">
                                            Metode
                                        </th>
                                        <th className="px-6 py-2 text-right font-medium">
                                            Nominal
                                        </th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {paymentReport.map((row) => (
                                        <tr
                                            key={row.id}
                                            className="border-b border-border/50"
                                        >
                                            <td className="px-6 py-2.5">
                                                <p className="font-medium">
                                                    {row.resident_name}
                                                </p>
                                                <p className="font-mono text-[0.65rem] text-muted-foreground">
                                                    {row.receipt_no}
                                                </p>
                                            </td>
                                            <td className="px-3 py-2.5 text-muted-foreground">
                                                {row.room_number ?? '-'}
                                            </td>
                                            <td className="px-3 py-2.5">
                                                <span className="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold">
                                                    {row.method_label}
                                                </span>
                                            </td>
                                            <td className="px-6 py-2.5 text-right font-semibold">
                                                {rupiah(row.amount)}
                                            </td>
                                        </tr>
                                    ))}
                                    {paymentReport.length === 0 && (
                                        <tr>
                                            <td
                                                colSpan={4}
                                                className="px-6 py-8 text-center text-muted-foreground"
                                            >
                                                Belum ada pembayaran
                                                terverifikasi bulan ini.
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </>
    );
}

FinanceIndex.layout = { breadcrumbs };

/**
 * Kartu ringkasan: nominal besar + perubahan vs bulan lalu.
 */
function SummaryCard({
    label,
    value,
    change,
    icon,
    tone,
}: {
    label: string;
    value: number;
    change: number | null;
    icon: React.ReactNode;
    tone: 'income' | 'expense' | 'profit';
}) {
    const toneClass = {
        income: 'bg-teal-600/10 text-teal-700 dark:text-teal-400',
        expense: 'bg-red-500/10 text-red-600 dark:text-red-400',
        profit: 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    }[tone];

    return (
        <Card className="py-0">
            <CardContent className="px-6 py-5">
                <div className="flex items-center justify-between">
                    <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                        {label}
                    </p>
                    <div
                        className={cn(
                            'flex size-8 items-center justify-center rounded-lg',
                            toneClass,
                        )}
                    >
                        {icon}
                    </div>
                </div>
                <p className="mt-2 font-serif text-2xl font-bold tracking-tight">
                    {rupiah(value)}
                </p>
                {change !== null && (
                    <p
                        className={cn(
                            'mt-1 text-xs font-medium',
                            change >= 0
                                ? 'text-teal-600 dark:text-teal-400'
                                : 'text-red-600 dark:text-red-400',
                        )}
                    >
                        {change >= 0 ? '▲' : '▼'} {Math.abs(change)}% vs bulan lalu
                    </p>
                )}
            </CardContent>
        </Card>
    );
}
