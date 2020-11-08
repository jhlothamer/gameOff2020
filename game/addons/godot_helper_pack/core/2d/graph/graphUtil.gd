extends Node
class_name GraphUtil

static func generate_min_span_tree(node_array: Array, node_2d_object_property_name, point_id_property_name) -> AStar2D:
	var path: AStar2D = AStar2D.new()
	if node_array == null || node_array.size() == 0:
		return path
	var unprocessed_node_array = node_array.duplicate(false)
	var point_id: int = path.get_available_point_id()
	var node = unprocessed_node_array.pop_front()
	var node_2d_object: Node2D = node.get(node_2d_object_property_name)
	node.set(point_id_property_name, point_id)
	path.add_point(point_id, node_2d_object.global_position)

	#while there are unprocessed rooms
	while unprocessed_node_array:
		var min_dist = INF
		var min_p = null
		var p = null
		#for each point in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			#find the combo of nearest point in path and room not in path
			for p2 in unprocessed_node_array:
				node_2d_object = p2.get(node_2d_object_property_name)
				var temp = p1.distance_squared_to(node_2d_object.global_position)
				if temp < min_dist:
					min_dist = temp
					min_p = p2 #Room
					p = p1 #Vector2
		unprocessed_node_array.erase(min_p)
		var n = path.get_available_point_id()
		min_p.set(point_id_property_name, n)
		node_2d_object = min_p.get(node_2d_object_property_name)
		path.add_point(n, node_2d_object.global_position)
		path.connect_points(path.get_closest_point(p), n)

	return path

"""
this algorithm is from this post
https://stackoverflow.com/questions/3706219/algorithm-for-iterating-over-an-outward-spiral-on-a-discrete-2d-grid-from-the-or
it creates a list of unit vectors that spiral out from the first
it may be useful for filling in maps around a player in the background
"""
static func spiral_vectors(number_of_points) -> PoolVector2Array:
	var spiral_vectors: PoolVector2Array = PoolVector2Array()
	#(di, dj) is a vector - direction in which we move right now
	var di:int = 1
	var dj:int = 0
	#length of current segment
	var segment_length: int = 1
	
	#current position (i,j) and how much of the current sugement we passe3d
	var i: int = 0
	var j: int = 0
	spiral_vectors.append(Vector2(i,j))
	var segment_passed: int = 0
	for k in range(0, number_of_points-1):
		i += di
		j += dj
		spiral_vectors.append(Vector2(i,j))		
		segment_passed += 1
		
		if segment_passed == segment_length:
				#done with current segment
				segment_passed = 0
				
				#'rotate' directions
				var buffer: int = di
				di = -dj
				dj = buffer
				
				if dj == 0:
					segment_length += 1
	return spiral_vectors
