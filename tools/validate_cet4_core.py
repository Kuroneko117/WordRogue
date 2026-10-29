"""Structural checks and exhaustive answer-pool checks; no claim of exhaustive semantic proof."""
import pathlib, json, re, random, hashlib
ROOT=pathlib.Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'data/cet4_core_1500.json').read_text(encoding='utf-8'))
old=json.loads((ROOT/'data/words.json').read_text(encoding='utf-8'))
errors=[]
def check(ok,msg):
    if not ok: errors.append(msg)
check(len(data)==1500,'Count is not 1500')
check(len({x['word'].lower() for x in data})==1500,'Duplicate normalized words')
check(len(old)==120,'Original 120 altered')
for x in data:
    check(bool(re.fullmatch('[a-z]+',x['word'])),x['word']+': invalid lemma')
    check(x['level']=='CET4' and x['meaning'].strip() and re.search('[一-鿿]',x['meaning']),x['word']+': missing Chinese')
    check(x['phonetic'].startswith('/') and x['phonetic'].endswith('/') and not re.search('[一-鿿<>]',x['phonetic']),x['word']+': invalid phonetic')
    check(not re.search(r'<[^>]*>|&[a-z]+;|\\n|\ufffd|[\x00-\x08]',x['meaning']),x['word']+': residue')
    check(bool(re.match(r'^[a-z]+\.',x['meaning'])),x['word']+': missing POS')
    check(len(x['meaning'])<=44,x['word']+': display too long')
def compatible(a,b):
    if a['word']==b['word'] or a['meaning']==b['meaning']: return False
    if set(a['ambiguity_keys'])&set(b['ambiguity_keys']): return False
    return not any(len(x)>=2 and len(y)>=2 and (x in y or y in x) for x in a['gloss_tokens'] for y in b['gloss_tokens'])
minimum=9999
for x in data:
    pool=[y for y in data if compatible(x,y)]
    minimum=min(minimum,len(pool))
    selected=[x]
    for y in pool:
        if all(compatible(p,y) for p in selected): selected.append(y)
        if len(selected)==4: break
    check(len(selected)==4 and len({p['meaning'] for p in selected})==4,x['word']+': insufficient non-equivalent choices')
report={'passed':not errors,'errors':errors,'count':len(data),'unique':len({x['word'] for x in data}),
    'original_count':len(old),'shared_words':len({x['word'] for x in old}&{x['word'] for x in data}),
    'entries_checked':len(data),'min_distractor_candidates':minimum,'source':'ECDICT cet4 tag / frq',
    'semantic_limit':'Token, substring and curated equivalence-group checks cannot prove absence of every semantic ambiguity. 100 entries reviewed separately; no human-teacher full review claimed.',
    'sha256':hashlib.sha256((ROOT/'data/cet4_core_1500.json').read_bytes()).hexdigest()}
(ROOT/'docs/CET4_1500_VALIDATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
raise SystemExit(0 if not errors else 1)
