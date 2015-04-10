`include "defines.v"

module ex (
	// 从 ID 输出
	input wire 				rst,
	input wire[`AluOpBus]	aluop_i,
	input wire[`AluSelBus]	alusel_i,
	input wire[`RegBus]		reg1_i,
	input wire[`RegBus]		reg2_i,
	input wire[`RegAddrBus]	waddr_i,
	input wire				we_i,
	// 从 mem 输入
	input wire				mem_whilo_i,
	input wire[`RegBus]		mem_hi_i,
	input wire[`RegBus]		mem_lo_i,
	// 从 wb 输入
	input wire				wb_whilo_i,
	input wire[`RegBus]		wb_hi_i,
	input wire[`RegBus]		wb_lo_i,
	// 从 hilo_reg 输入
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,
	
	// 输出给 MEM
	output reg[`RegAddrBus]	waddr_o,
	output reg 				we_o,
	output reg[`RegBus]		wdata_o,
	output reg				whilo_o,
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o
);

	// 保存运算结果
	reg[`RegBus]	logicout;
	reg[`RegBus] 	shiftout;
	reg[`RegBus] 	moveout;
	// 存放输入
	reg[`RegBus]	hi_i_reg;
	reg[`RegBus]	lo_i_reg;

	// 选择 HI LO 的输入
	always @(*) begin
		if (rst == `RstEnable) begin
			hi_i_reg <= `ZeroWord;
			lo_i_reg <= `ZeroWord;
		end
		else if (mem_whilo_i == `WriteEnable) begin
			hi_i_reg <= mem_hi_i;
			lo_i_reg <= mem_lo_i;
		end
		else if (wb_whilo_i == `WriteEnable) begin
			hi_i_reg <= wb_hi_i;
			lo_i_reg <= wb_lo_i;
		end
		else begin
			hi_i_reg <= hi_i;
			lo_i_reg <= lo_i;
		end
	end

	// LOGIC
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
				default: begin
					logicout <= `ZeroWord;
				end
			endcase
		end
	end

	// SHIFT
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

	// MOVE
	always @(*) begin
		if (rst == `RstEnable) begin
			moveout <= `ZeroWord;
		end
		else begin
			case (aluop_i)
				`EXE_OP_MOVE_MOVZ: begin
					moveout <= reg1_i;
				end
				`EXE_OP_MOVE_MOVN: begin
					moveout <= reg1_i;
				end
				`EXE_OP_MOVE_MFHI: begin
					moveout <= hi_i_reg;
				end
				`EXE_OP_MOVE_MFLO: begin
					moveout <= lo_i_reg;
				end
				default: begin
					moveout <= `ZeroWord;
				end
			endcase
		end
	end

	// MATH
	// (1) 如果是减法或者大小比较，就把数字换成它的负数形式？用补码来表示。
	assign reg2_i_mux = ((aluop_i == `EXE_OP_MATH_SUB) ||
						 (aluop_i == `EXE_OP_MATH_SUBU) ||
						 (aluop_i == `EXE_OP_MATH_SLT)) ?
						 (~reg2_i) + 1 : reg2_i;

	// (2) 加法就是加法，减法就是减法，比较运算用减法
	assign result_sum = reg1_i + reg2_i_mux;

	// (3) 判断是不是溢出
	// 1. 正 + 正变负
	// 2. 负 + 负变正
	assign overflow_sum = ((!reg1_i[31] && !reg2_i_mux[31]) && result_sum[31]) ||
						  ((reg1_i[31] && reg2_i_mux[31]) && !result_sum[31]);
	// (4) 计算操作数 1 是不是小于操作数 2
	// 有符号时又几种情况
	// 1. o1 > 0, o2 < 0, o1 > o2
	// 2. o1 > 0, o2 > 0, sum < 0
	// 3. o1 < 0, o2 < 0, sum < 0
	// 无符号时直接比较大小
	


	// OTHER
	always @(*) begin
		if (rst) begin
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end
		else begin
			case (aluop_i)
				`EXE_OP_OTHER_MTHI: begin
					whilo_o <= `WriteEnable;
					hi_o <= reg1_i;
					lo_o <= lo_i_reg;
				end
				`EXE_OP_OTHER_MTLO: begin
					whilo_o <= `WriteEnable;
					hi_o <= hi_i_reg;
					lo_o <= reg1_i;
				end
				default: begin
					whilo_o <= `WriteDisable;
					hi_o <= hi_i_reg;
					lo_o <= lo_i_reg;
				end
			endcase
		end
	end

	// 根据 alusel_i 指示的运算类型，选择一个运算结果作为最终结果
	always @(*) begin
		waddr_o <= waddr_i;
		we_o <= we_i;
		case (alusel_i)
			`EXE_RES_LOGIC: begin
				wdata_o <= logicout;
			end
			`EXE_RES_SHIFT: begin
				wdata_o <= shiftout;
			end
			`EXE_RES_MOVE: begin
				wdata_o <= moveout;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase 
	end

endmodule