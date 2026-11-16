import { useEffect, useState } from 'react';
import { Head, router, usePage } from '@inertiajs/react';
import { Plus, Trash2, Wallet } from 'lucide-react';
import { toast } from 'sonner';

import Heading from '@/components/heading';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { dashboard } from '@/routes';
import * as expensesRoutes from '@/routes/expenses';
import * as financeRoutes from '@/routes/finance';
import type { BreadcrumbItem } from '@/types';

type MonthOption = { value: string; label: string };

type Summary = {
    month: string;
    month_label: string;
    income: number;
    expense: number;
    profit: number;
};

type CategoryRow = {
    category: string;
    total_items: number;
    total_amount: number;
};

type ExpenseRow = {
    id: number;
    expense_date: string;
    expense_date_formatted: string;
    category: string;
    description: string | null;
    amount: number;
    amount_formatted: string;
    creator_name: string | null;
};

type Props = {
    month: string;
    summary: Summary;
    months: MonthOption[];
    expenseByCategory: CategoryRow[];
    expenses: ExpenseRow[];
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Laporan Keuangan', href: financeRoutes.index() },
    { title: 'Pengeluaran', href: expensesRoutes.index() },
];

const rupiah = (value: number) =>
    'Rp ' + value.toLocaleString('id-ID', { maximumFractionDigits: 0 });

/**
 * Halaman Pengeluaran Operasional — terpisah dari Laporan Keuangan (Rev-2).
 * Menampilkan rekap per kategori + daftar pengeluaran + tombol catat baru.
 */
export default function ExpensesIndex({
    month,
    summary,
    months,
    expenseByCategory,
    expenses,
}: Props) {
    const { flash } = usePage().props;
    const [expenseDialogOpen, setExpenseDialogOpen] = useState(false);

    useEffect(() => {
        if (flash?.success) toast.success(flash.success);
        if (flash?.error) toast.error(flash.error);
    }, [flash]);

    function changeMonth(next: string) {
        router.get(
            expensesRoutes.index(),
            { month: next },
            { preserveState: true },
        );
    }

    return (
        <>
            <Head title="Pengeluaran" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                {/* Header */}
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <Heading
                        title="Pengeluaran Operasional"
                        description="Catatan pengeluaran harian kos: listrik, kebersihan, perawatan, dan lainnya."
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
                        <Button
                            size="sm"
                            onClick={() => setExpenseDialogOpen(true)}
                        >
                            <Plus className="size-4" />
                            Catat Pengeluaran
                        </Button>
                    </div>
                </div>

                {/* Ringkasan bulan */}
                <div className="grid gap-4 sm:grid-cols-3">
                    <Card className="py-0">
                        <CardContent className="px-6 py-5">
                            <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Total Pengeluaran
                            </p>
                            <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-red-600 dark:text-red-400">
                                {rupiah(summary.expense)}
                            </p>
                            <p className="mt-1 text-xs text-muted-foreground">
                                {summary.month_label}
                            </p>
                        </CardContent>
                    </Card>
                    <Card className="py-0">
                        <CardContent className="px-6 py-5">
                            <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Pemasukan Sewa
                            </p>
                            <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-teal-600 dark:text-teal-400">
                                {rupiah(summary.income)}
                            </p>
                            <p className="mt-1 text-xs text-muted-foreground">
                                {summary.month_label}
                            </p>
                        </CardContent>
                    </Card>
                    <Card className="py-0">
                        <CardContent className="px-6 py-5">
                            <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Laba Bersih
                            </p>
                            <p className="mt-2 font-serif text-2xl font-bold tracking-tight text-amber-600 dark:text-amber-400">
                                {rupiah(summary.profit)}
                            </p>
                            <p className="mt-1 text-xs text-muted-foreground">
                                {summary.month_label}
                            </p>
                        </CardContent>
                    </Card>
                </div>

                <div className="grid gap-6 xl:grid-cols-5">
                    {/* Rekap per kategori */}
                    <Card className="py-0 xl:col-span-2">
                        <CardContent className="px-6 py-5">
                            <p className="pb-4 text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Rekap per Kategori — {summary.month_label}
                            </p>
                            {expenseByCategory.length > 0 ? (
                                <div className="space-y-3">
                                    {expenseByCategory.map((cat) => (
                                        <div key={cat.category}>
                                            <div className="flex justify-between text-sm">
                                                <span className="font-medium">
                                                    {cat.category}{' '}
                                                    <span className="text-muted-foreground font-normal">
                                                        ({cat.total_items}x)
                                                    </span>
                                                </span>
                                                <span className="font-semibold">
                                                    {rupiah(cat.total_amount)}
                                                </span>
                                            </div>
                                            <div className="mt-1.5 h-1.5 rounded-full bg-muted">
                                                <div
                                                    className="h-1.5 rounded-full bg-red-400/70"
                                                    style={{
                                                        width: `${Math.min(
                                                            (cat.total_amount /
                                                                Math.max(summary.expense, 1)) *
                                                                100,
                                                            100,
                                                        )}%`,
                                                    }}
                                                />
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            ) : (
                                <p className="py-8 text-center text-sm text-muted-foreground">
                                    Belum ada pengeluaran bulan ini.
                                </p>
                            )}
                        </CardContent>
                    </Card>

                    {/* Daftar pengeluaran */}
                    <Card className="py-0 xl:col-span-3">
                        <CardContent className="px-6 py-5">
                            <div className="flex items-center justify-between pb-4">
                                <p className="text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                    Daftar Pengeluaran — {summary.month_label}
                                </p>
                                <span className="text-xs text-muted-foreground">
                                    {expenses.length} catatan
                                </span>
                            </div>

                            <div className="max-h-[28rem] space-y-2 overflow-y-auto">
                                {expenses.map((expense) => (
                                    <div
                                        key={expense.id}
                                        className="flex items-center gap-3 rounded-lg border px-3 py-2.5"
                                    >
                                        <div className="flex size-9 shrink-0 items-center justify-center rounded-md bg-red-400/10">
                                            <Wallet className="size-4 text-red-500" />
                                        </div>
                                        <div className="min-w-0 flex-1">
                                            <p className="truncate text-sm font-medium">
                                                {expense.category}
                                            </p>
                                            <p className="truncate text-xs text-muted-foreground">
                                                {expense.expense_date_formatted}
                                                {expense.description
                                                    ? ` · ${expense.description}`
                                                    : ''}
                                            </p>
                                        </div>
                                        <span className="shrink-0 text-sm font-semibold">
                                            {expense.amount_formatted}
                                        </span>
                                        <button
                                            type="button"
                                            className="shrink-0 rounded-md p-1.5 text-muted-foreground transition hover:bg-destructive/10 hover:text-destructive"
                                            title="Hapus pengeluaran"
                                            onClick={() => {
                                                if (
                                                    window.confirm(
                                                        `Hapus pengeluaran "${expense.category}" ${expense.amount_formatted}?`,
                                                    )
                                                ) {
                                                    router.delete(
                                                        expensesRoutes.destroy({
                                                            expense: expense.id,
                                                        }),
                                                        { preserveScroll: true },
                                                    );
                                                }
                                            }}
                                        >
                                            <Trash2 className="size-4" />
                                        </button>
                                    </div>
                                ))}
                                {expenses.length === 0 && (
                                    <p className="py-10 text-center text-sm text-muted-foreground">
                                        Belum ada pengeluaran yang dicatat bulan ini.
                                    </p>
                                )}
                            </div>
                        </CardContent>
                    </Card>
                </div>
            </div>

            {/* Dialog catat pengeluaran */}
            <ExpenseDialog
                open={expenseDialogOpen}
                onOpenChange={setExpenseDialogOpen}
                defaultDate={
                    month === new Date().toISOString().slice(0, 7)
                        ? new Date().toISOString().slice(0, 10)
                        : `${month}-01`
                }
            />
        </>
    );
}

ExpensesIndex.layout = { breadcrumbs };

/**
 * Dialog pencatatan pengeluaran operasional.
 */
function ExpenseDialog({
    open,
    onOpenChange,
    defaultDate,
}: {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    defaultDate: string;
}) {
    const [expenseDate, setExpenseDate] = useState(defaultDate);
    const [category, setCategory] = useState('');
    const [description, setDescription] = useState('');
    const [amount, setAmount] = useState('');
    const [processing, setProcessing] = useState(false);

    function submit(event: React.FormEvent) {
        event.preventDefault();
        setProcessing(true);

        router.post(
            expensesRoutes.store(),
            {
                expense_date: expenseDate,
                category: category.trim(),
                description: description.trim() || null,
                amount: Number(amount),
            },
            {
                onSuccess: () => {
                    onOpenChange(false);
                    setCategory('');
                    setDescription('');
                    setAmount('');
                },
                onFinish: () => setProcessing(false),
            },
        );
    }

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>Catat Pengeluaran</DialogTitle>
                    <DialogDescription>
                        Pengeluaran operasional kos (listrik, kebersihan,
                        perawatan, dll.) untuk bahan laporan kas &amp; laba.
                    </DialogDescription>
                </DialogHeader>

                <form onSubmit={submit} className="space-y-4">
                    <div className="grid grid-cols-2 gap-3">
                        <div className="space-y-1.5">
                            <Label htmlFor="expense-date">Tanggal</Label>
                            <Input
                                id="expense-date"
                                type="date"
                                value={expenseDate}
                                max={new Date().toISOString().slice(0, 10)}
                                onChange={(e) => setExpenseDate(e.target.value)}
                                required
                            />
                        </div>
                        <div className="space-y-1.5">
                            <Label htmlFor="expense-amount">Nominal (Rp)</Label>
                            <Input
                                id="expense-amount"
                                type="number"
                                min={1000}
                                step={500}
                                value={amount}
                                onChange={(e) => setAmount(e.target.value)}
                                placeholder="450000"
                                required
                            />
                        </div>
                    </div>

                    <div className="space-y-1.5">
                        <Label htmlFor="expense-category">Kategori</Label>
                        <Input
                            id="expense-category"
                            value={category}
                            onChange={(e) => setCategory(e.target.value)}
                            placeholder="mis. Listrik & Air"
                            list="expense-categories"
                            required
                        />
                        <datalist id="expense-categories">
                            <option value="Listrik & Air" />
                            <option value="Kebersihan" />
                            <option value="Perawatan" />
                            <option value="Internet" />
                            <option value="Lainnya" />
                        </datalist>
                    </div>

                    <div className="space-y-1.5">
                        <Label htmlFor="expense-description">Keterangan</Label>
                        <Textarea
                            id="expense-description"
                            value={description}
                            onChange={(e) => setDescription(e.target.value)}
                            placeholder="Opsional"
                            rows={2}
                        />
                    </div>

                    <DialogFooter>
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => onOpenChange(false)}
                        >
                            Batal
                        </Button>
                        <Button
                            type="submit"
                            disabled={processing || !category.trim() || !amount}
                        >
                            Simpan
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}

