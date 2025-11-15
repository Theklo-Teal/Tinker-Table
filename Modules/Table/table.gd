@tool
extends Control
class_name Table

#TODO: Changing column order by dragging titles.
#TODO: Make sure sorting is stable between the last sorted action and the next.
## A Control node that displays a simple table where cells in the same row are grouped as the same element, so add and remove multiple cells at a time.[br]
## You start by setting the [code]columns[/code] variable with titles of each column. Then [code]add_row()[/code] or [code]add_dict_row()[/code] to insert [code]String[/code] data.[br]
## You may [code]set_row_id()[/code] to index rows independently of their order on the table.[br]
## You may [code]set_cell_meta()[/code] to add data which is used in comparisons when sorting the rows. Cells without metadata will be sorted according to the text associated to them.[br]
## You may extend this script to create your own sorting logic by implementing [code]sort_by_{column_title}()[/code] functions. Check [code]_row_sorting()[/code] for details on how sorting works.[br]

var _rows_idx : Dictionary[int, int] ## idx -> id This is an index between a rows's index as a child of the HBox and the arbitrary ids to find them.
var _rows_ids : Dictionary[int, int] ## id -> idx Back-reference to «_rows_idx»
var _col_title : Dictionary[String, int] ## title -> idx A reference of where columns associated with a title are.
var _title_col : Dictionary[int, String]
var _rows_meta : Dictionary[int, Variant] ## idx -> metadata

var _sort_dir : bool ## false = Ascending, true = Descending
var _last_sort_title : String  ## The last column that was used for sorting
var _sort_chevron_radius = 6
var _sort_chevron_margin = 3

@export var show_header : bool = true :
	set(val):
		show_header = val
		_header.visible = val
		_landing.get_node("Spacer").visible = val
		_landing.queue_redraw()
@export var columns : Array[String] : ## The titles of columns the table includes.
	set(val):
		columns = val
		_col_title.clear()
		for n in range(_columns.get_children().size()):
			_columns.get_child(n).queue_free()
			_header.get_child(n).queue_free()
		var n : int = 0
		for title in val:
			var title_butt = Button.new()
			title_butt.text = title
			title_butt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_butt.focus_mode = Control.FOCUS_NONE
			title_butt.show_behind_parent = true
			title_butt.custom_minimum_size.x = _sort_chevron_radius + _sort_chevron_margin
			title_butt.pressed.connect(_on_title_pressed.bind(title))
			#title_butt.button_down.connect(_on_title_held.bind(title))
			#title_butt.button_up.connect(_on_title_release.bind(title))
			_header.add_child(title_butt)
			var col_box = VBoxContainer.new()
			col_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_columns.add_child(col_box)
			_col_title[title] = n
			_title_col[n] = title
			n += 1

@export_color_no_alpha var base_color : Color ## The primary color of the UI, so custom drawing can use correct contrasting colors.

var _header : BoxContainer
var _landing : BoxContainer
var _columns : BoxContainer
func _init() -> void:
	var scene = preload("Table.tscn").instantiate()
	add_child(scene)
	scene.owner = self
	
	_header = scene.get_node("%Header")
	_landing = scene.get_node("%Landing")
	_columns = scene.get_node("%Columns")
	
	scene.get_node("ScrollHeader").get_h_scroll_bar().share(scene.get_node("ScrollLanding").get_h_scroll_bar())

func _ready() -> void:
	_landing.draw.connect(_on_landing_draw)
	_landing.gui_input.connect(_on_landing_gui_input)
	_header.draw.connect(_on_header_draw)

func _draw() -> void:
	var max_hei : float = 0
	for n in range(_header.get_child_count()):
		var title_butt = _header.get_child(n)
		title_butt.custom_minimum_size.x = _columns.get_child(n).size.x
		max_hei = max(max_hei, title_butt.size.y)
	_sort_chevron_radius = max_hei * 0.3
	_sort_chevron_margin = _sort_chevron_radius * 1.4

func _on_header_draw():
	if _last_sort_title.is_empty():
		return
	var title_butt = get_title_col(_last_sort_title)
	title_butt = _header.get_child(title_butt)
	
	var centre = Vector2(
		title_butt.position.x + _sort_chevron_margin * 2,
		title_butt.size.y * 0.5
	)
	if _sort_dir:
		_header.draw_arc(centre, _sort_chevron_radius, 0, PI, 3, base_color.inverted(), 3)
	else:
		_header.draw_arc(centre, _sort_chevron_radius, PI, TAU, 3, base_color.inverted(), 3)

func _on_landing_draw():
	var spacer_y : float = 0 
	if show_header:
		spacer_y = _header.size.y + 4
		_landing.get_node("Spacer").custom_minimum_size.y = _header.size.y
	
	# Highlight selected rows
	for row in selected_rows:
		var rect = get_row_rect(row)
		rect.position.y += spacer_y - 2
		rect.size.y += 3
		_landing.draw_rect(rect, base_color.lightened(0.4))
	
	# Draw horizontal rules
	#FIXME For some reason this is not drawing properly at on_ready.
	for row in _rows_idx:
		var rect := get_row_rect(row)
		rect.position.y += spacer_y + 2
		var start := Vector2(rect.position.x, rect.end.y)
		_landing.draw_line(start, rect.end, base_color.lightened(0.4))
	
	# Highlight mouse hover cell
	if hover_cell.x >= 0 and hover_cell.y >= 0:
		var rect = get_cell_rect(hover_cell.x, hover_cell.y) 
		rect.position.y += spacer_y - 2
		rect.size.y += 3
		_landing.draw_rect(rect, base_color.lightened(0.3))



var hover_cell := -Vector2i.ONE
var selected_rows : Array[int]
func _on_cell_mouse_enter(cell:Control):
	var col = cell.get_parent().get_index()
	var idx = cell.get_index()
	hover_cell = Vector2i(col, idx)
	_landing.queue_redraw()

func _on_landing_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_released() and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.is_key_pressed(KEY_CTRL) and not selected_rows.is_empty():
			var start = min(selected_rows[-1], hover_cell.y)
			var stop = max(selected_rows[-1], hover_cell.y)
			var new_select : Array[int]
			selected_rows.clear()
			for each in range(start, stop + 1):
				new_select.append(each)
			selected_rows = new_select
		else:
			selected_rows = [hover_cell.y]
		_landing.queue_redraw()


## Sort rows according to a title.
func _on_title_pressed(title:String):
	if _last_sort_title == title:
		_sort_dir = not _sort_dir
	else:
		_last_sort_title = title
		_sort_dir = false
	
	var col = get_title_col(title)
	
	var picks : Array = _rows_idx.keys()
	picks.sort_custom(_row_sorting.bind(title, col))
	if _sort_dir:
		picks.reverse()
	
	for col_item in _columns.get_children():
		var childs : Array[Control]
		for i in picks:
			childs.append(col_item.get_child(i))
		for each in childs:
			col_item.move_child(each, 0)
	
	var new_rows_idx : Dictionary[int, int]
	var new_rows_ids : Dictionary[int, int]
	var new_rows_meta : Dictionary[int, Variant]
	for old_idx in range(picks.size()):
		var new_idx = picks[old_idx]
		var id = _rows_idx[old_idx]
		new_rows_ids[id] = new_idx
		new_rows_idx[new_idx] = id
		if old_idx in _rows_meta:
			new_rows_meta[new_idx] = _rows_meta[old_idx]
	_rows_idx = new_rows_idx
	_rows_ids = new_rows_ids
	_rows_meta = new_rows_meta
	
	_header.queue_redraw()

## Row sorting delegator function. Extend this script and write your own «sort_by_{column_title}» functions for custom rules when sorting a table.
func _row_sorting(a, b, title:String, col:int):
	var sort_func_name = "sort_by_" + title
	var val_a = get_cell_meta(a, title, get_cell_text(col, a))
	var val_b = get_cell_meta(b, title, get_cell_text(col, b))
	if has_method(sort_func_name):
		return call(sort_func_name, val_a, val_b)
	else:
		return str(val_a).filecasecmp_to(str(val_b)) > 0

func _add_cell_text(col:int, _row:int, text:String = "---") -> Control:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	
	_columns.get_child(col).add_child(label)
	return label

## This adds a row, where each argument is a cell text. Their order should line up with the default order of columns.
func add_row(data:Array[String]) -> int:
	var idx = 0
	var id = 0
	if not _rows_idx.is_empty():
		idx = _rows_idx.keys().max() + 1
	if not _rows_ids.is_empty():
		id = _rows_ids.keys().max() + 1
	for col in range(data.size()):
		var cell = _add_cell_text(col, idx, data[col])
		var title = _title_col[col]
		cell.mouse_entered.connect(_on_cell_mouse_enter.bind(title, id))
		_rows_ids[id] = idx
		_rows_idx[idx] = id
	return idx

## This adds a row given a dictionary where the keys are column titles and the values are the items pertaining those columns. Returns the index of the row.
func add_dict_row(data:Dictionary) -> int:
	var idx = 0
	var id = 0
	if not _rows_idx.is_empty():
		idx = _rows_idx.keys().max() + 1
	if not _rows_ids.is_empty():
		id = _rows_ids.keys().max() + 1
		
	for title in data:
		var cell = _add_cell_text(get_title_col(title), idx, data[title])
		cell.mouse_entered.connect(_on_cell_mouse_enter.bind(cell))
		_rows_ids[id] = idx
		_rows_idx[idx] = id
	_landing.queue_redraw()
	return idx

## Set id to a row. If the id was already set to a row, then it returns `false`.
func set_row_id(idx:int, id:int) -> bool:
	if not id in _rows_ids:
		_rows_idx[idx] = id
		_rows_ids[id] = idx
		return true
	else:
		return false

## Set a metadata for a row.
func set_row_meta(idx:int, meta):
	_rows_meta[idx] = meta
## Get the metadata of a row, or return default if there's none.
func get_row_meta(idx:int, default=null) -> Variant:
	return _rows_meta.get(idx, default)

## Set a value that's used to test when sorting rows.
func set_cell_meta(idx:int, col:String, meta):
	get_cell_item(get_title_col(col), idx).set_meta("_table_sort_val_", meta)
## Get metadata of a cell, that's used for sorting rows.
func get_cell_meta(idx:int, col:String, default=null) -> Variant:
	return get_cell_item(get_title_col(col), idx).get_meta("_table_sort_val_", default)

## Remove a row at the position in the table.
func remove_row(idx:int):
	for col in _columns.get_children():
		col.get_child(idx).queue_free()
	
	var all_idx = _rows_idx.keys()
	all_idx.sort()
	var new_idx : Dictionary[int, int]
	var new_ids : Dictionary[int, int]
	var i : int = 0
	for each in all_idx:
		if each == idx:
			continue
		new_idx[i] = _rows_idx[each]
		new_ids[_rows_idx[each]] = i
		i += 1
	_rows_idx = new_idx
	_rows_ids = new_ids


## Get the coordinate or index of a column of the given title.
func get_title_col(title:String) -> int:
	return _col_title.get(title, -1)

## Get the index of the row with a given id.
func get_row_index(id:int) -> int:
	return _rows_ids.get(id, -1)

## Get the id of the row at the given index.
func get_row_ids(idx:int) -> int:
	return _rows_idx.get(idx, -1)

## Get a list of the elements of the row at the given index.
func get_row_items(idx:int) -> Array[Control]:
	var items : Array[Control]
	for col : BoxContainer in _columns.get_children():
		items.append(col.get_child(idx))
	return items

## Get the Rect2 of the row at the given index.
func get_row_rect(idx:int) -> Rect2:
	var items = get_row_items(idx)
	var row_x : float = 0
	var max_y : float = 0
	for each in items:
		row_x += each.size.x + 4
		max_y = max(max_y, each.size.y)
	
	return Rect2(
		items[0].position,
		Vector2(row_x, max_y)
		)

## Get a list of the strings in the elements of the row at the given index.
func get_row_text(idx:int) -> Array[String]:
	var items : Array[String]
	for col : BoxContainer in _columns:
		items.append(col.get_child(idx).text)
	return items

## Get the Control element of the cell at a given coordinate.
func get_cell_item(col:int, row:int) -> Control:
	var col_item = _columns.get_child(col)
	var cell_item = col_item.get_child(row)
	return cell_item

## Get the text of the Control element of the cell at the given coordinate.
func get_cell_text(col:int, row:int) -> String:
	return _columns.get_child(col).get_child(row).text

## Get the Rect2 of the cell at the given coordinate.
func get_cell_rect(col:int, row:int) -> Rect2:
	var column = _columns.get_child(col)
	var col_rect = column.get_rect()
	var cell_rect = column.get_child(row).get_rect()
	return Rect2(
		Vector2(col_rect.position.x, cell_rect.position.y),
		cell_rect.size
		)


func get_selected_rows() -> PackedInt32Array:
	return selected_rows as PackedInt32Array
