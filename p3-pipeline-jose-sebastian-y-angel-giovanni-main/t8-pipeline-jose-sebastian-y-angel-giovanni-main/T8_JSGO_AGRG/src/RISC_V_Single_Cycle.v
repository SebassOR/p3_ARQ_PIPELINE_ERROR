/******************************************************************
* Author:
* José Sebastián González Ortega
* Angel Giovanni Reynoso González
* email:
*  joses.gonzalez@iteso.mx
*	angel.reynoso@iteso.mx
* Date:
*	16/05/2026
******************************************************************/

module RISC_V_Single_Cycle
#(
    parameter PROGRAM_MEMORY_DEPTH = 128,
    parameter DATA_MEMORY_DEPTH = 128
)
(
  //input       reset,
    input        clk,
    output [10:0] gpio_port_out,
    input  [9:0] gpio_port_in,
    output        rs232_tx      
);

    wire branch_w;
    wire alu_src_w;
    wire reg_write_w;
    wire auipc_w;
    wire mem_to_reg_w;
    wire mem_write_w;
    wire mem_read_w;
    wire [2:0] alu_op_w;
    wire PCSrc_w;
    wire rs232_tx_w;

    wire [31:0] pc_plus_4_w;
    wire [31:0] pc_w;
    wire [31:0] New_pc_w;
    wire [31:0] PC_imm_result_w;
    wire [31:0] read_data_1_w;
    wire [31:0] read_data_2_w;
    wire [31:0] READ_DATA_w;
    wire [31:0] MUX_ALU_o_w;
    wire [31:0] inmmediate_data_w;
    wire [31:0] alu_result_w;
    wire        Zero_o_w;
    wire [31:0] instruction_bus_w;
    wire [31:0] read_data_2_or_imm_w;
    wire [3:0]  alu_operation_w;
    wire [31:0] alu_input_a_w;

    wire lui_w;
    
    //forwarding
    wire[1:0] Forward_A_w;
    wire[1:0] Forward_B_w;
    wire [31:0] alu_input_a_forward_w;
    wire [31:0] alu_input_b_forward_w;
    
    //hazard 
    wire      PC_write_w;
    wire          IF_ID_write_w;
    wire         control_mux_w;

    // JAL
    wire [31:0] write_data_reg_w;
    wire        jal_w;
    // JALR
    wire [31:0] branch_target_w;
    wire        jalr_w;

    wire clk_1hz;
    wire reset_global_w = gpio_port_in[9];

    assign gpio_port_out[9] = clk_1hz;

    //Cables IF
    wire [31:0] instruction_IF_w;
    wire [31:0] pc_IF_w;

    //Cables ID
    wire [31:0] instruction_ID_w;
    wire [31:0] pc_ID_w;
    wire [31:0] pc_plus_4_ID_w; // <-- AGREGADO

    //Cables ID/EX
    wire [31:0] pc_EX_w;
    wire [31:0] Rs1_EX_w;
    wire [31:0] Rs2_EX_w;
    wire [31:0] Imm_EX_w;
    wire [4:0]  Rd_addr_EX_w;
    wire [31:0] Ins_EX_w;
    wire [31:0] pc_plus_4_EX_w; // <-- AGREGADO
    //Control WB
    wire reg_write_EX_w;
    wire mem_to_reg_EX_w;
    //Control MEM
    wire mem_read_EX_w;
    wire mem_write_EX_w;
    wire branch_EX_w;
    wire jal_EX_w;
    wire jalr_EX_w;
    wire [2:0] funct3_MEM_w;
    //Control EX
    wire alu_src_EX_w;
    wire [2:0] alu_op_EX_w;
    wire auipc_EX_w;
    

    //Cables EX/MEM
    wire [31:0] PC_plus_imm_MEM_w;
    wire [31:0] ALU_result_MEM_w;
    wire [31:0] Rs2_MEM_w;
    wire [4:0]  Rd_addr_MEM_w;
    wire [31:0] pc_plus_4_MEM_w; // <-- AGREGADO
    wire        reg_write_MEM_w;
    wire        mem_to_reg_MEM_w;
    wire        mem_read_MEM_w;
    wire        mem_write_MEM_w;
    wire        branch_MEM_w;
    wire        jal_MEM_w;
    wire        jalr_MEM_w;
    wire        zero_MEM_w;

    //Cables MEM/WB
    wire [31:0] read_data_WB_w;
    wire [31:0] ALU_result_WB_w;
    wire [31:0] pc_plus_4_WB_w;
    wire [4:0]  Rd_addr_WB_w;
    wire        reg_write_WB_w;
    wire        mem_to_reg_WB_w;
    wire        jal_WB_w;

    //ETAPA IF
	 /*
    Clock_Divider #(.DIVIDER(2)) CLK_DIV (
    .clk_in (clk),
    .reset  (reset_global_w),
    .clk_out(clk_1hz)
)*/
	 assign clk_1hz = clk;

    PC_Register PROGRAM_COUNTER (
    .clk     (clk_1hz),
    .reset   (reset_global_w),
    .enable  (PC_write_w),    
    .Next_PC (New_pc_w),
    .PC_Value(pc_IF_w)
);

    Program_Memory #(.MEMORY_DEPTH(PROGRAM_MEMORY_DEPTH)) PROGRAM_MEMORY (
        .Address_i    (pc_IF_w),
        .Instruction_o(instruction_IF_w)
    );

    Adder_32_Bits PC_PLUS_4 (
        .Data0 (pc_IF_w),
        .Data1 (4),
        .Result(pc_plus_4_w)
    );

    //REGISTRO IF/ID
    IF_ID reg_IF_ID (
    .reset          (reset_global_w),
    .clk            (clk_1hz),
    .enable         (IF_ID_write_w),    
    .flush_branch_i (PCSrc_w),       
    .PC_in          (pc_IF_w),
    .ins_in         (instruction_IF_w),
    .pc_plus_4_in   (pc_plus_4_w),      // <-- AGREGADO
    .ins_out        (instruction_ID_w),
    .PC_out         (pc_ID_w),
    .pc_plus_4_out  (pc_plus_4_ID_w)    // <-- AGREGADO
);

    //ETAPA ID

    Control CONTROL_UNIT (
        .OP_i       (instruction_ID_w[6:0]),
        .Branch_o   (branch_w),
        .ALU_Op_o   (alu_op_w),
        .ALU_Src_o  (alu_src_w),
        .Reg_Write_o(reg_write_w),
        .AUIPC_o    (auipc_w),
        .Mem_to_Reg_o(mem_to_reg_w),
        .Mem_Read_o (mem_read_w),
        .JAL_o      (jal_w),
        .JALR_o     (jalr_w),
        .Mem_Write_o(mem_write_w)
    );

    Register_File REGISTER_FILE_UNIT (
        .clk              (clk_1hz),
        .reset            (reset_global_w),
        .Reg_Write_i      (reg_write_WB_w),        
        .Write_Register_i (Rd_addr_WB_w),            
        .Read_Register_1_i(instruction_ID_w[19:15]),
        .Read_Register_2_i(instruction_ID_w[24:20]),
        .Read_Data_1_o    (read_data_1_w),
        .Read_Data_2_o    (read_data_2_w),
        .Write_Data_i     (write_data_reg_w)
    );

    Immediate_Unit IMM_UNIT (
        .op_i            (instruction_ID_w[6:0]),
        .Instruction_bus_i(instruction_ID_w),
        .Immediate_o     (inmmediate_data_w)
    );

    //REGISTRO ID/EX

    ID_EX reg_ID_EX (
        // Entradas
        .reset      (reset_global_w),
        .clk        (clk_1hz),
        .flush_i    (control_mux_w),
        .PC_in      (pc_ID_w),
        .Rd1_in     (read_data_1_w),
        .Rd2_in     (read_data_2_w),
        .Imm_in     (inmmediate_data_w),
        .Rd_addr_in (instruction_ID_w[11:7]),
        .Ins_in     (instruction_ID_w),
        .pc_plus_4_in(pc_plus_4_ID_w),      // <-- AGREGADO
        // WB
        .reg_write_in  (reg_write_w),
        .mem_to_reg_in (mem_to_reg_w),
        // MEM
        .mem_read_in   (mem_read_w),
        .mem_write_in  (mem_write_w),
        .branch_in     (branch_w),
        .jal_ID        (jal_w),
        .jalr_ID       (jalr_w),        
        // EX
        .alu_src_in    (alu_src_w),
        .alu_op_in     (alu_op_w),
        .auipc_in      (auipc_w),
        //Salidas datos
        .PC_out        (pc_EX_w),
        .Rd1_out       (Rs1_EX_w),
        .Rd2_out       (Rs2_EX_w),
        .Imm_out       (Imm_EX_w),
        .Rd_addr_out   (Rd_addr_EX_w),
        .Ins_out       (Ins_EX_w),
        .pc_plus_4_out (pc_plus_4_EX_w),    // <-- AGREGADO
        //Salidas control WB
        .reg_write_out (reg_write_EX_w),
        .mem_to_reg_out(mem_to_reg_EX_w),
        //Salidas control MEM
        .mem_read_out  (mem_read_EX_w),
        .mem_write_out (mem_write_EX_w),
        .branch_out    (branch_EX_w),
        .jal_EX        (jal_EX_w),
        .jalr_EX       (jalr_EX_w),
        // Salidas control EX
        .alu_src_out   (alu_src_EX_w),
        .alu_op_out    (alu_op_EX_w),
        .auipc_out     (auipc_EX_w)
    );

    //ETAPA EX

    Adder_PC_imm PC_PLUS_imm (
        .PC_now     (pc_EX_w),
        .Immediate_i(Imm_EX_w),
        .Result_o   (PC_imm_result_w)
    );

    Multiplexer_2_to_1 #(.NBits(32)) MUX_DATA_OR_IMM_FOR_ALU (
    .Selector_i  (alu_src_EX_w),
    .Mux_Data_0_i(alu_input_b_forward_w),
    .Mux_Data_1_i(Imm_EX_w),
    .Mux_Output_o(read_data_2_or_imm_w)
);


    Multiplexer_2_to_1 #(.NBits(32)) MUX_PC_OR_RS1 (
    .Selector_i  (auipc_EX_w),
    .Mux_Data_0_i(alu_input_a_forward_w),  
    .Mux_Data_1_i(pc_EX_w),
    .Mux_Output_o(alu_input_a_w)
);

    ALU_Control ALU_CONTROL_UNIT (
        .funct7_i      ({Ins_EX_w[30], Ins_EX_w[25]}),
        .ALU_Op_i      (alu_op_EX_w),
        .funct3_i      (Ins_EX_w[14:12]),
        .ALU_Operation_o(alu_operation_w)
    );

    ALU ALU_UNIT (
        .ALU_Operation_i(alu_operation_w),
        .A_i            (alu_input_a_w),
        .B_i            (read_data_2_or_imm_w),
        .ALU_Result_o   (alu_result_w),
        .Zero_o         (Zero_o_w)
    );

    //REGISTRO EX/MEM

    EX_MEM reg_EX_MEM (
        .clk            (clk_1hz),
        .reset          (reset_global_w),
        // Datos
        .PC_plus_imm_in (PC_imm_result_w),
        .ALU_result_in  (alu_result_w),
        .Rs2_in         (alu_input_b_forward_w), //Cambio fw unit
        .Rd_addr_in     (Rd_addr_EX_w),
        .pc_plus_4_in   (pc_plus_4_EX_w),        // <-- AGREGADO
        // Control WB
        .reg_write_in   (reg_write_EX_w),
        .mem_to_reg_in  (mem_to_reg_EX_w),
        // Control MEM
        .mem_read_in    (mem_read_EX_w),
        .mem_write_in   (mem_write_EX_w),
        .branch_in      (branch_EX_w),
        .jal_in         (jal_EX_w),
        .jalr_in        (jalr_EX_w),
        .zero_in        (Zero_o_w),
        // Salidas
        .PC_plus_imm_out(PC_plus_imm_MEM_w),
        .ALU_result_out (ALU_result_MEM_w),
        .Rs2_out        (Rs2_MEM_w),
        .Rd_addr_out    (Rd_addr_MEM_w),
        .pc_plus_4_out  (pc_plus_4_MEM_w),       // <-- AGREGADO
        .reg_write_out  (reg_write_MEM_w),
        .mem_to_reg_out (mem_to_reg_MEM_w),
        .mem_read_out   (mem_read_MEM_w),
        .mem_write_out  (mem_write_MEM_w),
        .branch_out     (branch_MEM_w),
        .jal_out        (jal_MEM_w),
        .jalr_out       (jalr_MEM_w),
        .funct3_in  (Ins_EX_w[14:12]),
        .funct3_out (funct3_MEM_w),
        .zero_out       (zero_MEM_w)
    );

    //ETAPA MEM

    AND_CONTROL And_control (
    .PCscr     (PCSrc_w),
    .Branch_i  (branch_MEM_w),
    .JAL_i     (jal_MEM_w),
    .JALR_i    (jalr_MEM_w),
    .ALU_zero_i(zero_MEM_w),
    .funct3_i  (funct3_MEM_w)    
    );

    Multiplexer_2_to_1 MUX_JAL_OR_JALR (
        .Selector_i  (jalr_MEM_w),         
        .Mux_Data_0_i(PC_plus_imm_MEM_w),  
        .Mux_Data_1_i(ALU_result_MEM_w),   
        .Mux_Output_o(branch_target_w)
    );

    Mux_PC MUX_PC (
        .pc_plus_4  (pc_plus_4_w),
        .PCplus_imm (branch_target_w),
        .PCscr      (PCSrc_w),
        .new_PC     (New_pc_w)
    );

    Memory_Map MEMORY_AND_IO (
    .clk          (clk_1hz),
    .reset        (reset_global_w),   
    .addr_i       (ALU_result_MEM_w),
    .write_data_i (Rs2_MEM_w),
    .mem_write_i  (mem_write_MEM_w),
    .mem_read_i   (mem_read_MEM_w),
    .gpio_port_in (gpio_port_in[8:0]),
    .read_data_o  (READ_DATA_w),
    .gpio_port_out(gpio_port_out[8:0]),
    .rs232_tx     (rs232_tx_w)       
);

    //REGISTRO MEM/WB

    MEM_WB reg_MEM_WB (
        .clk           (clk_1hz),
        .reset         (reset_global_w),
        //info
        .read_data_in  (READ_DATA_w),
        .ALU_result_in (ALU_result_MEM_w),
        .pc_plus_4_in  (pc_plus_4_MEM_w),   
        .Rd_addr_in    (Rd_addr_MEM_w),
        //Control WB
        .reg_write_in  (reg_write_MEM_w),
        .mem_to_reg_in (mem_to_reg_MEM_w),
        .jal_in        (jal_MEM_w),
        //Salidas
        .read_data_out (read_data_WB_w),
        .ALU_result_out(ALU_result_WB_w),
        .pc_plus_4_out (pc_plus_4_WB_w),
        .Rd_addr_out   (Rd_addr_WB_w),
        .reg_write_out (reg_write_WB_w),
        .mem_to_reg_out(mem_to_reg_WB_w),
        .jal_out       (jal_WB_w)
    );

    //ETAPA WB

    MUX_MEMtoReg Mux_mem2reg (
        .mem2reg  (mem_to_reg_WB_w),      
        .mem_i    (read_data_WB_w),        
        .ALU_i    (ALU_result_WB_w),       
        .MUX_ALU_o(MUX_ALU_o_w)
    );

    Multiplexer_2_to_1 #(.NBits(32)) MUX_JAL (
        .Selector_i  (jal_WB_w),            
        .Mux_Data_0_i(MUX_ALU_o_w),
        .Mux_Data_1_i(pc_plus_4_WB_w),    
        .Mux_Output_o(write_data_reg_w)
    );
    Forwarding_Unit FORWARDING_UNIT (
    .Rs1_addr_EX_i  (Ins_EX_w[19:15]),
    .Rs2_addr_EX_i  (Ins_EX_w[24:20]),
    .Rd_addr_MEM_i  (Rd_addr_MEM_w),
    .reg_write_MEM_i(reg_write_MEM_w),  
    .Rd_addr_WB_i   (Rd_addr_WB_w),
    .reg_write_WB_i (reg_write_WB_w),
    .Forward_A_o    (Forward_A_w),
    .Forward_B_o    (Forward_B_w)
);

    Hazard_Unit HAZARD_UNIT (
    .Rs1_addr_ID_i (instruction_ID_w[19:15]),
    .Rs2_addr_ID_i (instruction_ID_w[24:20]),
    .Rd_addr_EX_i  (Rd_addr_EX_w),
    .mem_read_EX_i (mem_read_EX_w),
    .PC_write_o    (PC_write_w),
    .IF_ID_write   (IF_ID_write_w),   
    .control_mux_o (control_mux_w)
);
    
    Mux_3_to_1 #(.NBits(32)) MUX_FORWARD_A (
         .Selector_i   (Forward_A_w),
         .Mux_Data_00_i(Rs1_EX_w),         
         .Mux_Data_01_i(write_data_reg_w),   
         .Mux_Data_10_i(ALU_result_MEM_w),  
         .Mux_Output_o (alu_input_a_forward_w)
    );

    Mux_3_to_1 #(.NBits(32)) MUX_FORWARD_B (
         .Selector_i   (Forward_B_w),
         .Mux_Data_00_i(Rs2_EX_w),            
         .Mux_Data_01_i(write_data_reg_w),   
         .Mux_Data_10_i(ALU_result_MEM_w),  
         .Mux_Output_o (alu_input_b_forward_w)
    );
    assign rs232_tx = rs232_tx_w;
    
endmodule