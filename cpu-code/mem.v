`include "defines.v"

module mem (
	input wire				rst,
	input wire[`RegAddrBus]	waddr_i,
	input wire				we_i,
	input wire[`RegBus]		wdata_i,
	input wire 				whilo_i,
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,

	// 输出给 MEM_WB
	output reg[`RegAddrBus] waddr_o,
	output reg 				we_o,
	output reg[`RegBus]		wdata_o,
	output reg 				whilo_o,
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o
);

	always @(*) begin
		if (rst == `RstEnable) begin
			waddr_o <= `NOPRegAddr;
			we_o <= `WriteDisable;
			wdata_o <= `ZeroWord;

			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end
		else begin
			waddr_o <= waddr_i;
			we_o <= we_i;
			wdata_o <= wdata_i;

			whilo_o <= whilo_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
		end
	end

endmodule