extends RefCounted
class_name CpuCore

var cpu_pack : String = ""
static func get_cpu_name() -> String:
	return "Base CPU"
func _init(pack_name:String = "") -> void:
	cpu_pack = pack_name
	config_decoders()
	_setup()
func _setup():
	pass

#region Configuring Instruction Set
var mneop : Dictionary[String, int]  # Includes aliases for variants given argument prefixes, like «add,#» which would alias «add_immediate», for example.
var opmne : Dictionary[int, String]  # Doesn't include any alias and only preferred mnemonics for a given opcode.
var cycles : Dictionary[int, int]  # Opcode -> number of clock cycles to execute

func config_decoders():
	var path = "res://Architectures".path_join(cpu_pack +"/microcode.cfg")
	var section : Dictionary
	var curr_sect : String
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		line = line.get_slice("#", 0)
		if line.is_empty():
			continue
		line = line.strip_edges()
		if line[0] == "[":
			var end = line.length()
			curr_sect = line.substr(1, end - 2)
			section[curr_sect] = []
		else:
			section[curr_sect].append(line)
	
	for line in section["Opcodes"]:
		for code : String in line.split(",", false):
			code = code.strip_edges()
			var mne = code.get_slice(":", 0)
			var op = code.get_slice(":", 1).strip_edges().hex_to_int()
			mneop[mne] = op
			if not ("`" in code or op in opmne): # Don't save back-reference to aliases
				opmne[op] = mne
#endregion

var addr_wid : int = 8
var data_wid : int = 8
var ram_port_count : int = 1

var flag : Dictionary[String, bool]
var F : int :
	set(val):
		var n = 0
		for each in flag:
			flag[each] = bool(val & (1 << n))
			n += 1
	get():
		var n = 0
		for truth in flag.values():
			n = n << 1 | int(truth)
		return 0
var PC : int = 0 :
	set(val):
		PC = wrapi(val, 0, D.greatest(addr_wid) + 1)
var OP : int = 0

var registers : Dictionary[String, int]
var register_wid : Dictionary[String, int]
func declare_register(regist_name:String, bitwidth:int):
	registers[regist_name] = randi() % D.greatest(bitwidth)
	register_wid[regist_name] = bitwidth
func write_reg(regist_name:String, value:int=0):
	registers[regist_name] = D.trim(value, register_wid[regist_name])
	G.lue.write_reg(regist_name)
func read_reg(regist_name:String):
	return registers[regist_name]

func clock_tick() -> bool:
	G.lue.write_mar(PC)
	PC += 1
	if PC % 5 == 4:
		return true
	else:
		return false

func reset() -> void:
	PC = 0
	OP = 0
	G.lue.write_mar(0, 0)
	G.lue.write_mar(0, 1)


#region Parsing Assembly
var prog : Dictionary[int, int]  # Memory address -> opcode/value
var labels : Dictionary
var vectors : Dictionary
func parse_asm(raw_asm:String):
	labels.clear()
	vectors.clear()
	prog.clear()
	discovery_asm(raw_asm)
	
	# Cleanup the discovered labels.
	for each in labels:
		labels[each] = D.to_val(labels[each], addr_wid)
	var new_vects : Dictionary
	for each in vectors:
		var new_each = labels.get(each, D.to_val(labels[each], addr_wid))
		new_vects[new_each] = labels.get(vectors[each], D.to_val(labels[vectors[each]], addr_wid))
	
	return prog


func sanitize_asm(line:String):
	line = line.get_slice(";", 0)
	line = line.strip_edges()
	return line

func discovery_asm(raw_asm:String, last_addr:int=0):
	var multiline : String
	for line in raw_asm.split("\n", false):
		line = sanitize_asm(line)
		if line.is_empty():
			continue
		
		if not multiline.is_empty() and line[0] != ":":
			multiline = ""
		
		match line[0]:
			"|":  # an importation
				var path = "res://Programs/"+get_cpu_name()+"/"+FileAccess.get_file_as_string(line.right(-1))
				prog.merge(discovery_asm(path, last_addr))
			"&":  # A declared label
				line = line.right(-1)
				labels[line.get_slice(" ", 0)] = line.get_slice(" ", 1)
			"§": # A labeled section of code
				var addr_sep = line.find("=", 1)
				var vect_sep = line.find(" ", 1)
				line = line.right(-1)
				
				var sect_name : String
				var addr : String = str(last_addr)
				
				var rule = [
					addr_sep > 0,  # The section is set to the given memory address
					vect_sep > 0  # There's an interrupt declaration towards this memory address
					]
				
				if rule[0] and rule[1]:
					sect_name = line.left(addr_sep)
					addr = line.right(addr_sep).left(vect_sep)
					vectors[addr] = line.right(vect_sep)
					last_addr = D.to_val(addr, addr_wid)
				else:
					if rule[0]:
						sect_name = line.left(addr_sep)
						addr = line.right(addr_sep)
						last_addr = D.to_val(addr, addr_wid)
					elif rule[1]:
						sect_name = line.left(vect_sep)
						vectors[addr] = line.right(vect_sep)
					else:
						sect_name = line
					
				labels[sect_name] = addr
				
			":": # Raw data
				var data_type = line.get_slice(" ", 0).right(-1).strip_edges()
				var data_cont = line.get_slice(" ", 1)
				if data_type.is_empty():
					data_type = multiline
				
				match data_type:
					"text":
						multiline = "text"
						last_addr = parse_text_data(data_cont, last_addr)
				
			_:
				last_addr = parse_instr(line, last_addr)
				

## Put instruction from the opcode in the program.
func set_prog_op(opcode:int, last_addr:int=0) -> int:
	opcode = D.trim(opcode, data_wid)
	prog[last_addr] = opcode
	return last_addr + 1


## Find the info about an instruction from the mnemonic and arguments.
func parse_instr(expr:String, last_addr:int=0) -> int:
	var variant : String = ""
	var vals : Array[int]
	var parts = expr.split(" ", false)
	# Handle arguments
	for p in parts.slice(1):
		if not p[0] in ["#", "@", "$"]:
			p = "_" + p
		variant += p[0]
		vals.append(D.to_val(p.right(-1), data_wid))
	
	# Handle opcode
	vals.push_front(mneop.get( variant + "`" + parts[0], 0 ))
	
	# Finalize the thing.
	for opcode in vals:
		last_addr = set_prog_op(opcode, last_addr)
	
	return last_addr

## Find what numbers a string would be represented as, then what instructions those numbers represent.
func parse_text_data(expr:String, last_addr:int=0) -> int:
	for j in range(expr.length()):
		var chr : int = text_data_table(expr[j])
		last_addr = set_prog_op(chr, last_addr)
	# Append Null termination
	last_addr = set_prog_op(0, last_addr)
	return last_addr

## Define what number represent the given text character.
func text_data_table(chr:String) -> int:
	return ord(chr)

#endregion
