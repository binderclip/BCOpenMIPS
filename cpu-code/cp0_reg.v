`include "defines.v"

module cp0_reg (
	input wire 				clk,
	input wire 				rst,
	
	input wire[`RegAddrBus]	raddr_i,

	input wire[`RegBus]		data_i,
	input wire[`RegAddrBus]	waddr_i,
	input wire 				we_i,

	input wire[5:0]			int_i,
	input wire[`RegBus]		excepttype_i,

	// 当前执行的指令
	input wire[`RegBus]		mem_current_inst_addr_i,
	input wire 				mem_current_inst_loaded,
	input wire 				mem_is_in_delayslot_i,
	input wire[`RegBus]		ex_current_inst_addr_i,
	input wire 				ex_current_inst_loaded,
	input wire 				ex_is_in_delayslot_i,
	input wire[`RegBus]		id_current_inst_addr_i,
	input wire 				id_current_inst_loaded,
	input wire 				id_is_in_delayslot_i,
	input wire[`RegBus]		pc_current_inst_addr_i,

	output reg[`RegBus]		data_o,
	output reg[`RegBus]		count_o,
	output reg[`RegBus]		compare_o,
	output reg[`RegBus]		status_o,
	output reg[`RegBus]		cause_o,
	output reg[`RegBus]		epc_o,
	output reg[`RegBus]		config_o,
	output reg[`RegBus]		prid_o,
	output reg				timer_int_o
);

	reg[`RegBus]			current_inst_addr_i;
	reg 					is_in_delayslot_i;

	// 对 CP0 中寄存器的写操作
	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			// Count 寄存器初始值 0
			count_o <= `ZeroWord;
			// Compare 寄存器初始值 0
			compare_o <= `ZeroWord;
			// Status 寄存器初始值，其中 CU 字段为 4'b0001，表示协处理器 CP0 存在
			status_o <= 32'b00010000000000000000000000000000;
			// Cause 寄存器初始值为 0
			cause_o <= `ZeroWord;
			// EPC 寄存器的初始值
			epc_o <= `ZeroWord;
			// Config 寄存器的初始值，其中 BE 字段为 1，表示工作在大端模式 (MSB)
			config_o <= 32'b00000000000000001000000000000000;
			// PRId 寄存器初始值，制作者 L，对应 0x48，类型为 0x1，表示基本类型，版本号 v1.0
			prid_o <= 32'b00000000010011000000000100000010;
			timer_int_o <= `InterruptNotAssert;
		end
		else begin
			count_o <= count_o + 1;
			
			if (mem_current_inst_loaded == `Loaded) begin
				current_inst_addr_i <= mem_current_inst_addr_i;
				is_in_delayslot_i <= mem_is_in_delayslot_i;
			end
			else if (ex_current_inst_loaded == `Loaded) begin
				current_inst_addr_i <= ex_current_inst_addr_i;
				is_in_delayslot_i <= ex_is_in_delayslot_i;
			end
			else if (id_current_inst_loaded == `Loaded) begin
				current_inst_addr_i <= id_current_inst_addr_i;
				is_in_delayslot_i <= id_is_in_delayslot_i;
			end
			else begin
				current_inst_addr_i <= pc_current_inst_addr_i;
				is_in_delayslot_i <= `NotInDelaySlot;
			end

			if (compare_o != `ZeroWord && count_o == compare_o) begin
				timer_int_o <= `InterruptAssert;
			end

			if (we_i == `WriteEnable) begin
				case (waddr_i)
					`CP0_REG_COUNT: begin
						count_o <= data_i;
					end
					`CP0_REG_COMPARE: begin
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS: begin
						status_o <= data_i;
					end
					`CP0_REG_CAUSE: begin
						// cause 只有部分字段可写
						cause_o[9:8] <= data_i[9:8];
						cause_o[22] <= data_i[22];
						cause_o[23] <= data_i[23];
					end
					`CP0_REG_EPC: begin
						epc_o <= data_i;
					end
					default: begin
					end
				endcase
			end

			case (excepttype_i)
				`EXCEPTTYPE_INTERRUPT: begin 	// 外部中断
					if (is_in_delayslot_i == `InDelaySlot) begin
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;	// Cause 寄存器的 BD 字段
					end else begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;		// EXL 字段
					cause_o[6:2] <= 5'b00000;	// ExcCode 字段
				end
				`EXCEPTTYPE_SYSCALL: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end
						else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end 
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;
				end
				`EXCEPTTYPE_INST_INVALID: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end
						else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				`EXCEPTTYPE_TRAP: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end
						else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;
				end
				`EXCEPTTYPE_OV: begin
					if (status_o[1] == 1'b0) begin
						if (is_in_delayslot_i == `InDelaySlot) begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end
						else begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01110;
				end
				`EXCEPTTYPE_ERET: begin
					status_o[1] <= 1'b0;
				end
				default: begin
					
				end
			endcase

			#1 cause_o[15:10] = int_i;	// 外部中断声明，少量延时，防止定时中断恢复之后由于 compare 值写入路径长导致再次进入中断
		end
	end
	// 对 CP0 寄存器的读操作
	always @(*) begin
		if (rst == `RstEnable) begin
			data_o <= `ZeroWord;			
		end
		else begin
			case (raddr_i)
				`CP0_REG_COUNT: begin
					data_o <= count_o;
				end
				`CP0_REG_COMPARE: begin
					data_o <= compare_o;
				end
				`CP0_REG_STATUS: begin
					data_o <= status_o;
				end
				`CP0_REG_CAUSE: begin
					data_o <= cause_o;
				end
				`CP0_REG_EPC: begin
					data_o <= epc_o;
				end
				`CP0_REG_PRID: begin
					data_o <= prid_o;
				end
				`CP0_REG_CONFIG: begin
					data_o <= config_o;
				end
				default: begin
				end
			endcase
		end
	end

endmodule