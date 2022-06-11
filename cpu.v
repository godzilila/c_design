module cpu_design (reset, clock, write_read, M_address, M_data_in, M_data_out,overflow,status);
input reset,clock;
input[7:0] M_data_in;
output reg write_read,overflow;
output reg [7:0] M_data_out;
output reg[11:0] M_address;
reg[15:0] IR;
reg[7:0] MDR;
reg[11:0] MAR,PC;
reg [7:0]R0;
reg [7:0]R1;
reg [7:0]R2;
reg [7:0]R3;
reg [7:0]A;
reg [8:0]F;
//补充完整相关中间变量
output reg[2:0] status;
parameter idle=4'b0000, load=4'b0001, move=4'b0010, add=4'b0011, sub=4'b0100, AND=4'b0101;
parameter OR=4'b0110, XOR=4'b0111, shrp=4'b1000, shlp=4'b1001, swap=4'b1010, jmp=4'b1011;
parameter jz=4'b1100, read=4'b1101, write=4'b1110, stop=4'b1111;//补充完整所有指令操作码
 
always@(reset or status) // process the read and write operation for main memory. 
begin
	if((reset==1)&&(status==3)&&(IR[15:12]==write)) 
		write_read=1'b1;//write opeartion
	else
		write_read=1'b0;//read operation
	M_address=MAR;
	M_data_out=MDR;
	overflow=1'b0;
	if(IR[15:12]==add || IR[15:12]==sub)
	begin
		if(F[8]==F[7])
			overflow=0;
		else
			overflow=1;
	end
		//补充overflow标志位的处理，overflow仅在进行加、减运算时才可能为1.
 end
 
always @(negedge clock or negedge reset)// status_change process, status machine 
begin
	if(reset==1'b0)
	begin
		MAR<=12'b000000000000;
		status<=3'b000;// valid reset signal is 0 
	end
	else if(clock==1'b0)// descend edge of clock 
		case (status)
			3'b000: begin
						status<=3'b001;
						MAR<=PC;
						case(IR[9:8])
							2'b00: A<=R0;
							2'b01: A<=R1;
							2'b10: A<=R2;
							2'b11: A<=R3;
						endcase
					end
			3'b001: begin
						if(IR[15:12]==stop)status<=1;
						else if (IR[15:12]==swap|| (IR[15:12]==jmp)|| IR[15:12]==jz || IR[15:12]==read || IR[15:12]==write)// /补充完整
							status<=3'b010;
						else
							status<=3'b000;
					end
			3'b010:begin 
						if(IR[15:12]==swap)
							status <= 3'b000;
						else if ((IR[15:12]==jmp)||(IR[15:12]==read)||(IR[15:12]==write))
						begin
							MAR <= IR[11:0];
							status <= 3'b011;
						end
						else if((IR[15:12]==jz)&& (R0[7:0] == 8'b0000_0000))//条件转移
						begin
							MAR <= IR[11:0];
							status <= 3'b011;
						end
						else
						begin
							MAR <= PC;
							status <= 3'b011;
						end
					end
			3'b011:begin
						if((IR[15:12]==write) || (IR[15:12]==read))
						begin
							MAR<=PC;
							status<=3'b100;
						end
						else
							status<=3'b000;
					 end
			3'b100:begin
						status<=3'b000;
					 end
			default:status<=3'b000;
		endcase
end
always@(posedge clock or negedge reset)//process each status of each instruction 
begin
	if(reset==1'b0) 
	begin
		IR<=16'h0000;
		PC<=12'b000000000000;
		MDR<=8'b00000000;
		R0<=8'b00000000;
		R1<=8'b00000000;
		R2<=8'b00000000;
		R3<=8'b00000000;//reset operation，补充完整
	end
	else if (clock==1'b1)
	begin
		case (status)
			3'b000: begin
						IR[15:8]<=M_data_in;
						IR[7:0]<=8'b00000000; 
						PC<=PC+12'b000000000001; 
					end // status 0, fetch instruction
			3'b001: begin //status 1
						case(IR[15:12])//IR[15:12] is op segment
							load: R0<={4'b0000,IR[11:8]}; 
							swap:begin
									case(IR[11:10])
										2'b00:begin
													case(IR[9:8])
														2'b00:R0<=R0;
														2'b01:R1<=R0;
														2'b10:R2<=R0;
														2'b11:R3<=R0;
													endcase
												end
										2'b01:begin
													case(IR[9:8])
														2'b00:R0<=R1;
														2'b01:R1<=R1;
														2'b10:R2<=R1;
														2'b11:R3<=R1;
													endcase
												end
										2'b10:begin
													case(IR[9:8])
														2'b00:R0<=R2;
														2'b01:R1<=R2;
														2'b10:R2<=R2;
														2'b11:R3<=R2;
													endcase
												end
										2'b11:begin
													case(IR[9:8])
														2'b00:R0<=R3;
														2'b01:R1<=R3;
														2'b10:R2<=R3;
														2'b11:R3<=R3;
													endcase
												end
									endcase
								  end
							shlp:begin 
									case(IR[11:10]) 
										2'b00:R0<=R0<<1;
										2'b01:R1<=R1<<1;
										2'b10:R2<=R2<<1;
										2'b11:R3<=R3<<1;
									endcase
								  end
							shrp:begin
									case(IR[11:10]) 
										2'b00:R0<=R0>>1;
										2'b01:R1<=R1>>1;
										2'b10:R2<=R2>>1;
										2'b11:R3<=R3>>1;
									endcase
								  end
							add:begin
									case(IR[11:10])
										2'b00:begin
													F=A+R0;
													R0<=F[7:0];
												end
										2'b01:begin
													F=A+R1;
													R1<=F[7:0];
												end
										2'b10:begin
													F=A+R2;
													R2<=F[7:0];
												end
										2'b11:begin
													F=A+R3;
													R3<=F[7:0];
												end
									endcase
								 end
							sub:begin
									case(IR[11:10])
										2'b00:begin
													F=R0-A;
													R0<=F[7:0];
												end
										2'b01:begin
													F=R1-A;
													R1<=F[7:0];
												end
										2'b10:begin
													F=R2-A;
													R2<=F[7:0];
												end
										2'b11:begin
													F=R3-A;
													R3<=F[7:0];
												end
									endcase
								 end
							move:begin
										case(IR[11:10])
											2'b00:R0<=A;
											2'b01:R1<=A;
											2'b10:R2<=A;
											2'b11:R3<=A;
										endcase
								  end
							AND:begin
									case(IR[11:10])
										2'b00:R0=R0 & A;
										2'b01:R1=R1 & A;
										2'b10:R2=R2 & A;
										2'b11:R3=R3 & A;
									endcase
								 end
							OR:begin
									case(IR[11:10])
										2'b00:R0=R0 | A;
										2'b01:R1=R1 | A;
										2'b10:R2=R2 | A;
										2'b11:R3=R3 | A;
									endcase
								end
							XOR:begin
									case(IR[11:10])
										2'b00:R0=R0 ^ A;
										2'b01:R1=R1 ^ A;
										2'b10:R2=R2 ^ A;
										2'b11:R3=R3 ^ A;
									endcase
								 end
							default:;
						endcase
					end//补充完整每条指令的每个status的操作
			3'b010:begin
						case(IR[15:12])
							swap:begin
									case(IR[11:10])
										2'b00:R0<=A;
										2'b01:R1<=A;
										2'b10:R2<=A;
										2'b11:R3<=A;
									endcase
								  end
							read:begin
									IR[7:0]<=M_data_in;
									PC<=PC+12'b000000000001;
								  end
							write:begin
										IR[7:0]<=M_data_in;
										PC<=PC+12'b000000000001;
										MDR<=R0;
									end
							jmp:begin
									IR[7:0]<=M_data_in;
									PC<=PC+12'b000000000001;
								 end
							jz:begin
									IR[7:0]<=M_data_in;
									PC<=PC+12'b000000000001;
								end
						endcase
					 end
			3'b011:begin
						case(IR[15:12])
							jmp:begin
										PC<=IR[11:0];
									end
							jz:begin
									if(R0==8'b00000000)
										PC<=IR[11:0];
								end
							default:;
						endcase
					 end
			3'b100:begin
						case(IR[15:12])
							read:begin
									R0<=M_data_in;
								  end
						endcase
					 end
			default:;//补充完整每条指令的每个status的操作
		endcase
	end
end 
endmodule
