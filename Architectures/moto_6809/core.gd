extends CpuCore

static func get_cpu_name() -> String:
	return "Moto 6809"

func _setup():
	addr_wid = 16
	data_wid = 8
	flag = {
		"CRRY": true,
		"OVER": false,
		"ZERO": false,
		"NEGA": false,
		"MASK": false,
		"ENTR": false,
	}
	declare_register("A", 8)
	declare_register("B", 8)
	declare_register("X", 16)
	declare_register("Y", 16)
	declare_register("U", 16)
	declare_register("S", 16)
	declare_register("DP", 8)

func write_D(value:int):
	var d = D.split(value, 8)
	write_reg("A", d.x)
	write_reg("B", d.y)
func read_D():
	return D.join(read_reg("A"), read_reg("B"), 8, 8)


#NOTE: The 6809 uses a quadrature oscillator.
#func clock_tick() -> bool:
	#pass

#NOTE: The 6809 interprets the reset as interruption that jumps to xFFFE in memory.
func reset():
	OP = 0
