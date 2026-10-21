import { useEffect, useState } from 'react';
import { Head, router, usePage } from '@inertiajs/react';
import { Megaphone, Plus, Send, Users } from 'lucide-react';
import { toast } from 'sonner';

import Heading from '@/components/heading';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
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
import { Skeleton } from '@/components/ui/skeleton';
import { Textarea } from '@/components/ui/textarea';
import { cn } from '@/lib/utils';
import { dashboard } from '@/routes';
import * as chatRoutes from '@/routes/chat';
import * as chatMessages from '@/routes/chat/messages';
import * as chatRooms from '@/routes/chat/rooms';
import type { BreadcrumbItem } from '@/types';
import type { ChatMessage, ChatRoomSummary } from '@/types/kost';

type Props = {
    rooms: ChatRoomSummary[];
    activeRoom: ChatRoomSummary | null;
    messages: ChatMessage[];
    residents: { id: number; name: string }[];
};

const breadcrumbs: BreadcrumbItem[] = [
    { title: 'Dashboard', href: dashboard() },
    { title: 'Chat & Pengumuman', href: chatRoutes.index() },
];

/**
 * Chat & Pengumuman: pantau grup chat, balas percakapan penghuni,
 * dan siarkan pengumuman resmi (Sprint 3).
 */
export default function ChatIndex({
    rooms,
    activeRoom,
    messages,
    residents,
}: Props) {
    const { flash } = usePage().props;
    const [body, setBody] = useState('');
    const [announcement, setAnnouncement] = useState(false);
    const [sending, setSending] = useState(false);
    const [createOpen, setCreateOpen] = useState(false);

    // Notifikasi hasil aksi (flash message dari controller).
    useEffect(() => {
        if (flash?.success) {
            toast.success(flash.success);
        }
        if (flash?.error) {
            toast.error(flash.error);
        }
    }, [flash]);

    // Fokus ke pesan terbaru saat ganti grup / kirim pesan.
    useEffect(() => {
        window.scrollTo({ top: document.body.scrollHeight });
    }, [activeRoom?.id, messages.length]);

    /**
     * Kirim pesan / pengumuman ke grup aktif.
     */
    function sendMessage(event: React.FormEvent) {
        event.preventDefault();
        if (!activeRoom || !body.trim() || sending) {
            return;
        }

        setSending(true);
        router.post(
            chatMessages.store({ room: activeRoom.id }),
            { body: body.trim(), is_announcement: announcement },
            {
                preserveScroll: true,
                onSuccess: () => setBody(''),
                onFinish: () => setSending(false),
            },
        );
    }

    return (
        <>
            <Head title="Chat & Pengumuman" />

            <div className="flex h-full flex-1 flex-col gap-6 p-6">
                <div className="flex flex-wrap items-center justify-between gap-3">
                    <Heading
                        title="Chat & Pengumuman"
                        description="Pantau grup chat penghuni, balas percakapan, dan siarkan pengumuman resmi."
                    />
                    <Button onClick={() => setCreateOpen(true)}>
                        <Plus className="size-4" /> Grup Baru
                    </Button>
                </div>

                <div className="grid gap-6 lg:grid-cols-[280px_1fr]">
                    {/* Daftar grup */}
                    <Card className="h-fit py-0">
                        <CardContent className="px-0 py-3">
                            <p className="px-4 pb-2 text-xs font-semibold tracking-wide text-muted-foreground uppercase">
                                Grup Chat
                            </p>
                            {rooms.map((room) => {
                                const isActive = room.id === activeRoom?.id;

                                return (
                                    <a
                                        key={room.id}
                                        href={chatRoutes.index.url({
                                            query: { room: room.id },
                                        })}
                                        className={cn(
                                            'block border-l-2 px-4 py-2.5 transition-colors',
                                            isActive
                                                ? 'border-primary bg-muted'
                                                : 'border-transparent hover:bg-muted/60',
                                        )}
                                    >
                                        <p className="truncate text-sm font-medium">
                                            {room.name}
                                        </p>
                                        <p className="mt-0.5 flex items-center gap-2 text-xs text-muted-foreground">
                                            <Users className="size-3" />
                                            {room.members_count} anggota
                                        </p>
                                        {room.last_message && (
                                            <p className="mt-1 truncate text-xs text-muted-foreground">
                                                {room.last_message.is_announcement && (
                                                    <Megaphone className="mr-1 inline size-3 text-amber-600" />
                                                )}
                                                {room.last_message.body}
                                            </p>
                                        )}
                                    </a>
                                );
                            })}
                        </CardContent>
                    </Card>

                    {/* Percakapan grup aktif */}
                    <Card className="flex min-h-[60vh] flex-col py-0">
                        {activeRoom ? (
                            <>
                                <div className="border-b px-6 py-4">
                                    <p className="font-semibold">
                                        {activeRoom.name}
                                    </p>
                                    <p className="text-xs text-muted-foreground">
                                        {activeRoom.description ??
                                            `${activeRoom.members_count} anggota`}
                                    </p>
                                </div>

                                <CardContent className="flex flex-1 flex-col gap-3 overflow-y-auto px-6 py-4">
                                    {messages.length === 0 && (
                                        <p className="py-10 text-center text-sm text-muted-foreground">
                                            Belum ada pesan. Kirim pengumuman
                                            pertama untuk grup ini.
                                        </p>
                                    )}

                                    {messages.map((message) => (
                                        <div
                                            key={message.id}
                                            className={cn(
                                                'max-w-[85%] rounded-xl px-4 py-2.5',
                                                message.is_announcement
                                                    ? 'self-stretch border border-amber-300/60 bg-amber-500/10'
                                                    : message.is_own
                                                      ? 'self-end bg-primary text-primary-foreground'
                                                      : 'self-start bg-muted',
                                            )}
                                        >
                                            {message.is_announcement ? (
                                                <p className="flex items-center gap-1.5 text-[0.7rem] font-semibold tracking-wide text-amber-700 uppercase dark:text-amber-400">
                                                    <Megaphone className="size-3" />
                                                    Pengumuman Resmi ·{' '}
                                                    {message.sender?.name}
                                                </p>
                                            ) : (
                                                <p
                                                    className={cn(
                                                        'text-[0.7rem] font-semibold',
                                                        message.is_own
                                                            ? 'text-primary-foreground/80'
                                                            : 'text-muted-foreground',
                                                    )}
                                                >
                                                    {message.sender?.name}
                                                </p>
                                            )}
                                            <p className="mt-0.5 text-sm whitespace-pre-wrap">
                                                {message.body}
                                            </p>
                                            <p
                                                className={cn(
                                                    'mt-1 text-right text-[0.65rem]',
                                                    message.is_own &&
                                                        !message.is_announcement
                                                        ? 'text-primary-foreground/70'
                                                        : 'text-muted-foreground',
                                                )}
                                            >
                                                {message.sent_at_formatted}
                                            </p>
                                        </div>
                                    ))}
                                </CardContent>

                                {/* Composer */}
                                <form
                                    onSubmit={sendMessage}
                                    className="flex items-center gap-3 border-t px-6 py-4"
                                >
                                    <label className="flex cursor-pointer items-center gap-2 text-xs font-medium text-muted-foreground select-none">
                                        <input
                                            type="checkbox"
                                            checked={announcement}
                                            onChange={(e) =>
                                                setAnnouncement(
                                                    e.target.checked,
                                                )
                                            }
                                            className="size-4 accent-amber-600"
                                        />
                                        <Megaphone className="size-3.5 text-amber-600" />
                                        Pengumuman
                                    </label>
                                    <Input
                                        value={body}
                                        onChange={(e) =>
                                            setBody(e.target.value)
                                        }
                                        placeholder={
                                            announcement
                                                ? 'Tulis pengumuman resmi…'
                                                : 'Tulis pesan…'
                                        }
                                        onKeyDown={(e) => {
                                            if (
                                                e.key === 'Enter' &&
                                                !e.shiftKey
                                            ) {
                                                sendMessage(e);
                                            }
                                        }}
                                    />
                                    <Button
                                        type="submit"
                                        disabled={
                                            sending || !body.trim()
                                        }
                                    >
                                        <Send className="size-4" />
                                        Kirim
                                    </Button>
                                </form>
                            </>
                        ) : (
                            <CardContent className="flex flex-1 items-center justify-center py-16">
                                <div className="text-center text-muted-foreground">
                                    <Skeleton className="mx-auto mb-4 size-12 rounded-full" />
                                    <p className="text-sm">
                                        Belum ada grup chat.
                                    </p>
                                    <p className="text-xs">
                                        Buat grup pertama untuk mulai
                                        berkomunikasi dengan penghuni.
                                    </p>
                                </div>
                            </CardContent>
                        )}
                    </Card>
                </div>
            </div>

            {/* Dialog buat grup baru */}
            <CreateRoomDialog
                open={createOpen}
                onOpenChange={setCreateOpen}
                residents={residents}
            />
        </>
    );
}

ChatIndex.layout = { breadcrumbs };

/**
 * Dialog pembuatan grup chat: nama, deskripsi, pilih anggota.
 */
function CreateRoomDialog({
    open,
    onOpenChange,
    residents,
}: {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    residents: { id: number; name: string }[];
}) {
    const [name, setName] = useState('');
    const [description, setDescription] = useState('');

    /**
     * Anggota terpilih (dipilih satu per satu lewat select; daftar
     * tampil sebagai chip yang bisa dihapus).
     */
    const [selected, setSelected] = useState<number[]>([]);

    function toggleMember(id: number) {
        setSelected((current) =>
            current.includes(id)
                ? current.filter((member) => member !== id)
                : [...current, id],
        );
    }

    function submit(event: React.FormEvent) {
        event.preventDefault();
        if (!name.trim()) {
            return;
        }

        router.post(
            chatRooms.store(),
            {
                name: name.trim(),
                description: description.trim() || null,
                member_ids: selected,
            },
            {
                onSuccess: () => {
                    onOpenChange(false);
                    setName('');
                    setDescription('');
                    setSelected([]);
                },
            },
        );
    }

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="sm:max-w-md">
                <DialogHeader>
                    <DialogTitle>Buat Grup Chat</DialogTitle>
                    <DialogDescription>
                        Grup baru untuk pengumuman atau diskusi khusus
                        (mis. per lantai). Anda otomatis menjadi anggota.
                    </DialogDescription>
                </DialogHeader>

                <form onSubmit={submit} className="space-y-4">
                    <div className="space-y-1.5">
                        <Label htmlFor="room-name">Nama Grup</Label>
                        <Input
                            id="room-name"
                            value={name}
                            onChange={(e) => setName(e.target.value)}
                            placeholder="mis. Lantai 2 — Reguler"
                            required
                        />
                    </div>

                    <div className="space-y-1.5">
                        <Label htmlFor="room-description">Deskripsi</Label>
                        <Textarea
                            id="room-description"
                            value={description}
                            onChange={(e) => setDescription(e.target.value)}
                            placeholder="Opsional — tujuan grup ini"
                            rows={2}
                        />
                    </div>

                    <div className="space-y-1.5">
                        <Label>Tambah Anggota</Label>
                        <Select
                            value=""
                            onValueChange={(value) => {
                                toggleMember(Number(value));
                            }}
                        >
                            <SelectTrigger className="w-full">
                                <SelectValue placeholder="Pilih penghuni…" />
                            </SelectTrigger>
                            <SelectContent>
                                {residents
                                    .filter(
                                        (resident) =>
                                            !selected.includes(resident.id),
                                    )
                                    .map((resident) => (
                                        <SelectItem
                                            key={resident.id}
                                            value={String(resident.id)}
                                        >
                                            {resident.name}
                                        </SelectItem>
                                    ))}
                            </SelectContent>
                        </Select>
                        {selected.length > 0 && (
                            <div className="flex flex-wrap gap-1.5 pt-1">
                                {selected.map((id) => {
                                    const resident = residents.find(
                                        (r) => r.id === id,
                                    );

                                    return (
                                        <button
                                            key={id}
                                            type="button"
                                            onClick={() => toggleMember(id)}
                                            className="inline-flex items-center gap-1 rounded-full bg-secondary px-2.5 py-1 text-xs font-medium hover:bg-secondary/70"
                                        >
                                            {resident?.name}
                                            <span className="text-muted-foreground">
                                                ×
                                            </span>
                                        </button>
                                    );
                                })}
                            </div>
                        )}
                    </div>

                    <DialogFooter>
                        <Button
                            type="button"
                            variant="outline"
                            onClick={() => onOpenChange(false)}
                        >
                            Batal
                        </Button>
                        <Button type="submit" disabled={!name.trim()}>
                            Buat Grup
                        </Button>
                    </DialogFooter>
                </form>
            </DialogContent>
        </Dialog>
    );
}
