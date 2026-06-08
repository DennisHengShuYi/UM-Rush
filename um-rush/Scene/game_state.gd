extends Node

signal score_changed(level_score: int, total_score: int)

const CAT_SCORE := 250
const POWERUP_SCORE := 75
const HIT_PENALTY := 120
const CORRECT_ANSWER_SCORE := 200
const SNOOZE_SCORE := 25

var total_score := 0
var total_score_at_level_start := 0
var streak := 0
var combo_multiplier := 1.0
var current_level_id := 0
var current_level_score := 0
var hits := 0
var powerups_used := {}
var cats_collected := {}
var last_grade := "F"
var last_level_summary := {}
var unlocked_levels := 1

func start_level(level_id: int) -> void:
	if level_id != current_level_id:
		total_score_at_level_start = total_score
	else:
		total_score = total_score_at_level_start

	current_level_id = level_id
	current_level_score = 0
	hits = 0
	powerups_used = {}
	last_level_summary = {}
	cats_collected.erase(str(level_id))
	streak = 0
	combo_multiplier = 1.0
	score_changed.emit(current_level_score, total_score)

func add_score(amount: int) -> void:
	var final_amount = amount
	if amount > 0:
		final_amount = int(amount * combo_multiplier)
	current_level_score = max(current_level_score + final_amount, 0)
	score_changed.emit(current_level_score, total_score)

func record_hit() -> void:
	hits += 1
	reset_streak()
	add_score(-HIT_PENALTY)

func record_powerup(power_type: String) -> void:
	powerups_used[power_type] = int(powerups_used.get(power_type, 0)) + 1
	increase_streak(1)
	add_score(POWERUP_SCORE)

func record_cat(level_id: int) -> bool:
	var key := str(level_id)
	if cats_collected.has(key):
		return false
	cats_collected[key] = true
	increase_streak(1)
	add_score(CAT_SCORE)
	return true

func record_correct_answer() -> void:
	increase_streak(1)
	add_score(CORRECT_ANSWER_SCORE)

func record_snooze() -> void:
	increase_streak(1)
	add_score(SNOOZE_SCORE)

func reset_streak() -> void:
	streak = 0
	combo_multiplier = 1.0
	score_changed.emit(current_level_score, total_score)

func increase_streak(amount: int = 1) -> void:
	streak += amount
	_update_multiplier()
	score_changed.emit(current_level_score, total_score)

func _update_multiplier() -> void:
	if streak >= 15:
		combo_multiplier = 3.0
	elif streak >= 10:
		combo_multiplier = 2.0
	elif streak >= 5:
		combo_multiplier = 1.5
	else:
		combo_multiplier = 1.0

func finish_level(stats: Dictionary) -> Dictionary:
	var distance_score := int(stats.get("distance", 0.0) / 100.0)
	var time_bonus := int(max(float(stats.get("time_left", 0.0)), 0.0) * 10.0)
	var stress_penalty := int(float(stats.get("stress", 0.0)) * 3.0)
	current_level_score = max(current_level_score + distance_score + time_bonus - stress_penalty, 0)
	total_score += current_level_score
	last_grade = calculate_grade()
	last_level_summary = {
		"level": current_level_id,
		"level_score": current_level_score,
		"total_score": total_score,
		"grade": last_grade,
		"hits": hits,
		"cats": cats_collected.size(),
		"powerups": powerups_used.duplicate()
	}
	score_changed.emit(current_level_score, total_score)
	
	if current_level_id >= unlocked_levels:
		unlocked_levels = current_level_id + 1
		
	return last_level_summary

func calculate_grade() -> String:
	if current_level_score >= 900 and hits < 5:
		return "A+"
	if current_level_score >= 700 and hits < 5:
		return "A"
	if current_level_score >= 450 and hits < 5:
		return "B"
	if current_level_score >= 200:
		return "C"
	return "F"

func format_level_result(prefix: String = "") -> String:
	var summary := last_level_summary
	var heading := prefix if prefix != "" else "Level complete!"
	return "%s\nScore: %d | Total: %d\nGrade: %s | Cats: %d | Hits: %d" % [
		heading,
		int(summary.get("level_score", current_level_score)),
		int(summary.get("total_score", total_score)),
		str(summary.get("grade", last_grade)),
		int(summary.get("cats", cats_collected.size())),
		int(summary.get("hits", hits))
	]

func reset_game() -> void:
	total_score = 0
	total_score_at_level_start = 0
	streak = 0
	combo_multiplier = 1.0
	current_level_id = 0
	current_level_score = 0
	hits = 0
	powerups_used = {}
	cats_collected = {}
	last_grade = "F"
	last_level_summary = {}
