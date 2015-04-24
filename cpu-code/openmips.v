`include "defines.v"

module openmips (
	input wire					rst,
	input wire					clk,
	input wire[`RegBus]			rom_data_i,
	input wire[`RegBus]			ram_data_i,
	input wire[5:0]				int_i,

	output wire[`RegBus]		rom_addr_o,
	output wire					rom_ce_o,
	output wire[`RegBus]		ram_addr_o,
	output wire[`RegBus]		ram_data_o,
	output wire[3:0]			ram_sel_o,
	output wire 				ram_we_o,
	output wire 				ram_ce_o,
	output wire 				timer_int_o
);

	// PC 与 rom_addr_o 的连接
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
	wire 						next_inst_in_delayslot_o;
	wire[`RegBus]				link_addr_o;
	wire 						is_in_delayslot_o;
	wire[`RegBus]				id_inst_o;
	wire[`RegBus]				id_excepttype_o;
	wire[`RegBus]				id_current_inst_address_o;
	// ID 到 PC
	wire 						branch_flag_o;
	wire[`RegBus]				branch_target_address_o;

	// 连接 ID/EX 模块输出与执行阶段 EX 模块的输入的变量
	wire[`AluOpBus]				ex_aluop_i;
	wire[`AluSelBus]			ex_alusel_i;
	wire[`RegBus]				ex_reg1_i;
	wire[`RegBus]				ex_reg2_i;
	wire[`RegAddrBus]			ex_waddr_i;
	wire						ex_we_i;
	wire[`RegBus]				ex_link_address;
	wire 						ex_is_in_delayslot;
	wire 						is_delayslot_o;
	wire[`RegBus]				ex_inst_i;
	wire[`RegBus]				ex_excepttype_i;
	wire[`RegBus]				ex_current_inst_addr_i;

	// 连接 EX 的输出与 EX/MEM 的输入
	wire[`RegAddrBus]			ex_waddr_o;
	wire 						ex_we_o;
	wire[`RegBus]				ex_wdata_o;
	wire						ex_whilo_o;
	wire[`RegBus]				ex_hi_o;
	wire[`RegBus]				ex_lo_o;
	wire[`DoubleRegBus]			hilo_temp_ex_o;
	wire[1:0]					cnt_ex_o;
	wire[`AluOpBus]				ex_aluop_o;
	wire[`RegBus]				ex_mem_addr_o;
	wire[`RegBus]				ex_reg2_o;
	wire[`RegBus]				ex_cp0_reg_data_o;
	wire[`RegAddrBus]			ex_cp0_reg_waddr_o;
	wire 						ex_cp0_reg_we_o;
	wire[`RegBus]				ex_excepttype_o;
	wire[`RegBus]				ex_current_inst_addr_o;
	wire 						ex_is_in_delayslot_o;
	// 连接 EX 的输出与 DIV 的输入
	wire						signed_div_o;
	wire[`RegBus]				div_opdata1_o;		// 被除数
	wire[`RegBus]				div_opdata2_o;		// 除数
	wire						div_start_o;
	// 连接 EX 的输出与 CP0 的输入
	wire[`RegAddrBus]			ex_cp0_reg_raddr_o;

	// 连接 EX/MEM 的输出与 EX 的输入
	wire[`DoubleRegBus]			hilo_temp_ex_mem_o;
	wire[1:0]					cnt_ex_mem_o;
	// 连接 EX/MEM 的输出与 MEM 的输入
	wire						mem_rst;
	wire[`RegAddrBus]			mem_waddr_i;
	wire						mem_we_i;
	wire[`RegBus]				mem_wdata_i;
	wire						mem_whilo_i;
	wire[`RegBus]				mem_hi_i;
	wire[`RegBus]				mem_lo_i;
	wire[`AluOpBus]				mem_aluop_i;
	wire[`RegBus]				mem_mem_addr_i;
	wire[`RegBus]				mem_reg2_i;
	wire[`RegBus]				mem_cp0_reg_data_i;
	wire[`RegAddrBus]			mem_cp0_reg_waddr_i;
	wire 						mem_cp0_reg_we_i;
	wire[`RegBus]				mem_excepttype_i;
	wire[`RegBus]				mem_current_inst_addr_i;
	wire 						mem_is_in_delayslot_i;
	// 连接 MEM 的输出和 MEM/WB 的输入
	wire[`RegAddrBus] 			mem_waddr_o;
	wire 						mem_we_o;
	wire[`RegBus]				mem_wdata_o;
	wire						mem_whilo_o;
	wire[`RegBus]				mem_hi_o;
	wire[`RegBus]				mem_lo_o;
	wire		 				mem_LLbit_we_o;
	wire		 				mem_LLbit_value_o;
	wire[`RegBus]				mem_cp0_reg_data_o;
	wire[`RegAddrBus]			mem_cp0_reg_waddr_o;
	wire 						mem_cp0_reg_we_o;
	// 链接 MEM 的输出和 CP0、CTRL 的输入
	wire[`RegBus]				mem_cp0_epc_o;
	wire[`RegBus]				mem_excepttype_o;
	wire[`RegBus]				mem_current_inst_address_o;
	wire 						mem_is_in_delayslot_o;

	// 连接 MEM/WB 的输出与回写阶段的输入
	wire						wb_we_i;
	wire[`RegAddrBus]			wb_waddr_i;
	wire[`RegBus]				wb_wdata_i;
	wire 						wb_LLbit_we_i;
	wire 						wb_LLbit_value_i;
	// 连接 MEM/WB 的输出与 hilo_reg 的输入
	wire						hilo_whilo_i;
	wire[`RegBus]				hilo_hi_i;
	wire[`RegBus]				hilo_lo_i;
	// 连接 MEM/WB 的输出与 CP0 EX 的输入
	wire[`RegBus]				wb_cp0_reg_data_o;
	wire[`RegAddrBus]			wb_cp0_reg_waddr_o;
	wire 						wb_cp0_reg_we_o;

	// 连接 hilo_reg 的输出与 EX 的输入
	wire[`RegBus]				hilo_hi_o;
	wire[`RegBus]				hilo_lo_o;

	// 连接 ID 与 Regfile 的连接
	wire						reg_re1;
	wire[`RegAddrBus]			reg_raddr1;
	wire[`RegBus]				reg_rdata1;
	wire						reg_re2;
	wire[`RegAddrBus]			reg_raddr2;
	wire[`RegBus]				reg_rdata2;

	// 连接 CTRL 和其他模块
	wire[5:0]					stall;
	wire 						stallreq_from_id;	
	wire 						stallreq_from_ex;
	wire[`RegBus]				new_pc;
	wire 						flush;

	// 连接 DIV 和 EX 模块
	wire[`DoubleRegBus]			div_result_o;
	wire	 					div_result_ready_o;

	// 连接 LLbit 模块和 MEM 模块
	wire						LLbit_o;

	// 连接 CP0 模块和 EX 模块
	wire[`RegBus]				ex_cp0_reg_data_i;
	// 连接 CP0 和 MEM
	wire[`RegBus]				cp0_status_o;
	wire[`RegBus]				cp0_cause_o;
	wire[`RegBus]				cp0_epc_o;

	// pc_reg 模块例化
	pc_reg pc_reg0 (
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.branch_flag_i(branch_flag_o),
		.branch_target_address_i(branch_target_address_o),
		.new_pc(new_pc),
		.flush(flush),
		.pc(pc),
		.ce(rom_ce_o)
	);

	assign rom_addr_o = pc;

	// IF/ID 模块例化
	if_id if_id0 (
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),
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
		// 来自 EX 的输入
		.ex_waddr_i(ex_waddr_o),
		.ex_we_i(ex_we_o),
		.ex_wdata_i(ex_wdata_o),
		.is_in_delayslot_i(is_delayslot_o),
		.ex_aluop_i(ex_aluop_o),
		// 来自 MEM 的输入
		.mem_waddr_i(mem_waddr_o),
		.mem_we_i(mem_we_o),
		.mem_wdata_i(mem_wdata_o),

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
		.waddr_o(id_waddr_o),
		.next_inst_in_delayslot_o(next_inst_in_delayslot_o),
		.link_addr_o(link_addr_o),
		.is_in_delayslot_o(is_in_delayslot_o),
		.inst_o(id_inst_o),
		.excepttype_o(id_excepttype_o),
		.current_inst_address_o(id_current_inst_address_o),
		// 输出给 PC
		.branch_flag_o(branch_flag_o),
		.branch_target_address_o(branch_target_address_o),
		// 输出给 CTRL
		.stallreq(stallreq_from_id)
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
		.stall(stall),
		.flush(flush),

		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_waddr(id_waddr_o),
		.id_we(id_we_o),

		.id_link_address(link_addr_o),
		.id_is_in_delayslot(is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),

		.id_inst(id_inst_o),
		.id_excepttype(id_excepttype_o),
		.id_current_inst_addr(id_current_inst_address_o),

		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_waddr(ex_waddr_i),
		.ex_we(ex_we_i),

		.ex_link_address(ex_link_address),
		.ex_is_in_delayslot(ex_is_in_delayslot),
		.is_delayslot_o(is_delayslot_o),

		.ex_inst(ex_inst_i),
		.ex_excepttype(ex_excepttype_i),
		.ex_current_inst_addr(ex_current_inst_addr_i)
	);

	// EX 模块例化
	ex ex0 (
		.rst(rst),
		// 从 ID_EX 输入
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.waddr_i(ex_waddr_i),
		.we_i(ex_we_i),
		.link_address_i(ex_link_address),
		.is_in_delayslot_i(ex_is_in_delayslot),
		.inst_i(ex_inst_i),
		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),
		.excepttype_i(ex_excepttype_i),
		.current_inst_addr_i(ex_current_inst_addr_i),
		// 从 EX/MEM 输入
		.hilo_temp_i(hilo_temp_ex_mem_o),
		.cnt_i(cnt_ex_mem_o),
		// 从 MEM 输入
		.mem_whilo_i(mem_whilo_o),
		.mem_hi_i(mem_hi_o),
		.mem_lo_i(mem_lo_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
		.mem_cp0_reg_waddr(mem_cp0_reg_waddr_o),
		.mem_cp0_reg_we(mem_cp0_reg_we_o),
		// 从 MEM/WB 输入
		.wb_whilo_i(hilo_whilo_i),
		.wb_hi_i(hilo_hi_i),
		.wb_lo_i(hilo_lo_i),
		.wb_cp0_reg_data(wb_cp0_reg_data_o),
		.wb_cp0_reg_waddr(wb_cp0_reg_waddr_o),
		.wb_cp0_reg_we(wb_cp0_reg_we_o),
		// 从 hilo_reg 输入
		.hi_i(hilo_hi_o),
		.lo_i(hilo_lo_o),
		// 从 DIV 输入
		.div_result_i(div_result_o),
		.div_result_ready_i(div_result_ready_o),
		// 从 CP0 输入
		.cp0_reg_data_i(ex_cp0_reg_data_i),

		// 输出给 EX/MEM
		.waddr_o(ex_waddr_o),
		.we_o(ex_we_o),
		.wdata_o(ex_wdata_o),
		.whilo_o(ex_whilo_o),
		.hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.hilo_temp_o(hilo_temp_ex_o),
		.cnt_o(cnt_ex_o),
		.stallreq(stallreq_from_ex),
		.cp0_reg_data_o(ex_cp0_reg_data_o),
		.cp0_reg_waddr_o(ex_cp0_reg_waddr_o),
		.cp0_reg_we_o(ex_cp0_reg_we_o),
		.excepttype_o(ex_excepttype_o),
		.current_inst_addr_o(ex_current_inst_addr_o),
		.is_in_delayslot_o(ex_is_in_delayslot_o),
		// 输出给 DIV
		.signed_div_o(signed_div_o),
		.div_opdata1_o(div_opdata1_o),		// 被除数
		.div_opdata2_o(div_opdata2_o),		// 除数
		.div_start_o(div_start_o),
		// 输出给 CP0
		.cp0_reg_raddr_o(ex_cp0_reg_raddr_o)
	);

	// EX/MEM 模块例化
	ex_mem ex_mem0 (
		.rst(rst),
		.clk(clk),
		.stall(stall),
		.flush(flush),

		.ex_waddr(ex_waddr_o),
		.ex_we(ex_we_o),
		.ex_wdata(ex_wdata_o),
		.ex_whilo(ex_whilo_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.hilo_i(hilo_temp_ex_o),
		.cnt_i(cnt_ex_o),

		.ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),

		.ex_cp0_reg_data(ex_cp0_reg_data_o),
		.ex_cp0_reg_waddr(ex_cp0_reg_waddr_o),
		.ex_cp0_reg_we(ex_cp0_reg_we_o),
		.ex_excepttype(ex_excepttype_o),
		.ex_current_inst_addr(ex_current_inst_addr_o),
		.ex_is_in_delayslot(ex_is_in_delayslot_o),

		.mem_waddr(mem_waddr_i),
		.mem_we(mem_we_i),
		.mem_wdata(mem_wdata_i),
		.mem_whilo(mem_whilo_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.hilo_o(hilo_temp_ex_mem_o),
		.cnt_o(cnt_ex_mem_o),

		.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),

		.mem_cp0_reg_data(mem_cp0_reg_data_i),
		.mem_cp0_reg_waddr(mem_cp0_reg_waddr_i),
		.mem_cp0_reg_we(mem_cp0_reg_we_i),
		.mem_excepttype(mem_excepttype_i),
		.mem_current_inst_addr(mem_current_inst_addr_i),
		.mem_is_in_delayslot(mem_is_in_delayslot_i)
	);

	// MEM 模块例化
	mem mem0 (
		.rst(rst),

		// EX/MEM 的输入
		.waddr_i(mem_waddr_i),
		.we_i(mem_we_i),
		.wdata_i(mem_wdata_i),
		.whilo_i(mem_whilo_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		.cp0_reg_data_i(mem_cp0_reg_data_i),
		.cp0_reg_waddr_i(mem_cp0_reg_waddr_i),
		.cp0_reg_we_i(mem_cp0_reg_we_i),
		.excepttype_i(mem_excepttype_i),
		.current_inst_address_i(mem_current_inst_addr_i),
		.is_in_delayslot_i(mem_is_in_delayslot_i),
		// RAM 的输入
		.mem_data_i(ram_data_i),
		.LLbit_i(LLbit_o),
		// WB 的输入
		.wb_LLbit_we_i(wb_LLbit_we_i),
		.wb_LLbit_value_i(wb_LLbit_value_i),
		.wb_cp0_reg_we(wb_cp0_reg_we_o),
		.wb_cp0_reg_write_addr(wb_cp0_reg_waddr_o),
		.wb_cp0_reg_write_data(wb_cp0_reg_data_o),
		// CP0 的输入
		.cp0_status_i(cp0_status_o),
		.cp0_cause_i(cp0_cause_o),
		.cp0_epc_i(cp0_epc_o),
		// 输出给 MEM/WB
		.waddr_o(mem_waddr_o),
		.we_o(mem_we_o),
		.wdata_o(mem_wdata_o),
		.whilo_o(mem_whilo_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),

		.mem_addr_o(ram_addr_o),
		.mem_we_o(ram_we_o),
		.mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o),
		.mem_ce_o(ram_ce_o),

		.LLbit_we_o(mem_LLbit_we_o),
		.LLbit_value_o(mem_LLbit_value_o),

		.cp0_reg_data_o(mem_cp0_reg_data_o),
		.cp0_reg_waddr_o(mem_cp0_reg_waddr_o),
		.cp0_reg_we_o(mem_cp0_reg_we_o),

		.cp0_epc_o(mem_cp0_epc_o),
		.excepttype_o(mem_excepttype_o),
		.current_inst_address_o(mem_current_inst_address_o),
		.is_in_delayslot_o(mem_is_in_delayslot_o)
	);

	// MEM/WB 模块例化
	mem_wb mem_wb0 (
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.flush(flush),

		// 从 MEM 输入
		.mem_waddr(mem_waddr_o),
		.mem_we(mem_we_o),
		.mem_wdata(mem_wdata_o),
		.mem_whilo(mem_whilo_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_LLbit_we(mem_LLbit_we_o),
		.mem_LLbit_value(mem_LLbit_value_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
		.mem_cp0_reg_waddr(mem_cp0_reg_waddr_o),
		.mem_cp0_reg_we(mem_cp0_reg_we_o),
		// 输出给 WB
		.wb_waddr(wb_waddr_i),
		.wb_we(wb_we_i),
		.wb_wdata(wb_wdata_i),
		.wb_LLbit_we(wb_LLbit_we_i),
		.wb_LLbit_value(wb_LLbit_value_i),
		// 输出给 hilo_reg
		.wb_whilo(hilo_whilo_i),
		.wb_hi(hilo_hi_i),
		.wb_lo(hilo_lo_i),
		// 输出给 CP0 EX
		.wb_cp0_reg_data(wb_cp0_reg_data_o),
		.wb_cp0_reg_waddr(wb_cp0_reg_waddr_o),
		.wb_cp0_reg_we(wb_cp0_reg_we_o)
	);

	// hilo_reg 模块例化
	hilo_reg hilo_reg0 (
		.clk(clk),
		.rst(rst),

		// 从 MEM/WB 输入
		.we(hilo_whilo_i),
		.hi_i(hilo_hi_i),
		.lo_i(hilo_lo_i),

		// 输出给 EX
		.hi_o(hilo_hi_o),
		.lo_o(hilo_lo_o)
	);

	ctrl ctrl0 (
		.rst(rst),
	
		.stallreq_from_id(stallreq_from_id),
		.stallreq_from_ex(stallreq_from_ex),
		.cp0_epc_i(mem_cp0_epc_o),
		.excepttype_i(mem_excepttype_o),

		.stall(stall),
		.new_pc(new_pc),
		.flush(flush)
	);

	div div0 (
		.clk(clk),
		.rst(rst),

		.signed_div_i(signed_div_o),
		.opdata1_i(div_opdata1_o),		// 被除数
		.opdata2_i(div_opdata2_o),		// 除数
		.start_i(div_start_o),
		.annul_i(1'b0),

		.result_o(div_result_o),
		.result_ready_o(div_result_ready_o)
	);

	LLbit_reg LLbit_reg0 (
		.clk(clk),
		.rst(rst),

		.flush(flush),
		.LLbit_i(wb_LLbit_value_i),
		.we(wb_LLbit_we_i),

		.LLbit_o(LLbit_o)
	);

	cp0_reg cp0_reg0 (
		.clk(clk),
		.rst(rst),

		.raddr_i(ex_cp0_reg_raddr_o),

		.data_i(wb_cp0_reg_data_o),
		.waddr_i(wb_cp0_reg_waddr_o),
		.we_i(wb_cp0_reg_we_o),

		.int_i(int_i),
		.excepttype_i(mem_excepttype_o),
		.current_inst_addr_i(mem_current_inst_address_o),
		.is_in_delayslot_i(mem_is_in_delayslot_o),

		.data_o(ex_cp0_reg_data_i),
		.status_o(cp0_status_o),
		.cause_o(cp0_cause_o),
		.epc_o(cp0_epc_o),

		.timer_int_o(timer_int_o)
	);
endmodule