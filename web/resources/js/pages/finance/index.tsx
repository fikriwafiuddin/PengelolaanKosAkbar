import { Head, router } from '@inertiajs/react';
import {
    ArrowDownRight,
    ArrowUpRight,
    FileText,
    Printer,
    TrendingUp,
    Wallet,
} from 'lucide-react';
import {
    Bar,
    CartesianGrid,
    Cell,
    ComposedChart,
    Line,
    Pie,
    PieChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis,
} from 'recharts';

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

type ExpenseCategoryRow = {
    category: string;
    total_items: number;
    total_amount: number;
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
    expenseByCategory: ExpenseCategoryRow[];
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Laporan Keuangan', href: financeRoutes.index() },
];

const rupiah = (value: number) =>
    'Rp ' + value.toLocaleString('id-ID', { maximumFractionDigits: 0 });

/** Nominal ringkas untuk label sumbu grafik (1,2 jt / 450 rb). */
const compactRupiah = (value: number) => {
    if (Math.abs(value) >= 1_000_000) {
        return (
            (value / 1_000_000).toLocaleString('id-ID', {
                maximumFractionDigits: 1,
            }) + ' jt'
        );
    }

    if (Math.abs(value) >= 1_000) {
        return Math.round(value / 1_000) + ' rb';
    }

    return String(value);
};

/** Label bulan penuh dari periode YYYY-MM (untuk tooltip grafik). */
const fullMonthLabel = (period: string) =>
    new Date(`${period}-01T00:00:00`).toLocaleDateString('id-ID', {
        month: 'long',
        year: 'numeric',
    });

/** Warna seri grafik — token tema, otomatis ikut dark mode. */
const INCOME_COLOR = 'var(--chart-2)'; // teal
const EXPENSE_COLOR = 'var(--destructive)'; // merah bata
const PROFIT_COLOR = 'var(--chart-5)'; // oranye
const CATEGORY_COLORS = [
    'var(--chart-1)',
    'var(--chart-2)',
    'var(--chart-3)',
    'var(--chart-4)',
    'var(--chart-5)',
];

/**
 * Laporan Keuangan: ringkasan pemasukan-pengeluaran-laba,
 * grafik tren 6 bulan & komposisi pengeluaran per kategori,
 * laporan pembayaran sewa, dan ekspor CSV.
 * Pencatatan pengeluaran dipindah ke halaman /expenses (Rev-2).
 */
export default function FinanceIndex({
    month,
    summary,
    months,
    trend,
    paymentReport,
    expenseByCategory,
}: Props) {
    function changeMonth(next: string) {
        router.get(
            financeRoutes.index(),
            { month: next },
            { preserveState: true },
        );
    }

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
                                href={financeRoutes.print.url({
                                    query: { type: 'pembayaran', month },
                                })}
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                <FileText className="size-4" />
                                Cetak PDF Pembayaran
                            </a>
                        </Button>
                        <Button variant="outline" asChild>
                            <a
                                href={financeRoutes.print.url({
                                    query: { type: 'kas', month },
                                })}
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                <Printer className="size-4" />
                                Cetak PDF Kas & Laba
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
                                      ((summary.expense -
                                          summary.previous_expense) /
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
                                      ((summary.profit -
                                          summary.previous_profit) /
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

                {/* Grafik: tren 6 bulan + komposisi pengeluaran */}
                <div className="grid gap-4 xl:grid-cols-5">
                    <Card className="py-0 xl:col-span-3">
                        <CardContent className="px-6 py-5">
                            <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Tren 6 Bulan — Pemasukan vs Pengeluaran
                            </p>
                            <div className="mt-4 h-64">
                                <ResponsiveContainer width="100%" height="100%">
                                    <ComposedChart
                                        data={trend}
                                        margin={{
                                            top: 8,
                                            right: 8,
                                            left: 0,
                                            bottom: 0,
                                        }}
                                    >
                                        <CartesianGrid
                                            strokeDasharray="3 3"
                                            vertical={false}
                                            stroke="var(--border)"
                                        />
                                        <XAxis
                                            dataKey="month_label"
                                            tickLine={false}
                                            axisLine={false}
                                            tickMargin={8}
                                            tick={{
                                                fontSize: 11,
                                                fill: 'var(--muted-foreground)',
                                            }}
                                        />
                                        <YAxis
                                            width={52}
                                            tickLine={false}
                                            axisLine={false}
                                            tick={{
                                                fontSize: 11,
                                                fill: 'var(--muted-foreground)',
                                            }}
                                            tickFormatter={compactRupiah}
                                            domain={[
                                                (dataMin: number) =>
                                                    Math.min(dataMin, 0),
                                                (dataMax: number) =>
                                                    Math.max(dataMax, 0),
                                            ]}
                                        />
                                        <Tooltip
                                            content={<TrendTooltip />}
                                            cursor={{ fill: 'var(--accent)' }}
                                        />
                                        <Bar
                                            dataKey="income"
                                            name="Pemasukan"
                                            fill={INCOME_COLOR}
                                            radius={[4, 4, 0, 0]}
                                            maxBarSize={26}
                                        />
                                        <Bar
                                            dataKey="expense"
                                            name="Pengeluaran"
                                            fill={EXPENSE_COLOR}
                                            radius={[4, 4, 0, 0]}
                                            maxBarSize={26}
                                        />
                                        <Line
                                            dataKey="profit"
                                            name="Laba"
                                            stroke={PROFIT_COLOR}
                                            strokeWidth={2}
                                            dot={false}
                                            activeDot={{ r: 4 }}
                                        />
                                    </ComposedChart>
                                </ResponsiveContainer>
                            </div>
                            <div className="mt-3 flex flex-wrap items-center gap-4 text-xs text-muted-foreground">
                                <span className="flex items-center gap-1.5">
                                    <span
                                        className="size-2.5 rounded-sm"
                                        style={{
                                            backgroundColor: INCOME_COLOR,
                                        }}
                                    />
                                    Pemasukan
                                </span>
                                <span className="flex items-center gap-1.5">
                                    <span
                                        className="size-2.5 rounded-sm"
                                        style={{
                                            backgroundColor: EXPENSE_COLOR,
                                        }}
                                    />
                                    Pengeluaran
                                </span>
                                <span className="flex items-center gap-1.5">
                                    <span
                                        className="size-2.5 rounded-full"
                                        style={{
                                            backgroundColor: PROFIT_COLOR,
                                        }}
                                    />
                                    Laba
                                </span>
                            </div>
                        </CardContent>
                    </Card>

                    <Card className="py-0 xl:col-span-2">
                        <CardContent className="px-6 py-5">
                            <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Komposisi Pengeluaran — {summary.month_label}
                            </p>
                            {expenseByCategory.length > 0 ? (
                                <div className="mt-4 flex flex-col items-center gap-5">
                                    <div className="relative h-40 w-40 shrink-0">
                                        <ResponsiveContainer
                                            width="100%"
                                            height="100%"
                                        >
                                            <PieChart>
                                                <Tooltip
                                                    content={
                                                        <CategoryTooltip
                                                            total={
                                                                summary.expense
                                                            }
                                                        />
                                                    }
                                                />
                                                <Pie
                                                    data={expenseByCategory}
                                                    dataKey="total_amount"
                                                    nameKey="category"
                                                    innerRadius="60%"
                                                    outerRadius="96%"
                                                    paddingAngle={2}
                                                    stroke="var(--card)"
                                                    strokeWidth={2}
                                                >
                                                    {expenseByCategory.map(
                                                        (entry, index) => (
                                                            <Cell
                                                                key={
                                                                    entry.category
                                                                }
                                                                fill={
                                                                    CATEGORY_COLORS[
                                                                        index %
                                                                            CATEGORY_COLORS.length
                                                                    ]
                                                                }
                                                            />
                                                        ),
                                                    )}
                                                </Pie>
                                            </PieChart>
                                        </ResponsiveContainer>
                                        <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
                                            <span className="text-[0.65rem] text-muted-foreground">
                                                Total
                                            </span>
                                            <span className="text-sm font-bold">
                                                {compactRupiah(summary.expense)}
                                            </span>
                                        </div>
                                    </div>
                                    <div className="w-full space-y-2.5">
                                        {expenseByCategory.map(
                                            (entry, index) => {
                                                const share =
                                                    summary.expense > 0
                                                        ? (entry.total_amount /
                                                              summary.expense) *
                                                          100
                                                        : 0;

                                                return (
                                                    <div
                                                        key={entry.category}
                                                        className="flex items-center gap-2 text-sm"
                                                    >
                                                        <span
                                                            className="size-2.5 shrink-0 rounded-sm"
                                                            style={{
                                                                backgroundColor:
                                                                    CATEGORY_COLORS[
                                                                        index %
                                                                            CATEGORY_COLORS.length
                                                                    ],
                                                            }}
                                                        />
                                                        <span className="min-w-0 flex-1 truncate">
                                                            {entry.category}
                                                            <span className="text-xs text-muted-foreground">
                                                                {' '}
                                                                (
                                                                {
                                                                    entry.total_items
                                                                }
                                                                x)
                                                            </span>
                                                        </span>
                                                        <span className="shrink-0 font-semibold">
                                                            {rupiah(
                                                                entry.total_amount,
                                                            )}
                                                        </span>
                                                        <span className="w-11 shrink-0 text-right text-xs text-muted-foreground">
                                                            {Math.round(share)}%
                                                        </span>
                                                    </div>
                                                );
                                            },
                                        )}
                                    </div>
                                </div>
                            ) : (
                                <div className="flex h-40 items-center justify-center">
                                    <p className="text-sm text-muted-foreground">
                                        Belum ada pengeluaran bulan ini.
                                    </p>
                                </div>
                            )}
                        </CardContent>
                    </Card>
                </div>

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
 * Tooltip grafik tren: rincian pemasukan, pengeluaran, dan laba
 * bulan yang di-hover.
 */
function TrendTooltip({
    active,
    payload,
}: {
    active?: boolean;
    payload?: Array<{ payload: TrendPoint }>;
}) {
    if (!active || !payload?.length) {
        return null;
    }

    const point = payload[0]?.payload;

    if (!point) {
        return null;
    }

    return (
        <div className="rounded-lg border bg-popover px-3 py-2 text-xs text-popover-foreground shadow-md">
            <p className="font-semibold">{fullMonthLabel(point.month)}</p>
            <div className="mt-1.5 space-y-1">
                <TrendTooltipRow
                    label="Pemasukan"
                    value={point.income}
                    color={INCOME_COLOR}
                />
                <TrendTooltipRow
                    label="Pengeluaran"
                    value={point.expense}
                    color={EXPENSE_COLOR}
                />
                <TrendTooltipRow
                    label="Laba"
                    value={point.profit}
                    color={PROFIT_COLOR}
                />
            </div>
        </div>
    );
}

function TrendTooltipRow({
    label,
    value,
    color,
}: {
    label: string;
    value: number;
    color: string;
}) {
    return (
        <div className="flex items-center justify-between gap-6">
            <span className="flex items-center gap-1.5 text-muted-foreground">
                <span
                    className="size-2 rounded-sm"
                    style={{ backgroundColor: color }}
                />
                {label}
            </span>
            <span
                className={cn('font-semibold', value < 0 && 'text-destructive')}
            >
                {rupiah(value)}
            </span>
        </div>
    );
}

/**
 * Tooltip donat komposisi pengeluaran: kategori, jumlah catatan,
 * dan persentase terhadap total.
 */
function CategoryTooltip({
    active,
    payload,
    total,
}: {
    active?: boolean;
    payload?: Array<{ value: number; payload: ExpenseCategoryRow }>;
    total: number;
}) {
    if (!active || !payload?.length) {
        return null;
    }

    const entry = payload[0];
    const row = entry?.payload;

    if (!entry || !row) {
        return null;
    }

    const share = total > 0 ? Math.round((entry.value / total) * 100) : 0;

    return (
        <div className="rounded-lg border bg-popover px-3 py-2 text-xs text-popover-foreground shadow-md">
            <p className="font-semibold">{row.category}</p>
            <p className="mt-0.5 text-muted-foreground">
                {row.total_items} catatan · {share}%
            </p>
            <p className="font-semibold">{rupiah(entry.value)}</p>
        </div>
    );
}

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
                        {change >= 0 ? '▲' : '▼'} {Math.abs(change)}% vs bulan
                        lalu
                    </p>
                )}
            </CardContent>
        </Card>
    );
}
