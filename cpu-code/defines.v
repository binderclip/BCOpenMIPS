// 全局宏定义
`define RstEnable 1'b1				// 复位信号有效
`define RstDisable 1'b0				// 复位信号无效
`define ZeroWord 32'h00000000		// 32 位的 0
`define WriteEnable 1'b1			// 写使能
`define WriteDisable 1'b0			// 写禁止
`define ReadEnable 1'b1				// 读使能
`define ReadDisable 1'b0			// 读禁止
`define AluOpBus 7:0				// 译码阶段 aluop_o 的宽度
`define AluSelBus 2:0				// 译码阶段 alusel_o 的宽度
`define InstValid 1'b0				// 指令有效
`define InstInvalid 1'b1			// 指令无效
`define Stop 1'b1
`define NoStop 1'b0
`define InDelaySlot 1'b1
`define NotInDelaySlot 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 1'b1
`define TrapNotAssert 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0

// 指令的大类和立即数指令的类型
`define EXE_SPECIAL		6'b000000
`define EXE_ANDI 		6'b001100
`define EXE_ORI 		6'b001101
`define EXE_XORI 		6'b001110
`define EXE_LUI 		6'b001111
`define EXE_PREF		6'b110011

// EXE_SPECIAL 寄存器型指令的子类型
// 移位操作
`define EXE_SPC_SLL 	6'b000000
`define EXE_SPC_SRL 	6'b000010
`define EXE_SPC_SRA 	6'b000011
`define EXE_SPC_SLLV 	6'b000100
`define EXE_SPC_SRLV 	6'b000110
`define EXE_SPC_SRAV 	6'b000111
// 逻辑运算
`define EXE_SPC_AND 	6'b100100
`define EXE_SPC_OR 		6'b100101
`define EXE_SPC_XOR 	6'b100110
`define EXE_SPC_NOR		6'b100111

// AluSel
`define EXE_RES_NOP		3'b000
`define EXE_RES_LOGIC 	3'b001

// AluOp
`define EXE_OP_NOP_NOP 		8'b00000000
`define EXE_OP_LOGIC_AND	8'b00000001
`define EXE_OP_LOGIC_OR		8'b00000010
`define EXE_OP_LOGIC_XOR 	8'b00000011
`define EXE_OP_LOGIC_NOR 	8'b00000100

// 与指令存储器 ROM 相关的指令
`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071
`define InstMemNumLog2 17

// 与通用寄存器 Regfile 有关的宏定义
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define DoubleRegWidth 64
`define DoubleRegBus 63:0
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b00000





