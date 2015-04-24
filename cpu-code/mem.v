`include "defines.v"

module mem (
	input wire				rst,
	input wire[`RegAddrBus]	waddr_i,
	input wire				we_i,
	input wire[`RegBus]		wdata_i,
	input wire 				whilo_i,
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,

	input wire[`AluOpBus]	aluop_i,
	input wire[`RegBus]		mem_addr_i,
	input wire[`RegBus]		reg2_i,
	input wire[`RegBus]		mem_data_i,

	input wire 				LLbit_i,
	input wire 				wb_LLbit_we_i,
	input wire 				wb_LLbit_value_i,

	input wire[`RegBus]		cp0_reg_data_i,
	input wire[`RegAddrBus]	cp0_reg_waddr_i,
	input wire 				cp0_reg_we_i,

	input wire[`RegBus]		excepttype_i,
	input wire[`RegBus]		current_inst_address_i,
	input wire 				current_inst_loaded_i,
	input wire 				is_in_delayslot_i,
	// 从 CP0 输入
	input wire[`RegBus]		cp0_status_i,
	input wire[`RegBus]		cp0_cause_i,
	input wire[`RegBus]		cp0_epc_i,
	// 从 WB 输入，有关 CP0 防止数据相关
	input wire 				wb_cp0_reg_we,
	input wire[4:0]			wb_cp0_reg_write_addr,
	input wire[`RegBus]		wb_cp0_reg_write_data,

	// 输出给 MEM_WB
	output reg[`RegAddrBus] waddr_o,
	output reg 				we_o,
	output reg[`RegBus]		wdata_o,
	output reg 				whilo_o,
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o,
	output reg 				LLbit_we_o,
	output reg 				LLbit_value_o,
	// 输出给 RAM 模块
	output reg[`RegBus]		mem_addr_o,
	output wire 			mem_we_o,
	output reg[3:0]			mem_sel_o,
	output reg[`RegBus]		mem_data_o,
	output reg 				mem_ce_o,

	output reg[`RegBus]		cp0_reg_data_o,
	output reg[`RegAddrBus]	cp0_reg_waddr_o,
	output reg 				cp0_reg_we_o,

	output wire[`RegBus]	cp0_epc_o,
	output reg[`RegBus]		excepttype_o,
	output wire[`RegBus]	current_inst_address_o,
	output wire 			current_inst_loaded_o,
	output wire 			is_in_delayslot_o
);

	wire[`RegBus]	zero32;
	reg 			mem_we;
	reg 			LLbit;
	reg[`RegBus]	cp0_status;
	reg[`RegBus]	cp0_cause;
	reg[`RegBus]	cp0_epc;

	assign mem_we_o = mem_we & (~(|excepttype_o));
	assign zero32 = `ZeroWord;
	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_address_o = current_inst_address_i;
	assign current_inst_loaded_o = current_inst_loaded_i;

	// 得到 CP0 寄存器中的最新值
	always @(*) begin
		if (rst == `RstEnable) begin
			cp0_status <= `ZeroWord;			
		end
		else if (wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == `CP0_REG_STATUS) begin
			cp0_status <= wb_cp0_reg_write_data;
		end
		else begin
			cp0_status <= cp0_status_i;
		end
	end

	always @(*) begin
		if (rst == `RstEnable) begin
			cp0_epc <= `ZeroWord;			
		end
		else if (wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == `CP0_REG_EPC) begin
			cp0_epc <= wb_cp0_reg_write_data;
		end
		else begin
			cp0_epc <= cp0_epc_i;
		end
	end

	assign cp0_epc_o = cp0_epc;

	always @(*) begin
		if (rst == `RstEnable) begin
			cp0_cause <= `ZeroWord;			
		end
		else if (wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == `CP0_REG_CAUSE) begin
			cp0_cause[9:8] <= wb_cp0_reg_write_data[9:8];
			cp0_cause[22] <= wb_cp0_reg_write_data[22];
			cp0_cause[23] <= wb_cp0_reg_write_data[23];
		end
		else begin
			cp0_cause <= cp0_cause_i;
		end
	end

	// 最终的异常类型
	always @(*) begin
		if (rst == `RstEnable) begin
			excepttype_o <= `ZeroWord;			
		end
		else begin
			excepttype_o <= `ZeroWord;
			if (((cp0_cause[15:8] & cp0_status[15:8]) != 8'h00) && (cp0_status[1] == 1'b0 && cp0_status[0] == 1'b1)) begin
				excepttype_o <= `EXCEPTTYPE_INTERRUPT;	// interrupt
			end
			else if (excepttype_i[8] == 1'b1) begin
				excepttype_o <= `EXCEPTTYPE_SYSCALL;	// syscall
			end
			else if (excepttype_i[9] == 1'b1) begin
				excepttype_o <= `EXCEPTTYPE_INST_INVALID;	// inst_invalid
			end
			else if (excepttype_i[10] == 1'b1) begin
				excepttype_o <= `EXCEPTTYPE_TRAP;	// trap
			end
			else if (excepttype_i[11] == 1'b1) begin
				excepttype_o <= `EXCEPTTYPE_OV;	// ov
			end
			else if (excepttype_i[12] == 1'b1) begin
				excepttype_o <= `EXCEPTTYPE_ERET;	// eret
			end
		end
	end

	always @(*) begin
		if (rst == `RstEnable) begin
			LLbit <= 1'b0;			
		end
		else begin
			if (wb_LLbit_we_i == `WriteEnable) begin
				LLbit <= wb_LLbit_value_i;
			end
			else begin
				LLbit <= LLbit_i;
			end
		end
	end

	always @(*) begin
		if (rst == `RstEnable) begin
			waddr_o <= `NOPRegAddr;
			we_o <= `WriteDisable;
			wdata_o <= `ZeroWord;

			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;

			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;
			mem_ce_o <=	`ChipDisable;

			LLbit_we_o <= `WriteDisable;
			LLbit_value_o <= 1'b0;

			cp0_reg_data_o <= `ZeroWord;
			cp0_reg_waddr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
		end
		else begin
			waddr_o <= waddr_i;
			we_o <= we_i;
			wdata_o <= wdata_i;

			whilo_o <= whilo_i;
			hi_o <= hi_i;
			lo_o <= lo_i;

			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce_o <=	`ChipDisable;

			LLbit_we_o <= `WriteDisable;
			LLbit_value_o <= 1'b0;

			cp0_reg_data_o <= cp0_reg_data_i;
			cp0_reg_waddr_o <= cp0_reg_waddr_i;
			cp0_reg_we_o <= cp0_reg_we_i;

			case (aluop_i)
				`EXE_OP_LOAD_STORE_LB: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
						end
						2'b01: begin
							wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
						end
						2'b10: begin
							wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
						end
						2'b11: begin
							wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_LH: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
						end
						2'b10: begin
							wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_LWL: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {mem_data_i[7:0], reg2_i[23:0]};
						end
						2'b01: begin
							wdata_o <= {mem_data_i[15:0], reg2_i[15:0]};
						end
						2'b10: begin
							wdata_o <= {mem_data_i[23:0], reg2_i[7:0]};
						end
						2'b11: begin
							wdata_o <= mem_data_i;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_LW: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_OP_LOAD_STORE_LBU: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
						end
						2'b01: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
						end
						2'b10: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
						end
						2'b11: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_LHU: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
						end
						2'b10: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_LWR: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= mem_data_i;
						end
						2'b01: begin
							wdata_o <= {reg2_i[31:24], mem_data_i[31:8]};
						end
						2'b10: begin
							wdata_o <= {reg2_i[31:16], mem_data_i[31:16]};
						end
						2'b11: begin
							wdata_o <= {reg2_i[31:8], mem_data_i[31:24]};
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_SB: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= {4{reg2_i[7:0]}};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							mem_sel_o <= 4'b1000;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_SH: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= {2{reg2_i[15:0]}};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b0011; 
						end
						2'b10: begin
							mem_sel_o <= 4'b1100;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_SWL: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_data_o <= {zero32[31:8], reg2_i[31:24]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							mem_data_o <= {zero32[31:16], reg2_i[31:16]};
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							mem_data_o <= {zero32[31:24], reg2_i[31:8]};
							mem_sel_o <= 4'b0111;
						end
						2'b11: begin
							mem_data_o <= reg2_i;
							mem_sel_o <= 4'b1111;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_SW: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_OP_LOAD_STORE_SWR: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_data_o <= reg2_i;
							mem_sel_o <= 4'b1111;
						end
						2'b01: begin
							mem_data_o <= {reg2_i[23:0], zero32[7:0]};
							mem_sel_o <= 4'b1110;
						end
						2'b10: begin
							mem_data_o <= {reg2_i[15:0], zero32[15:0]};
							mem_sel_o <= 4'b1100;
						end
						2'b11: begin
							mem_data_o <= {reg2_i[7:0], zero32[23:0]};
							mem_sel_o <= 4'b1000;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_OP_LOAD_STORE_LL: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
					LLbit_we_o <= `WriteEnable;
					LLbit_value_o <= 1'b1;
				end
				`EXE_OP_LOAD_STORE_SC: begin
					if (LLbit == 1'b1) begin
						mem_addr_o <= mem_addr_i;
						mem_we <= `WriteEnable;
						mem_ce_o <= `ChipEnable;
						wdata_o <= 32'b1;
						mem_data_o <= reg2_i;
						mem_sel_o <= 4'b1111;
						LLbit_we_o <= `WriteEnable;
						LLbit_value_o <= 1'b0;
					end
					else begin
						wdata_o <= 32'b0;
					end
				end
				default: begin
				end
			endcase
		end
	end

endmodule