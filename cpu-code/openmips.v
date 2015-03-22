`include "defines.v"

module openmips (
	input wire					rst,
	input wire					clk,
	input wire[`RegBus]			rom_data_i,

	output wire[`RegBus]		rom_addr_o,
	output wire					rom_ce_o
);

	// pc 与 rom_addr_o 的连接
	wire[`InstAddrBus]			pc;
	
	// 连接 IF/ID 模块与译码阶段 ID 模块的变量
	wire[`InstAddrBus]			id_pc_i;
	wire[`InstBus]				id_inst_i;

	// 连接译码阶段的 ID 模块输出与 ID/EX 模块的连接
	wire[`AluOpBus]				id_aluop_o;
	wire[`AluSelBus]			id_alusel_o;
	wire[`RegBus]				id_reg1_o;
	wire[`RegBus]				id_reg2_o;
	wire[`RegAddrBus]			id_waddr_o;
	wire						id_we_o;

	// 连接 ID/EX 模块输出与执行阶段 EX 模块的输入的变量
	wire[`AluOpBus]				ex_aluop_i;
	wire[`AluSelBus]			ex_alusel_i;
	wire[`RegBus]				ex_reg1_i;
	wire[`RegBus]				ex_reg2_i;
	wire[`RegAddrBus]			ex_waddr_i;
	wire						ex_we_i;

	// 连接 EX 的输出与 EX/MEM 的输入
	wire[`RegAddrBus]			ex_waddr_o;
	wire 						ex_we_o;
	wire[`RegBus]				ex_wdata_o;

	// 连接 EX/MEM 的输出与 MEM 的输入
	wire						mem_rst;
	wire[`RegAddrBus]			mem_waddr_i;
	wire						mem_we_i;
	wire[`RegBus]				mem_wdata_i;

	// 连接 MEM 的输出和 MEM/WB 的输入
	wire[`RegAddrBus] 			mem_waddr_o;
	wire 						mem_we_o;
	wire[`RegBus]				mem_wdata_o;

	// 连接 MEM/WB 的输出与回写阶段的输入
	wire						wb_we_i;
	wire[`RegAddrBus]			wb_waddr_i;
	wire[`RegBus]				wb_wdata_i;

	// 连接 ID 与 Regfile 的连接
	wire						reg_re1;
	wire[`RegAddrBus]			reg_raddr1;
	wire[`RegBus]				reg_rdata1,
	wire						reg_re2;
	wire[`RegAddrBus]			reg_raddr2;
	wire[`RegBus]				reg_rdata2,

	// pc_reg 模块例化
	pc_reg pc_reg0 (
		.clk(clk),
		.rst(rst),
		.pc(pc),
		.ce(rom_ce_o)
	);

	assign rom_addr_o = pc;

	// IF/ID 模块例化
	if_id if_id0 (
		.clk(clk),
		.rst(rst),
		.if_pc(pc),
		.if_inst(rom_data_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)
	);

	// ID 模块例化
	id id0 (
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
		
		// 来自 regfile 的输入
		.reg1_data_i(reg_rdata1),
		.reg2_data_i(reg_rdata2),

		// 输出给 regfile
		.reg1_re_o(reg_re1),
		.reg2_re_o(reg_re2),
		.reg1_addr_o(reg_raddr1),
		.reg2_addr_o(reg_raddr2),

		// 输出给 ID/EX 模块
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.we_o(id_we_o),
		.waddr_o(id_waddr_o)
	);

	// Regfile 模块例化
	regfile regfile0 (
		.rst(rst),
		.clk(clk),
		
		// wb 写输入
		.we(wb_we_i),
		.waddr(wb_waddr_i),
		.wdata(wb_wdata_i),

		// id 读输入
		.re1(reg_re1),
		.re2(reg_re2),
		.raddr1(reg_raddr1),
		.raddr2(reg_raddr2),

		// 输出给 id
		.rdata1(reg_rdata1),
		.rdata2(reg_rdata2)
	);
	
	// ID/EX 模块例化
	id_ex id_ex0 (
		.clk(clk),
		.rst(rst),

		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_waddr(id_waddr_o),
		.id_we(id_we_o),

		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_waddr(ex_waddr_i),
		.ex_we(ex_we_i)
	);

	// EX 模块例化
	ex ex0 (
		.rst(rst),

		// 从 id_ex 的输入
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.waddr_i(ex_waddr_i),
		.we_i(ex_we_i),

		// 输出给 mem
		.waddr_o(ex_waddr_o),
		.we_o(ex_we_o),
		.wdata_o(ex_wdata_o)
	);

	// EX/MEM 模块例化
	ex_mem ex_mem0 (
		.rst(rst),
		.clk(clk),
		.ex_waddr(ex_waddr_o),
		.ex_we(ex_we_o),
		.ex_wdata(ex_wdata_o),

		.mem_waddr(mem_waddr_i),
		.mem_we(mem_we_i),
		.mem_wdata(mem_wdata_i)
	);

	// MEM 模块例化
	mem mem0 (
		.rst(rst),

		// ex_mem 的输入
		.waddr_i(mem_waddr_i),
		.we_i(mem_we_i),
		.wdata_i(mem_wdata_i),

		// 输出给 mem_wb
		.waddr_o(mem_waddr_o),
		.we_o(mem_we_o),
		.wdata_o(mem_wdata_o),
	);

	// MEM/WB 模块例化
	mem_wb mem_wb (
		.rst(rst),
		.clk(clk),
		.mem_waddr(mem_waddr_o),
		.mem_we(mem_we_o),
		.mem_wdata(mem_wdata_o),

		.wb_waddr(wb_waddr_i),
		.wb_we(wb_we_i),
		.wb_wdata(wb_wdata_i)
	);

endmodule