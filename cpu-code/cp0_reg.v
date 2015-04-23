`include "defines.v"

module cp0_reg (
	input wire 				clk,
	input wire 				rst,
	
	input wire[`RegAddrBus]	raddr_i,

	input wire[`RegBus]		data_i,
	input wire[`RegAddrBus]	waddr_i,
	input wire 				we_i,

	input wire[5:0]			int_i,

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
			cause_o[15:10] <= int_i;	// 外部中断声明

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