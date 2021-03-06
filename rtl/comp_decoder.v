//`include "opcode.vh"
module comp_decoder (
    input wire [31:0] ins,
    output reg [31:0] ins_out,
    output reg compressed_ins,illegal_ins
    );

localparam  [ 6: 0] OP_AUIPC   = 7'b0010111,        // U-type
                    OP_LUI     = 7'b0110111,        // U-type
                    OP_JAL     = 7'b1101111,        // J-type
                    OP_JALR    = 7'b1100111,        // I-type
                    OP_BRANCH  = 7'b1100011,        // B-type
                    OP_LOAD    = 7'b0000011,        // I-type
                    OP_STORE   = 7'b0100011,        // S-type
                    OP_ARITHI  = 7'b0010011,        // I-type
                    OP_ARITHR  = 7'b0110011,        // R-type
                    OP_FENCE   = 7'b0001111,
                    OP_SYSTEM  = 7'b1110011;

always @(*) 
begin
    // For normal 32 bit instructions
    if(ins[1:0]==2'b11)
    begin
        illegal_ins = 1'b0;
        ins_out = ins;
        compressed_ins = 1'b0;
    end

    // For compressed instructions
    // For first Case Opcode = 0
    else if (ins[1:0]==2'b00)
    begin
        compressed_ins = 1'b1;
        case (ins[15:13])
            3'b000:
            begin
                if(ins[12:5]==8'b0000_0000)   //Illegal Instruction
                begin
                    illegal_ins = 1'b1;
                    compressed_ins = 1'b0;
                end
                else
                begin
                    ins_out = {2'd0, {ins[10:7]}, {ins[12:11]}, {ins[5]}, {ins[6]},2'd0,{5'd2},3'd0,{2'd1,{ins[4:2]}},{OP_ARITHI}};  //C.ADDI_4SPN  => addi rd', x2, imm
                end
            end
            //3'b001:
            3'b010:
            begin
              ins_out = {{5'd0}, {ins[5]}, {ins[12:10]},{ins[6]},2'd0,{2'd1,{ins[9:7]}},3'd2,{2'd1,{ins[4:2]}},{OP_LOAD}};   //C.LW  -> lw rd', imm(rs1')
            end 
            3'b110:
            begin
                ins_out = {{5'd0}, {ins[5]}, {ins[12]},{2'd1,{ins[4:2]}},{2'd1,{ins[9:7]}},3'd6,{ins[11:10]},{ins[6]},2'd0,{OP_STORE}};   //C.SW   -> sw rs2', imm(rs1')
            end 
            //3'b010:  //:->;
            3'b001:
            begin
                illegal_ins = 1'b1;
            end
            3'b011:
            begin
                illegal_ins = 1'b1;
            end
            3'b101:
            begin
                illegal_ins = 1'b1;
            end
            3'b111: 
            begin
                illegal_ins = 1'b1;
            end
            3'b100: 
            begin
                illegal_ins = 1'b1;
            end
            default: illegal_ins = 1'b0;
        endcase

    end

    // For first Case Opcode = 1
    else if (ins[1:0]==2'b01)
    begin
        illegal_ins = 1'b0;
        compressed_ins = 1'b1;  //Default case
        case (ins[15:13])
            3'b000: 
            begin
                ins_out = {{7{ins[12]}},{ins[6:2]},{ins[11:7]},3'd0,{ins[11:7]},{OP_ARITHI}};   //C.ADDI -> addi rd,rd, imm
            end
            3'b001:
            begin
                ins_out = {{ins[12]}, {ins[8]}, {ins[10:9]}, ins[6],ins[7],{ins[2]},{ins[11]},{ins[5:3]}, {9{ins[12]}}, {4'd0, ~{ins[15]}}, {OP_JAL}};  // C.JAL => jal x1, imm
            end
            3'b101:
            begin
              //$display("\n C.J Display \n");
                ins_out = {{ins[12]}, {ins[8]}, {ins[10:9]}, ins[6],ins[7],{ins[2]},{ins[11]},{ins[5:3]}, {9{ins[12]}}, {4'd0, ~{ins[15]}}, {OP_JAL}};  // C.J => jal x0, imm    
            end
            3'b010:
            begin
                ins_out = {{7{ins[12]}},{ins[6:2]},5'd0,3'd0,{ins[11:7]},{OP_ARITHI}};   //C.LI -> addi rd,rd, imm
            end
            3'b011:
            begin
                ins_out = {{15{ins[12]}}, {ins[6:2]}, {ins[11:7]},{OP_LUI}}; // C.LUI => lui,rd,imm 
                if (ins[11:7]==5'd2) 
                begin
                    ins_out = {{3{ins[12]}}, {ins[4:3]}, {ins[5]}, {ins[2]}, {ins[6]}, 4'd0, 5'd2, 3'b000, 5'd2,{OP_ARITHI}};  //C.AADI16SP => addi x2,x2, imm
                end
                if ({ins[12],ins[6:2]}==6'b000000) 
                begin
                    illegal_ins = 1'b1;    
                end
            end
            3'b100:
            begin
                case (ins[11:10])
                    2'b00: 
                    begin
                        ins_out = {6'b0, {ins[12]}, {ins[6:2]}, {2'd1, ins[9:7]}, 3'b101,{2'b01,ins[9:7]},{OP_ARITHI}}; // C.SRLI => srli rd,rd, imm
                        if (ins[12]==1'b1) 
                        begin
                            illegal_ins = 1'b1;    
                        end  
                    end 
                    2'b01: 
                    begin
                        ins_out = {6'b0, {ins[12]}, {ins[6:2]}, {2'd1, ins[9:7]}, 3'b101,{2'b01,ins[9:7]},{OP_ARITHI}}; //C.SRAI => srai rd,rd,imm
                        if (ins[12]==1'b1) 
                        begin
                            illegal_ins = 1'b1;    
                        end  
                    end 
                    2'b10: 
                    begin
                        ins_out = {{7{ins[12]}},{ins[6:2]}, {2'b01,ins[9:7]},3'b111,{2'd1,{ins[9:7]}},{OP_ARITHI}}; //  C.ANDI => andi rd, rd, imm 
                    end
                    2'b11:
                    begin
                        case ({ins[12], ins[6:5]})
                            3'b000:
                            begin
                                ins_out = {2'b01, 5'd0, {2'b01, ins[4:2]}, {2'b01,ins[9:7]}, 3'b000, {2'b01,ins[9:7]}, {OP_ARITHR}};  //C.SUB => sub rd, rd,rs2
                            end 
                            3'b001: 
                            begin
                                ins_out = {7'b0, {2'b01, ins[4:2]}, {2'b01, ins[9:7]}, 3'b100,{2'b01, ins[9:7]}, {OP_ARITHR}}; //C.XOR => xor, rd,rd,rs2
                            end
                            3'b010:
                            begin
                                ins_out = {7'b0, {2'b01, ins[4:2]}, {2'b01, ins[9:7]}, 3'b110,{2'b01, ins[9:7]}, {OP_ARITHR}};  //  C.OR => or rd, rd, rs2
                            end
                            3'b011:
                            begin
                                ins_out = {7'b0, {2'b01, ins[4:2]}, {2'b01, ins[9:7]}, 3'b111,{2'b01, ins[9:7]}, {OP_ARITHR}};  // C.AND => and rd, rd, rs2
                            end
                            3'b100:
                            begin
                                illegal_ins = 1'b1;
                            end
                            3'b101:
                            begin
                                illegal_ins = 1'b1;
                            end
                            3'b110:
                            begin
                                illegal_ins = 1'b1;
                            end
                            3'b111:
                            begin
                                illegal_ins = 1'b1;
                            end
                            default: illegal_ins = 1'b1;    
                        endcase
                    end
                    
                    default: illegal_ins = 1'b1;
                endcase
            end
            3'b110: 
            begin
                //C.BEQZ => beq rs1', x0, imm
                //ins_out = {{4 {ins[12]}}, {ins[6:5]}, {ins[2]}, 5'b0, {2'b01,ins[9:7]}, {2'b00, ins[13]}, {ins[11:10]}, {ins[4:3]},1'd0, {OP_BRANCH}};
                ins_out = {{4 {ins[12]}}, {ins[6:5]}, {ins[2]}, 5'b0, {2'b01,ins[9:7]}, {2'b00, ins[13]}, {ins[11:10]}, {ins[4:3]},{ins[12]}, {OP_BRANCH}};
            end
            3'b111: 
            begin
                // C.BNEZ => bne rs1', x0, imm
                //ins_out = {{4 {ins[12]}}, {ins[6:5]}, {ins[2]}, 5'b0, {2'b01,ins[9:7]}, {2'b00, ins[13]}, {ins[11:10]}, {ins[4:3]},1'd0, {OP_BRANCH}};
                ins_out = {{4 {ins[12]}}, {ins[6:5]}, {ins[2]}, 5'b0, {2'b01,ins[9:7]}, {2'b00, ins[13]}, {ins[11:10]}, {ins[4:3]},{ins[12]}, {OP_BRANCH}};
            end
            default: illegal_ins = 1'b1;   
                        
        endcase
    end


    // For first Case Opcode = 2
    else if (ins[1:0]==2'b10)
    begin
        compressed_ins = 1'b1;
        illegal_ins = 1'b0;
    case ({ins[15:13]})
        3'b000:
        begin
          ins_out = {6'b0,{ins[12]} ,{ins[6:2]}, {ins[11:7]}, 3'b001, {ins[11:7]}, {OP_ARITHI}};// C.SLLI -> slli rd, rd, immins_out = {6'b0,{in[12]} {ins[6:2]}, {ins[11:7]}, 3'b001, {ins[11:7]}, {OP_ARITHI}};// C.SLLI -> slli rd, rd, imm
            if (ins[12] == 1'b1) 
            begin
                illegal_ins = 1'b1;   // Reserved for Custom Extensions
                $display("\n Reserved For Custom Extension \n");
            end 
        end
        3'b010:
        begin
            ins_out = {4'b0, {ins[3:2]}, {ins[12]}, {ins[6:4]}, 2'b00, {5'd2},3'b010, {ins[11:7]}, {OP_LOAD}}; // C.LWSP => lw rd, imm(x2)
            if (ins[11:7] == 5'b0)  
            begin
                illegal_ins = 1'b1;
                //$display("\n Illegal Instruction \n");
            end
        end
        3'b100: 
        begin
            if (ins[12] == 1'b0) 
            begin
                if (ins[6:2] != 5'b0) 
                begin        
                    //ins_out = {12'd0, {ins[6:2]}, 3'b0, {ins[11:7]}, {OP_ARITHI}}; // C.MV => addi rd, rs2, 0
                    ins_out = {7'b0, {ins[6:2]}, 5'b0, 3'b0, {ins[11:7]}, {OP_ARITHR}}; // C.MV => add rd/rs1, x0, rs2
                    //instr_o = {7'b0, instr_i[6:2], 5'b0, 3'b0, instr_i[11:7], {OP_ARITHR}};
                end 
                else 
                begin
                    ins_out = {12'b0, {ins[11:7]}, 3'b0, 5'b0, {OP_JALR}};   // C.JR => jalr x0, rd/rs1, 0
                    if (ins[11:7] == 5'b0) 
                    begin
                        illegal_ins = 1'b1;
                    end     
                end
            end 
            else 
            begin
                if (ins[6:2] != 5'b0) 
                begin
                        ins_out = {7'b0, ins[6:2], ins[11:7], 3'b0, ins[11:7], {OP_ARITHR}};  // C.ADD => add rd, rd, rs2
                end 
                else 
                begin
                    if (ins[11:7] == 5'b0) 
                    begin
                        ins_out = {32'h00_10_00_73}; // C.EBREAK => ebreak
                    end 
                    else 
                    begin
                        ins_out = {12'b0, ins[11:7], 3'b000, 5'b00001, {OP_JALR}}; // C.JALR => jalr x1, rs1, 0
                    end
                end
            end
        end
        3'b110:
        begin
            ins_out = {4'b0, {ins[8:7]}, {ins[12]}, {ins[6:2]}, 5'h02, 3'b010, {ins[11:9]}, 2'b00, {OP_STORE}};  // C.SWSP => sw rs2, imm(x2)
        end
        3'b001:
        begin
            illegal_ins = 1'b1;
        end
        3'b011:
        begin
            illegal_ins = 1'b1;
        end
        3'b101:
        begin
            illegal_ins = 1'b1;
        end
        3'b111: 
        begin
            illegal_ins = 1'b1;
        end
        default: illegal_ins = 1'b1;
    endcase 
    end

end

endmodule

////////////////////// TEST BENCH ///////////////////////////////////////

/*

 module tb;
   
   reg [31:0] ins;
   reg [31:0] ins_out;
   reg compressed_ins,illegal_ins;
   
   comp_decoder DUT (ins,ins_out,compressed_ins,illegal_ins );


initial begin
  

  ins = 32'hA0_61_83_1A;
    #100;
  $display("\n Compressed Instructions: %h \n", ins_out);//addi
  $display("Illegal Ins: %d \n",  illegal_ins);
$display("Compressed Ins: %d \n",  compressed_ins);

  #100;
  //#100
  //ins = 32'h40_54_D4_93;
  //$monitor("\n Compressed Instructions: %d \n", ins_out);  //srai
end
initial
  begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
  end
   
   
 endmodule



*/

////////////////////// TEST BENCH ///////////////////////////////////////

/*

 module tb;
   
   reg [31:0] ins;
   reg [31:0] ins_out;
   reg compressed_ins,illegal_ins;
   
   comp_decoder DUT (ins,ins_out,compressed_ins,illegal_ins );


initial begin
  

  ins = 32'h83_1A_A0_61;
    #100;
  $display("\n Compressed Instructions: %h \n", ins_out);//addi
  $display("Illegal Ins: %d \n",  illegal_ins);
$display("Compressed Ins: %d \n",  compressed_ins);

  #100;
  //#100
  //ins = 32'h40_54_D4_93;
  //$monitor("\n Compressed Instructions: %d \n", ins_out);  //srai
end
initial
  begin
    $dumpfile("dump.vcd"); 
    $dumpvars;
  end
   
   
 endmodule



*/
