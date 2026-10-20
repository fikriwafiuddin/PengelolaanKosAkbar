import { BedDouble, LayoutGrid, MessageSquareText, ReceiptText, Users, Wallet } from 'lucide-react';

import { dashboard } from '@/routes';
import * as roomsRoutes from '@/routes/rooms';
import * as residentsRoutes from '@/routes/residents';
import * as paymentsRoutes from '@/routes/payments';
import type { NavItem } from '@/types';

/**
 * Navigasi utama dashboard admin Kost Akbar (Sprint 1–2).
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
];

/**
 * Menu yang akan hadir pada sprint berikutnya — ditampilkan
 * (nonaktif) agar struktur menu sesuai desain UI.
 */
export const upcomingNavItems: (NavItem & { sprint: string })[] = [
    {
        title: 'Chat & Pengumuman',
        href: '#',
        icon: MessageSquareText,
        sprint: 'Sprint 3',
    },
    {
        title: 'Laporan Keuangan',
        href: '#',
        icon: Wallet,
        sprint: 'Sprint 4',
    },
];
