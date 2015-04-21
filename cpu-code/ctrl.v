`include "defines.v"

module ctrl (
	input wire		rst,
	input wire		stallreq_from_id,
	input wire		stallreq_from_ex,
	output reg[5:0]	stall
);

	always @(*) begin
		if (rst == `RstEnable) begin
			stall <= `StallNone;
		end
		else if (stallreq_from_id == `StallEnable) begin
			stall <= `StallFromID;
		end
		else if (stallreq_from_ex == `StallEnable) begin
			stall <= `StallFromEX;
		end
		else begin
			stall <= `StallNone;
		end
	end

endmodule