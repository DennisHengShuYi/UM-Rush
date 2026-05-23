extends Node

var panel: Panel
var question_label: Label
var buttons: Array = []

var questions = [
	{"q": "What does OOP stand for?",
	 "options": ["Object Oriented Programming", "Open Operating Protocol", "Output Object Process"],
	 "answer": 0},
	{"q": "Which data structure is LIFO?",
	 "options": ["Queue", "Stack", "Array"],
	 "answer": 1},
	{"q": "What is Big O of binary search?",
	 "options": ["O(n)", "O(log n)", "O(n²)"],
	 "answer": 1},
	{"q": "What does CPU stand for?",
	 "options": ["Central Processing Unit", "Computer Personal Unit", "Core Power Usage"],
	 "answer": 0},
	{"q": "Which language runs in a browser?",
	 "options": ["Python", "Java", "JavaScript"],
	 "answer": 2},
	{"q": "What does RAM stand for?",
	 "options": ["Random Access Memory", "Read All Memory", "Run Any Module"],
	 "answer": 0},
	{"q": "Which is a loop in GDScript?",
	 "options": ["repeat", "for", "loop"],
	 "answer": 1},
]

var current_answer = -1

func _ready():
	_build_ui()

func _build_ui():
	var canvas: CanvasLayer = get_parent().get_node("CanvasLayer")

	panel = Panel.new()
	panel.position = Vector2(240, 150)
	panel.size = Vector2(800, 350)
	panel.visible = false
	
	# Add these lines to make panel visible
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.2, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(1.0, 0.8, 0.0, 1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	panel.add_theme_stylebox_override("panel", style)

	canvas.add_child(panel)

	question_label = Label.new()
	question_label.position = Vector2(20, 20)
	question_label.size = Vector2(760, 80)
	question_label.add_theme_font_size_override("font_size", 28)
	question_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.0))	
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(question_label)

	# Create 3 answer buttons
	for i in range(3):
		var btn = Button.new()
		btn.position = Vector2(20, 120 + i * 70)
		btn.size = Vector2(760, 55)
		btn.add_theme_font_size_override("font_size", 22)
		var idx = i
		btn.pressed.connect(func(): _on_answer(idx))
		panel.add_child(btn)
		buttons.append(btn)

func ask_question():
	var q = questions[randi() % questions.size()]
	current_answer = q["answer"]
	question_label.text = "📝 " + q["q"]
	for i in range(3):
		buttons[i].text = q["options"][i]
	panel.visible = true

func _on_answer(selected: int):
	panel.visible = false
	if selected == current_answer:
		get_parent().on_correct_answer()
	else:
		get_parent().on_wrong_answer()

func _process(_delta: float) -> void:
	pass
