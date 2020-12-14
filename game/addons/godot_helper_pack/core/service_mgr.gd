extends Node

var _services := {}
var _named_services := {}


func register_service(service: Resource, implementation: Object, name: String = "") -> void:
	if name != "":
		if !_named_services.has(service):
			_named_services[service] = {}
		_named_services[service][name] = implementation
		return
	_services[service] = implementation
	if implementation is Node:
		_watch_service_implementation_tree_exit(service, implementation, name)


func get_service(service: Resource, name: String = "") -> Object:
	if name != "":
		if _named_services.has(service):
			if _named_services[service].has(name):
				return _named_services[service][name]

	if _services.has(service):
		return _services[service]
	return null


func unregister(service: Resource, implementation: Object, name: String = "") -> void:
	if name != "":
		if _named_services.has(service):
			_named_services[service].erase(name)
		return
	_services.erase(service)
	if implementation is Node:
		implementation.disconnect("tree_exited", self, "_on_implementation_tree_exited")


func _watch_service_implementation_tree_exit(service: Resource, implementation: Node, name: String = "") -> void:
	pass
	implementation.connect("tree_exited", self, "_on_implementation_tree_exited", [service, implementation, name])


func _on_implementation_tree_exited(service: Resource, implementation: Object, name: String) -> void:
	unregister(service, implementation, name)
