"""Extract original MJPEG frames and PCM from Godot's AVI, without re-rendering."""
import json, pathlib, struct, wave

ROOT = pathlib.Path(__file__).resolve().parents[1]
FOLDER = ROOT/'.local_test/taptap_submission_capture'
raw = (FOLDER/'gameplay.avi').read_bytes()
assert raw[:4] == b'RIFF' and raw[8:12] == b'AVI '
frames = []
audio = []
audio_format = None
fps = 30

def walk(start, end, parent=b''):
    global audio_format, fps
    pos = start
    while pos+8 <= end:
        tag = raw[pos:pos+4]
        size = struct.unpack_from('<I',raw,pos+4)[0]
        body = pos+8
        finish = body+size
        if finish > len(raw): raise RuntimeError('Truncated AVI')
        if tag == b'LIST':
            walk(body+4,finish,raw[body:body+4])
        elif tag == b'avih':
            microseconds = struct.unpack_from('<I',raw,body)[0]
            fps = round(1_000_000/microseconds)
        elif tag == b'strf' and size >= 16 and parent == b'strl':
            code, channels, rate, byte_rate, align, bits = struct.unpack_from('<HHIIHH',raw,body)
            if code == 1 and channels in [1,2,6,8] and bits in [16,32]:
                audio_format = dict(channels=channels,rate=rate,bits=bits)
        elif tag in [b'00dc',b'00db'] and parent in [b'movi',b'rec ']:
            frames.append(raw[body:finish])
        elif tag == b'01wb' and parent in [b'movi',b'rec ']:
            audio.append(raw[body:finish])
        pos = finish+(size & 1)

walk(12,len(raw))
if not frames or not audio or not audio_format:
    raise RuntimeError(f'AVI streams missing: {len(frames)} frames, {len(audio)} audio blocks, {audio_format}')
out = FOLDER/'frames'
out.mkdir(exist_ok=True)
for i, frame in enumerate(frames):
    assert frame[:2] == b'\xff\xd8', 'Expected original MJPEG frame'
    (out/f'frame_{i:06d}.jpg').write_bytes(frame)
with wave.open(str(FOLDER/'gameplay.wav'),'wb') as wav:
    wav.setnchannels(audio_format['channels'])
    wav.setsampwidth(audio_format['bits']//8)
    wav.setframerate(audio_format['rate'])
    wav.writeframes(b''.join(audio))
result = dict(frames=len(frames),fps=fps,duration=len(frames)/fps,audio=audio_format)
(FOLDER/'streams.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result))
