class_name PluginUtilities


static func is_valid_url(url: String) -> bool:
	var regex = RegEx.new()
	var url_pattern = "/(https:\\/\\/www\\.|http:\\/\\/www\\.|https:\\/\\/|http:\\/\\/)?[a-zA-Z]{2,}(\\.[a-zA-Z]{2,})(\\.[a-zA-Z]{2,})?\\/[a-zA-Z0-9]{2,}|((https:\\/\\/www\\.|http:\\/\\/www\\.|https:\\/\\/|http:\\/\\/)?[a-zA-Z]{2,}(\\.[a-zA-Z]{2,})(\\.[a-zA-Z]{2,})?)|(https:\\/\\/www\\.|http:\\/\\/www\\.|https:\\/\\/|http:\\/\\/)?[a-zA-Z0-9]{2,}\\.[a-zA-Z0-9]{2,}\\.[a-zA-Z0-9]{2,}(\\.[a-zA-Z0-9]{2,})?/g"
	regex.compile(url_pattern)
	
	return regex.search(url) != null


static func filepath_is_valid(path: String):
	return not path.is_empty() and path.is_absolute_path() and ResourceLoader.exists(path)


static func dirpath_is_valid(path: String):
	return not path.is_empty() and path.is_absolute_path() and DirAccess.dir_exists_absolute(path)


static func directory_exist_on_executable_path(directory_path: String) -> Error:
	var real_path = OS.get_executable_path().get_base_dir().path_join(directory_path)
	var directory = DirAccess.open(real_path)
	
	if directory == null:
		return DirAccess.get_open_error()
	
	return OK
	
## Supports RegEx expressions
static func get_files_recursive(path: String, regex: RegEx = null) -> Array:
	var files = []
	var directory = DirAccess.open(path)
	
	if directory:
		directory.list_dir_begin()
		var file := directory.get_next()
		
		while file != "":
			if directory.current_is_dir():
				files += get_files_recursive(directory.get_current_dir().path_join(file), regex)
			else:
				var file_path = directory.get_current_dir().path_join(file)
				
				if regex != null:
					if regex.search(file_path):
						files.append(file_path)
				else:
					files.append(file_path)
					
			file = directory.get_next()
			
		return files
	else:
		push_error("PluginUtilities->get_files_recursive: An error %s occured when trying to open directory: %s" % [DirAccess.get_open_error(), path])
		
		return []


static func copy_directory_recursive(from_dir :String, to_dir :String) -> bool:
	if not DirAccess.dir_exists_absolute(from_dir):
		push_error("PluginUtilities->copy_directory_recursive: directory not found '%s'" % from_dir)
		return false
		
	if not DirAccess.dir_exists_absolute(to_dir):
		
		var err := DirAccess.make_dir_recursive_absolute(to_dir)
		if err != OK:
			push_error("PluginUtilities->copy_directory_recursive: Can't create directory '%s'. Error: %s" % [to_dir, error_string(err)])
			return false
			
	var source_dir := DirAccess.open(from_dir)
	var dest_dir := DirAccess.open(to_dir)
	
	if source_dir != null:
		source_dir.list_dir_begin()
		var next := "."

		while next != "":
			next = source_dir.get_next()
			if next == "" or next == "." or next == "..":
				continue
			var source := source_dir.get_current_dir() + "/" + next
			var dest := dest_dir.get_current_dir() + "/" + next
			
			if source_dir.current_is_dir():
				copy_directory_recursive(source + "/", dest)
				continue
				
			var err := source_dir.copy(source, dest)
			
			if err != OK:
				push_error("PluginUtilities->copy_directory_recursive: Error checked copy file '%s' to '%s'" % [source, dest])
				return false
				
		return true
	else:
		push_error("PluginUtilities->copy_directory_recursive: Directory not found: " + from_dir)
		return false


static func remove_files_recursive(path: String, regex: RegEx = null) -> void:
	var directory = DirAccess.open(path)
	
	if DirAccess.get_open_error() == OK:
		directory.list_dir_begin()
		
		var file_name = directory.get_next()
		
		while file_name != "":
			if directory.current_is_dir():
				remove_files_recursive(directory.get_current_dir().path_join(file_name), regex)
			else:
				if regex != null:
					if regex.search(file_name):
						directory.remove(file_name)
				else:
					directory.remove(file_name)
					
			file_name = directory.get_next()
		
		directory.remove(path)
	else:
		push_error("PluginUtilities->remove_recursive: An error %s happened open directory: %s " % [DirAccess.get_open_error(), path])


## To detect if a contains elements of b
static func intersects(a: Array[Variant], b: Array[Variant]) -> bool:
	for e: Variant in a:
		if b.has(e):
			return true
			
	return false
	
	
## To detect if a contains elements of b
static func intersected_elements(a: Array[Variant], b: Array[Variant]) -> Array[Variant]:
	if intersects(a, b):
		return a.filter(func(element): return element in b)
		
	return []


static func remove_duplicates(array: Array[Variant]) -> Array[Variant]:
	var cleaned_array := []
	
	for element in array:
		if not cleaned_array.has(element):
			cleaned_array.append(element)
		
	return cleaned_array
	
	
## Flatten any array with n dimensions recursively
static func flatten(array: Array[Variant]):
	var result := []
	
	for i in array.size():
		if typeof(array[i]) >= TYPE_ARRAY:
			result.append_array(flatten(array[i]))
		else:
			result.append(array[i])

	return result


static func pick_random_values(array: Array[Variant], items_to_pick: int = 1, duplicates: bool = true) -> Array[Variant]:
	var result := []
	var target = flatten(array.duplicate())
	target.shuffle()
	
	items_to_pick = min(target.size(), items_to_pick)
	
	for i in range(items_to_pick):
		var item = target.pick_random()
		result.append(item)

		if not duplicates:
			target.erase(item)
		
	return result
		

static func value_is_between(number: int, min_value: int, max_value: int, inclusive: = true) -> bool:
	if inclusive:
		return number >= min(min_value, max_value) and number <= max(min_value, max_value)
	else :
		return number > min(min_value, max_value) and number < max(min_value, max_value)


static func decimal_value_is_between(number: float, min_value: float, max_value: float, inclusive: = true, precision: float = 0.00001) -> bool:
	if inclusive:
		min_value -= precision
		max_value += precision

	return number >= min(min_value, max_value) and number <= max(min_value, max_value)


static func chance(rng: RandomNumberGenerator, probability_chance: float = 0.5, less_than: bool = true) -> bool:
	probability_chance = clamp(probability_chance, 0.0, 1.0)
	
	return rng.randf() < probability_chance if less_than else rng.randf() > probability_chance
