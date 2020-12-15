extends Control


export var odd_row_color: Color
export var even_row_color: Color


onready var dialog: AcceptDialog = $AcceptDialog
onready var tree = $AcceptDialog/Tree


# Called when the node enters the scene tree for the first time.
func _ready():
	#show()
	pass

func show():
	_refresh_contents()
	.show()
	dialog.popup_centered()

func _refresh_contents():
	tree.clear()
	tree.set_column_title(0, "Resource")
	tree.set_column_title(1, "Amount")
	tree.set_column_titles_visible(true)
	
	var resource_mgr: ResourceMgr = ServiceMgr.get_service(ResourceMgr)
	var resource_amounts := {}
	if resource_mgr != null:
		resource_amounts = resource_mgr.get_resource_amounts()
	else:
		resource_amounts = _make_test_resources_list()
	
	var _root = tree.create_item()
	
	var counter = 0
	
	for resource_name in resource_amounts.keys():
		var amount = resource_amounts[resource_name]
		var item: TreeItem = tree.create_item()
		item.set_text(0, resource_name + "     ")
		item.set_text_align(0,TreeItem.ALIGN_RIGHT)
		item.set_text(1, str(amount))
		if counter % 2 == 0:
			item.set_custom_bg_color(0, even_row_color)
			item.set_custom_bg_color(1, even_row_color)
		else:
			item.set_custom_bg_color(0, odd_row_color)
			item.set_custom_bg_color(1, odd_row_color)
		counter += 1
		
	
func _make_test_resources_list():
	var resource_amounts := {}
	for i in range(1, 101):
		resource_amounts["Resource " + str(i)] = i*1000
	return resource_amounts

func _unhandled_input(_event):
	if visible:
		get_tree().set_input_as_handled()

func _on_AcceptDialog_confirmed():
	hide()


func _on_AcceptDialog_popup_hide():
	hide()
