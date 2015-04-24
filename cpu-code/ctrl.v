`include "defines.v"

module ctrl (
	input wire				rst,
	input wire				stallreq_from_id,
	input wire				stallreq_from_ex,
	input wire[`RegBus]		excepttype_i,
	input wire[`RegBus]		cp0_epc_i,

	output reg[5:0]			stall,
	output reg[`RegBus]		new_pc,
	output reg 				flush
);

	always @(*) begin
		if (rst == `RstEnable) begin
			stall <= `StallNone;
			new_pc <= `ZeroWord;
			flush <= `NotFlush;
		end
		else if (excepttype_i != `ZeroWord) begin
			stall <= `StallNone;
			flush <= `Flush;
			case (excepttype_i)
				`EXCEPTTYPE_INTERRUPT: begin
					new_pc <= 32'h00000020;
				end
				`EXCEPTTYPE_SYSCALL: begin
					new_pc <= 32'h00000040;
				end
				`EXCEPTTYPE_INST_INVALID: begin
					new_pc <= 32'h00000040;
				end
				`EXCEPTTYPE_TRAP: begin
					new_pc <= 32'h00000040;
				end
				`EXCEPTTYPE_OV: begin
					new_pc <= 32'h00000040;
				end
				`EXCEPTTYPE_ERET: begin
					new_pc <= cp0_epc_i;
				end
				default: begin
				end
			endcase
		end
		else if (stallreq_from_id == `StallEnable) begin
			stall <= `StallFromID;
			flush <= `NotFlush;
		end
		else if (stallreq_from_ex == `StallEnable) begin
			stall <= `StallFromEX;
			flush <= `NotFlush;
		end
		else begin
			stall <= `StallNone;
			flush <= `NotFlush;
			new_pc <= `ZeroWord;
		end
	end

endmodule