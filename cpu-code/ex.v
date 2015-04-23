`include "defines.v"

module ex (
	// 从 ID 输出
	input wire 					rst,
	input wire[`AluOpBus]		aluop_i,
	input wire[`AluSelBus]		alusel_i,
	input wire[`RegBus]			reg1_i,
	input wire[`RegBus]			reg2_i,
	input wire[`RegAddrBus]		waddr_i,
	input wire					we_i,
	input wire[`RegBus]			link_address_i,
	input wire 					is_in_delayslot_i,
	input wire[`RegBus]			inst_i,
	// 从 mem 输入
	input wire					mem_whilo_i,
	input wire[`RegBus]			mem_hi_i,
	input wire[`RegBus]			mem_lo_i,
	// 从 wb 输入
	input wire					wb_whilo_i,
	input wire[`RegBus]			wb_hi_i,
	input wire[`RegBus]			wb_lo_i,
	// 从 hilo_reg 输入
	input wire[`RegBus]			hi_i,
	input wire[`RegBus]			lo_i,
	// 从 EX/MEM 输入
	input wire[`DoubleRegBus]	hilo_temp_i,
	input wire[1:0]				cnt_i,
	// 从 DIV 输入
	input wire[`DoubleRegBus]	div_result_i,
	input wire 					div_result_ready_i,
	// 输出给 EX/MEM
	output reg[`RegAddrBus]		waddr_o,
	output reg 					we_o,
	output reg[`RegBus]			wdata_o,
	output reg					whilo_o,
	output reg[`RegBus]			hi_o,
	output reg[`RegBus]			lo_o,
	output reg[`DoubleRegBus]	hilo_temp_o,
	output reg[1:0]				cnt_o,
	output wire[`AluOpBus]		aluop_o,
	output wire[`RegBus]		mem_addr_o,
	output wire[`RegBus]		reg2_o,
	// 输出给 ctrl
	output reg 					stallreq,
	// 输出给 DIV
	output reg					signed_div_o,
	output reg[`RegBus]			div_opdata1_o,		// 被除数
	output reg[`RegBus]			div_opdata2_o,		// 除数
	output reg					div_start_o
);

	// 保存运算结果
	reg[`RegBus]		logicout;
	reg[`RegBus] 		shiftout;
	reg[`RegBus] 		moveout;
	reg[`RegBus]		mathout;
	reg[`DoubleRegBus]	mulout;

	// 存放输入
	reg[`RegBus]		hi_i_reg;
	reg[`RegBus]		lo_i_reg;

	// 算数运算的中间变量
	wire 				overflow_sum;
	// wire 				reg1_eq_reg2;
	wire 				reg1_lt_reg2;
	wire[`RegBus]		reg2_i_mux;
	wire[`RegBus]		reg1_i_not;
	wire[`RegBus]		result_sum;
	wire[`RegBus]		opdata1_mult;
	wire[`RegBus]		opdata2_mult;
	wire[`DoubleRegBus]	hilo_temp;
	// stall
	reg stallreq_for_madd_msub;
	reg stallreq_for_div;
	reg[`DoubleRegBus]	hilo_temp_stall;

	// 会传递到访存阶段，届时利用其确定加载、存储类型
	assign aluop_o = aluop_i;
	// mem_addr_o 是加载、存储指令对应的存储器地址
	// reg1_i 是 base
	assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};
	// 存储指令要存储的数据，和 LWL、LWR 中要使用的目的寄存器的值
	assign reg2_o = reg2_i;

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
	// --- 第一段：计算以下 5 个变量的值 ---
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
	// 1. o1 < 0, o2 > 0
	// 2. o1 > 0, o2 > 0, sub < 0
	// 3. o1 < 0, o2 < 0, sub < 0
	// 无符号时直接比较大小
	assign reg1_lt_reg2 = (aluop_i == `EXE_OP_MATH_SLT) ? ((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31])) : (reg1_i < reg2_i);

	// (5) 对操作数 1 逐位取反，赋给 reg1_i_not
	assign reg1_i_not = ~reg1_i;

	// --- 第二段：对不同的算数运算进行赋值 ---
	always @(*) begin
		if (rst == `RstEnable) begin
			mathout <= `ZeroWord;
		end else begin
			case (aluop_i)
				`EXE_OP_MATH_ADD, `EXE_OP_MATH_ADDU, `EXE_OP_MATH_ADDI, `EXE_OP_MATH_ADDIU: begin
					mathout <= result_sum;
				end
				`EXE_OP_MATH_SUB, `EXE_OP_MATH_SUBU: begin
					mathout <= result_sum;
				end
				`EXE_OP_MATH_SLT, `EXE_OP_MATH_SLTU: begin
					mathout <= reg1_lt_reg2;
				end
				`EXE_OP_MATH_CLO: begin
					mathout <= reg1_i_not[31] ? 0 :
							   reg1_i_not[30] ? 1 :
							   reg1_i_not[29] ? 2 :
							   reg1_i_not[28] ? 3 :
							   reg1_i_not[27] ? 4 :
							   reg1_i_not[26] ? 5 :
							   reg1_i_not[25] ? 6 :
							   reg1_i_not[24] ? 7 :
							   reg1_i_not[23] ? 8 :
							   reg1_i_not[22] ? 9 :
							   reg1_i_not[21] ? 10 :
							   reg1_i_not[20] ? 11 :
							   reg1_i_not[19] ? 12 :
							   reg1_i_not[18] ? 13 :
							   reg1_i_not[17] ? 14 :
							   reg1_i_not[16] ? 15 :
							   reg1_i_not[15] ? 16 :
							   reg1_i_not[14] ? 17 :
							   reg1_i_not[13] ? 18 :
							   reg1_i_not[12] ? 19 :
							   reg1_i_not[11] ? 20 :
							   reg1_i_not[10] ? 21 :
							   reg1_i_not[9] ? 22 :
							   reg1_i_not[8] ? 23 :
							   reg1_i_not[7] ? 24 :
							   reg1_i_not[6] ? 25 :
							   reg1_i_not[5] ? 26 :
							   reg1_i_not[4] ? 27 :
							   reg1_i_not[3] ? 28 :
							   reg1_i_not[2] ? 29 :
							   reg1_i_not[1] ? 30 :
							   reg1_i_not[0] ? 31 : 32;
				end
				`EXE_OP_MATH_CLZ: begin
					mathout <= reg1_i[31] ? 0 :
							   reg1_i[30] ? 1 :
							   reg1_i[29] ? 2 :
							   reg1_i[28] ? 3 :
							   reg1_i[27] ? 4 :
							   reg1_i[26] ? 5 :
							   reg1_i[25] ? 6 :
							   reg1_i[24] ? 7 :
							   reg1_i[23] ? 8 :
							   reg1_i[22] ? 9 :
							   reg1_i[21] ? 10 :
							   reg1_i[20] ? 11 :
							   reg1_i[19] ? 12 :
							   reg1_i[18] ? 13 :
							   reg1_i[17] ? 14 :
							   reg1_i[16] ? 15 :
							   reg1_i[15] ? 16 :
							   reg1_i[14] ? 17 :
							   reg1_i[13] ? 18 :
							   reg1_i[12] ? 19 :
							   reg1_i[11] ? 20 :
							   reg1_i[10] ? 21 :
							   reg1_i[9] ? 22 :
							   reg1_i[8] ? 23 :
							   reg1_i[7] ? 24 :
							   reg1_i[6] ? 25 :
							   reg1_i[5] ? 26 :
							   reg1_i[4] ? 27 :
							   reg1_i[3] ? 28 :
							   reg1_i[2] ? 29 :
							   reg1_i[1] ? 30 :
							   reg1_i[0] ? 31 : 32;
				end
				default: begin
					mathout <= `ZeroWord;
				end
			endcase
		end
	end

	// --- 第三段：进行乘法运算 ---
	// (1) 取得乘法运算的被乘数，如果是有符号乘法且被乘数是负数，那么取补码
	assign opdata1_mult = (((aluop_i == `EXE_OP_MATH_MUL) ||
						    (aluop_i == `EXE_OP_MATH_MULT) ||
						    (aluop_i == `EXE_OP_MATH_MADD) ||
						    (aluop_i == `EXE_OP_MATH_MSUB)) && (reg1_i[31] == 1'b1)) ? (~reg1_i + 1) : reg1_i;
	// (2) 取得乘法运算的乘数，如果是有符号乘法且被乘数是负数，那么取补码
	assign opdata2_mult = (((aluop_i == `EXE_OP_MATH_MUL) ||
						    (aluop_i == `EXE_OP_MATH_MULT) ||
						    (aluop_i == `EXE_OP_MATH_MADD) ||
						    (aluop_i == `EXE_OP_MATH_MSUB)) && (reg2_i[31] == 1'b1)) ? (~reg2_i + 1) : reg2_i;
	// (3) 得到临时乘法结果，保存在变量 hilo_temp 中
	assign hilo_temp = opdata1_mult * opdata2_mult;
	// (4) 修正临时乘法结果的符号
	always @(*) begin
		if (rst == `RstEnable) begin
			mulout <= {`ZeroWord, `ZeroWord};
		end
		else begin
			if ((aluop_i == `EXE_OP_MATH_MULT) || (aluop_i == `EXE_OP_MATH_MUL) || (aluop_i == `EXE_OP_MATH_MADD) || (aluop_i == `EXE_OP_MATH_MSUB)) begin
				if (reg1_i[31] ^ reg2_i[31] == 1'b1) begin
					mulout <= ~hilo_temp + 1;
				end
				else begin
					mulout <= hilo_temp;
				end
			end
			else begin
				mulout <= hilo_temp;
			end
		end
	end

	// MADD, MADDU, MSUB, MSUBU
	always @(*) begin
		if (rst == `RstEnable) begin
			hilo_temp_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;
			stallreq_for_madd_msub <= `StallDisable;
		end
		else begin
			case (aluop_i)
				`EXE_OP_MATH_MADD, `EXE_OP_MATH_MADDU: begin
					if (cnt_i == 2'b00) begin 		// 第一个时钟周期
						hilo_temp_o <= mulout;
						cnt_o <= 2'b01;
						hilo_temp_stall <= {`ZeroWord, `ZeroWord};
						stallreq_for_madd_msub <= `StallEnable;
					end
					else if (cnt_i == 2'b01) begin 						// 第二个时钟周期
						hilo_temp_o <= {`ZeroWord, `ZeroWord};
						cnt_o <= 2'b10;
						hilo_temp_stall <= hilo_temp_i + {hi_i_reg, lo_i_reg};
						stallreq_for_madd_msub <= `StallDisable;
					end
				end
				`EXE_OP_MATH_MSUB, `EXE_OP_MATH_MSUBU: begin
					if (cnt_i == 2'b00) begin
						hilo_temp_o <= ~mulout + 1;
						cnt_o <= 2'b01;
						hilo_temp_stall <= {`ZeroWord, `ZeroWord};
						stallreq_for_madd_msub <= `StallEnable;
					end
					else if (cnt_i == 2'b01) begin
						hilo_temp_o <= {`ZeroWord, `ZeroWord};
						cnt_o <= 2'b10;
						hilo_temp_stall <= hilo_temp_i + {hi_i_reg, lo_i_reg};
						stallreq_for_madd_msub <= `StallDisable;
					end
				end
				default: begin
					hilo_temp_o <= {`ZeroWord, `ZeroWord};
					cnt_o <= 2'b00;
					stallreq_for_madd_msub <= `StallDisable;		
				end
			endcase
		end
	end

	// DIV, DIVU
	always @(*) begin
		if (rst == `RstEnable) begin
			stallreq_for_div <= `StallDisable;
			div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivNotStart;
			signed_div_o <= `DivNotSigned;
		end
		else begin
			stallreq_for_div <= `StallDisable;
			div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivNotStart;
			signed_div_o <= `DivNotSigned;
			case (aluop_i)
				`EXE_OP_MATH_DIV: begin
					if (div_result_ready_i <= `DivResultNotReady) begin
						div_opdata1_o <= reg1_i;		// 被除数
						div_opdata2_o <= reg2_i;		// 除数
						div_start_o <= `DivStart;
						signed_div_o <= `DivSigned;
						stallreq_for_div <= `StallEnable;
					end
					else if (div_result_ready_i <= `DivResultNotReady) begin
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivNotStart;
						signed_div_o <= `DivSigned;
						stallreq_for_div <= `StallDisable;
					end
				end
				`EXE_OP_MATH_DIVU: begin
					if (div_result_ready_i <= `DivResultNotReady) begin
						div_opdata1_o <= reg1_i;		// 被除数
						div_opdata2_o <= reg2_i;		// 除数
						div_start_o <= `DivStart;
						signed_div_o <= `DivNotSigned;
						stallreq_for_div <= `StallEnable;
					end
					else if (div_result_ready_i <= `DivResultNotReady) begin
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivNotStart;
						signed_div_o <= `DivNotSigned;
						stallreq_for_div <= `StallDisable;
					end
				end
			endcase
		end
	end

	always @ (*) begin
    	stallreq = stallreq_for_madd_msub || stallreq_for_div;
  	end

	// HI LO 输出
	always @(*) begin
		if (rst == `RstEnable) begin
			whilo_o <= `WriteDisable;
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
				`EXE_OP_MATH_MULT, `EXE_OP_MATH_MULTU: begin
					whilo_o <= `WriteEnable;
					hi_o <= mulout[63:32];
					lo_o <= mulout[31:0];
				end
				`EXE_OP_MATH_MADD, `EXE_OP_MATH_MADDU: begin
					whilo_o <= `WriteEnable;
					hi_o <= hilo_temp_stall[63:32];
					lo_o <= hilo_temp_stall[31:0];
				end
				`EXE_OP_MATH_MSUB, `EXE_OP_MATH_MSUBU: begin
					whilo_o <= `WriteEnable;
					hi_o <= hilo_temp_stall[63:32];
					lo_o <= hilo_temp_stall[31:0];					
				end
				`EXE_OP_MATH_DIV, `EXE_OP_MATH_DIVU: begin
					whilo_o <= `WriteEnable;
					hi_o <= div_result_i[63:32];
					lo_o <= div_result_i[31:0];
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
			`EXE_RES_MATH: begin
				wdata_o <= mathout;
			end
			`EXE_RES_MUL: begin
				wdata_o <= mulout[31:0];
			end
			`EXE_RES_JUMP_BRANCH: begin
				wdata_o <= link_address_i;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
	end

endmodule
