// 全局宏定义
`define RstEnable 			1'b1			// 复位信号有效
`define RstDisable 			1'b0			// 复位信号无效
`define ZeroWord 			32'h00000000	// 32 位的 0
`define WriteEnable 		1'b1			// 写使能
`define WriteDisable 		1'b0			// 写禁止
`define ReadEnable 			1'b1			// 读使能
`define ReadDisable 		1'b0			// 读禁止
`define AluOpBus 			7:0				// 译码阶段 aluop_o 的宽度
`define AluSelBus 			2:0				// 译码阶段 alusel_o 的宽度
`define InstValid 			1'b0			// 指令有效
`define InstInvalid 		1'b1			// 指令无效
`define InDelaySlot 		1'b1
`define NotInDelaySlot 		1'b0
`define Branch 				1'b1
`define NotBranch 			1'b0
`define InterruptAssert 	1'b1
`define InterruptNotAssert 	1'b0
`define TrapAssert 			1'b1
`define TrapNotAssert 		1'b0
`define ChipEnable 			1'b1
`define ChipDisable 		1'b0
`define Flush 				1'b1
`define NotFlush			1'b0

// 流水线暂停
`define StallEnable 	1'b1
`define StallDisable 	1'b0
`define StallNone 		6'b000000
`define StallFromID 	6'b000111
`define StallFromEX 	6'b001111

// 指令的大类和立即数指令的类型
`define EXE_SPECIAL		6'b000000		// SPECIAL
`define EXE_REGIMM_INST	6'b000001
`define EXE_J 			6'b000010
`define EXE_JAL 		6'b000011
`define EXE_BEQ 		6'b000100
`define EXE_BNE			6'b000101
`define EXE_BLEZ		6'b000110
`define EXE_BGTZ		6'b000111
`define EXE_ADDI 		6'b001000		// ADD
`define EXE_ADDIU 		6'b001001		// ADDU
`define EXE_SLTI 		6'b001010		// SLT
`define EXE_SLTIU 		6'b001011		// SLTU
`define EXE_ANDI 		6'b001100		// AND
`define EXE_ORI 		6'b001101		// OR
`define EXE_XORI 		6'b001110		// OR
`define EXE_LUI 		6'b001111		// OR
`define EXE_SPECIAL2	6'b011100		// SPECIAL2
`define EXE_LB 			6'b100000
`define EXE_LH 			6'b100001
`define EXE_LWL 		6'b100010
`define EXE_LW 			6'b100011
`define EXE_LBU 		6'b100100
`define EXE_LHU 		6'b100101
`define EXE_LWR 		6'b100110
`define EXE_SB 			6'b101000
`define EXE_SH 			6'b101001
`define EXE_SWL 		6'b101010
`define EXE_SW 			6'b101011
`define EXE_SWR 		6'b101110
`define EXE_LL 			6'b110000
`define EXE_SC 			6'b111000
`define EXE_PREF		6'b110011		// NOP

// EXE_SPECIAL 寄存器型指令的子类型
// 移位操作
`define EXE_SPC_SLL 	6'b000000
`define EXE_SPC_SRL 	6'b000010
`define EXE_SPC_SRA 	6'b000011
`define EXE_SPC_SLLV 	6'b000100
`define EXE_SPC_SRLV 	6'b000110
`define EXE_SPC_SRAV 	6'b000111
// 移动操作
`define EXE_SPC_MOVZ	6'b001010
`define EXE_SPC_MOVN	6'b001011
`define EXE_SPC_MFHI	6'b010000
`define EXE_SPC_MTHI	6'b010001
`define EXE_SPC_MFLO	6'b010010
`define EXE_SPC_MTLO	6'b010011
// 算数运算
`define EXE_SPC_MULT	6'b011000
`define EXE_SPC_MULTU	6'b011001
`define EXE_SPC_DIV 	6'b011010
`define EXE_SPC_DIVU 	6'b011011
`define EXE_SPC_ADD		6'b100000
`define EXE_SPC_ADDU	6'b100001
`define EXE_SPC_SUB		6'b100010
`define EXE_SPC_SUBU	6'b100011
`define EXE_SPC_SLT		6'b101010
`define EXE_SPC_SLTU	6'b101011
// 逻辑运算
`define EXE_SPC_AND 	6'b100100
`define EXE_SPC_OR 		6'b100101
`define EXE_SPC_XOR 	6'b100110
`define EXE_SPC_NOR		6'b100111
// 其他操作（可以被当做移位操作来处理）
`define EXE_SPC_NOP		6'b000000
`define EXE_SPC_SSNOP	6'b000000
`define EXE_SPC_SYNC	6'b001111
// 转移操作
`define EXE_SPC_JR 		6'b001000
`define EXE_SPC_JALR	6'b001001
// 系统调用和异常处理
`define EXE_SPC_SYSCALL	6'b001100
`define EXE_SPC_TGE		6'b110000
`define EXE_SPC_TGEU	6'b110001
`define EXE_SPC_TLT		6'b110010
`define EXE_SPC_TLTU	6'b110011
`define EXE_SPC_TEQ		6'b110100
`define EXE_SPC_TNE		6'b110110

// EXE_SPECIAL2 寄存器型指令的子类型
`define EXE_SPC2_MADD	6'b000000
`define EXE_SPC2_MADDU	6'b000001
`define EXE_SPC2_MUL	6'b000010
`define EXE_SPC2_MSUB	6'b000100
`define EXE_SPC2_MSUBU	6'b000101
`define EXE_SPC2_CLZ	6'b100000
`define EXE_SPC2_CLO	6'b100001

// REGIMM_INST
`define EXE_REGIMM_BLTZ		5'b00000
`define EXE_REGIMM_BGEZ		5'b00001
`define EXE_REGIMM_BLTZAL	5'b10000
`define EXE_REGIMM_BGEZAL	5'b10001

// EXCEPTION_INST
`define EXE_REGIMM_TGEI		5'b01000
`define EXE_REGIMM_TGEIU	5'b01001
`define EXE_REGIMM_TLTI		5'b01010
`define EXE_REGIMM_TLTIU	5'b01011
`define EXE_REGIMM_TEQI		5'b01100
`define EXE_REGIMM_TNEI		5'b01110

`define EXE_ERET			32'b01000010000000000000000000011000

// AluSel
`define EXE_RES_NOP			3'b000
`define EXE_RES_LOGIC 		3'b001
`define EXE_RES_SHIFT		3'b010
`define EXE_RES_MOVE		3'b011
`define EXE_RES_MATH		3'b100
`define EXE_RES_MUL			3'b101
`define EXE_RES_JUMP_BRANCH	3'b110
`define EXE_RES_LOAD_STORE 	3'b111

// AluOp
`define EXE_OP_NOP_NOP 		8'b00000000

`define EXE_OP_LOGIC_AND	8'b00000001
`define EXE_OP_LOGIC_OR		8'b00000010
`define EXE_OP_LOGIC_XOR 	8'b00000011
`define EXE_OP_LOGIC_NOR 	8'b00000100

`define EXE_OP_SHIFT_SLL	8'b00000101
`define EXE_OP_SHIFT_SRL	8'b00000110
`define EXE_OP_SHIFT_SRA	8'b00000111

`define EXE_OP_MOVE_MOVZ	8'b00001000
`define EXE_OP_MOVE_MOVN	8'b00001001
`define EXE_OP_MOVE_MFHI	8'b00001010
`define EXE_OP_MOVE_MFLO	8'b00001011
`define EXE_OP_MOVE_MFC0	8'b00001100
`define EXE_OP_MOVE_MTC0	8'b00001101

`define EXE_OP_MATH_ADD		8'b00010000
`define EXE_OP_MATH_ADDU	8'b00010001
`define EXE_OP_MATH_ADDI	8'b00010010
`define EXE_OP_MATH_ADDIU	8'b00010011
`define EXE_OP_MATH_SUB		8'b00010100
`define EXE_OP_MATH_SUBU	8'b00010101
`define EXE_OP_MATH_SLT		8'b00010110
`define EXE_OP_MATH_SLTU	8'b00010111
`define EXE_OP_MATH_CLO		8'b00011000
`define EXE_OP_MATH_CLZ		8'b00011001

`define EXE_OP_MATH_MULTU	8'b00011010
`define EXE_OP_MATH_MULT	8'b00011011
`define EXE_OP_MATH_MUL		8'b00011100
`define EXE_OP_MATH_MADD 	8'b00011101
`define EXE_OP_MATH_MADDU 	8'b00011110
`define EXE_OP_MATH_MSUB 	8'b00011111
`define EXE_OP_MATH_MSUBU 	8'b00100000
`define EXE_OP_MATH_DIV 	8'b00100001
`define EXE_OP_MATH_DIVU 	8'b00100010

`define EXE_OP_JUMP_BRANCH_JR		8'b00100100
`define EXE_OP_JUMP_BRANCH_JALR		8'b00100101
`define EXE_OP_JUMP_BRANCH_J		8'b00100110
`define EXE_OP_JUMP_BRANCH_JAL		8'b00100111
`define EXE_OP_JUMP_BRANCH_BEQ		8'b00101000
`define EXE_OP_JUMP_BRANCH_BNE		8'b00101001
`define EXE_OP_JUMP_BRANCH_BLEZ		8'b00101010
`define EXE_OP_JUMP_BRANCH_BGTZ		8'b00101011
`define EXE_OP_JUMP_BRANCH_BLTZ 	8'b00101100
`define EXE_OP_JUMP_BRANCH_BGEZ 	8'b00101101
`define EXE_OP_JUMP_BRANCH_BLTZAL 	8'b00101110
`define EXE_OP_JUMP_BRANCH_BGEZAL 	8'b00101111

`define EXE_OP_LOAD_STORE_LB 		8'b00110000
`define EXE_OP_LOAD_STORE_LH 		8'b00110001
`define EXE_OP_LOAD_STORE_LWL 		8'b00110010
`define EXE_OP_LOAD_STORE_LW 		8'b00110011
`define EXE_OP_LOAD_STORE_LBU 		8'b00110100
`define EXE_OP_LOAD_STORE_LHU 		8'b00110101
`define EXE_OP_LOAD_STORE_LWR 		8'b00110110
`define EXE_OP_LOAD_STORE_SB 		8'b00111000
`define EXE_OP_LOAD_STORE_SH 		8'b00111001
`define EXE_OP_LOAD_STORE_SWL 		8'b00111010
`define EXE_OP_LOAD_STORE_SW 		8'b00111011
`define EXE_OP_LOAD_STORE_SWR 		8'b00111100
`define EXE_OP_LOAD_STORE_LL 		8'b00111101
`define EXE_OP_LOAD_STORE_SC 		8'b00111110

`define EXE_OP_EXCEPTION_SYSCALL	8'b01000000
`define EXE_OP_EXCEPTION_TGE		8'b01000001
`define EXE_OP_EXCEPTION_TGEU		8'b01000010
`define EXE_OP_EXCEPTION_TLT		8'b01000011
`define EXE_OP_EXCEPTION_TLTU		8'b01000100
`define EXE_OP_EXCEPTION_TEQ		8'b01000101
`define EXE_OP_EXCEPTION_TNE		8'b01000110
`define EXE_OP_EXCEPTION_TGEI		8'b01011000
`define EXE_OP_EXCEPTION_TGEIU		8'b01011001
`define EXE_OP_EXCEPTION_TLTI		8'b01011010
`define EXE_OP_EXCEPTION_TLTIU		8'b01011011
`define EXE_OP_EXCEPTION_TEQI		8'b01011100
`define EXE_OP_EXCEPTION_TNEI		8'b01011101
`define EXE_OP_EXCEPTION_ERET		8'b01011110

`define EXE_OP_OTHER_MTHI			8'b10001100
`define EXE_OP_OTHER_MTLO			8'b10001101

// 与指令存储器 ROM 相关的宏定义
`define InstAddrBus 		31:0
`define InstBus 			31:0
`define InstMemNum 			131071
`define InstMemNumLog2 		17

// 与 RAM 相关的宏定义
`define DataAddrBus			31:0
`define DataBus 			31:0
// `define DataMemNumber 		131072
// `define DataMemNumberLog2 	17
`define DataMemNumber 		16
`define DataMemNumberLog2 	4
`define ByteWidth 			7:0

// 与通用寄存器 Regfile 有关的宏定义
`define RegAddrBus 			4:0
`define RegBus 				31:0
`define RegWidth 			32
`define DoubleRegWidth 		64
`define DoubleRegBus 		63:0
`define RegNum 				32
`define RegNumLog2 			5
`define NOPRegAddr 			5'b00000

// 与除法器相关的宏定义
`define DivFree				2'b00
`define DivOn				2'b01
`define DivByZero			2'b10
`define DivEnd				2'b11
`define DivResultNotReady	1'b0
`define DivResultReady		1'b1
`define DivNotStart			1'b0
`define DivStart 			1'b1
`define DivNotAnnul			1'b0
`define DivAnnul 			1'b1
`define DivNotSigned 		1'b0
`define DivSigned 			1'b1

// 与协处理器 CP0 相关的指令
`define CP0_REG_COUNT		5'b01001
`define CP0_REG_COMPARE		5'b01011
`define CP0_REG_STATUS		5'b01100
`define CP0_REG_CAUSE		5'b01101
`define CP0_REG_EPC			5'b01110
`define CP0_REG_PRID		5'b01111
`define CP0_REG_CONFIG		5'b10000

// 与跳转有关的宏定义
`define RegRAAddr			5'b11111

// 有关异常的宏定义
`define EXCEPTTYPE_INTERRUPT		32'h00000001
`define EXCEPTTYPE_SYSCALL			32'h00000008
`define EXCEPTTYPE_INST_INVALID		32'h0000000a
`define EXCEPTTYPE_TRAP				32'h0000000d
`define EXCEPTTYPE_OV				32'h0000000c
`define EXCEPTTYPE_ERET				32'h0000000e