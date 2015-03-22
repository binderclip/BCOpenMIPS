`include "defines.v"

module mem (
	input wire				rst,
	input wire[`RegAddrBus]	waddr_i,
	input wire				we_i,
	input wire[`RegBus]		wdata_i,

	output reg[`RegAddrBus] waddr_o,
	output reg 				we_o,
	output reg[`RegBus]		wdata_o
);

	always @(*) begin
		if (rst == `RstEnable) begin
			waddr_o <= `NOPRegAddr;
			we_o <= `WriteDisable;
			wdata_o <= `ZeroWord;
		end
		else begin
			waddr_o <= waddr_i;
			we_o <= we_i;
			wdata_o <= wdata_i;
		end
	end

endmodule