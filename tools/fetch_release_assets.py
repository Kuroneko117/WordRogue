"""Fetch the matching official Windows template and OFL Chinese subsets.

No global installation. ZIP members are checked against the archive's CRC32.
Use --allow-invalid-tls only for this machine's failing certificate chain.
"""
import argparse, hashlib, json, pathlib, re, ssl, struct, time, urllib.parse, urllib.request, zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--allow-invalid-tls', action='store_true')
parser.add_argument('--fonts-only', action='store_true')
parser.add_argument('--template-only', action='store_true')
args = parser.parse_args()
context = ssl._create_unverified_context() if args.allow_invalid_tls else ssl.create_default_context()

def fetch(url, headers=None):
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'WordRogue-release-assets/1.0', **(headers or {})})
            with urllib.request.urlopen(req, context=context, timeout=90) as response:
                data = response.read()
                return data, dict(response.headers), response.geturl()
        except Exception:
            if attempt == 3: raise
            time.sleep(2)

def sha(data): return hashlib.sha256(data).hexdigest()

def template():
    cache = ROOT / '.local_test/release/cache'
    cache.mkdir(parents=True, exist_ok=True)
    output = cache / 'windows_release_x86_64.exe'
    if output.exists():
        print('Template already present', output.stat().st_size, flush=True)
        return
    url = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
    # Exact size obtained from the official release API (asset 519674520).
    archive_size = 1281349702
    tail, headers, resolved = fetch(url, {'Range': f'bytes={archive_size-65557}-{archive_size-1}'})
    if 'Content-Range' not in headers and 'content-range' not in headers:
        raise RuntimeError('Server did not honor ZIP range request; refusing full archive download')
    marker = tail.rfind(b'PK\x05\x06')
    if marker < 0: raise RuntimeError('ZIP end directory absent')
    end = struct.unpack_from('<4s4H2IH', tail, marker)
    directory_size, directory_offset = end[5:7]
    central, _, _ = fetch(resolved, {'Range': f'bytes={directory_offset}-{directory_offset+directory_size-1}'})
    offset = 0
    found = None
    while offset < len(central):
        h = struct.unpack_from('<4s6H3I5H2I', central, offset)
        if h[0] != b'PK\x01\x02': raise RuntimeError('Invalid central directory')
        name = central[offset+46:offset+46+h[10]].decode('utf-8')
        if name.endswith('/windows_release_x86_64.exe') or name == 'windows_release_x86_64.exe':
            found = (name, h[4], h[7], h[8], h[9], h[16])
        offset += 46+h[10]+h[11]+h[12]
    if found is None: raise RuntimeError('Matching Windows release template absent')
    name, method, crc, packed, unpacked, local_offset = found
    print('Downloading only', name, packed, 'bytes, archive', headers.get('Content-Range'), flush=True)
    header, _, _ = fetch(resolved, {'Range': f'bytes={local_offset}-{local_offset+29}'})
    local = struct.unpack_from('<4s5H3I2H', header)
    begin = local_offset+30+local[9]+local[10]
    payload, _, _ = fetch(resolved, {'Range': f'bytes={begin}-{begin+packed-1}'})
    data = zlib.decompress(payload, -15) if method == 8 else payload
    if len(data) != unpacked or zlib.crc32(data) & 0xffffffff != crc:
        raise RuntimeError('Template size/CRC mismatch')
    if data[:2] != b'MZ': raise RuntimeError('Not a Windows executable')
    output.write_bytes(data)
    (cache/'template_source.json').write_text(json.dumps({'source': url, 'member': name, 'bytes': len(data), 'sha256': sha(data), 'crc32': hex(crc), 'verification': 'ZIP member size and CRC32; archive SHA256 not checked for range download', 'tls_verification_disabled': args.allow_invalid_tls}, indent=2), encoding='utf-8')
    print('Template ready', len(data), flush=True)

def fonts():
    out = ROOT/'assets/fonts'
    out.mkdir(parents=True, exist_ok=True)
    texts = ''.join(p.read_text(encoding='utf-8-sig') for folder in ['scripts','data'] for p in (ROOT/folder).rglob('*') if p.suffix in ['.gd','.json'])
    chars = sorted(set(texts) - set('\r\n\t'))
    source = 'https://raw.githubusercontent.com/google/fonts/main/ofl/notosanssc/OFL.txt'
    license_text, _, _ = fetch(source)
    (out/'OFL.txt').write_bytes(license_text)
    manifest = {'family': 'Noto Sans SC', 'license': 'SIL Open Font License 1.1', 'license_source': source, 'character_count': len(chars), 'files': []}
    for i in range(0, len(chars), 300):
        chunk = ''.join(chars[i:i+300])
        css_url = 'https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400&text='+urllib.parse.quote(chunk)
        css, _, _ = fetch(css_url)
        match = re.search(rb'url\((https://[^)]+)\)', css)
        if not match: raise RuntimeError('Font URL not found: '+css[:200].decode())
        url = match[1].decode()
        data, _, _ = fetch(url)
        extension = 'woff2' if data[:4] == b'wOF2' else ('woff' if data[:4] == b'wOFF' else 'ttf')
        name = f'noto_sc_{i//300:02d}.{extension}'
        (out/name).write_bytes(data)
        manifest['files'].append({'file': name, 'source': url, 'bytes': len(data), 'sha256': sha(data), 'characters': chunk})
        print('Font subset', name, len(data), flush=True)
    # The SC font deliberately excludes IPA and some decorative symbols.
    for family, directory, characters in [
        ('Noto Sans','notosans','ŋɒɔəɜɪʃʊʌʒˈˌː'),
        ('Noto Sans Symbols 2','notosanssymbols2','↻⌁◈⚑✦✧'),
    ]:
        css_url = 'https://fonts.googleapis.com/css2?family='+urllib.parse.quote(family)+':wght@400&text='+urllib.parse.quote(characters)
        css, _, _ = fetch(css_url)
        match = re.search(rb'url\((https://[^)]+)\)', css)
        if not match: raise RuntimeError('Supplementary font URL missing')
        url = match[1].decode()
        data, _, _ = fetch(url)
        extension = 'woff2' if data[:4] == b'wOF2' else ('woff' if data[:4] == b'wOFF' else 'ttf')
        name = directory+'.'+extension
        (out/name).write_bytes(data)
        license_url = 'https://raw.githubusercontent.com/google/fonts/main/ofl/'+directory+'/OFL.txt'
        license_data, _, _ = fetch(license_url)
        (out/(directory+'_OFL.txt')).write_bytes(license_data)
        manifest['files'].append({'file':name,'family':family,'source':url,'license_source':license_url,'bytes':len(data),'sha256':sha(data),'characters':characters})
        print('Supplementary font', name, len(data), flush=True)
    (out/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')

if not args.fonts_only: template()
if not args.template_only: fonts()
