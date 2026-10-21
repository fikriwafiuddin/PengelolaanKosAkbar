/**
 * Tipe data domain Kost Akbar yang dipakai lintas halaman admin.
 */

export type Facility = {
    id: number;
    name: string;
};

export type RoomStatus = 'kosong' | 'terisi' | 'terbooking';

export type Room = {
    id: number;
    room_number: string;
    type: string;
    price_monthly: number;
    status: RoomStatus;
    status_label: string;
    description: string | null;
    image_url?: string | null;
    facilities: Facility[];
};

export type RoomTypeStat = {
    type: string;
    total: number;
    kosong: number;
};

export type RoomStats = {
    total: number;
    terisi: number;
    kosong: number;
    terbooking: number;
    by_type: RoomTypeStat[];
};

export type ResidentPaymentStatus =
    | 'lunas'
    | 'menunggu_verifikasi'
    | 'belum_bayar'
    | 'tanpa_tagihan';

export type Resident = {
    id: number;
    full_name: string;
    identity_number: string;
    birth_date: string | null;
    address: string | null;
    occupation: string | null;
    guardian_name?: string | null;
    guardian_phone?: string | null;
    payment_status?: ResidentPaymentStatus;
    user?: {
        id: number;
        name: string;
        email: string;
        phone: string | null;
        status: string;
        status_label?: string;
    } | null;
    active_booking?: {
        start_date: string;
        duration_months: number;
        room: {
            id: number;
            room_number: string;
            type: string;
        } | null;
    } | null;
};

export type ResidentStats = {
    total: number;
    lunas: number;
    menunggu_verifikasi: number;
    belum_bayar: number;
};

export type PaymentStatus = 'pending' | 'terverifikasi' | 'ditolak';

export type ChatRoomSummary = {
    id: number;
    name: string;
    description: string | null;
    members_count: number;
    unread_count: number;
    last_message: {
        body: string;
        is_announcement: boolean;
        sender_name: string | null;
        sent_at_formatted: string | null;
    } | null;
};

export type ChatMessage = {
    id: number;
    chat_room_id: number;
    body: string;
    is_announcement: boolean;
    sent_at: string | null;
    sent_at_formatted: string | null;
    is_own: boolean;
    sender: {
        id: number;
        name: string | null;
        role: string;
    } | null;
};

/**
 * Ringkasan tagihan yang terlampir pada data pembayaran.
 */
export type PaymentInvoice = {
    id: number;
    period: string;
    period_label: string;
    amount: number;
    amount_formatted: string;
    status: string;
    status_label: string;
    due_date_formatted: string;
};

export type Payment = {
    id: number;
    invoice_id: number;
    amount: number;
    amount_formatted: string;
    method: 'transfer' | 'tunai';
    method_label: string;
    proof_url: string | null;
    receipt_no: string | null;
    status: PaymentStatus;
    status_label: string;
    paid_at: string | null;
    paid_at_formatted: string | null;
    verified_at: string | null;
    verified_at_formatted: string | null;
    verifier_name?: string | null;
    invoice?: PaymentInvoice | null;
    resident_name?: string | null;
    room_number?: string | null;
};

/**
 * Struktur paginasi standar Inertia/Laravel.
 */
export type Pagination<T> = {
    data: T[];
    current_page: number;
    last_page: number;
    per_page: number;
    total: number;
    from: number | null;
    to: number | null;
};
