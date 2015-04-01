`include "defines.v"

module ex (
	input wire 				rst,
	input wire[`AluOpBus]	aluop_i,
	input wire[`AluSelBus]	alusel_i,
	input wire[`RegBus]		reg1_i,
	input wire[`RegBus]		reg2_i,
	input wire[`RegAddrBus]	waddr_i,
	input wire				we_i,

	// 输出给 MEM
	output reg[`RegAddrBus]	waddr_o,
	output reg 				we_o,
	output reg[`RegBus]		wdata_o,

	// 输出给 ID
	output reg[`RegAddrBus]	waddr_id_o,
	output reg 				we_id_o,
	output reg[`RegBus]		wdata_id_o
);

	// 保存运算结果
	reg[`RegBus] logicout;
	reg[`RegBus] shiftout;

	// 根据 alusel_i 指示的运算类型，选择一个运算结果作为最终结果
	always @(*) begin
		waddr_o <= waddr_i;
		we_o <= we_i;

		waddr_id_o <= waddr_i;
		we_id_o <= we_i;		
		case (alusel_i)
			`EXE_RES_LOGIC: begin
				wdata_o <= logicout;
				wdata_id_o <= logicout;
			end
			`EXE_RES_SHIFT: begin
				wdata_o <= shiftout;
				wdata_id_o <= shiftout;
			end
			default: begin
				wdata_o <= `ZeroWord;
				wdata_id_o <= `ZeroWord;
			end
		endcase 
	end

	// 根据 aluop_i 指定的类型进行运算
	always @(*) begin
		if (rst == `RstEnable) begin
			logicout <= `ZeroWord;			
		end
		else begin
			case (aluop_i)
				`EXE_OP_LOGIC_AND: begin
					logicout <= reg1_i & reg2_i;
				end
				`EXE_OP_LOGIC_OR: begin
					logicout <= reg1_i | reg2_i;
				end
				`EXE_OP_LOGIC_XOR: begin
					logicout <= reg1_i ^ reg2_i;
				end
				`EXE_OP_LOGIC_NOR: begin
					logicout <= ~(reg1_i | reg2_i);
				end
				`EXE_OP_SHIFT_SLL: begin
					logicout <= reg2_i << reg1_i[4:0];
				end
				`EXE_OP_SHIFT_SRL: begin
					logicout <= reg2_i >> reg1_i[4:0];
				end
				`EXE_OP_SHIFT_SRA: begin
					
				end
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end
	end

	always @(*) begin
		if (rst == `RstEnable) begin
			shiftout <= `ZeroWord;			
		end
		else begin
			case (aluop_i)
				`EXE_OP_SHIFT_SLL: begin
					shiftout <= reg2_i << reg1_i[4:0];
				end
				`EXE_OP_SHIFT_SRL: begin
					shiftout <= reg2_i >> reg1_i[4:0];
				end
				`EXE_OP_SHIFT_SRA: begin
					// 算数右移的操作相对复杂一些
					shiftout <= (reg2_i >> reg1_i[4:0]) | ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]}));
				end
				default: begin
					shiftout <= `ZeroWord;
				end
			endcase
		end
	end

endmodule