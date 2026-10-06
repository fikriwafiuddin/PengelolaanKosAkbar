import { useState } from 'react';
import { router, usePage } from '@inertiajs/react';
import { Trash2 } from 'lucide-react';
import { toast } from 'sonner';

import { Button } from '@/components/ui/button';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
    DialogTrigger,
} from '@/components/ui/dialog';
import * as roomsRoutes from '@/routes/rooms';
import type { Room } from '@/types/kost';

/**
 * Tombol hapus kamar dengan konfirmasi.
 */
export function DeleteRoomButton({ room }: { room: Room }) {
    const { errors } = usePage().props;
    const [open, setOpen] = useState(false);
    const [processing, setProcessing] = useState(false);

    function destroy() {
        setProcessing(true);

        router.delete(roomsRoutes.destroy({ room: room.id }), {
            preserveScroll: true,
            onSuccess: () => {
                toast.success(`Kamar ${room.room_number} berhasil dihapus.`);
                setOpen(false);
            },
            onError: () => toast.error(errors.room ?? 'Kamar gagal dihapus.'),
            onFinish: () => setProcessing(false),
        });
    }

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <Button
                    variant="ghost"
                    size="icon"
                    className="size-8 text-destructive hover:bg-destructive/10 hover:text-destructive"
                    aria-label={`Hapus kamar ${room.room_number}`}
                >
                    <Trash2 className="size-3.5" />
                </Button>
            </DialogTrigger>

            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle className="font-serif">
                        Hapus Kamar {room.room_number}?
                    </DialogTitle>
                    <DialogDescription>
                        Kamar {room.room_number} ({room.type}) akan dihapus
                        permanen dari sistem. Tindakan ini tidak dapat
                        dibatalkan.
                    </DialogDescription>
                </DialogHeader>
                <DialogFooter>
                    <Button
                        variant="outline"
                        onClick={() => setOpen(false)}
                        disabled={processing}
                    >
                        Batal
                    </Button>
                    <Button
                        variant="destructive"
                        onClick={destroy}
                        disabled={processing}
                    >
                        Ya, Hapus
                    </Button>
                </DialogFooter>
            </DialogContent>
        </Dialog>
    );
}
