extends CpuCore

var stage : int = 0
var trrp_trigger : bool

static func get_cpu_name() -> String:
	return "Azulógico"

func _setup():
	addr_wid = 16
	data_wid = 16
	ram_port_count = 2
	flag = {
		"BOOL": true,
		"HALF": false,
		"CRRY": false,
		"OVER": false,
		"MASK": false,
		"TRRP": false,
	}
	declare_register("X", 8)
	declare_register("Y", 8)
	declare_register("S", 16)
	declare_register("A", 16)


func reset() -> void:
	stage = 0
	PC = 0
	OP = 0
	G.lue.write_mar(0, 0)
	G.lue.write_mar(0, 1)

func clock_tick() -> bool:
	stage += 1
	call(opmne.get(OP, "next_cycle"))
	match stage:
		0:
			OP = G.lue.load_mem(1)
			return true
	
	return false

func next_cycle():
	stage = 0
	PC += 2
	#TODO: How do put this in another stage?
	G.lue.write_mar(PC, 1)


func WAIT():
	match stage:
		1:
			G.lue.write_mar(PC+1, 1)
		2:
			write_reg("S", G.lue.load_mem(1))
		_:
			if read_reg("S") > 0 and trrp_trigger:
				#TODO: Run polling subroutine and check if trigger come from the device with the address in D.
				next_cycle()
			elif stage > 6:
				next_cycle()

func LOAD():
	match stage:
		1:
			G.lue.write_mar(PC + 1)
		2:
			write_reg("X", G.lue.load_mem())
			next_cycle()

func STOR():
	match stage:
		1:
			G.lue.write_mar(PC + 1, 1)
		2:
			write_reg("A", G.lue.load_mem())
		3:
			G.lue.write_mar("A", 0)
		4:
			G.lue.store_mem(read_reg("X"), 0)
			next_cycle()
