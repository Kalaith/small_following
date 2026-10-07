extends RefCounted
## Branch summaries plus the branch buttons, branch picker and node browser built from them.

const Layout = preload("res://scripts/ritual_layout.gd")
const Style = preload("res://scripts/ritual_style.gd")
const Widgets = preload("res://scripts/ritual_widgets.gd")

var screen: Control
var bar: HBoxContainer
var buttons: Dictionary = {}
var order: Array[String] = []
var browse_ids: Array[String] = []


func _init(owner_screen: Control, branch_bar: HBoxContainer) -> void:
	screen = owner_screen
	bar = branch_bar


func summaries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ordered: Array[String] = ["talk", "run", "persuade", "gather", "helper"]
	for item in screen.catalog:
		var branch: String = str(item.get("branch", ""))
		if not ordered.has(branch):
			ordered.append(branch)
	for branch in ordered:
		var ids: Array[String] = []
		var owned: int = 0
		var available: int = 0
		for item in screen.catalog:
			if str(item.get("branch", "")) != branch:
				continue
			var id: String = str(item.get("id", ""))
			ids.append(id)
			owned += 1 if screen.rank_of(id) > 0 else 0
			available += 1 if screen.state_of(id) == "affordable" else 0
		if not ids.is_empty():
			ids.sort_custom(func(a: String, b: String) -> bool: return int(screen.by_id[a].get("ring", 1)) < int(screen.by_id[b].get("ring", 1)))
			result.append({"id": branch, "title": Layout.branch_title(branch), "count": ids.size(), "owned": owned, "available": available, "ids": ids})
	return result


func focus(branch: String) -> void:
	for summary in summaries():
		if str(summary.id) != branch:
			continue
		var target: String = str(summary.ids[0])
		for id in summary.ids:
			if screen.state_of(id) == "affordable":
				target = str(id)
				break
			if screen.state_of(id) == "unaffordable":
				target = str(id)
		screen.hovered_id = ""
		screen.focus_node(target)
		return


func rebuild() -> void:
	for child in bar.get_children():
		bar.remove_child(child)
		child.queue_free()
	buttons.clear()
	order.clear()
	screen.branch_picker.clear()
	var items: Array[Dictionary] = summaries()
	for summary in items:
		var branch: String = str(summary.id)
		order.append(branch)
		screen.branch_picker.add_item(str(summary.title))
		screen.branch_picker.set_item_metadata(screen.branch_picker.item_count - 1, branch)
		if items.size() <= 6:
			var button: Button = Widgets.button(bar, str(summary.title), false)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 12)
			button.pressed.connect(focus.bind(branch))
			buttons[branch] = button
	bar.visible = items.size() <= 6
	screen.branch_picker.visible = items.size() > 6
	update()


func update() -> void:
	if not is_instance_valid(screen.node_picker):
		return
	var selected_branch: String = str(screen.by_id.get(screen.selected_id, {}).get("branch", ""))
	# Summarizing asks progression for every node's state, so gather once per refresh.
	var items: Array[Dictionary] = summaries()
	for summary in items:
		var text: String = "%s  %d/%d" % [summary.title, summary.owned, summary.count]
		var tooltip: String = "%s: %d of %d nodes owned; %d ready to buy. Click to focus this branch." % [summary.title, summary.owned, summary.count, summary.available]
		if buttons.has(summary.id):
			var button: Button = buttons[summary.id]
			button.text = text + (" +" if int(summary.available) > 0 else "")
			button.tooltip_text = tooltip
			button.add_theme_color_override("font_color", Style.WHITE if str(summary.id) == selected_branch else Style.MUTED)
		var index: int = order.find(str(summary.id))
		if index >= 0:
			screen.branch_picker.set_item_text(index, "%s · %d ready" % [text, summary.available])
			if str(summary.id) == selected_branch:
				screen.branch_picker.select(index)
	if selected_branch.is_empty():
		screen.branch_picker.select(-1)
		screen.branch_picker.text = "Browse %d ritual branches" % order.size()
	browse_ids.clear()
	screen.node_picker.clear()
	for summary in items:
		if str(summary.id) != selected_branch:
			continue
		for id in summary.ids:
			browse_ids.append(str(id))
			var state: String = screen.state_of(id)
			var state_text: String = {"locked": "locked", "affordable": "ready", "unaffordable": "needs resources", "purchased": "complete"}.get(state, state)
			screen.node_picker.add_item("%s · %d/%d · %s" % [screen.by_id[id].get("title", id), screen.rank_of(id), screen.max_rank_of(id), state_text])
			screen.node_picker.set_item_metadata(screen.node_picker.item_count - 1, str(id))
			if str(id) == screen.selected_id:
				screen.node_picker.select(browse_ids.size() - 1)
	screen.node_picker.disabled = browse_ids.is_empty()
	if browse_ids.is_empty():
		screen.node_picker.add_item("Choose a branch above to browse its nodes")
	screen.node_picker.tooltip_text = "Browse every node in the selected branch, including locked nodes. Choosing one centers it at a readable scale."
	screen.focus_button.disabled = screen.selected_id.is_empty()
