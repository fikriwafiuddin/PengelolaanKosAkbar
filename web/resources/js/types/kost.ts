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
    payment_status?: ResidentPaymentStatus;
    user?: {
        id: number;
        name: string;
        email: string;
        phone: string | null;
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
