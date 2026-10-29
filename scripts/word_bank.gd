extends Node

const WORD_PATH := "res://data/words.json"
var entries: Array[Dictionary] = []
var load_error := ""
var rng := RandomNumberGenerator.new()
var active_path := WORD_PATH
var hard_distractors := false
var equivalence: Array = []
var distractor_cache: Dictionary = {}
const DOMAINS := {
	"身体":["身体","头","手","眼","脚","胸","唇","牙","病","健康","医","血"],
	"时间":["时间","年","月","日","小时","分钟","时期","过去","未来","季节"],
	"金钱":["钱","资金","金融","费用","价格","支付","买","卖","经济","税","利润"],
	"教育":["学习","教育","学生","老师","教师","学校","大学","考试","知识","读","书","词","语言"],
	"人物":["人","者","员","官","领袖","朋友","同伴","男人","女人","绅士"],
	"情感":["心情","感情","情绪","快乐","高兴","悲","愤","怒","恐","担心","信心","喜爱","爱好"],
	"认知":["认为","理解","思考","意识","判断","记忆","聪明","想","感觉","认知"],
	"运动":["移动","旅行","路","到达","行走","跑","飞","滑","转","运输","车辆"],
	"地点":["地区","国家","城市","乡村","房","屋","地域","地方","场所","空间"],
	"自然":["自然","动物","植物","树","木","花","水","火","海","河","天气","太阳","地球","土地"],
	"社会":["政治","社会","法律","制度","政府","组织","战争","和平","条约","权力"],
	"数量":["数量","数目","增加","减少","大小","大量","部分","比率","总数"],
	"物品":["物品","东西","装置","设备","工具","衣服","食物","材料","产品"]
}

func _ready() -> void:
	rng.randomize()
	var rules := FileAccess.open("res://data/meaning_equivalence.json",FileAccess.READ)
	if rules != null:
		var groups: Variant = JSON.parse_string(rules.get_as_text())
		if groups is Array: equivalence = groups
	load_words()

func load_words(path: String = WORD_PATH, expected: int = 0, hard: bool = false) -> bool:
	entries.clear()
	load_error = ""
	distractor_cache.clear()
	active_path = path
	hard_distractors = hard
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		load_error = "Word bank could not be opened."
		push_error(load_error)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		load_error = "Word bank JSON is invalid."
		push_error(load_error)
		return false
	var seen_words := {}
	var seen_meanings := {}
	for value in parsed:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var word := str(value.get("word", "")).strip_edges().to_lower()
		var meaning := str(value.get("meaning", "")).strip_edges()
		if word.is_empty() or meaning.is_empty() or seen_words.has(word):
			continue
		seen_words[word] = true
		seen_meanings[meaning] = true
		var record: Dictionary = value.duplicate(true)
		record.word = word
		record.meaning = meaning
		record.phonetic = str(value.get("phonetic",""))
		record.level = str(value.get("level","CET4"))
		record.gloss_tokens = value.gloss_tokens if value.has("gloss_tokens") else _tokens(meaning)
		record.ambiguity_keys = value.ambiguity_keys if value.has("ambiguity_keys") else _keys(record.gloss_tokens)
		record.domain = _domain(meaning)
		entries.append(record)
	if entries.size() < 4:
		load_error = "Word bank needs at least four distinct meanings."
		push_error(load_error)
		return false
	if expected > 0 and entries.size() != expected:
		load_error = "词库条数未通过校验，无法开始该难度。"
		return false
	return true

func make_question(battle_index: int, recent: Array[String], seen_this_run: Dictionary, missed_this_run: Dictionary = {}) -> Dictionary:
	if entries.size() < 4:
		return {}
	var available: Array[Dictionary] = []
	for entry in entries:
		if not recent.has(str(entry["word"])):
			available.append(entry)
	if available.is_empty():
		available = entries.duplicate()
	var chosen: Dictionary = {}
	if battle_index == 3:
		var missed: Array[Dictionary] = []
		for entry in available:
			if missed_this_run.has(str(entry["word"])):
				missed.append(entry)
		var familiar: Array[Dictionary] = []
		for entry in available:
			if seen_this_run.has(str(entry["word"])):
				familiar.append(entry)
		if familiar.is_empty():
			familiar = available
		familiar.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _weakness_score(a) < _weakness_score(b))
		var top_count := mini(12, familiar.size())
		# A missed word is strongly preferred, but the recent-word exclusion
		# still applies. Remaining questions challenge the lowest Mastery pool.
		if not missed.is_empty() and rng.randf() < 0.7:
			chosen = missed[rng.randi_range(0, missed.size() - 1)]
		else:
			var long_term: Array[Dictionary] = []
			for entry in available:
				if SaveData.mastery_of(str(entry["word"])) < 50:
					long_term.append(entry)
			if not long_term.is_empty():
				long_term.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _weakness_score(a) < _weakness_score(b))
				chosen = long_term[rng.randi_range(0, mini(12, long_term.size()) - 1)]
			else:
				chosen = familiar[rng.randi_range(0, top_count - 1)]
	else:
		var total := 0.0
		var weights: Array[float] = []
		for entry in available:
			var mastery := SaveData.mastery_of(str(entry["word"]))
			var wrongs := int(SaveData.words.get(str(entry["word"]), {}).get("wrong_count", 0))
			var weight := 1.0 + float(100 - mastery) / (35.0 if battle_index == 2 else 100.0) + float(wrongs) * (2.0 if battle_index == 2 else 0.5)
			weights.append(weight)
			total += weight
		var roll := rng.randf_range(0.0, total)
		for i in available.size():
			roll -= weights[i]
			if roll <= 0.0:
				chosen = available[i]
				break
		if chosen.is_empty():
			chosen = available.back()
	return question_for(chosen,missed_this_run)

func _tokens(text: String) -> Array:
	var regex := RegEx.new()
	regex.compile("[一-鿿]+")
	var result: Array = []
	for match_value in regex.search_all(text): result.append(match_value.get_string())
	return result

func _domain(text: String) -> String:
	for domain in DOMAINS:
		for cue in DOMAINS[domain]:
			if text.contains(str(cue)): return str(domain)
	return "其他"

func _keys(tokens: Array) -> Array:
	var result: Array = tokens.duplicate()
	for i in equivalence.size():
		for token in tokens:
			if equivalence[i].has(token):
				result.append("syn_"+str(i))
				break
	return result

func compatible(a: Dictionary, b: Dictionary) -> bool:
	if a.word == b.word or a.meaning == b.meaning: return false
	for key in a.ambiguity_keys:
		if b.ambiguity_keys.has(key): return false
	for left in a.gloss_tokens:
		for right in b.gloss_tokens:
			if str(left).length() >= 2 and str(right).length() >= 2 and (str(left).contains(str(right)) or str(right).contains(str(left))): return false
	return true

func question_for(entry: Dictionary, missed: Dictionary = {}) -> Dictionary:
	var id := str(entry.word)
	if not distractor_cache.has(id):
		var candidates: Array[Dictionary] = []
		for other in entries:
			if compatible(entry,other): candidates.append(other)
		distractor_cache[id] = candidates
	var choices: Array = distractor_cache[id].duplicate()
	choices.shuffle()
	if hard_distractors:
		# Coarse meaning topics and POS rank safe choices; unknown topics fall back.
		choices.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
			var sa: int = (0 if a.get("pos","") == entry.get("pos","") else 100)+(0 if entry.domain != "其他" and a.domain == entry.domain else 50)+absi(str(a.meaning).length()-str(entry.meaning).length())
			var sb: int = (0 if b.get("pos","") == entry.get("pos","") else 100)+(0 if entry.domain != "其他" and b.domain == entry.domain else 50)+absi(str(b.meaning).length()-str(entry.meaning).length())
			return sa < sb)
	var options: Array[String] = [str(entry.meaning)]
	var option_entries: Array = [entry]
	for other in choices:
		if options.has(str(other.meaning)): continue
		var safe := true
		for prior in option_entries:
			if not compatible(prior,other): safe = false; break
		if not safe: continue
		options.append(str(other.meaning))
		option_entries.append(other)
		if options.size() == 4: break
	if options.size() != 4: return {}
	options.shuffle()
	return {"entry":entry,"options":options,"correct_index":options.find(str(entry.meaning)),"mastery":SaveData.mastery_of(id),"missed_this_run":missed.has(id),"weak_word":SaveData.mastery_of(id)<50}

func _weakness_score(entry: Dictionary) -> int:
	var word := str(entry["word"])
	var stats: Dictionary = SaveData.words.get(word, {})
	return SaveData.mastery_of(word) - mini(3, int(stats.get("wrong_count", 0))) * 5

