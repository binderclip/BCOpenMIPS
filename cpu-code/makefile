top_module = openmips_min_sopc_tb
sfiles = defines.v ex.v ex_mem.v id.v id_ex.v if_id.v inst_rom.v mem.v mem_wb.v openmips.v openmips_min_sopc.v openmips_min_sopc_tb.v pc_reg.v regfile.v hilo_reg.v ctrl.v
out = openmips_min_sopc_tb.out

build: $(out)

run: $(out)
	vvp $(out)

$(out):
	iverilog -o $(out) $(sfiles)

clean:
	rm $(out)