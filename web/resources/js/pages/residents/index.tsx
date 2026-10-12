import { useEffect, useState } from 'react';
import { Head, router, usePage } from '@inertiajs/react';
import { CheckCircle2, Search, ShieldCheck, XCircle } from 'lucide-react';
import { toast } from 'sonner';

import Heading from '@/components/heading';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { cn } from '@/lib/utils';
import { formatDate, initialsOf } from '@/lib/format';
import { dashboard } from '@/routes';
import * as residentsRoutes from '@/routes/residents';
import * as residentsValidation from '@/routes/residents/validation';
import type { BreadcrumbItem } from '@/types';
import type { Pagination, Resident } from '@/types/kost';

type Props = {
    residents: Pagination<Resident>;
    filters: { q?: string; status?: string };
};

/**
 * Badge status akun penghuni (hasil validasi admin).
 */
const ACCOUNT_STATUS: Record<
    string,
    { label: string; className: string }
> = {
    aktif: {
        label: 'Aktif',
        className: 'bg-teal-600/10 text-teal-700 dark:text-teal-400',
    },
    menunggu_validasi: {
        label: 'Menunggu Validasi',
        className: 'bg-amber-500/15 text-amber-700 dark:text-amber-400',
    },
    ditolak: {
        label: 'Ditolak',
        className: 'bg-red-500/10 text-red-700 dark:text-red-400',
    },
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Data Penghuni', href: residentsRoutes.index() },
];

export default function ResidentsIndex({
    residents: residentPagination,
    filters,
}: Props) {
    const { flash } = usePage().props;
    const [search, setSearch] = useState(filters.q ?? '');

    // Notifikasi hasil aksi validasi akun (flash message dari controller).
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

        router.get(residentsRoutes.index(), query, {
            preserveState: true,
            replace: true,
        });
    }

    /**
     * Aksi admin: setujui / tolak akun penghuni.
     */
    function validateAccount(resident: Resident, status: 'aktif' | 'ditolak') {
        const userId = resident.user?.id;

        if (!userId) {
            return;
        }

        const label =
            status === 'aktif' ? 'menyetujui' : 'menolak';

        if (
            !window.confirm(
                `Yakin ${label} akun ${resident.full_name}?`,
            )
        ) {
            return;
        }

        router.put(
            residentsValidation.update({ user: userId }),
            { status },
            { preserveScroll: true },
        );
    }

    return (
        <>
            <Head title="Data Penghuni" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <Heading
                    title="Data Penghuni"
                    description="Direktori biodata penyewa, kontak penanggung jawab, dan status akun (validasi registrasi)."
                />

                {/* Pencarian & filter status akun */}
                <div className="flex flex-wrap items-center gap-3">
                    <div className="relative w-full max-w-sm">
                        <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
                        <Input
                            className="pl-9"
                            placeholder="Cari nama, NIK, atau nomor kamar..."
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                        />
                    </div>
                    <Select
                        value={filters.status ?? 'semua'}
                        onValueChange={(v) =>
                            applyFilters({
                                status: v === 'semua' ? undefined : v,
                            })
                        }
                    >
                        <SelectTrigger className="w-56">
                            <SelectValue placeholder="Semua Status Akun" />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="semua">
                                Semua Status Akun
                            </SelectItem>
                            <SelectItem value="aktif">Aktif</SelectItem>
                            <SelectItem value="menunggu_validasi">
                                Menunggu Validasi
                            </SelectItem>
                            <SelectItem value="ditolak">Ditolak</SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                {/* Tabel penghuni */}
                <Card className="py-0">
                    <CardContent className="px-0">
                        <Table>
                            <TableHeader>
                                <TableRow className="hover:bg-transparent">
                                    <TableHead className="pl-6">Nama Penghuni</TableHead>
                                    <TableHead>NIK</TableHead>
                                    <TableHead>Tgl Lahir</TableHead>
                                    <TableHead>No. HP</TableHead>
                                    <TableHead>Penanggung Jawab</TableHead>
                                    <TableHead>Pekerjaan</TableHead>
                                    <TableHead>Alamat</TableHead>
                                    <TableHead>Status Akun</TableHead>
                                    <TableHead className="pr-6 text-right">Aksi</TableHead>
                                </TableRow>
                            </TableHeader>
                            <TableBody>
                                {residentPagination.data.map((resident) => {
                                    const status =
                                        ACCOUNT_STATUS[
                                            resident.user?.status ?? 'aktif'
                                        ] ?? ACCOUNT_STATUS.aktif;
                                    const isPending =
                                        resident.user?.status ===
                                        'menunggu_validasi';

                                    return (
                                        <TableRow key={resident.id}>
                                            <TableCell className="pl-6">
                                                <div className="flex items-center gap-3">
                                                    <Avatar className="size-9">
                                                        <AvatarFallback className="bg-secondary font-semibold text-primary">
                                                            {initialsOf(
                                                                resident.full_name,
                                                            )}
                                                        </AvatarFallback>
                                                    </Avatar>
                                                    <div>
                                                        <p className="font-medium">
                                                            {
                                                                resident.full_name
                                                            }
                                                        </p>
                                                        <p className="text-xs text-muted-foreground">
                                                            {
                                                                resident.user
                                                                    ?.email
                                                            }
                                                        </p>
                                                    </div>
                                                </div>
                                            </TableCell>
                                            <TableCell className="font-mono text-xs">
                                                {resident.identity_number}
                                            </TableCell>
                                            <TableCell>
                                                {formatDate(
                                                    resident.birth_date,
                                                )}
                                            </TableCell>
                                            <TableCell>
                                                {resident.user?.phone ?? '-'}
                                            </TableCell>
                                            <TableCell>
                                                {resident.guardian_name ? (
                                                    <>
                                                        <p className="text-sm">
                                                            {
                                                                resident.guardian_name
                                                            }
                                                        </p>
                                                        <p className="text-xs text-muted-foreground">
                                                            {
                                                                resident.guardian_phone
                                                            }
                                                        </p>
                                                    </>
                                                ) : (
                                                    <span className="text-muted-foreground">
                                                        -
                                                    </span>
                                                )}
                                            </TableCell>
                                            <TableCell>
                                                {resident.occupation ?? '-'}
                                            </TableCell>
                                            <TableCell className="max-w-48">
                                                <span className="line-clamp-2 text-sm text-muted-foreground">
                                                    {resident.address ?? '-'}
                                                </span>
                                            </TableCell>
                                            <TableCell>
                                                <span
                                                    className={cn(
                                                        'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium',
                                                        status.className,
                                                    )}
                                                >
                                                    {isPending && (
                                                        <ShieldCheck className="size-3" />
                                                    )}
                                                    {status.label}
                                                </span>
                                            </TableCell>
                                            <TableCell className="pr-6">
                                                {isPending ? (
                                                    <div className="flex items-center justify-end gap-1">
                                                        <Button
                                                            size="sm"
                                                            className="h-8"
                                                            onClick={() =>
                                                                validateAccount(
                                                                    resident,
                                                                    'aktif',
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
                                                                validateAccount(
                                                                    resident,
                                                                    'ditolak',
                                                                )
                                                            }
                                                        >
                                                            <XCircle className="size-3.5" />
                                                            Tolak
                                                        </Button>
                                                    </div>
                                                ) : (
                                                    <span className="block text-right text-xs text-muted-foreground">
                                                        -
                                                    </span>
                                                )}
                                            </TableCell>
                                        </TableRow>
                                    );
                                })}

                                {residentPagination.data.length === 0 && (
                                    <TableRow>
                                        <TableCell
                                            colSpan={9}
                                            className="py-10 text-center text-muted-foreground"
                                        >
                                            Tidak ada penghuni yang cocok
                                            dengan pencarian / filter.
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
                            onClick={() =>
                                router.get(
                                    residentsRoutes.index(),
                                    {
                                        page:
                                            residentPagination.current_page - 1,
                                        ...filters,
                                    },
                                    { preserveState: true },
                                )
                            }
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
                            onClick={() =>
                                router.get(
                                    residentsRoutes.index(),
                                    {
                                        page:
                                            residentPagination.current_page + 1,
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
        </>
    );
}

ResidentsIndex.layout = { breadcrumbs };
