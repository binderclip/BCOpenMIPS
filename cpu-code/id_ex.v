`include "defines.v"

module id_ex (
	input wire 				clk,
	input wire				rst,

	input wire[`AluOpBus]	id_aluop,
	input wire[`AluSelBus]	id_alusel,
	input wire[`RegBus]		id_reg1,
	input wire[`RegBus]		id_reg2,
	input wire[`RegAddrBus]	id_waddr,
	input wire				id_we,

	output reg[`AluOpBus]	ex_aluop,
	output reg[`AluSelBus]	ex_alusel,
	output reg[`RegBus]		ex_reg1,
	output reg[`RegBus]		ex_reg2,
	output reg[`RegAddrBus] ex_waddr,
	output reg 				ex_we
);
	
	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_OP_NOP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_we <= `WriteDisable;			
		end
		else begin
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_waddr <= id_waddr;
			ex_we <= id_we;
		end
	end

endmodule