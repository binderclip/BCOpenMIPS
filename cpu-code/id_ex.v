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
	input wire[5:0]			stall,

	input wire[`RegBus]		id_link_address,
	input wire 				id_is_in_delayslot,
	input wire 				next_inst_in_delayslot_i,

	input wire[`RegBus]		id_inst,

	output reg[`AluOpBus]	ex_aluop,
	output reg[`AluSelBus]	ex_alusel,
	output reg[`RegBus]		ex_reg1,
	output reg[`RegBus]		ex_reg2,
	output reg[`RegAddrBus] ex_waddr,
	output reg 				ex_we,

	output reg[`RegBus]		ex_link_address,
	output reg 				ex_is_in_delayslot,
	output reg 				is_delayslot_o,

	output reg[`RegBus]		ex_inst
);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_OP_NOP_NOP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_we <= `WriteDisable;

			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_delayslot_o <= `NotInDelaySlot;
			ex_inst <= `ZeroWord;
		end
		else if (stall[2] == `StallEnable && stall[3] == `StallDisable) begin
			ex_aluop <= `EXE_OP_NOP_NOP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_waddr <= `NOPRegAddr;
			ex_we <= `WriteDisable;

			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_delayslot_o <= `NotInDelaySlot;
			ex_inst <= `ZeroWord;
		end
		else if (stall[2] == `StallDisable) begin
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_waddr <= id_waddr;
			ex_we <= id_we;

			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
			is_delayslot_o <= next_inst_in_delayslot_i;
			ex_inst <= id_inst;
		end
	end

endmodule