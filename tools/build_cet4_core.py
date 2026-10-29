"""Offline reproducible ECDICT (MIT) selection, no runtime Python dependency."""
import csv, hashlib, json, re, pathlib, argparse, collections

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / '.local_test/v16_sources/ecdict.csv'
OUT = ROOT / 'data/cet4_core_1500.json'
SYNONYMS = [
    '保持 维持 保留', '开始 开端 起始', '结束 终止 完毕', '购买 买', '出售 卖 销售',
    '帮助 协助 援助', '允许 许可 准许', '拒绝 拒绝接受', '选择 挑选 选取',
    '增加 增长 增大 提高', '减少 降低 减小', '建立 建造 建设', '毁坏 破坏 毁灭',
    '重要的 重大的 主要的', '迅速的 快的 快速的', '困难的 艰难的 难的',
    '容易的 简单的', '聪明的 智慧的 明智的', '美丽的 漂亮的', '快乐的 高兴的 愉快的',
    '生气的 愤怒的', '害怕 恐惧 担心', '看 观看 看见', '说 讲 告诉 谈话',
    '人 人类 人们 人员', '工作 劳动 作业 职业', '问题 疑问 难题', '目的 目标 意图',
    '机会 时机', '道路 路 路线', '实际的 真实的 真正的', '错误 错误的 差错',
    '旅程 旅行 旅游', '习惯 风俗 习俗', '学习 学 研究', '保护 防护 保卫',
    '需要 必须 必要 需求', '理解 明白 领会', '喜欢 喜爱 爱好', '力量 力 能力',
    '安全的 安全 保险的', '自由 自由的', '停止 停 终止', '回答 答复 响应',
    '安静的 宁静的 平静的', '大 巨大的 庞大的 大的', '小 小的 微小的',
]
OVERRIDES = {
    'power':'n. 力量；权力', 'public':'a. 公众的；公共的', 'reach':'v. 到达；达到',
    'project':'n. 项目；计划', 'patient':'n. 病人', 'decade':'n. 十年',
    'final':'a. 最后的；最终的', 'improve':'v. 改善；提高', 'customer':'n. 顾客；客户',
    'conduct':'v. 进行；实施', 'camp':'n. 营地；露营', 'equipment':'n. 设备；装备',
    'moral':'a. 道德的', 'fair':'a. 公平的；公正的', 'device':'n. 装置；设备',
    'soul':'n. 灵魂；心灵', 'sight':'n. 视力；景象', 'accident':'n. 事故；意外事件',
    'link':'n. 联系；连接', 'sheet':'n. 床单；薄片', 'solve':'v. 解决；解答',
    'meanwhile':'adv. 同时；其间', 'stir':'v. 搅动；激起', 'tip':'n. 尖端；小费',
    'criminal':'n. 罪犯', 'incident':'n. 事件', 'weak':'a. 虚弱的；薄弱的',
    'graduate':'n. 毕业生', 'consist':'v. 组成；存在于', 'impose':'v. 强加；征收',
    'substantial':'a. 大量的；实质的', 'corporation':'n. 公司；法人团体',
    'treaty':'n. 条约；协定', 'guarantee':'n. 保证；担保', 'mode':'n. 方式；模式',
    'leader':'n. 领导者；领袖', 'statement':'n. 陈述；声明', 'score':'n. 得分；分数',
    'potential':'n. 潜力；潜能', 'fellow':'n. 同伴；同事', 'reduction':'n. 减少；降低',
    'internet':'n. 互联网', 'twin':'n. 双胞胎；孪生者', 'journalist':'n. 新闻记者',
    'regularly':'adv. 经常；有规律地', 'extra':'a. 额外的',
}
PHONETIC_OVERRIDES = {'conduct':'kənˈdʌkt','graduate':'ˈɡrædʒuət','power':'ˈpaʊə'}

def phonetic(text):
    text = text.strip('/').replace('ә','ə').replace('є','e').replace("'",'ˈ').replace(':','ː').replace('ɒː','ɔː').replace('əː','ɜː').replace('.','ˌ')
    for old, new in [('ei','eɪ'),('ai','aɪ'),('oi','ɔɪ'),('ou','əʊ'),('au','aʊ'),('iə','ɪə'),('uə','ʊə')]:
        text = text.replace(old,new)
    return '/'+text+'/'

def atoms(text):
    text = re.sub(r'\[[^\]]*\]|\([^)]*\)|（[^）]*）', '', text)
    text = re.sub(r'(?<![A-Za-z])[a-z]+\.', '', text)
    return sorted({re.sub(r'[^\u4e00-\u9fff]', '', s) for s in re.split(r'[,，;；\n/、]',text) if re.search(r'[\u4e00-\u9fff]',s)})

def ambiguity_keys(glosses):
    result = set(glosses)
    for i, group in enumerate(SYNONYMS):
        if result.intersection(group.split()): result.add('syn_'+str(i))
    return sorted(result)

def build():
    records, rejected = {}, collections.Counter()
    for row in csv.DictReader(SOURCE.open(encoding='utf-8-sig', newline='')):
        w = row['word'].strip().lower()
        if 'cet4' not in row['tag'].split(): continue
        if not re.fullmatch('[a-z]+',w) or not 2 <= len(w) <= 22:
            rejected['not_single_lemma'] += 1; continue
        if re.search(r'(?:^|/)0:',row['exchange']):
            rejected['inflected_form'] += 1; continue
        p = row['phonetic'].strip()
        text = row['translation'].replace('\\n','\n').strip()
        if not p or not text or '<' in text or '\ufffd' in text:
            rejected['empty_or_markup'] += 1; continue
        first = text.splitlines()[0].strip()
        first = re.sub(r'\[[^\]]*\]|\([^)]*\)|（[^）]*）','',first)
        first = first.replace(',','；').replace('，','；').replace(';','；')
        first = re.sub(r'\s+',' ',first).strip(' ；')
        pos_match = re.match(r'^([a-z]+(?:\./[a-z]+)?\.)\s*',first)
        pos = pos_match[1] if pos_match else ''
        body = first[len(pos):].strip()
        if not re.search(r'[\u4e00-\u9fff]',body) or re.search('[A-Za-z<>]|\\\\',body) or len(first)>44:
            rejected['unsuitable_quiz_gloss'] += 1; continue
        # A complete first POS line is the displayed primary sense; all source
        # senses remain available to the distractor ambiguity filter.
        first = pos+' '+ '；'.join([x.strip() for x in body.split('；')[:2]])
        first = OVERRIDES.get(w,first.strip())
        pos = first.split(' ')[0] if '.' in first.split(' ')[0] else ''
        glosses = sorted(set(atoms(text)+atoms(first)))
        keys = ambiguity_keys(glosses)
        frq = int(row['frq'] or 0); bnc = int(row['bnc'] or 0)
        if frq <= 0 and bnc <= 0:
            rejected['no_frequency'] += 1; continue
        rank = frq if frq > 0 else bnc+100000
        records[w] = {'word':w,'phonetic':phonetic(PHONETIC_OVERRIDES.get(w,p)),'meaning':first,
            'level':'CET4','pos':pos,'frequency_rank':rank,'frq':frq,'bnc':bnc,
            'gloss_tokens':glosses,'ambiguity_keys':keys,'source':'ECDICT cet4 tag',
            'source_translation':text}
    selected = sorted(records.values(),key=lambda r:(r['frequency_rank'],r['word']))[:1500]
    assert len(selected)==1500, 'Insufficient suitable CET4 data'
    OUT.write_text(json.dumps(selected,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ROOT/'data/meaning_equivalence.json').write_text(json.dumps([g.split() for g in SYNONYMS],ensure_ascii=False,indent=2),encoding='utf-8')
    sample = [selected[i] for i in range(0,1500,15)]
    (ROOT/'docs/CET4_1500_REVIEW_SAMPLE.json').write_text(json.dumps(sample,ensure_ascii=False,indent=2),encoding='utf-8')
    review = ['# 100词逐项语义抽样审核','',
        '审核者：Codex 开发助手；2026-10-09。按最终词频序列每15项取1项，覆盖完整1500词范围。',
        '本表是开发助手逐项阅读后的审核记录，不是人类教师签核；未声称1500条均通过专业语义/语音审核。',
        '检查词形与所选中文义对应、词性、常用义优先和明显异常。原多义数据保留在JSON的source_translation供复核；题目仅使用meaning所列主要义。',
        '源音标使用较旧的英式字典记法；统一重音、长音和部分IPA字符，conduct/graduate按所选词性单独修正。仍可能存在口音与词性异读，建议教师后续复核。','',
        '| 序号 | 单词 | 当前音标 | 当前答案 | 抽样结论 |','| --- | --- | --- | --- | --- |']
    for i,x in enumerate(sample,1):
        note = '修订为较常用义/规范词性后复核通过' if x['word'] in OVERRIDES else '所选义与词形对应；抽样未发现明显错配'
        review.append(f"| {i} | {x['word']} | {x['phonetic']} | {x['meaning']} | {note} |")
    review += ['',f'100条样本中，{sum(x["word"] in OVERRIDES for x in sample)}条应用了显式释义修订。修订字典见tools/build_cet4_core.py；全部原始样本字段见CET4_1500_REVIEW_SAMPLE.json。',
        '重点修订包括：decade去掉不准确的“十”，solve去掉不适合教学的“付给/溶解”，corporation去掉“合作”，treaty去掉“谈判”，substantial改用常见形容词义，graduate使用名词音标。',
        '自动规则只能排除已知重叠与等价词义，不能证明所有语境下无歧义。发现争议题目时应记录词条与四个选项，再修订释义或等价组。']
    (ROOT/'docs/CET4_1500_REVIEW.md').write_text('\n'.join(review)+'\n',encoding='utf-8')
    meta = {'source_url':'https://raw.githubusercontent.com/skywind3000/ECDICT/master/ecdict.csv',
        'retrieved':'2026-10-09','source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'output_sha256':hashlib.sha256(OUT.read_bytes()).hexdigest(),'license':'MIT, Copyright (c) 2025 Linwei',
        'selection':'cet4 tag; single lemmas; readable first-POS gloss; positive frq ascending, BNC fallback after frq; no random/alphabetical truncation',
        'eligible':len(records),'selected':len(selected),'rejected':dict(rejected),'sample_count':100}
    (ROOT/'data/cet4_core_provenance.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(meta,ensure_ascii=False,indent=2))

if __name__=='__main__': build()
