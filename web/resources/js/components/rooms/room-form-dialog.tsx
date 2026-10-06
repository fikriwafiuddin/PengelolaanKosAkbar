import { useEffect, useState } from 'react';
import { router, usePage } from '@inertiajs/react';
import { Pencil, Plus } from 'lucide-react';
import { toast } from 'sonner';

import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Checkbox } from '@/components/ui/checkbox';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import * as roomsRoutes from '@/routes/rooms';
import type { Facility, Room, RoomStatus } from '@/types/kost';

type Props = {
    facilities: Facility[];
    types: string[];
    room?: Room;
};

type FormData = {
    room_number: string;
    type: string;
    price_monthly: string;
    status: RoomStatus;
    description: string;
    facility_ids: number[];
};

const STATUS_OPTIONS: { value: RoomStatus; label: string }[] = [
    { value: 'kosong', label: 'Kosong (tersedia)' },
    { value: 'terisi', label: 'Terisi' },
    { value: 'terbooking', label: 'Terbooking' },
];

/**
 * Dialog tambah/ubah kamar — dipakai di halaman Data Kamar.
 */
export function RoomFormDialog({ facilities, types, room }: Props) {
    const isEdit = room !== undefined;
    const { errors } = usePage().props;

    const [open, setOpen] = useState(false);
    const [processing, setProcessing] = useState(false);
    const [data, setData] = useState<FormData>({
        room_number: room?.room_number ?? '',
        type: room?.type ?? types[0] ?? '',
        price_monthly: room?.price_monthly?.toString() ?? '',
        status: room?.status ?? 'kosong',
        description: room?.description ?? '',
        facility_ids: room?.facilities.map((f) => f.id) ?? [],
    });

    /** Perbarui satu field formulir secara imutabel. */
    function setField<K extends keyof FormData>(key: K, value: FormData[K]) {
        setData((prev) => ({ ...prev, [key]: value }));
    }

    // Reset formulir saat dialog tambah dibuka.
    useEffect(() => {
        if (open && !isEdit) {
            setData({
                room_number: '',
                type: types[0] ?? '',
                price_monthly: '',
                status: 'kosong',
                description: '',
                facility_ids: [],
            });
        }
    }, [open, isEdit, types]);

    function toggleFacility(id: number, checked: boolean) {
        setData((prev) => ({
            ...prev,
            facility_ids: checked
                ? [...prev.facility_ids, id]
                : prev.facility_ids.filter((fid) => fid !== id),
        }));
    }

    function submit(close: () => void) {
        const options = {
            preserveScroll: true,
            onSuccess: () => {
                toast.success(
                    isEdit
                        ? `Kamar ${data.room_number} berhasil diperbarui.`
                        : `Kamar ${data.room_number} berhasil ditambahkan.`,
                );
                close();
            },
            onFinish: () => setProcessing(false),
        };

        setProcessing(true);

        if (isEdit && room) {
            router.put(roomsRoutes.update({ room: room.id }), data, options);
        } else {
            router.post(roomsRoutes.store(), data, options);
        }
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                {isEdit ? (
                    <Button variant="ghost" size="sm" className="h-8 gap-1">
                        <Pencil className="size-3.5" /> Edit
                    </Button>
                ) : (
                    <Button>
                        <Plus className="size-4" /> Tambah Kamar Baru
                    </Button>
                )}
            </DialogTrigger>

            <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
                <DialogHeader>
                    <DialogTitle className="font-serif">
                        {isEdit
                            ? `Ubah Kamar ${room?.room_number}`
                            : 'Tambah Kamar Baru'}
                    </DialogTitle>
                    <DialogDescription>
                        Lengkapi informasi kamar, harga sewa, dan fasilitasnya.
                    </DialogDescription>
                </DialogHeader>

                <div className="grid gap-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="grid gap-2">
                            <Label htmlFor="room_number">Nomor Kamar</Label>
                            <Input
                                id="room_number"
                                placeholder="cth. 30"
                                value={data.room_number}
                                onChange={(e) =>
                                    setField('room_number', e.target.value)
                                }
                            />
                            <InputError message={errors.room_number} />
                        </div>

                        <div className="grid gap-2">
                            <Label htmlFor="type">Tipe / Lantai</Label>
                            <Select
                                value={data.type}
                                onValueChange={(v) => setField('type', v)}
                            >
                                <SelectTrigger id="type" className="w-full">
                                    <SelectValue placeholder="Pilih tipe" />
                                </SelectTrigger>
                                <SelectContent>
                                    {types.map((type) => (
                                        <SelectItem key={type} value={type}>
                                            {type}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                            <InputError message={errors.type} />
                        </div>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div className="grid gap-2">
                            <Label htmlFor="price_monthly">
                                Harga per Bulan (Rp)
                            </Label>
                            <Input
                                id="price_monthly"
                                type="number"
                                min={0}
                                placeholder="cth. 500000"
                                value={data.price_monthly}
                                onChange={(e) =>
                                    setField('price_monthly', e.target.value)
                                }
                            />
                            <InputError message={errors.price_monthly} />
                        </div>

                        <div className="grid gap-2">
                            <Label htmlFor="status">Status</Label>
                            <Select
                                value={data.status}
                                onValueChange={(v) =>
                                    setField('status', v as RoomStatus)
                                }
                            >
                                <SelectTrigger id="status" className="w-full">
                                    <SelectValue placeholder="Pilih status" />
                                </SelectTrigger>
                                <SelectContent>
                                    {STATUS_OPTIONS.map((opt) => (
                                        <SelectItem
                                            key={opt.value}
                                            value={opt.value}
                                        >
                                            {opt.label}
                                        </SelectItem>
                                    ))}
                                </SelectContent>
                            </Select>
                            <InputError message={errors.status} />
                        </div>
                    </div>

                    <div className="grid gap-2">
                        <Label>Fasilitas</Label>
                        <div className="grid grid-cols-2 gap-2 rounded-lg border border-border/70 p-3">
                            {facilities.map((facility) => (
                                <label
                                    key={facility.id}
                                    className="flex items-center gap-2 text-sm font-normal"
                                >
                                    <Checkbox
                                        checked={data.facility_ids.includes(
                                            facility.id,
                                        )}
                                        onCheckedChange={(checked) =>
                                            toggleFacility(
                                                facility.id,
                                                checked === true,
                                            )
                                        }
                                    />
                                    {facility.name}
                                </label>
                            ))}
                        </div>
                        <InputError message={errors.facility_ids} />
                    </div>

                    <div className="grid gap-2">
                        <Label htmlFor="description">
                            Deskripsi (opsional)
                        </Label>
                        <Textarea
                            id="description"
                            placeholder="cth. Kamar 3x4 m, kapasitas 1 orang, jendela menghadap timur."
                            value={data.description}
                            onChange={(e) =>
                                setField('description', e.target.value)
                            }
                        />
                        <InputError message={errors.description} />
                    </div>
                </div>

                <DialogFooter>
                    <Button
                        variant="outline"
                        onClick={() => setOpen(false)}
                        disabled={processing}
                    >
                        Batal
                    </Button>
                    <Button
                        onClick={() => submit(() => setOpen(false))}
                        disabled={processing}
                    >
                        {isEdit ? 'Simpan Perubahan' : 'Simpan Kamar'}
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
