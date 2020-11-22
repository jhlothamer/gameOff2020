extends Control



func _ready():
	_test()


func _test():
	var x_measures = [1,2,3,4,5]
	var y_measures = [2,4,5,4,5]
	var l = StatsUtil.linear_regression(x_measures, y_measures)
	print("line is : y = " + str(l.b) + " + " + str(l.m) + "x")
	l = StatsUtil.linear_regression_one_array(y_measures)
	print("line is : y = " + str(l.b) + " + " + str(l.m) + "x")
	
	_test_line(0, 1, 3)
	
	randomize()
	var sw = StopWatch.new()
	sw.start()
	for i in range(1000):
		var b = rand_range(-100.0, 100.0)
		var m = rand_range(-100.0, 100.0)
		var p = 20 # int(rand_range(10, 100))
		_test_line(b, m, p)
	sw.stop()
	var msec = sw.get_elapsed_msec()
	print("test took " + str(msec) + " msec")

func _test_line(b: float, m: float, point_count: int):
	var measures := []
	for i in range(point_count):
		measures.append(b + m*float(i))
	var l = StatsUtil.linear_regression_one_array(measures)
	if !is_equal_approx(l.b, b): # l.b != b:
		printerr("l.b != b: " + str(l.b) + ", " + str(b) )
	if !is_equal_approx(l.m, m): # l.m != m:
		printerr("l.m != m: " + str(l.m) + ", " + str(m) )
