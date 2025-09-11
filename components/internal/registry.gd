extends Node

# paths
const item_path: String = "res://data/game/items"

# registry
var items: Dictionary = {}

func _ready() -> void:
	# register items
	items.clear()
	_register_items_recursive(item_path)

func _register_items_recursive(path: String) -> void:
	# open path
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Registry: Failed to open %s" % path)
		return

	# get and register all items in directory and subdirectories
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# is subdirectory
		if dir.current_is_dir() and not file_name.begins_with("."):
			_register_items_recursive(path + "/" + file_name)

		# is resource file
		elif file_name.ends_with(".tres"):
			var res_path = path + "/" + file_name
			var res: Resource = load(res_path)

			# verify as item data
			if res is ItemData:
				# get file name as item id
				var id := file_name.get_basename() # removes ".tres"

				# store item
				items[id] = res

		file_name = dir.get_next()
	dir.list_dir_end()
