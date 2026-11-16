import { BedDouble, LayoutGrid, MessageSquareText, ReceiptText, Users, Wallet, TrendingDown } from 'lucide-react';

import { dashboard } from '@/routes';
import * as roomsRoutes from '@/routes/rooms';
import * as residentsRoutes from '@/routes/residents';
import * as paymentsRoutes from '@/routes/payments';
import * as chatRoutes from '@/routes/chat';
import * as financeRoutes from '@/routes/finance';
import * as expensesRoutes from '@/routes/expenses';
import type { NavItem } from '@/types';

/**
 * Navigasi utama dashboard admin Kost Akbar (Sprint 1–4 + revisi dosen).
 */
export const mainNavItems: NavItem[] = [
    {
        title: 'Dashboard',
        href: dashboard(),
        icon: LayoutGrid,
    },
    {
        title: 'Data Kamar',
        href: roomsRoutes.index(),
        icon: BedDouble,
    },
    {
        title: 'Data Penghuni',
        href: residentsRoutes.index(),
        icon: Users,
    },
    {
        title: 'Verifikasi Pembayaran',
        href: paymentsRoutes.index(),
        icon: ReceiptText,
    },
    {
        title: 'Chat & Pengumuman',
        href: chatRoutes.index(),
        icon: MessageSquareText,
    },
    {
        title: 'Laporan Keuangan',
        href: financeRoutes.index(),
        icon: Wallet,
    },
    {
        title: 'Pengeluaran',
        href: expensesRoutes.index(),
        icon: TrendingDown,
    },
];

/**
 * Seluruh menu sprint 1-4 telah aktif — tidak ada placeholder lagi.
 */
export const upcomingNavItems: (NavItem & { sprint: string })[] = [];
