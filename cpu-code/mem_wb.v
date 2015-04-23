`include "defines.v"

module mem_wb (
	input wire					rst,
	input wire					clk,
	input wire[`RegAddrBus]		mem_waddr,
	input wire					mem_we,
	input wire[`RegBus]			mem_wdata,

	input wire 					mem_whilo,
	input wire[`RegBus]			mem_hi,
	input wire[`RegBus]			mem_lo,
	input wire[5:0]				stall,

	input wire 					mem_LLbit_we,
	input wire 					mem_LLbit_value,

	input wire[`RegBus]			mem_cp0_reg_data,
	input wire[`RegAddrBus]		mem_cp0_reg_waddr,
	input wire 					mem_cp0_reg_we,

	output reg[`RegAddrBus]		wb_waddr,
	output reg 					wb_we,
	output reg[`RegBus]			wb_wdata,

	output reg 					wb_whilo,
	output reg[`RegBus]			wb_hi,
	output reg[`RegBus]			wb_lo,

	output reg 					wb_LLbit_we,
	output reg 					wb_LLbit_value,

	output reg[`RegBus]			wb_cp0_reg_data,
	output reg[`RegAddrBus]		wb_cp0_reg_waddr,
	output reg 					wb_cp0_reg_we
);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			wb_waddr <= `NOPRegAddr;
			wb_we <= `WriteDisable;
			wb_wdata <= `ZeroWord;

			wb_whilo <= `WriteDisable;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;

			wb_LLbit_we <= `WriteDisable;
			wb_LLbit_value <= 1'b0;

			wb_cp0_reg_data <= `ZeroWord;
			wb_cp0_reg_waddr <= 5'b00000;
			wb_cp0_reg_we <= `WriteDisable;
		end
		else if (stall[4] == `StallEnable && stall[5] == `StallDisable) begin
			wb_waddr <= `NOPRegAddr;
			wb_we <= `WriteDisable;
			wb_wdata <= `ZeroWord;

			wb_whilo <= `WriteDisable;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;

			wb_LLbit_we <= `WriteDisable;
			wb_LLbit_value <= 1'b0;

			wb_cp0_reg_data <= `ZeroWord;
			wb_cp0_reg_waddr <= 5'b00000;
			wb_cp0_reg_we <= `WriteDisable;
		end
		else if (stall[4] == `StallDisable) begin
			wb_waddr <= mem_waddr;
			wb_we <= mem_we;
			wb_wdata <= mem_wdata;

			wb_whilo <= mem_whilo;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;

			wb_LLbit_we <= mem_LLbit_we;
			wb_LLbit_value <= mem_LLbit_value;

			wb_cp0_reg_data <= mem_cp0_reg_data;
			wb_cp0_reg_waddr <= mem_cp0_reg_waddr;
			wb_cp0_reg_we <= mem_cp0_reg_we;
		end
	end

endmodule