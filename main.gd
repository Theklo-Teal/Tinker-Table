extends MarginContainer

var reg_index : Dictionary[String, int]  # Register Name -> %Reg_List index
var wtc_index : Dictionary[int, int]  # Memory Address -> %Watch_List index
var dis_index : Dictionary[int, int]  # Memory Address -> %Disasm_List index

func _ready() -> void:
	G.lue = self
	%Archie.clear()
	var startup_archie : int = 0
	for pack in DirAccess.get_directories_at("res://Architectures/"):
		var cpu_script = load("res://Architectures/"+pack+"/core.gd")
		var id = %Archie.item_count
		%Archie.add_item(cpu_script.get_cpu_name())
		%Archie.set_item_metadata(id, pack)
		if pack == G.sett.get_value("Foobar", "architecture", ""):
			startup_archie = id
	%Archie.item_selected.connect(_on_archie_selected)
	%Archie.select(startup_archie)
	
	%Flags.bits = G.CPU.flag.values()
	%Flags.labels = G.CPU.flag.keys()
	
	%Reg_List.clear()
	for reg in G.CPU.registers:
		var val = G.CPU.registers[reg]
		var wid = D.greatest(G.CPU.register_wid[reg])
		val = String.num_uint64(val, 16, true).lpad( D.digit_count(wid), "0" )
		%Reg_List.add_item(reg)
		var idx = %Reg_List.add_item(val)
		reg_index[reg] = idx


func _on_archie_selected(index:int):
	G.set_architecture(%Archie.get_item_metadata(index))

func _on_prog_parse_pressed(assembly_code: String) -> void:
	%Status.text = "Assembling program..."
	%Prog/%Parse.disabled = true
	var parse_start = Time.get_ticks_msec()
	await get_tree().process_frame
	await get_tree().process_frame  #NOTE: I don't know why you need to wait twice.
	
	var assem = G.CPU.parse_asm(assembly_code)
	for start_addr in assem:
		%Table.content[start_addr] = assem[start_addr]
		%Table.update_shown_data()
	
	var duration = str(snappedf( (Time.get_ticks_msec() - parse_start) as float / 1000, 0.001 ))
	%Status.text = "Finished Assembling. It took " + duration + " secs"
	%Prog/%Parse.disabled = false
	await get_tree().create_timer(4).timeout
	%Status.text = "Idle"
	

#region Table Monitoring
func _on_table_deselect_pressed() -> void:
	%Disasm_List.clear()
	dis_index.clear()
	%Table.deselect_all()
	
func _on_table_data_selected(cells: PackedInt32Array) -> void:
	%Disasm_List.clear()
	for addr in cells:
		var wid = D.greatest(G.CPU.data_wid)
		wid = D.digit_count(wid)
		var addr_str = String.num_uint64(addr, 16, true).lpad(wid, "0")
		var idx = %Disasm_List.add_item(addr_str)
		var code = %Table.content[addr]
		var mne = G.CPU.opmne.get(code, "ILLEGAL")
		%Disasm_List.add_item(mne)
		dis_index[addr] = idx

func _on_table_select_data_updated(cell: int, code: int) -> void:
	var idx = dis_index[cell]
	var mne = G.CPU.opmne.get(code, "ILLEGAL")
	%Disasm_List.set_item_text(idx, cell)
	%Disasm_List.set_item_text(idx+1, mne)


func _on_add_addr_pressed() -> void:
	for addr in %Table.get_selected_cells():
		if not addr in wtc_index:
			var wid = D.greatest(G.CPU.addr_wid)
			wid = D.digit_count(wid)
			var addr_str := String.num_uint64(addr, 16, true).lpad(wid, "0")
			wid = D.greatest(G.CPU.data_wid)
			wid = D.digit_count(wid)
			var data_str := String.num_uint64(%Table.content[addr], 16, true).lpad(wid, "0")
			wtc_index[addr] = %Watch_List.add_row([addr_str, data_str] as Array[String])


func _on_rem_addr_pressed() -> void:
	for idx in %Watch_List.get_selected_rows():
		var addr = %Watch_List.get_row_ids(idx)
		wtc_index.erase(addr)
		%Watch_List.remove_row(idx)


#endregion

#region Clock/Tick updating
var running : bool
var period : float
var elapsed : float = 0
func _process(delta: float) -> void:
	if not running:
		return
	if period < delta:
		for n in range(floori(delta/period)):
			_on_clk_ctrl_cycle_step_pressed()
	else:
		elapsed += delta
		if elapsed > period:
			elapsed = 0
			_on_clk_ctrl_cycle_step_pressed()

func _on_clk_ctrl_exec_mode_changed(is_auto: bool) -> void:
	running = is_auto

func _on_clk_ctrl_rate_changed(rate: float) -> void:
	period = 1/rate
	elapsed = 0

var temp_run : bool
func _on_clk_ctrl_instr_step_pressed() -> void:
	running = true
	temp_run = true

func _on_clk_ctrl_cycle_step_pressed() -> void:
	var fetched = G.CPU.clock_tick()
	if temp_run:
		running = not fetched
		temp_run = not fetched
#endregion

#region CPU actions
func _on_exec_reset():
	G.CPU.reset()


func write_mar(val:int, port:int=0):
	%Table.set_addr(val, port)

func store_mem(val:int, port:int=0):
	%Table.set_data(val, port)

func load_mem(port:int=0):
	return %Table.get_data(port)

func write_reg(reg:String):
	var val = G.CPU.registers[reg]
	var wid = D.greatest(G.CPU.register_wid[reg])
	val = String.num_uint64(val, 16, true).lpad(D.digit_count(wid), "0")
	%Reg_List.set_item_text(reg_index[reg], val)
#endregion
