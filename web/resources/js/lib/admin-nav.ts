import { BedDouble, LayoutGrid, MessageSquareText, ReceiptText, Users, Wallet } from 'lucide-react';

import { dashboard } from '@/routes';
import * as roomsRoutes from '@/routes/rooms';
import * as residentsRoutes from '@/routes/residents';
import type { NavItem } from '@/types';

/**
 * Navigasi utama dashboard admin Kost Akbar (Sprint 1).
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
];

/**
 * Menu yang akan hadir pada sprint berikutnya — ditampilkan
 * (nonaktif) agar struktur menu sesuai desain UI.
 */
export const upcomingNavItems: (NavItem & { sprint: string })[] = [
    {
        title: 'Verifikasi Pembayaran',
        href: '#',
        icon: ReceiptText,
        sprint: 'Sprint 2',
    },
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
