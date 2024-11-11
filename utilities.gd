class_name Utilities
extends Resource


static func convert_string_to_int_keys(dict: Dictionary) -> Dictionary:
	var new_dict: Dictionary = {}
	for key in dict:
		if key is String:
			var int_key: int = key.to_int()
			new_dict[int_key] = dict[key]
		else:
			new_dict[key] = dict[key]
	return new_dict

static func convert_float_values_to_ints(dict: Dictionary) -> Dictionary:
	var converted_dict: Dictionary =  {}
	for key in dict.keys():
		var value = dict[key]
		if typeof(value) == TYPE_FLOAT:
			converted_dict[key] = int(value)
		else:
			converted_dict[key] = value
	return converted_dict


static func find_alphabetical_insertion_index(string_to_insert: String, array_to_search: Array[String]) -> int:
	for index: int in array_to_search.size():
		var comparison_string: String = array_to_search[index]
		if comparison_string < string_to_insert:
			continue
		else:
			return index

	return -1
