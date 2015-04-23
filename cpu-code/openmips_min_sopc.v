`include "defines.v"

module openmips_min_sopc (
	input wire		clk,
	input wire		rst
);

	// 连接指令寄存器
	wire[`InstAddrBus]		inst_addr;
	wire[`InstBus]			inst;
	wire					rom_ce;

	// 连接 RAM
	wire[`RegBus]			mem_addr_o;
	wire[`RegBus]			mem_data_o;
	wire[3:0]				mem_sel_o;
	wire 					mem_we_o;
	wire 					mem_ce_o;

	wire[`RegBus]			mem_data_i;

	// 连接中断
	wire[5:0]				int;
	wire 					timer_int;

	assign int = {5'b00000, timer_int};

	// 实例化处理器 OpemMIPS
	openmips openmips0 (
		.rst(rst),
		.clk(clk),
		.rom_data_i(inst),
		.ram_data_i(mem_data_i),
		.int_i(int),

		.rom_addr_o(inst_addr),
		.rom_ce_o(rom_ce),
		.ram_addr_o(mem_addr_o),
		.ram_data_o(mem_data_o),
		.ram_sel_o(mem_sel_o),
		.ram_we_o(mem_we_o),
		.ram_ce_o(mem_ce_o),
		.timer_int_o(timer_int)
	);

	// 实例化指令存储器 ROM
	inst_rom inst_rom0 (
		.addr(inst_addr),
		.inst(inst),
		.ce(rom_ce)
	);

	// 实例化 RAM
	data_ram data_ram0 (
		.clk(clk),
		.ce(mem_ce_o),
		.we(mem_we_o),
		.addr(mem_addr_o),
		.sel(mem_sel_o),
		.data_i(mem_data_o),

		.data_o(mem_data_i)
	);

endmodule