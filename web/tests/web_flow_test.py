"""
Uji alur web admin (Inertia) + API secara end-to-end untuk sprint1rev:
login admin -> dashboard -> rooms (CRUD + urut numerik + foto) ->
residents (biodata + validasi akun) -> print -> alur persetujuan
registrasi (register -> login ditolak -> admin setujui -> login -> ubah profil).
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


def api(path, method='GET', body=None, token=None):
    """Panggilan REST API publik/ber-token (tanpa sesi browser)."""
    headers = {'Content-Type': 'application/json', 'Accept': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(body).encode() if body is not None else None,
        method=method,
    )
    for key, value in headers.items():
        req.add_header(key, value)
    fresh = urllib.request.build_opener()
    try:
        with fresh.open(req) as response:
            return response.status, json.loads(response.read().decode() or '{}')
    except urllib.error.HTTPError as error:
        raw = error.read().decode()
        return error.code, json.loads(raw) if raw else {}


def inertia_headers(version, referer='/login'):
    return {
        'Content-Type': 'application/json',
        'X-Inertia': 'true',
        'Accept': 'application/json',
        'X-Inertia-Version': version,
        'X-XSRF-TOKEN': xsrf_token(),
        'Referer': BASE + referer,
        'X-Requested-With': 'XMLHttpRequest',
    }


def main():
    failures = []

    def check(label, condition, detail=''):
        status = 'PASS' if condition else 'FAIL'
        print(f'[{status}] {label} {detail}')
        if not condition:
            failures.append(label)

    # ==============================================================
    # A. Alur persetujuan registrasi (sebelum login admin)
    # ==============================================================
    # Email unik per-run agar suite bisa dijalankan berulang tanpa
    # bentrok constraint unique (tanpa harus reseed).
    import time
    register_payload = {
        'email': f'e2e-approve-{int(time.time())}@contoh.com',
        'password': 'rahasia123',
        'password_confirmation': 'rahasia123',
        'full_name': 'E2e Approve',
        'identity_number': '3573999888777000',
        'phone': '+6289911100011',
        'birth_date': '2000-01-15',
        'address': 'Kota Kediri',
        'occupation': 'Karyawan',
        'guardian_name': 'Bapak E2e',
        'guardian_phone': '+6281311100011',
    }

    status, body = api('/api/v1/auth/register', 'POST', register_payload)
    check('API register (valid)', status == 201 and 'token' not in body.get('data', {}),
          f'(status={status})')

    status, body = api('/api/v1/auth/login', 'POST', {
        'email': register_payload['email'], 'password': register_payload['password'],
    })
    blocked = status == 422 and 'menunggu validasi' in json.dumps(body, ensure_ascii=False).lower()
    check('API login ditolak saat menunggu validasi', blocked, f'(status={status})')

    status, body = api('/api/v1/auth/register', 'POST', {
        **register_payload, 'email': 'nik-salah@contoh.com', 'identity_number': '12345',
    })
    check('API register NIK < 16 digit ditolak', status == 422 and 'identity_number' in body.get('errors', {}))

    status, body = api('/api/v1/auth/register', 'POST', {
        **register_payload, 'email': 'anak@contoh.com', 'birth_date': '2012-01-01',
    })
    check('API register usia < 18 ditolak', status == 422 and 'birth_date' in body.get('errors', {}))

    # ==============================================================
    # B. Login admin & halaman-halaman web
    # ==============================================================
    status, body_html, _ = fetch('/login')
    match = re.search(r'<script data-page="app" type="application/json">(.*?)</script>', body_html, re.S)
    version = json.loads(match.group(1))['version'] if match else None
    check('GET /login', status == 200 and version is not None, f'(inertia v={version})')

    inertia = inertia_headers(version)
    status, body, _ = fetch('/login', headers=inertia, method='POST', data=json.dumps({
        'email': 'admin@kostakbar.id', 'password': 'password',
    }))
    check('POST /login (admin)', status in (200, 302) and 'two_factor' in body)

    # Dashboard
    status, body, _ = fetch('/dashboard', headers=inertia)
    page = json.loads(body)
    overview = page['props']['overview']
    check('GET /dashboard', page['component'] == 'dashboard')
    check('  okupansi 20/29', overview['rooms']['terisi'] == 20 and overview['rooms']['total'] == 29,
          f"({overview['rooms']['terisi']}/{overview['rooms']['total']})")

    # Data kamar: urut numerik + foto
    status, body, _ = fetch('/rooms', headers=inertia)
    page = json.loads(body)
    rooms_data = page['props']['rooms']['data']
    numbers = [int(r['room_number']) for r in rooms_data]
    check('GET /rooms urut numerik 1..15', numbers == sorted(numbers), f'({numbers[:6]}...)')
    check('  thumbnail image_url terisi', all(r.get('image_url') for r in rooms_data),
          f"(contoh: {rooms_data[0].get('image_url')})")

    status, body, _ = fetch('/rooms?sort=desc', headers=inertia)
    numbers_desc = [int(r['room_number']) for r in json.loads(body)['props']['rooms']['data']]
    check('GET /rooms?sort=desc urut 29..15',
          numbers_desc == sorted(numbers_desc, reverse=True), f'({numbers_desc[:6]}...)')

    status, body, _ = fetch('/rooms?q=ac&status=kosong', headers=inertia)
    props = json.loads(body)['props']
    check('GET /rooms?q=ac&status=kosong', json.loads(body)['component'] == 'rooms/index')
    check('  hasil pencarian 3 kamar AC kosong', props['rooms']['total'] == 3,
          f"({props['rooms']['total']})")

    # Data penghuni: biodata + filter status akun
    status, body, _ = fetch('/residents', headers=inertia)
    page = json.loads(body)
    props = page['props']
    check('GET /residents (biodata)', page['component'] == 'residents/index')
    first = props['residents']['data'][0] if props['residents']['data'] else {}
    check('  kolom biodata lengkap', all(
        k in first for k in ('identity_number', 'guardian_name', 'guardian_phone', 'user')
    ), f"(NIK+guardian ok, total={props['residents']['total']})")

    status, body, _ = fetch('/residents?status=menunggu_validasi', headers=inertia)
    props = json.loads(body)['props']
    pending_rows = props['residents']['data']
    check('GET /residents?status=menunggu_validasi', props['residents']['total'] == 2
          and all(r['user']['status'] == 'menunggu_validasi' for r in pending_rows),
          f"(total={props['residents']['total']}: fixture + e2e)")

    # Cetak katalog
    status, body, _ = fetch('/rooms/print', headers=inertia)
    page = json.loads(body)
    print_rooms = page['props']['rooms']
    check('GET /rooms/print', page['component'] == 'rooms/print' and len(print_rooms) == 29)

    # CRUD kamar: tambah -> ubah -> hapus
    facility_id = None
    status, body, _ = fetch('/rooms', headers=inertia)
    for facility in json.loads(body)['props']['facilities']:
        facility_id = facility['id']
        break

    room_payload = {
        'room_number': '30', 'type': 'Lantai 1 - AC', 'price_monthly': '650000',
        'status': 'kosong', 'description': 'Kamar uji otomatis.', 'facility_ids': [facility_id],
        'remove_image': False,
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
        status, _, _ = fetch(f"/rooms/{created['id']}", headers=inertia, method='PUT',
                             data=json.dumps(room_payload))
        status, body, _ = fetch('/rooms?q=30', headers=inertia)
        updated = next((r for r in json.loads(body)['props']['rooms']['data'] if r['id'] == created['id']), None)
        check('PUT /rooms/{id} (ubah harga 700k)',
              updated and float(updated['price_monthly']) == 700000.0,
              f"(harga={updated['price_monthly'] if updated else '-'})")

        inertia['X-XSRF-TOKEN'] = xsrf_token()
        status, _, _ = fetch(f"/rooms/{created['id']}", headers=inertia, method='DELETE')
        status, body, _ = fetch('/rooms?q=30', headers=inertia)
        total_after = json.loads(body)['props']['rooms']['total']
        check('DELETE /rooms/{id} (hapus kamar uji)', total_after == 0, f'(sisa={total_after})')

    # ==============================================================
    # C. Admin menyetujui akun -> pengguna bisa login & ubah profil
    # ==============================================================
    status, body, _ = fetch('/residents?q=' + urllib.parse.quote('E2e Approve'), headers=inertia)
    e2e_resident = next((r for r in json.loads(body)['props']['residents']['data']
                         if r['user']['email'] == register_payload['email']), None)
    check('cari pendaftar e2e di Data Penghuni', e2e_resident is not None)
    user_id = e2e_resident['user']['id'] if e2e_resident else None

    if user_id:
        inertia['X-XSRF-TOKEN'] = xsrf_token()
        status, _, _ = fetch(f'/residents/{user_id}/validation', headers=inertia,
                             method='PUT', data=json.dumps({'status': 'aktif'}))
        check('PUT /residents/{id}/validation (setujui)', status in (200, 302, 303),
              f'(status={status})')

        status, body = api('/api/v1/auth/login', 'POST', {
            'email': register_payload['email'], 'password': register_payload['password'],
        })
        token = body.get('data', {}).get('token')
        check('API login setelah disetujui', status == 200 and bool(token), f'(status={status})')

        if token:
            status, body = api('/api/v1/auth/profile', 'PUT', {
                'full_name': 'E2e Approve Baru',
                'phone': '+6289911100022',
                'birth_date': '2000-01-15',
                'address': 'Kediri Baru',
                'occupation': 'Wirausaha',
                'guardian_name': 'Bapak E2e Baru',
                'guardian_phone': '+6281311100022',
            }, token=token)
            resident = body.get('data', {}).get('resident', {})
            check('API ubah profil (PUT /auth/profile)',
                  status == 200 and resident.get('full_name') == 'E2e Approve Baru'
                  and resident.get('guardian_phone') == '+6281311100022',
                  f"(status={status})")

            status, body = api('/api/v1/auth/profile', 'PUT', {
                'full_name': '', 'phone': '', 'birth_date': '2000-01-15',
                'guardian_phone': '',
            }, token=token)
            check('API ubah profil validasi (nama kosong ditolak)',
                  status == 422 and 'full_name' in body.get('errors', {}))

            api('/api/v1/auth/logout', 'POST', token=token)

    # ==============================================================
    # D. Penghuni TIDAK boleh masuk dashboard web
    # ==============================================================
    jar.clear()
    status, body_html, _ = fetch('/login')
    match = re.search(r'<script data-page="app" type="application/json">(.*?)</script>', body_html, re.S)
    version2 = json.loads(match.group(1))['version'] if match else version
    status, _, _ = fetch('/login', headers=inertia_headers(version2), method='POST', data=json.dumps({
        'email': 'dimaspratama@kostakbar.id', 'password': 'password',
    }))
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
