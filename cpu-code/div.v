`include "defines.v"

module div (
	input wire				clk,
	input wire				rst,

	input wire				signed_div_i,
	input wire[`RegBus]		opdata1_i,		// 被除数
	input wire[`RegBus]		opdata2_i,		// 除数
	input wire				start_i,
	input wire				annul_i,

	output reg[`DoubleRegBus]	result_o,
	output reg 					result_ready_o
);

	wire[32:0]			div_temp;
	reg[5:0]			cnt;
	reg[`DoubleRegBus]	dividend;
	reg[1:0]			state;		// DivFree, DivOn, DivByZero, DivEnd 状态
	reg[`RegBus]		divisor;
	wire[`RegBus]		temp_op1;
	wire[`RegBus]		temp_op2;
	// reg[1:0]			new_state;

	assign div_temp = dividend[63:31] - divisor;

	// always @(posedge clk) begin
	// 	if (rst == `RstEnable) begin
	// 		state <= `DivFree;
	// 		new_state <= `DivFree;
	// 	end
	// 	else begin
	// 		state <= new_state;
	// 	end
	// end

	assign temp_op1 = (signed_div_i == `DivSigned && opdata1_i[31] == 1'b1) ? (~opdata1_i + 1) : opdata1_i;
	assign temp_op2 = (signed_div_i == `DivSigned && opdata2_i[31] == 1'b1) ? (~opdata2_i + 1) : opdata2_i;

	// always @(*) begin
	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			state <= `DivFree;
			result_ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord, `ZeroWord};
		end
		else begin
			case (state)
				`DivFree: begin
					if (start_i == `DivStart && annul_i == `DivNotAnnul) begin
						if (opdata2_i == `ZeroWord) begin
							state <= `DivByZero;
						end
						else begin
							state <= `DivOn;
							// new_state <= `DivOn;
							cnt <= 0;
							// if (signed_div_i == `DivSigned && opdata1_i[31] == 1'b1) begin
							// 	temp_op1 <= ~opdata1_i + 1;
							// end
							// else begin
							// 	temp_op1 <= opdata1_i;
							// end
							// if (signed_div_i == `DivSigned && opdata2_i[31] == 1'b1) begin
							// 	temp_op2 <= ~opdata2_i + 1;
							// end
							// else begin
							// 	temp_op2 <= opdata2_i;
							// end

							// test
							// temp_op1 <= 32'h1111;
							// temp_op2 <= 32'h2222;

							dividend <= {`ZeroWord, temp_op1};
							divisor <= temp_op2;
						end
					end
					else begin
						result_ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				`DivOn: begin
					if (annul_i == `DivNotAnnul) begin
						if (cnt != 32) begin 	// 试商法还未结束
							if (div_temp[32] == 1'b1) begin
								// 表示 (minuted - n) 的结果小于 0
								// dividend 左移一位
								dividend <= {dividend[62:0], 1'b0};
							end
							else begin
								dividend <= {div_temp[31:0], dividend[30:0], 1'b1};
							end
							cnt <= cnt + 1;
						end
						else begin 						// 试商法结束
							if (signed_div_i == `DivSigned && (opdata1_i[31] ^ opdata2_i[31]) == 1'b1) begin
								dividend[31:0] <= ~dividend[31:0] + 1;
							end
							if (signed_div_i == `DivSigned && opdata1_i[31] == 1'b1) begin
								dividend[63:32] <= ~dividend[63:32] + 1;
							end
							state <= `DivEnd;
							cnt <= 0;
						end
					end
					else begin
						state <= `DivFree;
					end
				end
				`DivByZero: begin
					dividend <= {`ZeroWord, `ZeroWord};
					state <= `DivEnd;
				end
				`DivEnd: begin
					result_o <= {dividend[63:32], dividend[31:0]};
					result_ready_o <= `DivResultReady;
					if (start_i == `DivNotStart) begin
						state <= `DivFree;
						result_ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
			endcase
		end
	end

endmodule