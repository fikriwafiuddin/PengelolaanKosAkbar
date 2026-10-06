"""
Uji alur web admin (Inertia) secara end-to-end:
login admin -> dashboard -> rooms (CRUD via service) -> residents -> print.
Dijalankan manual: python tests/web_flow_test.py
"""
import json
import re
import sys
import urllib.request
from http.cookiejar import CookieJar

BASE = 'http://localhost:8000'
jar = CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))


def fetch(path, headers=None, data=None, method=None):
    req = urllib.request.Request(
        BASE + path,
        data=data.encode() if isinstance(data, str) else data,
        method=method,
    )
    for key, value in (headers or {}).items():
        req.add_header(key, value)
    try:
        with opener.open(req) as response:
            return response.status, response.read().decode(), dict(response.headers)
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode(), dict(error.headers)


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def fetch_no_redirect(path, headers=None):
    """Permintaan yang TIDAK mengikuti redirect (untuk uji tolakan akses)."""
    no_redirect_opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(jar),
        NoRedirect(),
    )
    req = urllib.request.Request(BASE + path)
    for key, value in (headers or {}).items():
        req.add_header(key, value)
    try:
        with no_redirect_opener.open(req) as response:
            return response.status, response.read().decode(), dict(response.headers)
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode(), dict(error.headers)


def xsrf_token():
    for cookie in jar:
        if cookie.name == 'XSRF-TOKEN':
            return urllib.parse.unquote(cookie.value)
    return ''


def main():
    failures = []

    def check(label, condition, detail=''):
        status = 'PASS' if condition else 'FAIL'
        print(f'[{status}] {label} {detail}')
        if not condition:
            failures.append(label)

    # 1. Ambil halaman login (HTML) -> versi inertia
    status, body, _ = fetch('/login')
    match = re.search(r'<script data-page="app" type="application/json">(.*?)</script>', body, re.S)
    version = json.loads(match.group(1))['version'] if match else None
    check('GET /login', status == 200 and version is not None, f'(inertia v={version})')

    inertia = {
        'Content-Type': 'application/json',
        'X-Inertia': 'true',
        'Accept': 'application/json',
        'X-Inertia-Version': version,
        'X-XSRF-TOKEN': xsrf_token(),
        'Referer': BASE + '/login',
        'X-Requested-With': 'XMLHttpRequest',
    }

    # 2. Login admin
    status, body, _ = fetch('/login', headers=inertia, method='POST', data=json.dumps({
        'email': 'admin@kostakbar.id', 'password': 'password',
    }))
    check('POST /login (admin)', status in (200, 302) and 'two_factor' in body)

    # 3. Dashboard
    status, body, _ = fetch('/dashboard', headers=inertia)
    page = json.loads(body)
    overview = page['props']['overview']
    check('GET /dashboard', page['component'] == 'dashboard')
    check('  okupansi 20/29', overview['rooms']['terisi'] == 20 and overview['rooms']['total'] == 29,
          f"({overview['rooms']['terisi']}/{overview['rooms']['total']})")
    check('  penghuni 20 (16/1/3)', overview['residents'] == {
        'total': 20, 'lunas': 16, 'menunggu_verifikasi': 1, 'belum_bayar': 3,
    }, f"({overview['residents']})")

    # 4. Data kamar + pencarian
    status, body, _ = fetch('/rooms?q=ac&status=kosong', headers=inertia)
    page = json.loads(body)
    props = page['props']
    check('GET /rooms?q=ac&status=kosong', page['component'] == 'rooms/index')
    check('  hasil pencarian 3 kamar AC kosong', props['rooms']['total'] == 3,
          f"({props['rooms']['total']})")
    check('  fasilitas & tipe terpasang', len(props['facilities']) == 10 and len(props['types']) == 3)

    # 5. Data penghuni + status pembayaran
    status, body, _ = fetch('/residents?status=menunggu_verifikasi', headers=inertia)
    page = json.loads(body)
    props = page['props']
    check('GET /residents?status=menunggu_verifikasi', page['component'] == 'residents/index')
    check('  1 penghuni menunggu verifikasi', props['residents']['total'] >= 1
          and len(props['residents']['data']) == 1)
    check('  kartu statistik', props['stats']['lunas'] == 16, f"({props['stats']})")

    # 6. Cetak katalog
    status, body, _ = fetch('/rooms/print', headers=inertia)
    page = json.loads(body)
    check('GET /rooms/print', page['component'] == 'rooms/print'
          and len(page['props']['rooms']) == 29)

    # 7. CRUD kamar: tambah -> ubah -> hapus
    facility_id = None
    status, body, _ = fetch('/rooms', headers=inertia)
    for facility in json.loads(body)['props']['facilities']:
        facility_id = facility['id']
        break

    room_payload = {
        'room_number': '30', 'type': 'Lantai 1 - AC', 'price_monthly': '650000',
        'status': 'kosong', 'description': 'Kamar uji otomatis.', 'facility_ids': [facility_id],
    }
    inertia['X-XSRF-TOKEN'] = xsrf_token()
    status, body, _ = fetch('/rooms', headers=inertia, method='POST', data=json.dumps(room_payload))
    check('POST /rooms (tambah kamar 30)', status in (200, 302, 303), f'(status={status})')

    status, body, _ = fetch('/rooms?q=30', headers=inertia)
    created = next((r for r in json.loads(body)['props']['rooms']['data'] if r['room_number'] == '30'), None)
    check('  kamar 30 tersimpan + fasilitas', created is not None and bool(created['facilities']),
          f"(id={created['id'] if created else '-'})")

    if created:
        room_payload['price_monthly'] = '700000'
        inertia['X-XSRF-TOKEN'] = xsrf_token()
        status, body, _ = fetch(f"/rooms/{created['id']}", headers=inertia, method='PUT', data=json.dumps(room_payload))
        status, body, _ = fetch('/rooms?q=30', headers=inertia)
        updated = next((r for r in json.loads(body)['props']['rooms']['data'] if r['id'] == created['id']), None)
        check('PUT /rooms/{id} (ubah harga 700k)',
              updated and float(updated['price_monthly']) == 700000.0,
              f"(harga={updated['price_monthly'] if updated else '-'})")

        inertia['X-XSRF-TOKEN'] = xsrf_token()
        status, body, _ = fetch(f"/rooms/{created['id']}", headers=inertia, method='DELETE')
        status, body, _ = fetch('/rooms?q=30', headers=inertia)
        total_after = json.loads(body)['props']['rooms']['total']
        check('DELETE /rooms/{id} (hapus kamar uji)', total_after == 0, f'(sisa={total_after})')

    # 8. Penghuni TIDAK boleh masuk dashboard web
    jar.clear()
    status, body, _ = fetch('/login')
    match = re.search(r'<script data-page="app" type="application/json">(.*?)</script>', body, re.S)
    version2 = json.loads(match.group(1))['version'] if match else version
    status, body, _ = fetch('/login', headers={
        'Content-Type': 'application/json', 'X-Inertia': 'true', 'Accept': 'application/json',
        'X-Inertia-Version': version2, 'X-XSRF-TOKEN': xsrf_token(),
        'Referer': BASE + '/login', 'X-Requested-With': 'XMLHttpRequest',
    }, method='POST', data=json.dumps({
        'email': 'dimaspratama@kostakbar.id', 'password': 'password',
    }))
    # Login penghuni boleh sukses, tapi dashboard harus menolak & me-logout
    if status in (200, 302):
        status2, _, headers2 = fetch_no_redirect('/dashboard', headers={
            'X-Inertia': 'true', 'Accept': 'application/json',
            'X-Inertia-Version': version2,
        })
        redirected = status2 in (301, 302) or 'location' in {k.lower() for k in headers2}
        check('penghuni ditolak di dashboard web', redirected, f'(status={status2})')
    else:
        check('penghuni ditolak di dashboard web', True, '(login web ditolak)')

    print()
    if failures:
        print(f'{len(failures)} GAGAL: {failures}')
        sys.exit(1)
    print('Semua uji web admin LULUS.')


if __name__ == '__main__':
    main()
