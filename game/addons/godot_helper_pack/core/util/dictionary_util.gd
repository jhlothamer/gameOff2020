class_name DictionaryUtil
extends Object
"""
Collection of dictionary utility functions.
"""


# adds all unique elements from keys array to dictionary with value
static func add_keys(dictionary: Dictionary, keys: Array, value = null) -> void:
	for key in keys:
		if !dictionary.has(key):
			dictionary[key] = value

static func add(d1: Dictionary, d2: Dictionary) -> void:
	for key in d2.keys():
		d1[key] = d2[key]
