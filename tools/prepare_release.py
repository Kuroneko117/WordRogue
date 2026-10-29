"""Create a small, separate export project; never edit original art or user data."""
import argparse, hashlib, json, pathlib, re, shutil, zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--stage', default='.local_test/release/staging')
args = parser.parse_args()
stage = (ROOT/args.stage).resolve()
if ROOT not in stage.parents or stage == ROOT:
    raise SystemExit('Staging must be a child of this project')
stage.mkdir(parents=True, exist_ok=True)
if (stage/'project.godot').exists():
    raise SystemExit('Stage already exists; choose a new --stage to avoid stale files')
inventory = []
excluded = {'assets/enemies/library_battle.png'}
for folder in ['scripts','scenes','data','assets']:
    for source in (ROOT/folder).rglob('*'):
        if not source.is_file() or '.godot' in source.parts: continue
        rel = source.relative_to(ROOT).as_posix()
        if rel in excluded: continue
        target = stage/rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        if source.suffix == '.json':
            parsed = json.loads(source.read_text(encoding='utf-8-sig'))
            target.write_text(json.dumps(parsed, ensure_ascii=False, separators=(',',':')), encoding='utf-8')
            assert parsed == json.loads(target.read_text(encoding='utf-8'))
        if source.suffix == '.import' and source.name.endswith(('.png.import','.jpg.import','.jpeg.import')):
            text = target.read_text(encoding='utf-8')
            # Native Godot WebP importer preserves alpha/aspect. Source images untouched.
            limit = 1280 if '/backgrounds/' in rel else (1024 if '/characters/' in rel else 768)
            for key, value in [('compress/mode','1'),('compress/lossy_quality','0.82'),('process/size_limit',str(limit))]:
                text, count = re.subn(r'(?m)^'+re.escape(key)+r'=.*$',key+'='+value,text)
                if not count: text += '\n'+key+'='+value+'\n'
            target.write_text(text, encoding='utf-8')
        inventory.append({'path':rel,'source_bytes':source.stat().st_size,'stage_bytes':target.stat().st_size,'sha256_source':hashlib.sha256(source.read_bytes()).hexdigest()})
for filename in ['project.godot','export_presets.cfg']:
    shutil.copy2(ROOT/filename,stage/filename)
manifest = {'source':str(ROOT),'stage':str(stage),'excluded':sorted(excluded),'files':inventory,'notes':['Source art/audio are byte-identical; only native importer settings change textures.', 'OGG music is retained at original quality.', 'JSON whitespace minified; parsed values equal.', 'Development records, backups, screenshots, reference art, tools, tests and user data excluded.']}
(stage.parent/'release_inputs.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
archive = stage.parent/'WordRogue-release-source.zip'
with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as package:
    for item in inventory:
        package.write(stage/item['path'],item['path'])
    for name in ['project.godot','export_presets.cfg']: package.write(stage/name,name)
print(json.dumps({'stage':str(stage),'stage_bytes':sum(p.stat().st_size for p in stage.rglob('*') if p.is_file()),'source_zip_bytes':archive.stat().st_size,'files':len(inventory)},ensure_ascii=False))
