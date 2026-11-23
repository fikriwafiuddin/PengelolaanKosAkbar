import { useEffect } from 'react';
import { Head } from '@inertiajs/react';
import { ArrowLeft, Printer } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { formatRupiah } from '@/lib/format';
import * as financeRoutes from '@/routes/finance';
import type { BreadcrumbItem } from '@/types';

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

type PaymentReportRow = {
    id: number;
    resident_name: string;
    room_number: string | null;
    period: string;
    amount: number;
    method: string;
    method_label: string;
    receipt_no: string | null;
    paid_at_formatted: string | null;
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
    type: 'pembayaran' | 'kas';
    month: string;
    summary: Summary;
    paymentReport: PaymentReportRow[];
    expenseByCategory: CategoryRow[];
    expenses: ExpenseRow[];
    printed_at: string;
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Laporan Keuangan', href: financeRoutes.index() },
    { title: 'Cetak Laporan', href: financeRoutes.print() },
];

export default function FinancePrint({
    type,
    summary,
    paymentReport,
    expenseByCategory,
    expenses,
    printed_at,
}: Props) {
    // Otomatis memicu dialog cetak/simpan PDF browser setelah halaman dimuat
    useEffect(() => {
        const timer = setTimeout(() => window.print(), 400);
        return () => clearTimeout(timer);
    }, []);

    const isKas = type === 'kas';
    const title = isKas
        ? `Laporan Kas & Laba Rugi — ${summary.month_label}`
        : `Laporan Pembayaran Sewa — ${summary.month_label}`;

    return (
        <>
            <Head title={title} />

            <div className="min-h-screen bg-white p-8 text-neutral-900 print:p-0">
                {/* Bar navigasi saat tampil di layar (sembunyi saat cetak) */}
                <div className="flex items-center justify-between pb-6 print:hidden">
                    <Button variant="outline" asChild>
                        <a href={financeRoutes.index.url({ query: { month: summary.month } })}>
                            <ArrowLeft className="size-4" /> Kembali ke Laporan Keuangan
                        </a>
                    </Button>
                    <div className="flex items-center gap-2">
                        <Button onClick={() => window.print()}>
                            <Printer className="size-4" /> Cetak / Simpan PDF
                        </Button>
                    </div>
                </div>

                {/* Kop Laporan Resmi */}
                <div className="border-b-2 border-neutral-900 pb-4 text-center">
                    <h1 className="font-serif text-2xl font-bold tracking-tight uppercase">
                        Kost Akbar Kediri
                    </h1>
                    <p className="text-sm text-neutral-600">
                        Jl. Mastrip No.130, Sukorame, Kec. Mojoroto, Kota Kediri, Jawa Timur 64114 · Telp: 0812-3456-7890
                    </p>
                    <div className="mt-3">
                        <h2 className="font-serif text-lg font-bold underline underline-offset-4">
                            {isKas ? 'LAPORAN ARUS KAS & LABA RUGI OPERASIONAL' : 'LAPORAN REKAP PEMBAYARAN SEWA KAMAR'}
                        </h2>
                        <p className="text-xs text-neutral-500 mt-0.5">
                            Periode: <strong className="text-neutral-800">{summary.month_label}</strong> · Dicetak pada: {printed_at}
                        </p>
                    </div>
                </div>

                {/* Ringkasan Angka Utama */}
                <div className="grid grid-cols-3 gap-4 border border-neutral-300 p-4 rounded-md">
                    <div>
                        <p className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">
                            Total Pemasukan
                        </p>
                        <p className="font-serif text-lg font-bold text-teal-800 mt-1">
                            {formatRupiah(summary.income)}
                        </p>
                    </div>
                    <div>
                        <p className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">
                            Total Pengeluaran
                        </p>
                        <p className="font-serif text-lg font-bold text-red-800 mt-1">
                            {formatRupiah(summary.expense)}
                        </p>
                    </div>
                    <div>
                        <p className="text-xs font-semibold text-neutral-500 uppercase tracking-wide">
                            Laba Bersih ({summary.month_label})
                        </p>
                        <p className="font-serif text-lg font-bold text-neutral-900 mt-1">
                            {formatRupiah(summary.profit)}
                        </p>
                    </div>
                </div>

                {/* ISI LAPORAN SESUAI TIPE */}
                {isKas ? (
                    // === LAPORAN KAS (PEMASUKAN & PENGELUARAN) ===
                    <div className="space-y-6">
                        {/* Rekap Pemasukan */}
                        <section className="space-y-2">
                            <h3 className="font-serif text-base font-semibold border-b border-neutral-300 pb-1">
                                A. Rincian Pemasukan Kas
                            </h3>
                            <table className="w-full text-sm border-collapse">
                                <thead>
                                    <tr className="border-b border-neutral-300 text-left text-xs text-neutral-600">
                                        <th className="py-2 w-10">No.</th>
                                        <th className="py-2">Sumber / Keterangan</th>
                                        <th className="py-2">Jumlah Transaksi</th>
                                        <th className="py-2 text-right">Total Nominal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr className="border-b border-neutral-200">
                                        <td className="py-2">1.</td>
                                        <td className="py-2 font-medium">Pembayaran Sewa Kamar Terverifikasi</td>
                                        <td className="py-2">{paymentReport.length} transaksi</td>
                                        <td className="py-2 text-right font-bold text-neutral-900">
                                            {formatRupiah(summary.income)}
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </section>

                        {/* Rekap Pengeluaran per Kategori */}
                        <section className="space-y-2">
                            <h3 className="font-serif text-base font-semibold border-b border-neutral-300 pb-1">
                                B. Rincian Pengeluaran Operasional
                            </h3>
                            <table className="w-full text-sm border-collapse">
                                <thead>
                                    <tr className="border-b border-neutral-300 text-left text-xs text-neutral-600">
                                        <th className="py-2 w-10">No.</th>
                                        <th className="py-2">Kategori Pengeluaran</th>
                                        <th className="py-2">Frekuensi</th>
                                        <th className="py-2 text-right">Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {expenseByCategory.map((cat, idx) => (
                                        <tr key={cat.category} className="border-b border-neutral-200">
                                            <td className="py-2">{idx + 1}.</td>
                                            <td className="py-2 font-medium">{cat.category}</td>
                                            <td className="py-2">{cat.total_items} kali</td>
                                            <td className="py-2 text-right font-semibold">
                                                {formatRupiah(cat.total_amount)}
                                            </td>
                                        </tr>
                                    ))}
                                    {expenseByCategory.length === 0 && (
                                        <tr>
                                            <td colSpan={4} className="py-4 text-center text-neutral-500 text-xs">
                                                Tidak ada pengeluaran operasional yang dicatat pada bulan ini.
                                            </td>
                                        </tr>
                                    )}
                                    <tr className="border-t-2 border-neutral-800 font-bold bg-neutral-50">
                                        <td colSpan={3} className="py-2 text-right">
                                            TOTAL PENGELUARAN:
                                        </td>
                                        <td className="py-2 text-right text-red-800">
                                            {formatRupiah(summary.expense)}
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </section>

                        {/* Tabel Detail Daftar Pengeluaran */}
                        {expenses.length > 0 && (
                            <section className="space-y-2 break-inside-avoid">
                                <h4 className="text-xs font-semibold text-neutral-700 uppercase tracking-wide">
                                    Daftar Catatan Pengeluaran ({expenses.length} item)
                                </h4>
                                <table className="w-full text-xs border-collapse">
                                    <thead>
                                        <tr className="border-b border-neutral-300 text-left text-neutral-600">
                                            <th className="py-1.5 w-8">No.</th>
                                            <th className="py-1.5">Tanggal</th>
                                            <th className="py-1.5">Kategori</th>
                                            <th className="py-1.5">Keterangan</th>
                                            <th className="py-1.5 text-right">Nominal</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {expenses.map((exp, idx) => (
                                            <tr key={exp.id} className="border-b border-neutral-200">
                                                <td className="py-1.5">{idx + 1}.</td>
                                                <td className="py-1.5">{exp.expense_date_formatted}</td>
                                                <td className="py-1.5 font-medium">{exp.category}</td>
                                                <td className="py-1.5 text-neutral-600">{exp.description || '-'}</td>
                                                <td className="py-1.5 text-right font-semibold">{exp.amount_formatted}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </section>
                        )}
                    </div>
                ) : (
                    // === LAPORAN PEMBAYARAN SEWA ===
                    <section className="space-y-2">
                        <table className="w-full text-sm border-collapse">
                            <thead>
                                <tr className="border-b-2 border-neutral-800 text-left text-xs uppercase text-neutral-600">
                                    <th className="py-2 w-10">No.</th>
                                    <th className="py-2">No. Kuitansi</th>
                                    <th className="py-2">Nama Penghuni</th>
                                    <th className="py-2">Kamar</th>
                                    <th className="py-2">Tanggal Bayar</th>
                                    <th className="py-2">Metode</th>
                                    <th className="py-2 text-right">Nominal</th>
                                </tr>
                            </thead>
                            <tbody>
                                {paymentReport.map((row, idx) => (
                                    <tr key={row.id} className="border-b border-neutral-200">
                                        <td className="py-2">{idx + 1}.</td>
                                        <td className="py-2 font-mono text-xs">{row.receipt_no || '-'}</td>
                                        <td className="py-2 font-medium">{row.resident_name}</td>
                                        <td className="py-2">Kamar {row.room_number || '-'}</td>
                                        <td className="py-2 text-neutral-600">{row.paid_at_formatted || '-'}</td>
                                        <td className="py-2">{row.method_label}</td>
                                        <td className="py-2 text-right font-bold text-neutral-900">
                                            {formatRupiah(row.amount)}
                                        </td>
                                    </tr>
                                ))}
                                {paymentReport.length === 0 && (
                                    <tr>
                                        <td colSpan={7} className="py-6 text-center text-neutral-500 text-sm">
                                            Belum ada pembayaran sewa terverifikasi pada periode {summary.month_label}.
                                        </td>
                                    </tr>
                                )}
                                <tr className="border-t-2 border-neutral-900 font-bold bg-neutral-50">
                                    <td colSpan={6} className="py-2.5 text-right">
                                        TOTAL PENERIMAAN SEWA:
                                    </td>
                                    <td className="py-2.5 text-right font-serif text-base text-teal-800">
                                        {formatRupiah(summary.income)}
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </section>
                )}

                {/* Kolom Tanda Tangan Resmi Pemilik Kost */}
                <div className="mt-8 flex justify-end pt-6 text-sm break-inside-avoid">
                    <div className="text-center w-64">
                        <p className="text-xs text-neutral-500 mb-16">
                            Kediri, {printed_at.split(',')[0]}<br />
                            Pemilik Kost Akbar
                        </p>
                        <p className="font-semibold underline">Pemilik Kost Akbar</p>
                        <p className="text-xs text-neutral-500">Kost Akbar Kediri</p>
                    </div>
                </div>
            </div>
        </>
    );
}

FinancePrint.layout = { breadcrumbs };

