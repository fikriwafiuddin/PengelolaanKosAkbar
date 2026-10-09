// import { useEffect, useState } from 'react';
// import { Head, router } from '@inertiajs/react';
// import {
//     BadgeCheck,
//     CircleAlert,
//     Clock4,
//     Search,
//     UserRound,
// } from 'lucide-react';

// import Heading from '@/components/heading';
// import { Avatar, AvatarFallback } from '@/components/ui/avatar';
// import { Button } from '@/components/ui/button';
// import { Card, CardContent } from '@/components/ui/card';
// import { Input } from '@/components/ui/input';
// import {
//     Select,
//     SelectContent,
//     SelectItem,
//     SelectTrigger,
//     SelectValue,
// } from '@/components/ui/select';
// import {
//     Table,
//     TableBody,
//     TableCell,
//     TableHead,
//     TableHeader,
//     TableRow,
// } from '@/components/ui/table';
// import { cn } from '@/lib/utils';
// import { formatDate, initialsOf } from '@/lib/format';
// import { dashboard } from '@/routes';
// import * as residentsRoutes from '@/routes/residents';
// import type { BreadcrumbItem } from '@/types';
// import type {
//     Pagination,
//     Resident,
//     ResidentPaymentStatus,
//     ResidentStats,
// } from '@/types/kost';

// type Props = {
//     residents: Pagination<Resident>;
//     filters: { q?: string; status?: string; with_room?: string };
//     stats: ResidentStats;
// };

// const PAYMENT_BADGE: Record<ResidentPaymentStatus, { label: string; className: string }> = {
//     lunas: {
//         label: 'Lunas',
//         className: 'bg-teal-600/10 text-teal-700 dark:text-teal-400',
//     },
//     menunggu_verifikasi: {
//         label: 'Menunggu Verifikasi',
//         className: 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
//     },
//     belum_bayar: {
//         label: 'Menunggak',
//         className: 'bg-red-500/10 text-red-700 dark:text-red-400',
//     },
//     tanpa_tagihan: {
//         label: 'Tanpa Tagihan',
//         className: 'bg-neutral-500/10 text-neutral-600 dark:text-neutral-400',
//     },
// };

// const breadcrumbs: BreadcrumbItem[] = [
//     { title: 'Dashboard', href: dashboard() },
//     { title: 'Data Penghuni', href: residentsRoutes.index() },
// ];

// export default function ResidentsIndex({
//     residents: residentPagination,
//     filters,
//     stats,
// }: Props) {
//     const [search, setSearch] = useState(filters.q ?? '');

//     useEffect(() => {
//         const timer = setTimeout(() => {
//             if (search !== (filters.q ?? '')) {
//                 applyFilters({ q: search || undefined });
//             }
//         }, 350);

//         return () => clearTimeout(timer);
//         // eslint-disable-next-line react-hooks/exhaustive-deps
//     }, [search]);

//     /**
//      * Kirim kombinasi filter aktif ke server via Inertia visit.
//      */
//     function applyFilters(next: Record<string, string | undefined>) {
//         const merged = { ...filters, ...next };
//         const query = Object.fromEntries(
//             Object.entries(merged).filter(([, v]) => v),
//         );

//         router.get(residentsRoutes.index(), query, {
//             preserveState: true,
//             replace: true,
//         });
//     }

//     const summaryCards = [
//         {
//             label: 'Total Penghuni',
//             value: stats.total,
//             icon: <UserRound className="size-5 text-primary" />,
//             valueClass: '',
//         },
//         {
//             label: 'Lunas',
//             value: stats.lunas,
//             icon: <BadgeCheck className="size-5 text-teal-700 dark:text-teal-400" />,
//             valueClass: 'text-teal-700 dark:text-teal-400',
//         },
//         {
//             label: 'Menunggu Verifikasi',
//             value: stats.menunggu_verifikasi,
//             icon: <Clock4 className="size-5 text-amber-600" />,
//             valueClass: 'text-amber-600',
//         },
//         {
//             label: 'Belum Bayar',
//             value: stats.belum_bayar,
//             icon: <CircleAlert className="size-5 text-red-600" />,
//             valueClass: 'text-red-600',
//         },
//     ];

//     return (
//         <>
//             <Head title="Data Penghuni" />

//             <div className="flex h-full flex-1 flex-col gap-6 p-6">
//                 <Heading
//                     title="Data Penghuni"
//                     description="Daftar direktori penyewa aktif beserta status pembayaran kamar."
//                 />

//                 {/* Kartu ringkasan */}
//                 <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
//                     {summaryCards.map((card) => (
//                         <Card key={card.label}>
//                             <CardContent className="flex items-center justify-between">
//                                 <div>
//                                     <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
//                                         {card.label}
//                                     </p>
//                                     <p
//                                         className={cn(
//                                             'mt-1 text-3xl font-serif font-semibold',
//                                             card.valueClass,
//                                         )}
//                                     >
//                                         {card.value}
//                                     </p>
//                                 </div>
//                                 <div className="rounded-full bg-secondary p-3">
//                                     {card.icon}
//                                 </div>
//                             </CardContent>
//                         </Card>
//                     ))}
//                 </div>

//                 {/* Filter tampilan */}
//                 <div className="flex flex-wrap gap-2">
//                     <Button
//                         size="sm"
//                         variant={filters.with_room !== '1' ? 'default' : 'secondary'}
//                         onClick={() => applyFilters({ with_room: undefined })}
//                     >
//                         Semua ({stats.total})
//                     </Button>
//                     <Button
//                         size="sm"
//                         variant={filters.with_room === '1' ? 'default' : 'secondary'}
//                         onClick={() => applyFilters({ with_room: '1' })}
//                     >
//                         Sedang Menyewa
//                     </Button>
//                 </div>

//                 {/* Pencarian & status */}
//                 <div className="flex flex-wrap items-center gap-3">
//                     <div className="relative w-full max-w-sm">
//                         <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
//                         <Input
//                             className="pl-9"
//                             placeholder="Cari nama penghuni, email, atau nomor kamar..."
//                             value={search}
//                             onChange={(e) => setSearch(e.target.value)}
//                         />
//                     </div>
//                     <Select
//                         value={filters.status ?? 'semua'}
//                         onValueChange={(v) =>
//                             applyFilters({
//                                 status: v === 'semua' ? undefined : v,
//                             })
//                         }
//                     >
//                         <SelectTrigger className="w-56">
//                             <SelectValue placeholder="Semua Status Pembayaran" />
//                         </SelectTrigger>
//                         <SelectContent>
//                             <SelectItem value="semua">
//                                 Semua Status Pembayaran
//                             </SelectItem>
//                             <SelectItem value="lunas">Lunas</SelectItem>
//                             <SelectItem value="menunggu_verifikasi">
//                                 Menunggu Verifikasi
//                             </SelectItem>
//                             <SelectItem value="belum_bayar">
//                                 Belum Bayar
//                             </SelectItem>
//                         </SelectContent>
//                     </Select>
//                 </div>

//                 {/* Tabel penghuni */}
//                 <Card className="py-0">
//                     <CardContent className="px-0">
//                         <Table>
//                             <TableHeader>
//                                 <TableRow className="hover:bg-transparent">
//                                     <TableHead className="pl-6">Nama Penghuni</TableHead>
//                                     <TableHead>No. HP</TableHead>
//                                     <TableHead>Kamar</TableHead>
//                                     <TableHead>Tgl Mulai Sewa</TableHead>
//                                     <TableHead>Status Pembayaran</TableHead>
//                                 </TableRow>
//                             </TableHeader>
//                             <TableBody>
//                                 {residentPagination.data.map((resident) => {
//                                     const badge =
//                                         PAYMENT_BADGE[
//                                             resident.payment_status ??
//                                                 'tanpa_tagihan'
//                                         ];

//                                     return (
//                                         <TableRow key={resident.id}>
//                                             <TableCell className="pl-6">
//                                                 <div className="flex items-center gap-3">
//                                                     <Avatar className="size-9">
//                                                         <AvatarFallback className="bg-secondary font-semibold text-primary">
//                                                             {initialsOf(
//                                                                 resident.full_name,
//                                                             )}
//                                                         </AvatarFallback>
//                                                     </Avatar>
//                                                     <div>
//                                                         <p className="font-medium">
//                                                             {
//                                                                 resident.full_name
//                                                             }
//                                                         </p>
//                                                         <p className="text-xs text-muted-foreground">
//                                                             {
//                                                                 resident.user
//                                                                     ?.email
//                                                             }
//                                                         </p>
//                                                     </div>
//                                                 </div>
//                                             </TableCell>
//                                             <TableCell>
//                                                 {resident.user?.phone ?? '-'}
//                                             </TableCell>
//                                             <TableCell>
//                                                 {resident.active_booking
//                                                     ?.room ? (
//                                                     <>
//                                                         <span className="font-medium">
//                                                             Kamar{' '}
//                                                             {
//                                                                 resident
//                                                                     .active_booking
//                                                                     .room
//                                                                     .room_number
//                                                             }
//                                                         </span>
//                                                         <p className="text-xs text-muted-foreground">
//                                                             {
//                                                                 resident
//                                                                     .active_booking
//                                                                     .room.type
//                                                             }
//                                                         </p>
//                                                     </>
//                                                 ) : (
//                                                     <span className="text-muted-foreground">
//                                                         Belum menyewa
//                                                     </span>
//                                                 )}
//                                             </TableCell>
//                                             <TableCell>
//                                                 {formatDate(
//                                                     resident.active_booking
//                                                         ?.start_date,
//                                                 )}
//                                             </TableCell>
//                                             <TableCell>
//                                                 <span
//                                                     className={cn(
//                                                         'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
//                                                         badge.className,
//                                                     )}
//                                                 >
//                                                     {badge.label}
//                                                 </span>
//                                             </TableCell>
//                                         </TableRow>
//                                     );
//                                 })}

//                                 {residentPagination.data.length === 0 && (
//                                     <TableRow>
//                                         <TableCell
//                                             colSpan={5}
//                                             className="py-10 text-center text-muted-foreground"
//                                         >
//                                             Tidak ada penghuni yang cocok
//                                             dengan pencarian / filter.
//                                         </TableCell>
//                                     </TableRow>
//                                 )}
//                             </TableBody>
//                         </Table>
//                     </CardContent>
//                 </Card>

//                 {/* Paginasi */}
//                 <div className="flex items-center justify-between text-sm text-muted-foreground">
//                     <span>
//                         Menampilkan {residentPagination.from ?? 0}–
//                         {residentPagination.to ?? 0} dari{' '}
//                         {residentPagination.total} penghuni
//                     </span>
//                     <div className="flex items-center gap-2">
//                         <Button
//                             variant="outline"
//                             size="sm"
//                             disabled={residentPagination.current_page <= 1}
//                             onClick={() =>
//                                 router.get(
//                                     residentsRoutes.index(),
//                                     {
//                                         page:
//                                             residentPagination.current_page - 1,
//                                         ...filters,
//                                     },
//                                     { preserveState: true },
//                                 )
//                             }
//                         >
//                             Sebelumnya
//                         </Button>
//                         <span>
//                             {residentPagination.current_page} /{' '}
//                             {residentPagination.last_page}
//                         </span>
//                         <Button
//                             variant="outline"
//                             size="sm"
//                             disabled={
//                                 residentPagination.current_page >=
//                                 residentPagination.last_page
//                             }
//                             onClick={() =>
//                                 router.get(
//                                     residentsRoutes.index(),
//                                     {
//                                         page:
//                                             residentPagination.current_page + 1,
//                                         ...filters,
//                                     },
//                                     { preserveState: true },
//                                 )
//                             }
//                         >
//                             Berikutnya
//                         </Button>
//                     </div>
//                 </div>
//             </div>
//         </>
//     );
// }

// ResidentsIndex.layout = { breadcrumbs };

import { useEffect, useState } from 'react';
import { Head, router } from '@inertiajs/react';
import { Search } from 'lucide-react';

import Heading from '@/components/heading';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
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
import { formatDate, initialsOf } from '@/lib/format';
import { dashboard } from '@/routes';
import * as residentsRoutes from '@/routes/residents';
import type { BreadcrumbItem } from '@/types';
import type { Pagination, Resident } from '@/types/kost';

type Props = {
    residents: Pagination<Resident>;
    filters: { q?: string };
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Data Penghuni', href: residentsRoutes.index() },
];

export default function ResidentsIndex({
    residents: residentPagination,
    filters,
}: Props) {
    const [search, setSearch] = useState(filters.q ?? '');

    useEffect(() => {
        const timer = setTimeout(() => {
            if (search !== (filters.q ?? '')) {
                router.get(
                    residentsRoutes.index(),
                    search ? { q: search } : {},
                    { preserveState: true, replace: true },
                );
            }
        }, 350);

        return () => clearTimeout(timer);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [search]);

    function goToPage(page: number) {
        router.get(
            residentsRoutes.index(),
            { page, ...filters },
            { preserveState: true },
        );
    }

    return (
        <>
            <Head title="Data Penghuni" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <Heading
                    title="Data Penghuni"
                    description="Daftar biodata penghuni kost."
                />

                {/* Pencarian */}
                <div className="relative w-full max-w-sm">
                    <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                        className="pl-9"
                        placeholder="Cari nama, nomor identitas, atau nomor kamar..."
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>

                {/* Tabel penghuni */}
                <Card className="py-0">
                    <CardContent className="px-0">
                        <Table>
                            <TableHeader>
                                <TableRow className="hover:bg-transparent">
                                    <TableHead className="pl-6">Nama Lengkap</TableHead>
                                    <TableHead>No. Identitas</TableHead>
                                    <TableHead>Tgl Lahir</TableHead>
                                    <TableHead>Alamat</TableHead>
                                    <TableHead>Pekerjaan</TableHead>
                                    <TableHead>No. HP</TableHead>
                                    <TableHead>Kamar</TableHead>
                                    <TableHead>Tgl Mulai Sewa</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {residentPagination.data.map((resident) => (
                                    <TableRow key={resident.id}>
                                        <TableCell className="pl-6">
                                            <div className="flex items-center gap-3">
                                                <Avatar className="size-9">
                                                    <AvatarFallback className="bg-secondary font-semibold text-primary">
                                                        {initialsOf(resident.full_name)}
                                                    </AvatarFallback>
                                                </Avatar>
                                                <span className="font-medium">
                                                    {resident.full_name}
                                                </span>
                                            </div>
                                        </TableCell>
                                        <TableCell>{resident.identity_number}</TableCell>
                                        <TableCell>
                                            {resident.birth_date
                                                ? formatDate(resident.birth_date)
                                                : '-'}
                                        </TableCell>
                                        <TableCell
                                            className="max-w-xs truncate"
                                            title={resident.address ?? ''}
                                        >
                                            {resident.address ?? '-'}
                                        </TableCell>
                                        <TableCell>{resident.occupation ?? '-'}</TableCell>
                                        <TableCell>{resident.user?.phone ?? '-'}</TableCell>
                                        <TableCell>
                                            {resident.active_booking?.room ? (
                                                <>
                                                    <span className="font-medium">
                                                        Kamar {resident.active_booking.room.room_number}
                                                    </span>
                                                    <p className="text-xs text-muted-foreground">
                                                        {resident.active_booking.room.type}
                                                    </p>
                                                </>
                                            ) : (
                                                <span className="text-muted-foreground">Belum menyewa</span>
                                            )}
                                        </TableCell>
                                        <TableCell>
                                            {formatDate(resident.active_booking?.start_date)}
                                        </TableCell>
                                    </TableRow>
                                ))}

                                {residentPagination.data.length === 0 && (
                                    <TableRow>
                                        <TableCell
                                            colSpan={6}
                                            className="py-10 text-center text-muted-foreground"
                                        >
                                            Tidak ada penghuni yang cocok dengan pencarian.
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
                        Menampilkan {residentPagination.from ?? 0}–
                        {residentPagination.to ?? 0} dari{' '}
                        {residentPagination.total} penghuni
                    </span>
                    <div className="flex items-center gap-2">
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={residentPagination.current_page <= 1}
                            onClick={() => goToPage(residentPagination.current_page - 1)}
                        >
                            Sebelumnya
                        </Button>
                        <span>
                            {residentPagination.current_page} /{' '}
                            {residentPagination.last_page}
                        </span>
                        <Button
                            variant="outline"
                            size="sm"
                            disabled={
                                residentPagination.current_page >=
                                residentPagination.last_page
                            }
                            onClick={() => goToPage(residentPagination.current_page + 1)}
                        >
                            Berikutnya
                        </Button>
                    </div>
                </div>
            </div>
        </>
    );
}

ResidentsIndex.layout = { breadcrumbs };