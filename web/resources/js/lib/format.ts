/**
 * Helper format tampilan bersama (Rupiah & tanggal Indonesia).
 */

export function formatRupiah(value: number | string | null | undefined): string {
    const num = typeof value === 'string' ? Number.parseFloat(value) : value;

    if (num === null || num === undefined || Number.isNaN(num)) {
        return '-';
    }

    return `Rp ${new Intl.NumberFormat('id-ID', {
        maximumFractionDigits: 0,
    }).format(num)}`;
}

export function formatDate(
    value: string | Date | null | undefined,
    withTime = false,
): string {
    if (!value) {
        return '-';
    }

    const date = typeof value === 'string' ? new Date(value) : value;

    if (Number.isNaN(date.getTime())) {
        return '-';
    }

    return new Intl.DateTimeFormat('id-ID', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
    }).format(date);
}

/**
 * Awalan nama untuk avatar inisial (mis. "Dimas Pratama" -> "DP").
 */
export function initialsOf(name: string): string {
    return name
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((part) => part[0]?.toUpperCase() ?? '')
        .join('');
}
