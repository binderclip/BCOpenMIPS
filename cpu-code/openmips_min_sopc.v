`include "defines.v"

module openmips_min_sopc (
	input wire		clk,
	input wire		rst
);

	// 连接指令寄存器
	wire[`InstAddrBus]		inst_addr;
	wire[`InstBus]			inst;
	wire					rom_ce;

	// 实例化处理器 OpemMIPS
	openmips openmips0 (
		.rst(rst),
		.clk(clk),
		.rom_data_i(inst),

		.rom_addr_o(inst_addr),
		.rom_ce_o(rom_ce)
	);

	// 实例化指令存储器 ROM
	inst_rom inst_rom0 (
		.addr(inst_addr),
		.inst(inst),
		.ce(rom_ce)
	);

endmodule