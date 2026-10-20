import { useEffect } from 'react';
import { Head } from '@inertiajs/react';
import { Printer } from 'lucide-react';

import { Button } from '@/components/ui/button';
import * as paymentsRoutes from '@/routes/payments';
import type { BreadcrumbItem } from '@/types';
import type { Payment } from '@/types/kost';

type Props = {
    payment: Payment;
    printedAt: string;
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Verifikasi Pembayaran', href: paymentsRoutes.index() },
    { title: 'Kuitansi', href: '#' },
];

/**
 * Kuitansi pembayaran sewa — dicetak admin sebagai bukti pembayaran
 * resmi penghuni (mengikuti desain UI Sprint 2).
 */
export default function PaymentReceipt({ payment, printedAt }: Props) {
    // Buka dialog cetak browser otomatis saat halaman dibuka.
    useEffect(() => {
        const timer = setTimeout(() => window.print(), 400);

        return () => clearTimeout(timer);
    }, []);

    const rows: [string, string][] = [
        ['No. Kuitansi', payment.receipt_no ?? '-'],
        ['Diterima Dari', payment.resident_name ?? '-'],
        ['Kamar', `Kamar ${payment.room_number ?? '-'}`],
        [
            'Untuk Pembayaran',
            `Sewa kamar periode ${payment.invoice?.period_label ?? payment.invoice?.period}`,
        ],
        ['Metode', payment.method_label],
        ['Tanggal Bayar', payment.paid_at_formatted ?? '-'],
        ['Diverifikasi Oleh', payment.verifier_name ?? '-'],
    ];

    return (
        <>
            <Head title={`Kuitansi ${payment.receipt_no ?? payment.id}`} />

            <div className="flex h-full flex-1 flex-col gap-6 bg-white p-8 print:p-0">
                <div className="flex items-center justify-between print:hidden">
                    <Button variant="outline" asChild>
                        <a href={paymentsRoutes.index.url()}>
                            ← Kembali ke Verifikasi Pembayaran
                        </a>
                    </Button>
                    <Button onClick={() => window.print()}>
                        <Printer className="size-4" /> Cetak Kuitansi
                    </Button>
                </div>

                {/* Kuitansi — ikut tercetak */}
                <div className="mx-auto w-full max-w-2xl border-2 border-neutral-800">
                    {/* Kop kuitansi */}
                    <div className="flex items-center justify-between border-b-2 border-neutral-800 px-6 py-4">
                        <div>
                            <h1 className="font-serif text-xl font-bold tracking-tight">
                                KOST AKBAR
                            </h1>
                            <p className="text-xs text-neutral-600">
                                Jl. Mastrip No.130, Sukorame, Kec. Mojoroto,
                                Kota Kediri, Jawa Timur 64114
                            </p>
                            <p className="text-xs text-neutral-600">
                                +62 812-3456-7890
                            </p>
                        </div>
                        <div className="text-center">
                            <p className="font-serif text-lg font-semibold uppercase">
                                Kuitansi
                            </p>
                            <p className="text-xs text-neutral-500">
                                Bukti Pembayaran Sewa
                            </p>
                        </div>
                    </div>

                    {/* Rincian pembayaran */}
                    <div className="px-6 py-5 text-sm">
                        <table className="w-full">
                            <tbody>
                                {rows.map(([label, value]) => (
                                    <tr key={label} className="align-top">
                                        <td className="w-44 py-1.5 text-neutral-600">
                                            {label}
                                        </td>
                                        <td className="w-3 py-1.5 text-neutral-400">
                                            :
                                        </td>
                                        <td className="py-1.5 font-medium">
                                            {value}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>

                        {/* Nominal besar */}
                        <div className="mt-4 flex items-center justify-between rounded-md bg-neutral-100 px-4 py-3">
                            <span className="text-sm font-medium text-neutral-700">
                                Jumlah Diterima
                            </span>
                            <span className="font-serif text-2xl font-bold">
                                {payment.amount_formatted}
                            </span>
                        </div>
                    </div>

                    {/* Tanda tangan */}
                    <div className="flex items-end justify-between border-t border-dashed border-neutral-400 px-6 py-5 text-sm">
                        <p className="max-w-55 text-xs text-neutral-500">
                            Kuitansi ini sah diterbitkan oleh pengelola Kost
                            Akbar dan berlaku sebagai bukti pembayaran sewa.
                        </p>
                        <div className="text-center">
                            <p className="text-neutral-600">Kota Kediri,{' '}
                                {payment.verified_at_formatted}
                            </p>
                            <p className="mt-1 text-neutral-600">Pengelola</p>
                            <div className="h-14" />
                            <p className="font-semibold underline">
                                {payment.verifier_name ?? 'Kost Akbar'}
                            </p>
                        </div>
                    </div>
                </div>

                <p className="text-center text-xs text-neutral-500">
                    Dicetak: {printedAt} · Kuitansi {payment.receipt_no}
                </p>
            </div>
        </>
    );
}

PaymentReceipt.layout = { breadcrumbs };
