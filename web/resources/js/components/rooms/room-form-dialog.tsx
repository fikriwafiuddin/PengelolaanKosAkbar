import { useEffect, useRef, useState } from 'react';
import { router, usePage } from '@inertiajs/react';
import { ImagePlus, Pencil, Plus, Trash2 } from 'lucide-react';
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

type FormValues = {
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
 * Dialog tambah/ubah kamar — termasuk unggah/ganti/hapus foto kamar.
 * Submit memakai FormData (multipart) agar berkas gambar ikut terkirim.
 */
export function RoomFormDialog({ facilities, types, room }: Props) {
    const isEdit = room !== undefined;
    const { errors } = usePage().props;
    const fileInputRef = useRef<HTMLInputElement>(null);

    const [open, setOpen] = useState(false);
    const [processing, setProcessing] = useState(false);
    const [imageFile, setImageFile] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(
        room?.image_url ?? null,
    );
    const [removeImage, setRemoveImage] = useState(false);
    const [data, setData] = useState<FormValues>({
        room_number: room?.room_number ?? '',
        type: room?.type ?? types[0] ?? '',
        price_monthly: room?.price_monthly?.toString() ?? '',
        status: room?.status ?? 'kosong',
        description: room?.description ?? '',
        facility_ids: room?.facilities.map((f) => f.id) ?? [],
    });

    /** Perbarui satu field formulir secara imutabel. */
    function setField<K extends keyof FormValues>(key: K, value: FormValues[K]) {
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
            setImageFile(null);
            setImagePreview(null);
            setRemoveImage(false);
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

    /** Pilih berkas gambar baru; tampilkan pratinjau lokal. */
    function pickImage(file: File | undefined) {
        if (!file) {
            return;
        }

        setImageFile(file);
        setRemoveImage(false);
        setImagePreview(URL.createObjectURL(file));
    }

    /** Hapus pilihan gambar (kembali ke foto lama bila ada). */
    function clearImage() {
        setImageFile(null);
        setImagePreview(null);
        setRemoveImage(Boolean(room?.image_url));
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    }

    function submit(close: () => void) {
        // FormData (multipart) — Inertia otomatis mengatur header.
        const formData = new FormData();
        formData.append('room_number', data.room_number);
        formData.append('type', data.type);
        formData.append('price_monthly', data.price_monthly);
        formData.append('status', data.status);
        formData.append('description', data.description ?? '');
        formData.append('remove_image', removeImage ? '1' : '0');
        data.facility_ids.forEach((id) => formData.append('facility_ids[]', String(id)));

        if (imageFile) {
            formData.append('image', imageFile);
        }

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
            // Method spoofing PUT untuk FormData.
            formData.append('_method', 'PUT');
            router.post(roomsRoutes.update({ room: room.id }), formData, options);
        } else {
            router.post(roomsRoutes.store(), formData, options);
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
                        Lengkapi informasi kamar, harga sewa, fasilitas, dan
                        fotonya.
                    </DialogDescription>
                </DialogHeader>

                <div className="grid gap-4">
                    {/* Foto kamar */}
                    <div className="grid gap-2">
                        <Label htmlFor="room_image">Foto Kamar</Label>
                        <div className="flex items-start gap-4">
                            <div className="flex h-24 w-36 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-dashed border-border bg-muted/40">
                                {imagePreview ? (
                                    <img
                                        src={imagePreview}
                                        alt="Pratinjau foto kamar"
                                        className="h-full w-full object-cover"
                                    />
                                ) : (
                                    <ImagePlus className="size-6 text-muted-foreground" />
                                )}
                            </div>
                            <div className="flex flex-col gap-2">
                                <Input
                                    id="room_image"
                                    ref={fileInputRef}
                                    type="file"
                                    accept="image/jpeg,image/png,image/webp"
                                    className="text-xs"
                                    onChange={(e) =>
                                        pickImage(e.target.files?.[0])
                                    }
                                />
                                <p className="text-xs text-muted-foreground">
                                    JPG/PNG/WebP, maksimal 2 MB.
                                </p>
                                {(imageFile || imagePreview || removeImage) && (
                                    <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        className="h-7 w-fit gap-1 text-destructive"
                                        onClick={clearImage}
                                    >
                                        <Trash2 className="size-3" /> Hapus Foto
                                    </Button>
                                )}
                                {removeImage && (
                                    <p className="text-xs text-amber-600">
                                        Foto akan dihapus saat disimpan.
                                    </p>
                                )}
                            </div>
                        </div>
                        <InputError message={errors.image} />
                    </div>

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
