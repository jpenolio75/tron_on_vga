module vga(input  logic clk, reset, 
           output logic vgaclk,          // 25.175 MHz VGA clock 
           output logic hsync, vsync, 
           output logic sync_b, blank_b, // to monitor & DAC 
		   input logic serialin1,serialin2, // serial input 8 bits total
           output logic [7:0] r, g, b,
		   output controllerpulse1,controllerpulse2, 
		   output latchpulse1,latchpulse2) ;
	
	//Intermediate signals
	logic up,down,left,right;
	logic up2,down2,left2,right2;
	logic [9:0] x, y; 

 
  // Use a clock divider to create the 25 MHz VGA pixel clock 
  // 25 MHz clk period = 40 ns 
  // Screen is 800 clocks wide by 525 tall, but only 640 x 480 used for display 
  // HSync = 1/(40 ns * 800) = 31.25 kHz 
  // Vsync = 31.25 KHz / 525 = 59.52 Hz (~60 Hz refresh rate) 
  
  // divide 50 MHz input clock by 2 to get 25 MHz clock
  always_ff @(posedge clk, posedge reset)
    if (reset)
	   vgaclk = 1'b0;
    else
	   vgaclk = ~vgaclk;
	
	//Controller inputs to direction FSM for p1 and p2
	controlfsm3 p1(clk, reset, serialin1,latchpulse1, controllerpulse1, down, up, left, right); // switched up and down
	controlfsm3 p2(clk, reset, serialin2,latchpulse2, controllerpulse2, down2, up2, left2, right2);
	vgaController vgaCont(vgaclk, reset, hsync, vsync, sync_b, blank_b, x, y); 
  
	
	videoGen videoGen(x, y, r, g, b,vgaclk,up,down,left,right,reset,clk,up2,down2,left2,right2); // added vgaclk here 

endmodule 


module vgaController #(parameter HBP     = 10'd48,   // horizontal back porch
                                 HACTIVE = 10'd640,  // number of pixels per line
                                 HFP     = 10'd16,   // horizontal front porch
                                 HSYN    = 10'd96,   // horizontal sync pulse = 96 to move electron gun back to left
                                 HMAX    = HBP + HACTIVE + HFP + HSYN, //48+640+16+96=800: number of horizontal pixels (i.e., clock cycles)
                                 VBP     = 10'd32,   // vertical back porch
                                 VACTIVE = 10'd480,  // number of lines
                                 VFP     = 10'd11,   // vertical front porch
                                 VSYN    = 10'd2,    // vertical sync pulse = 2 to move electron gun back to top
                                 VMAX    = VBP + VACTIVE + VFP  + VSYN) //32+480+11+2=525: number of vertical pixels (i.e., clock cycles)                      

     (input  logic vgaclk, reset,
      output logic hsync, vsync, sync_b, blank_b, 
      output logic [9:0] hcnt, vcnt); 

      // counters for horizontal and vertical positions 
      always @(posedge vgaclk, posedge reset) begin 
        if (reset) begin
          hcnt <= 0;
          vcnt <= 0;
        end
        else  begin
          hcnt++; 
      	   if (hcnt == HMAX) begin 
            hcnt <= 0; 
  	        vcnt++; 
  	        if (vcnt == VMAX) 
  	          vcnt <= 0; 
          end 
        end
      end 
	  
      // compute sync signals (active low)
      assign hsync  = ~( (hcnt >= (HBP + HACTIVE + HFP)) & (hcnt < HMAX) ); 
      assign vsync  = ~( (vcnt >= (VBP + VACTIVE + VFP)) & (vcnt < VMAX) ); 

      // assign sync_b = hsync & vsync; 
      assign sync_b = 1'b0;  // this should be 0 for newer monitors

      // force outputs to black when not writing pixels
      assign blank_b = (hcnt > HBP & hcnt < (HBP + HACTIVE)) & (vcnt > VBP & vcnt < (VBP + VACTIVE)); 
endmodule 

module videoGen(input logic [9:0] x, y, output logic [7:0] r, g, b, input logic clk, up,down,left,right,reset,fastclk,up2,down2,left2,right2); // added  clk for movement here
    logic [9:0] pixelx2,pixely2,pixelx , pixely,trailx,traily,trailx2,traily2,trailx3,traily3,trailx4,traily4,trailx5,traily5,trailx6,traily6,trailx7,traily7,trailx8,traily8,trailx9,traily9,trailx10,traily10,trailx11,traily11,trailx12,traily12,trailx13,traily13,trailx14,traily14,trailx15,traily15,trailx16,traily16,trailx17,traily17,trailx18,traily18, trailx19,traily19, trailx20,traily20, trailx21,traily21, trailx22,traily22, trailx23,traily23, trailx24,traily24, trailx25,traily25, trailx26,traily26, trailx27,traily27, trailx28,traily28, trailx29,traily29, trailx30,traily30, trailx31,traily31, trailx32,traily32, trailx33,traily33, trailx34,traily34, trailx35,traily35, trailx36,traily36, trailx37,traily37, trailx38,traily38, trailx39,traily39, trailx40,traily40, trailx41,traily41, trailx42,traily42, trailx43,traily43, trailx44,traily44, trailx45,traily45, trailx46,traily46, trailx47,traily47, trailx48,traily48, trailx49,traily49, trailx50,traily50;//,colx,coly;
	logic [9:0] p2trailx,p2traily, p2trailx2,p2traily2, p2trailx3,p2traily3, p2trailx4,p2traily4, p2trailx5,p2traily5, p2trailx6,p2traily6, p2trailx7,p2traily7, p2trailx8,p2traily8, p2trailx9,p2traily9, p2trailx10,p2traily10, p2trailx11,p2traily11, p2trailx12,p2traily12, p2trailx13,p2traily13, p2trailx14,p2traily14, p2trailx15,p2traily15, p2trailx16,p2traily16, p2trailx17,p2traily17, p2trailx18,p2traily18, p2trailx19,p2traily19, p2trailx20,p2traily20, p2trailx21,p2traily21, p2trailx22,p2traily22, p2trailx23,p2traily23, p2trailx24,p2traily24, p2trailx25,p2traily25, p2trailx26,p2traily26, p2trailx27,p2traily27, p2trailx28,p2traily28, p2trailx29,p2traily29, p2trailx30,p2traily30, p2trailx31,p2traily31, p2trailx32,p2traily32, p2trailx33,p2traily33, p2trailx34,p2traily34, p2trailx35,p2traily35, p2trailx36,p2traily36, p2trailx37,p2traily37, p2trailx38,p2traily38, p2trailx39,p2traily39, p2trailx40,p2traily40, p2trailx41,p2traily41, p2trailx42,p2traily42, p2trailx43,p2traily43, p2trailx44,p2traily44, p2trailx45,p2traily45, p2trailx46,p2traily46, p2trailx47,p2traily47, p2trailx48,p2traily48, p2trailx49,p2traily49, p2trailx50,p2traily50;
	logic [9:0] qx,qy,trailx51,traily51,trailx52,traily52,trailx53,traily53,trailx54,traily54;
	logic [9:0] coly [9:0];
	logic [6:0] countadr1 , counteradr2 , addr1,addr2,addr1a,addr2a;
	logic [19:0] trails [127:0] ;
	logic [19:0] trails2 [127:0] ;
	logic [9:0] addressx, addressy;
	logic wren;
	logic slowclk3;
    logic  slwclk,minus,vert,ho,onoffx,onoffy, hit,hity,slwclk2,gameover,vert2,ho2,onoffx2,onoffy2,horizontal, verticle,horizontal2, verticle2;
	
	//Modified clock speeds for 1hz, 10hz, 100hz
	slowclk100hz slowclk1( clk, reset, slwclk);
	slowclk1hz slowclk2( clk, reset, slwclk3);
	slowclk10hz slowclkram( clk, reset, slwclk2);
	
	//Player 1's movement counter for x and y locations
	counter #(11) counterx(slwclk,reset,onoffx,horizontal, pixelx);//,colx);
	counter #(10,40,510,35) countery(slwclk,reset,onoffy,verticle, pixely);//,coly); 
	
	//Player 2's movement counter for x and y locations
	counter #(11) counter2x(slwclk,reset,onoffx2,horizontal2, pixelx2);//,colx);
	counter #(10,400,510,35) counter2y(slwclk,reset,onoffy2,verticle2, pixely2);//,coly);
	
	//Directions of both players
	dirfsm dir(clk, reset, up,down,left,right,onoffx, onoffy, horizontal, verticle);
	dirfsm dir2(clk, reset, up2,down2,left2,right2,onoffx2, onoffy2, horizontal2, verticle2);
	
	
	//All the intermediate logic for the trail of both players
	logic v1,h1,ox1,oy1,p2h1, p2v1,p2ox1,p2oy1,
	v2,h2,ox2,oy2,p2h2, p2v2,p2ox2,p2oy2,
	v3,h3,ox3,oy3,p2h3, p2v3,p2ox3,p2oy3,
	v4,h4,ox4,oy4,p2h4, p2v4,p2ox4,p2oy4,
	v5,h5,ox5,oy5,p2h5, p2v5,p2ox5,p2oy5,
	v6,h6,ox6,oy6,p2h6, p2v6,p2ox6,p2oy6,
	v7,h7,ox7,oy7,p2h7, p2v7,p2ox7,p2oy7,
	v8,h8,ox8,oy8,p2h8, p2v8,p2ox8,p2oy8,
	v9,h9,ox9,oy9,p2h9, p2v9,p2ox9,p2oy9,
	v10,h10,ox10,oy10,p2h10, p2v10,p2ox10,p2oy10,
	v11,h11,ox11,oy11,p2h11, p2v11,p2ox11,p2oy11,
	v12,h12,ox12,oy12,p2h12, p2v12,p2ox12,p2oy12,
	v13,h13,ox13,oy13,p2h13, p2v13,p2ox13,p2oy13,
	v14,h14,ox14,oy14,p2h14, p2v14,p2ox14,p2oy14,
	v15,h15,ox15,oy15,p2h15, p2v15,p2ox15,p2oy15,
	v16,h16,ox16,oy16,p2h16, p2v16,p2ox16,p2oy16,
	v17,h17,ox17,oy17,p2h17, p2v17,p2ox17,p2oy17,
	v18,h18,ox18,oy18,p2h18, p2v18,p2ox18,p2oy18,
	v19,h19,ox19,oy19,p2h19, p2v19,p2ox19,p2oy19,
	v20,h20,ox20,oy20,p2h20, p2v20,p2ox20,p2oy20,
	v21,h21,ox21,oy21,p2h21, p2v21,p2ox21,p2oy21,
	v22,h22,ox22,oy22,p2h22, p2v22,p2ox22,p2oy22,
	v23,h23,ox23,oy23,p2h23, p2v23,p2ox23,p2oy23,
	v24,h24,ox24,oy24,p2h24, p2v24,p2ox24,p2oy24,
	v25,h25,ox25,oy25,p2h25, p2v25,p2ox25,p2oy25,
	v26,h26,ox26,oy26,p2h26, p2v26,p2ox26,p2oy26,
	v27,h27,ox27,oy27,p2h27, p2v27,p2ox27,p2oy27,
	v28,h28,ox28,oy28,p2h28, p2v28,p2ox28,p2oy28,
	v29,h29,ox29,oy29,p2h29, p2v29,p2ox29,p2oy29,
	v30,h30,ox30,oy30,p2h30, p2v30,p2ox30,p2oy30,
	v31,h31,ox31,oy31,p2h31, p2v31,p2ox31,p2oy31,
	v32,h32,ox32,oy32,p2h32, p2v32,p2ox32,p2oy32,
	v33,h33,ox33,oy33,p2h33, p2v33,p2ox33,p2oy33,
	v34,h34,ox34,oy34,p2h34, p2v34,p2ox34,p2oy34,
	v35,h35,ox35,oy35,p2h35, p2v35,p2ox35,p2oy35,
	v36,h36,ox36,oy36,p2h36, p2v36,p2ox36,p2oy36,
	v37,h37,ox37,oy37,p2h37, p2v37,p2ox37,p2oy37,
	v38,h38,ox38,oy38,p2h38, p2v38,p2ox38,p2oy38,
	v39,h39,ox39,oy39,p2h39, p2v39,p2ox39,p2oy39,
	v40,h40,ox40,oy40,p2h40, p2v40,p2ox40,p2oy40,
	v41,h41,ox41,oy41,p2h41, p2v41,p2ox41,p2oy41,
	v42,h42,ox42,oy42,p2h42, p2v42,p2ox42,p2oy42,
	v43,h43,ox43,oy43,p2h43, p2v43,p2ox43,p2oy43,
	v44,h44,ox44,oy44,p2h44, p2v44,p2ox44,p2oy44,
	v45,h45,ox45,oy45,p2h45, p2v45,p2ox45,p2oy45,
	v46,h46,ox46,oy46,p2h46, p2v46,p2ox46,p2oy46,
	v47,h47,ox47,oy47,p2h47, p2v47,p2ox47,p2oy47,
	v48,h48,ox48,oy48,p2h48, p2v48,p2ox48,p2oy48,
	v49,h49,ox49,oy49,p2h49, p2v49,p2ox49,p2oy49,
	v50,h50,ox50,oy50,p2h50, p2v50,p2ox50,p2oy50;
	
	//player 1's trail definitions
	trail t1(slwclk2, reset, horizontal, verticle,onoffx,onoffy,pixelx, pixely,trailx,traily,h1,v1,ox1,oy1);
	trail t2(slwclk2, reset, h1, v1,ox1,oy1,trailx, traily,trailx2,traily2,h2,v2,ox2,oy2);
	trail t3(slwclk2, reset, h2, v2,ox2,oy2,trailx2,traily2,trailx3,traily3,h3,v3,ox3,oy3);
	trail t4(slwclk2, reset, h3, v3,ox3,oy3,trailx3,traily3,trailx4,traily4,h4,v4,ox4,oy4);
	trail t5(slwclk2, reset, h4, v4,ox4,oy4,trailx4,traily4,trailx5,traily5,h5,v5,ox5,oy5);
	trail t6(slwclk2, reset, h5, v5,ox5,oy5,trailx5,traily5,trailx6,traily6,h6,v6,ox6,oy6);
	trail t7(slwclk2, reset, h6, v6,ox6,oy6,trailx6,traily6,trailx7,traily7,h7,v7,ox7,oy7);
	trail t8(slwclk2, reset, h7, v7,ox7,oy7,trailx7,traily7,trailx8,traily8,h8,v8,ox8,oy8);
	trail t9(slwclk2, reset, h8, v8,ox8,oy8,trailx8,traily8,trailx9,traily9,h9,v9,ox9,oy9);
	trail t10(slwclk2, reset, h9, v9,ox9,oy9,trailx9,traily9,trailx10,traily10,h10,v10,ox10,oy10);
	trail t11(slwclk2, reset, h10, v10,ox10,oy10,trailx10,traily10,trailx11,traily11,h11,v11,ox11,oy11);
	trail t12(slwclk2, reset, h11, v11,ox11,oy11,trailx11,traily11,trailx12,traily12,h12,v12,ox12,oy12);
	trail t13(slwclk2, reset, h12, v12,ox12,oy12,trailx12,traily12,trailx13,traily13,h13,v13,ox13,oy13);
	trail t14(slwclk2, reset, h13, v13,ox13,oy13,trailx13,traily13,trailx14,traily14,h14,v14,ox14,oy14);
	trail t15(slwclk2, reset, h14, v14,ox14,oy14,trailx14,traily14,trailx15,traily15,h15,v15,ox15,oy15);
	trail t16(slwclk2, reset, h15, v15,ox15,oy15,trailx15,traily15,trailx16,traily16,h16,v16,ox16,oy16);
	trail t17(slwclk2, reset, h16, v16,ox16,oy16,trailx16,traily16,trailx17,traily17,h17,v17,ox17,oy17);
	trail t18(slwclk2, reset, h17, v17,ox17,oy17,trailx17,traily17,trailx18,traily18,h18,v18,ox18,oy18);
	trail t19(slwclk2, reset, h18, v18,ox18,oy18,trailx18,traily18,trailx19,traily19,h19,v19,ox19,oy19);
	trail t20(slwclk2, reset, h19, v19,ox19,oy19,trailx19,traily19,trailx20,traily20,h20,v20,ox20,oy20);
	trail t21(slwclk2, reset, h20, v20,ox20,oy20,trailx20,traily20,trailx21,traily21,h21,v21,ox21,oy21);
	trail t22(slwclk2, reset, h21, v21,ox21,oy21,trailx21,traily21,trailx22,traily22,h22,v22,ox22,oy22);
	trail t23(slwclk2, reset, h22, v22,ox22,oy22,trailx22,traily22,trailx23,traily23,h23,v23,ox23,oy23);
	trail t24(slwclk2, reset, h23, v23,ox23,oy23,trailx23,traily23,trailx24,traily24,h24,v24,ox24,oy24);
	trail t25(slwclk2, reset, h24, v24,ox24,oy24,trailx24,traily24,trailx25,traily25,h25,v25,ox25,oy25);
	trail t26(slwclk2, reset, h25, v25,ox25,oy25,trailx25,traily25,trailx26,traily26,h26,v26,ox26,oy26);
	trail t27(slwclk2, reset, h26, v26,ox26,oy26,trailx26,traily26,trailx27,traily27,h27,v27,ox27,oy27);
	trail t28(slwclk2, reset, h27, v27,ox27,oy27,trailx27,traily27,trailx28,traily28,h28,v28,ox28,oy28);
	trail t29(slwclk2, reset, h28, v28,ox28,oy28,trailx28,traily28,trailx29,traily29,h29,v29,ox29,oy29);
	trail t30(slwclk2, reset, h29, v29,ox29,oy29,trailx29,traily29,trailx30,traily30,h30,v30,ox30,oy30);
	trail t31(slwclk2, reset, h30, v30,ox30,oy30,trailx30,traily30,trailx31,traily31,h31,v31,ox31,oy31);
	trail t32(slwclk2, reset, h31, v31,ox31,oy31,trailx31,traily31,trailx32,traily32,h32,v32,ox32,oy32);
	trail t33(slwclk2, reset, h32, v32,ox32,oy32,trailx32,traily32,trailx33,traily33,h33,v33,ox33,oy33);
	trail t34(slwclk2, reset, h33, v33,ox33,oy33,trailx33,traily33,trailx34,traily34,h34,v34,ox34,oy34);
	trail t35(slwclk2, reset, h34, v34,ox34,oy34,trailx34,traily34,trailx35,traily35,h35,v35,ox35,oy35);
	trail t36(slwclk2, reset, h35, v35,ox35,oy35,trailx35,traily35,trailx36,traily36,h36,v36,ox36,oy36);
	trail t37(slwclk2, reset, h36, v36,ox36,oy36,trailx36,traily36,trailx37,traily37,h37,v37,ox37,oy37);
	trail t38(slwclk2, reset, h37, v37,ox37,oy37,trailx37,traily37,trailx38,traily38,h38,v38,ox38,oy38);
	trail t39(slwclk2, reset, h38, v38,ox38,oy38,trailx38,traily38,trailx39,traily39,h39,v39,ox39,oy39);
	trail t40(slwclk2, reset, h39, v39,ox39,oy39,trailx39,traily39,trailx40,traily40,h40,v40,ox40,oy40);
	trail t41(slwclk2, reset, h40, v40,ox40,oy40,trailx40,traily40,trailx41,traily41,h41,v41,ox41,oy41);
	trail t42(slwclk2, reset, h41, v41,ox41,oy41,trailx41,traily41,trailx42,traily42,h42,v42,ox42,oy42);
	trail t43(slwclk2, reset, h42, v42,ox42,oy42,trailx42,traily42,trailx43,traily43,h43,v43,ox43,oy43);
	trail t44(slwclk2, reset, h43, v43,ox43,oy43,trailx43,traily43,trailx44,traily44,h44,v44,ox44,oy44);
	trail t45(slwclk2, reset, h44, v44,ox44,oy44,trailx44,traily44,trailx45,traily45,h45,v45,ox45,oy45);
	trail t46(slwclk2, reset, h45, v45,ox45,oy45,trailx45,traily45,trailx46,traily46,h46,v46,ox46,oy46);
	trail t47(slwclk2, reset, h46, v46,ox46,oy46,trailx46,traily46,trailx47,traily47,h47,v47,ox47,oy47);
	trail t48(slwclk2, reset, h47, v47,ox47,oy47,trailx47,traily47,trailx48,traily48,h48,v48,ox48,oy48);
	trail t49(slwclk2, reset, h48, v48,ox48,oy48,trailx48,traily48,trailx49,traily49,h49,v49,ox49,oy49);
	trail t50(slwclk2, reset, h49, v49,ox49,oy49,trailx49,traily49,trailx50,traily50,h50,v50,ox50,oy50);
	
	//All of p2's trial definitions
	trail p2t1(slwclk2, reset, horizontal2, verticle2,onoffx2,onoffy2,pixelx2, pixely2,p2trailx,p2traily,p2h1,p2v1,p2ox1,p2oy1);
	trail p2t2(slwclk2, reset, p2h1, p2v1,p2ox1,p2oy1,p2trailx,p2traily,p2trailx2,p2traily2,p2h2,p2v2,p2ox2,p2oy2);
	trail p2t3(slwclk2, reset, p2h2, p2v2,p2ox2,p2oy2,p2trailx2,p2traily2,p2trailx3,p2traily3,p2h3,p2v3,p2ox3,p2oy3);
	trail p2t4(slwclk2, reset, p2h3, p2v3,p2ox3,p2oy3,p2trailx3,p2traily3,p2trailx4,p2traily4,p2h4,p2v4,p2ox4,p2oy4);
	trail p2t5(slwclk2, reset, p2h4, p2v4,p2ox4,p2oy4,p2trailx4,p2traily4,p2trailx5,p2traily5,p2h5,p2v5,p2ox5,p2oy5);
	trail p2t6(slwclk2, reset, p2h5, p2v5,p2ox5,p2oy5,p2trailx5,p2traily5,p2trailx6,p2traily6,p2h6,p2v6,p2ox6,p2oy6);
	trail p2t7(slwclk2, reset, p2h6, p2v6,p2ox6,p2oy6,p2trailx6,p2traily6,p2trailx7,p2traily7,p2h7,p2v7,p2ox7,p2oy7);
	trail p2t8(slwclk2, reset, p2h7, p2v7,p2ox7,p2oy7,p2trailx7,p2traily7,p2trailx8,p2traily8,p2h8,p2v8,p2ox8,p2oy8);
	trail p2t9(slwclk2, reset, p2h8, p2v8,p2ox8,p2oy8,p2trailx8,p2traily8,p2trailx9,p2traily9,p2h9,p2v9,p2ox9,p2oy9);
	trail p2t10(slwclk2, reset, p2h9, p2v9,p2ox9,p2oy9,p2trailx9,p2traily9,p2trailx10,p2traily10,p2h10,p2v10,p2ox10,p2oy10);
	trail p2t11(slwclk2, reset, p2h10, p2v10,p2ox10,p2oy10,p2trailx10,p2traily10,p2trailx11,p2traily11,p2h11,p2v11,p2ox11,p2oy11);
	trail p2t12(slwclk2, reset, p2h11, p2v11,p2ox11,p2oy11,p2trailx11,p2traily11,p2trailx12,p2traily12,p2h12,p2v12,p2ox12,p2oy12);
	trail p2t13(slwclk2, reset, p2h12, p2v12,p2ox12,p2oy12,p2trailx12,p2traily12,p2trailx13,p2traily13,p2h13,p2v13,p2ox13,p2oy13);
	trail p2t14(slwclk2, reset, p2h13, p2v13,p2ox13,p2oy13,p2trailx13,p2traily13,p2trailx14,p2traily14,p2h14,p2v14,p2ox14,p2oy14);
	trail p2t15(slwclk2, reset, p2h14, p2v14,p2ox14,p2oy14,p2trailx14,p2traily14,p2trailx15,p2traily15,p2h15,p2v15,p2ox15,p2oy15);
	trail p2t16(slwclk2, reset, p2h15, p2v15,p2ox15,p2oy15,p2trailx15,p2traily15,p2trailx16,p2traily16,p2h16,p2v16,p2ox16,p2oy16);
	trail p2t17(slwclk2, reset, p2h16, p2v16,p2ox16,p2oy16,p2trailx16,p2traily16,p2trailx17,p2traily17,p2h17,p2v17,p2ox17,p2oy17);
	trail p2t18(slwclk2, reset, p2h17, p2v17,p2ox17,p2oy17,p2trailx17,p2traily17,p2trailx18,p2traily18,p2h18,p2v18,p2ox18,p2oy18);
	trail p2t19(slwclk2, reset, p2h18, p2v18,p2ox18,p2oy18,p2trailx18,p2traily18,p2trailx19,p2traily19,p2h19,p2v19,p2ox19,p2oy19);
	trail p2t20(slwclk2, reset, p2h19, p2v19,p2ox19,p2oy19,p2trailx19,p2traily19,p2trailx20,p2traily20,p2h20,p2v20,p2ox20,p2oy20);
	trail p2t21(slwclk2, reset, p2h20, p2v20,p2ox20,p2oy20,p2trailx20,p2traily20,p2trailx21,p2traily21,p2h21,p2v21,p2ox21,p2oy21);
	trail p2t22(slwclk2, reset, p2h21, p2v21,p2ox21,p2oy21,p2trailx21,p2traily21,p2trailx22,p2traily22,p2h22,p2v22,p2ox22,p2oy22);
	trail p2t23(slwclk2, reset, p2h22, p2v22,p2ox22,p2oy22,p2trailx22,p2traily22,p2trailx23,p2traily23,p2h23,p2v23,p2ox23,p2oy23);
	trail p2t24(slwclk2, reset, p2h23, p2v23,p2ox23,p2oy23,p2trailx23,p2traily23,p2trailx24,p2traily24,p2h24,p2v24,p2ox24,p2oy24);
	trail p2t25(slwclk2, reset, p2h24, p2v24,p2ox24,p2oy24,p2trailx24,p2traily24,p2trailx25,p2traily25,p2h25,p2v25,p2ox25,p2oy25);
	trail p2t26(slwclk2, reset, p2h25, p2v25,p2ox25,p2oy25,p2trailx25,p2traily25,p2trailx26,p2traily26,p2h26,p2v26,p2ox26,p2oy26);
	trail p2t27(slwclk2, reset, p2h26, p2v26,p2ox26,p2oy26,p2trailx26,p2traily26,p2trailx27,p2traily27,p2h27,p2v27,p2ox27,p2oy27);
	trail p2t28(slwclk2, reset, p2h27, p2v27,p2ox27,p2oy27,p2trailx27,p2traily27,p2trailx28,p2traily28,p2h28,p2v28,p2ox28,p2oy28);
	trail p2t29(slwclk2, reset, p2h28, p2v28,p2ox28,p2oy28,p2trailx28,p2traily28,p2trailx29,p2traily29,p2h29,p2v29,p2ox29,p2oy29);
	trail p2t30(slwclk2, reset, p2h29, p2v29,p2ox29,p2oy29,p2trailx29,p2traily29,p2trailx30,p2traily30,p2h30,p2v30,p2ox30,p2oy30);
	trail p2t31(slwclk2, reset, p2h30, p2v30,p2ox30,p2oy30,p2trailx30,p2traily30,p2trailx31,p2traily31,p2h31,p2v31,p2ox31,p2oy31);
	trail p2t32(slwclk2, reset, p2h31, p2v31,p2ox31,p2oy31,p2trailx31,p2traily31,p2trailx32,p2traily32,p2h32,p2v32,p2ox32,p2oy32);
	trail p2t33(slwclk2, reset, p2h32, p2v32,p2ox32,p2oy32,p2trailx32,p2traily32,p2trailx33,p2traily33,p2h33,p2v33,p2ox33,p2oy33);
	trail p2t34(slwclk2, reset, p2h33, p2v33,p2ox33,p2oy33,p2trailx33,p2traily33,p2trailx34,p2traily34,p2h34,p2v34,p2ox34,p2oy34);
	trail p2t35(slwclk2, reset, p2h34, p2v34,p2ox34,p2oy34,p2trailx34,p2traily34,p2trailx35,p2traily35,p2h35,p2v35,p2ox35,p2oy35);
	trail p2t36(slwclk2, reset, p2h35, p2v35,p2ox35,p2oy35,p2trailx35,p2traily35,p2trailx36,p2traily36,p2h36,p2v36,p2ox36,p2oy36);
	trail p2t37(slwclk2, reset, p2h36, p2v36,p2ox36,p2oy36,p2trailx36,p2traily36,p2trailx37,p2traily37,p2h37,p2v37,p2ox37,p2oy37);
	trail p2t38(slwclk2, reset, p2h37, p2v37,p2ox37,p2oy37,p2trailx37,p2traily37,p2trailx38,p2traily38,p2h38,p2v38,p2ox38,p2oy38);
	trail p2t39(slwclk2, reset, p2h38, p2v38,p2ox38,p2oy38,p2trailx38,p2traily38,p2trailx39,p2traily39,p2h39,p2v39,p2ox39,p2oy39);
	trail p2t40(slwclk2, reset, p2h39, p2v39,p2ox39,p2oy39,p2trailx39,p2traily39,p2trailx40,p2traily40,p2h40,p2v40,p2ox40,p2oy40);
	trail p2t41(slwclk2, reset, p2h40, p2v40,p2ox40,p2oy40,p2trailx40,p2traily40,p2trailx41,p2traily41,p2h41,p2v41,p2ox41,p2oy41);
	trail p2t42(slwclk2, reset, p2h41, p2v41,p2ox41,p2oy41,p2trailx41,p2traily41,p2trailx42,p2traily42,p2h42,p2v42,p2ox42,p2oy42);
	trail p2t43(slwclk2, reset, p2h42, p2v42,p2ox42,p2oy42,p2trailx42,p2traily42,p2trailx43,p2traily43,p2h43,p2v43,p2ox43,p2oy43);
	trail p2t44(slwclk2, reset, p2h43, p2v43,p2ox43,p2oy43,p2trailx43,p2traily43,p2trailx44,p2traily44,p2h44,p2v44,p2ox44,p2oy44);
	trail p2t45(slwclk2, reset, p2h44, p2v44,p2ox44,p2oy44,p2trailx44,p2traily44,p2trailx45,p2traily45,p2h45,p2v45,p2ox45,p2oy45);
	trail p2t46(slwclk2, reset, p2h45, p2v45,p2ox45,p2oy45,p2trailx45,p2traily45,p2trailx46,p2traily46,p2h46,p2v46,p2ox46,p2oy46);
	trail p2t47(slwclk2, reset, p2h46, p2v46,p2ox46,p2oy46,p2trailx46,p2traily46,p2trailx47,p2traily47,p2h47,p2v47,p2ox47,p2oy47);
	trail p2t48(slwclk2, reset, p2h47, p2v47,p2ox47,p2oy47,p2trailx47,p2traily47,p2trailx48,p2traily48,p2h48,p2v48,p2ox48,p2oy48);
	trail p2t49(slwclk2, reset, p2h48, p2v48,p2ox48,p2oy48,p2trailx48,p2traily48,p2trailx49,p2traily49,p2h49,p2v49,p2ox49,p2oy49);
	trail p2t50(slwclk2, reset, p2h49, p2v49,p2ox49,p2oy49,p2trailx49,p2traily49,p2trailx50,p2traily50,p2h50,p2v50,p2ox50,p2oy50);


	//Output everything onto the display using border module
	//This was done to separate combinational logic 
	graphics graphics1( slwclk3,x,y,pixelx,pixely,pixelx2,pixely2,r,g,b, clk,reset,p2trailx,p2traily,trailx,traily,trailx2,traily2,trailx3,traily3,trailx4,traily4,trailx5,traily5,trailx6,traily6,trailx7,traily7,trailx8,traily8,trailx9,traily9,trailx10,traily10,trailx11,traily11,trailx12,traily12,trailx13,traily13,trailx14,traily14,trailx15,traily15,trailx16,traily16,trailx17,traily17,trailx18,traily18, trailx19,traily19, trailx20,traily20, trailx21,traily21, trailx22,traily22, trailx23,traily23, trailx24,traily24, trailx25,traily25, trailx26,traily26, trailx27,traily27, trailx28,traily28, trailx29,traily29, trailx30,traily30, trailx31,traily31, trailx32,traily32, trailx33,traily33, trailx34,traily34, trailx35,traily35, trailx36,traily36, trailx37,traily37, trailx38,traily38, trailx39,traily39, trailx40,traily40, trailx41,traily41, trailx42,traily42, trailx43,traily43, trailx44,traily44, trailx45,traily45, trailx46,traily46, trailx47,traily47, trailx48,traily48, trailx49,traily49, trailx50,traily50,p2trailx2,p2traily2, p2trailx3,p2traily3, p2trailx4,p2traily4, p2trailx5,p2traily5, p2trailx6,p2traily6, p2trailx7,p2traily7, p2trailx8,p2traily8, p2trailx9,p2traily9, p2trailx10,p2traily10, p2trailx11,p2traily11, p2trailx12,p2traily12, p2trailx13,p2traily13, p2trailx14,p2traily14, p2trailx15,p2traily15, p2trailx16,p2traily16, p2trailx17,p2traily17, p2trailx18,p2traily18, p2trailx19,p2traily19, p2trailx20,p2traily20, p2trailx21,p2traily21, p2trailx22,p2traily22, p2trailx23,p2traily23, p2trailx24,p2traily24, p2trailx25,p2traily25, p2trailx26,p2traily26, p2trailx27,p2traily27, p2trailx28,p2traily28, p2trailx29,p2traily29, p2trailx30,p2traily30, p2trailx31,p2traily31, p2trailx32,p2traily32, p2trailx33,p2traily33, p2trailx34,p2traily34, p2trailx35,p2traily35, p2trailx36,p2traily36, p2trailx37,p2traily37, p2trailx38,p2traily38, p2trailx39,p2traily39, p2trailx40,p2traily40, p2trailx41,p2traily41, p2trailx42,p2traily42, p2trailx43,p2traily43, p2trailx44,p2traily44, p2trailx45,p2traily45, p2trailx46,p2traily46, p2trailx47,p2traily47, p2trailx48,p2traily48, p2trailx49,p2traily49, p2trailx50,p2traily50,p2trailx,p2traily );//trails[0],trails[1],trails[2],trails[3],trails[4],trails[5],trails[6],trails[7],trails[8],trails[9],trails[10],trails[11],trails[12],trails[13],trails[14],trails[15]);

endmodule 

//Counter to update the player location on the screen
module counter #(parameter N = 10,  parameter Q = 56, parameter L = 685, parameter H = 50)//, parameter C = 10) // set for x , for y use 510 and 35
               
					 (input  logic clk,
					  input  logic reset,
					  input  logic onoff,
					  input  logic pm,
					  output logic [N-1:0] q);
					  
  always_ff @(posedge clk, posedge reset)

        if (reset) 		  q <= Q;
	 	else if (q == L & onoff)   q <= H + 1;// col[q] <=q ; end
	 	else if (q == H & onoff)  q <= L - 1;//col[q] <=q ; end
		else if (~pm & onoff)     q <= q - 1;// col[q] <=q ; end
	 	else if (pm & onoff)      q <= q + 1;//col[q] <=q ; end
endmodule
	 
//Graphics of the playing area along with any other information that need to be displayed onto the VGA
module graphics ( input logic slwclk,
				  input logic [9:0] x,y,pixelx,pixely,pixelx2,pixely2,
				  input logic clk, reset,
				  input logic [9:0] p2trailx1,p2traily1, trailx,traily,trailx2,traily2,trailx3,traily3,trailx4,traily4,trailx5,traily5,trailx6,traily6,trailx7,traily7,trailx8,traily8,trailx9,traily9,trailx10,traily10,trailx11,traily11,trailx12,traily12,trailx13,traily13,trailx14,traily14,trailx15,traily15,trailx16,traily16,trailx17,traily17,trailx18,traily18, trailx19,traily19, trailx20,traily20, trailx21,traily21, trailx22,traily22, trailx23,traily23, trailx24,traily24, trailx25,traily25, trailx26,traily26, trailx27,traily27, trailx28,traily28, trailx29,traily29, trailx30,traily30, trailx31,traily31, trailx32,traily32, trailx33,traily33, trailx34,traily34, trailx35,traily35, trailx36,traily36, trailx37,traily37, trailx38,traily38, trailx39,traily39, trailx40,traily40, trailx41,traily41, trailx42,traily42, trailx43,traily43, trailx44,traily44, trailx45,traily45, trailx46,traily46, trailx47,traily47, trailx48,traily48, trailx49,traily49, trailx50,traily50,p2trailx2,p2traily2, p2trailx3,p2traily3, p2trailx4,p2traily4, p2trailx5,p2traily5, p2trailx6,p2traily6, p2trailx7,p2traily7, p2trailx8,p2traily8, p2trailx9,p2traily9, p2trailx10,p2traily10, p2trailx11,p2traily11, p2trailx12,p2traily12, p2trailx13,p2traily13, p2trailx14,p2traily14, p2trailx15,p2traily15, p2trailx16,p2traily16, p2trailx17,p2traily17, p2trailx18,p2traily18, p2trailx19,p2traily19, p2trailx20,p2traily20, p2trailx21,p2traily21, p2trailx22,p2traily22, p2trailx23,p2traily23, p2trailx24,p2traily24, p2trailx25,p2traily25, p2trailx26,p2traily26, p2trailx27,p2traily27, p2trailx28,p2traily28, p2trailx29,p2traily29, p2trailx30,p2traily30, p2trailx31,p2traily31, p2trailx32,p2traily32, p2trailx33,p2traily33, p2trailx34,p2traily34, p2trailx35,p2traily35, p2trailx36,p2traily36, p2trailx37,p2traily37, p2trailx38,p2traily38, p2trailx39,p2traily39, p2trailx40,p2traily40, p2trailx41,p2traily41, p2trailx42,p2traily42, p2trailx43,p2traily43, p2trailx44,p2traily44, p2trailx45,p2traily45, p2trailx46,p2traily46, p2trailx47,p2traily47, p2trailx48,p2traily48, p2trailx49,p2traily49, p2trailx50,p2traily50,p2trailx,p2traily,
				  output logic [7:0] r,g,b);

	logic [19:0] cnt ;

	always_ff @(posedge slwclk, posedge reset)
		if(reset) cnt <=0;
		else if (cnt != 1024) cnt <= cnt + 1;
		else if (cnt == 1024) cnt <= 1024;

    //Draw border
     always_ff @(posedge clk) begin
		if ((y < 10'd35 | y > 10'd510)) {r, g, b} = 24'hff0000;		
		else{r, g, b} = 24'h000000;
	    if( x < 10'd55  | x > 10'd680) {r, g, b} = 24'hff0000;
		if( x == pixelx & y == pixely ) {r, g, b} = 24'hff0000;		//Pixel coordinates of p1 from counter
		if( x == pixelx2 & y == pixely2 ) {r, g, b} = 24'hff00ff;   //Pixel coordinates of p2 from counter
		
		//All output logic for the player and trails on the screen
		if(	x >= pixelx - 25 & x <= pixelx & y <= pixely + 25 & y >= pixely){r, g, b} = 24'hff0000;
		if(cnt >= 1 &	x >= trailx - 25 & x <= trailx & y <= traily + 25 & y >= traily){r, g, b} = 24'hff0000;
		if(cnt >= 2 &	x >= trailx2 - 25 & x <= trailx2 & y <= traily2 + 25 & y >= traily2){r, g, b} = 24'hff0000;
		if(cnt >= 3 &	x >= trailx3 - 25 & x <= trailx3 & y <= traily3 + 25 & y >= traily3){r, g, b} = 24'hff0000;
		if(cnt >= 4 &	x >= trailx4 - 25 & x <= trailx4 & y <= traily4 + 25 & y >= traily4){r, g, b} = 24'hff0000;
		if(cnt >= 5 &	x >= trailx5 - 25 & x <= trailx5 & y <= traily5 + 25 & y >= traily5){r, g, b} = 24'hff0000;
		if(cnt >= 6 &	x >= trailx6 - 25 & x <= trailx6 & y <= traily6 + 25 & y >= traily6){r, g, b} = 24'hff0000;
		if(cnt >= 7 &	x >= trailx7 - 25 & x <= trailx7 & y <= traily7 + 25 & y >= traily7){r, g, b} = 24'hff0000;
		if(cnt >= 8 &	x >= trailx8 - 25 & x <= trailx8 & y <= traily8 + 25 & y >= traily8){r, g, b} = 24'hff0000;
		if(cnt >= 9 &	x >= trailx9 - 25 & x <= trailx9 & y <= traily9 + 25 & y >= traily9){r, g, b} = 24'hff0000;
		if(cnt >= 10 &	x >= trailx10 - 25 & x <= trailx10 & y <= traily10 + 25 & y >= traily10){r, g, b} = 24'hff0000;
		if(cnt >= 11 &	x >= trailx11 - 25 & x <= trailx11 & y <= traily11 + 25 & y >= traily11){r, g, b} = 24'hff0000;
		if(cnt >= 12 &	x >= trailx12 - 25 & x <= trailx12 & y <= traily12 + 25 & y >= traily12){r, g, b} = 24'hff0000;
		if(cnt >= 13 &	x >= trailx13 - 25 & x <= trailx13 & y <= traily13 + 25 & y >= traily13){r, g, b} = 24'hff0000;
		if(cnt >= 14 &	x >= trailx14 - 25 & x <= trailx14 & y <= traily14 + 25 & y >= traily14){r, g, b} = 24'hff0000;
		if(cnt >= 15 &	x >= trailx15 - 25 & x <= trailx15 & y <= traily15 + 25 & y >= traily15){r, g, b} = 24'hff0000;
		if(cnt >= 16 &	x >= trailx16 - 25 & x <= trailx16 & y <= traily16 + 25 & y >= traily16){r, g, b} = 24'hff0000;
		if(cnt >= 17 &	x >= trailx17 - 25 & x <= trailx17 & y <= traily17 + 25 & y >= traily17){r, g, b} = 24'hff0000;
		if(cnt >= 18 &	x >= trailx18 - 25 & x <= trailx18 & y <= traily18 + 25 & y >= traily18){r, g, b} = 24'hff0000;
		if(cnt >= 19 &	x >= trailx19 - 25 & x <= trailx19 & y <= traily19 + 25 & y >= traily19){r, g, b} = 24'hff0000;
		if(cnt >= 20 &	x >= trailx20 - 25 & x <= trailx20 & y <= traily20 + 25 & y >= traily20){r, g, b} = 24'hff0000;
		if(cnt >= 21 &	x >= trailx21 - 25 & x <= trailx21 & y <= traily21 + 25 & y >= traily21){r, g, b} = 24'hff0000;
		if(cnt >= 22 &	x >= trailx22 - 25 & x <= trailx22 & y <= traily22 + 25 & y >= traily22){r, g, b} = 24'hff0000;
		if(cnt >= 23 &	x >= trailx23 - 25 & x <= trailx23 & y <= traily23 + 25 & y >= traily23){r, g, b} = 24'hff0000;
		if(cnt >= 24 &	x >= trailx24 - 25 & x <= trailx24 & y <= traily24 + 25 & y >= traily24){r, g, b} = 24'hff0000;
		if(cnt >= 25 &	x >= trailx25 - 25 & x <= trailx25 & y <= traily25 + 25 & y >= traily25){r, g, b} = 24'hff0000;
		if(cnt >= 26 &	x >= trailx26 - 25 & x <= trailx26 & y <= traily26 + 25 & y >= traily26){r, g, b} = 24'hff0000;
		if(cnt >= 27 &	x >= trailx27 - 25 & x <= trailx27 & y <= traily27 + 25 & y >= traily27){r, g, b} = 24'hff0000;
		if(cnt >= 28 &	x >= trailx28 - 25 & x <= trailx28 & y <= traily28 + 25 & y >= traily28){r, g, b} = 24'hff0000;
		if(cnt >= 29 &	x >= trailx29 - 25 & x <= trailx29 & y <= traily29 + 25 & y >= traily29){r, g, b} = 24'hff0000;
		if(cnt >= 30 &	x >= trailx30 - 25 & x <= trailx30 & y <= traily30 + 25 & y >= traily30){r, g, b} = 24'hff0000;
		if(cnt >= 31 &	x >= trailx31 - 25 & x <= trailx31 & y <= traily31 + 25 & y >= traily31){r, g, b} = 24'hff0000;
		if(cnt >= 32 &	x >= trailx32 - 25 & x <= trailx32 & y <= traily32 + 25 & y >= traily32){r, g, b} = 24'hff0000;
		if(cnt >= 33 &	x >= trailx33 - 25 & x <= trailx33 & y <= traily33 + 25 & y >= traily33){r, g, b} = 24'hff0000;
		if(cnt >= 34 &	x >= trailx34 - 25 & x <= trailx34 & y <= traily34 + 25 & y >= traily34){r, g, b} = 24'hff0000;
		if(cnt >= 35 &	x >= trailx35 - 25 & x <= trailx35 & y <= traily35 + 25 & y >= traily35){r, g, b} = 24'hff0000;
		if(cnt >= 36 &	x >= trailx36 - 25 & x <= trailx36 & y <= traily36 + 25 & y >= traily36){r, g, b} = 24'hff0000;
		if(cnt >= 37 &	x >= trailx37 - 25 & x <= trailx37 & y <= traily37 + 25 & y >= traily37){r, g, b} = 24'hff0000;
		if(cnt >= 38 &	x >= trailx38 - 25 & x <= trailx38 & y <= traily38 + 25 & y >= traily38){r, g, b} = 24'hff0000;
		if(cnt >= 39 &	x >= trailx39 - 25 & x <= trailx39 & y <= traily39 + 25 & y >= traily39){r, g, b} = 24'hff0000;
		if(cnt >= 40 &	x >= trailx40 - 25 & x <= trailx40 & y <= traily40 + 25 & y >= traily40){r, g, b} = 24'hff0000;
		if(cnt >= 41 &	x >= trailx41 - 25 & x <= trailx41 & y <= traily41 + 25 & y >= traily41){r, g, b} = 24'hff0000;
		if(cnt >= 42 &	x >= trailx42 - 25 & x <= trailx42 & y <= traily42 + 25 & y >= traily42){r, g, b} = 24'hff0000;
		if(cnt >= 43 &	x >= trailx43 - 25 & x <= trailx43 & y <= traily43 + 25 & y >= traily43){r, g, b} = 24'hff0000;
		if(cnt >= 44 &	x >= trailx44 - 25 & x <= trailx44 & y <= traily44 + 25 & y >= traily44){r, g, b} = 24'hff0000;
		if(cnt >= 45 &	x >= trailx45 - 25 & x <= trailx45 & y <= traily45 + 25 & y >= traily45){r, g, b} = 24'hff0000;
		if(cnt >= 46 &	x >= trailx46 - 25 & x <= trailx46 & y <= traily46 + 25 & y >= traily46){r, g, b} = 24'hff0000;
		if(cnt >= 47 &	x >= trailx47 - 25 & x <= trailx47 & y <= traily47 + 25 & y >= traily47){r, g, b} = 24'hff0000;
		if(cnt >= 48 &	x >= trailx48 - 25 & x <= trailx48 & y <= traily48 + 25 & y >= traily48){r, g, b} = 24'hff0000;
		if(cnt >= 49 &	x >= trailx49 - 25 & x <= trailx49 & y <= traily49 + 25 & y >= traily49){r, g, b} = 24'hff0000;
		if(cnt >= 50 &	x >= trailx50 - 25 & x <= trailx50 & y <= traily50 + 25 & y >= traily50){r, g, b} = 24'hff0000;
		if(	x >= pixelx2 - 25 & x <= pixelx2 & y <= pixely2 + 25 & y >= pixely2){r, g, b} = 24'hff00ff;
		if(cnt >= 1 &	x >= p2trailx1 - 25 & x <= p2trailx1 & y <= p2traily1 + 25 & y >= p2traily1){r, g, b} = 24'hff00ff;
		if(cnt >= 2 &	x >= p2trailx2 - 25 & x <= p2trailx2 & y <= p2traily2 + 25 & y >= p2traily2){r, g, b} = 24'hff00ff;
		if(cnt >= 3 &	x >= p2trailx3 - 25 & x <= p2trailx3 & y <= p2traily3 + 25 & y >= p2traily3){r, g, b} = 24'hff00ff;
		if(cnt >= 4 &	x >= p2trailx4 - 25 & x <= p2trailx4 & y <= p2traily4 + 25 & y >= p2traily4){r, g, b} = 24'hff00ff;
		if(cnt >= 5 &	x >= p2trailx5 - 25 & x <= p2trailx5 & y <= p2traily5 + 25 & y >= p2traily5){r, g, b} = 24'hff00ff;
		if(cnt >= 6 &	x >= p2trailx6 - 25 & x <= p2trailx6 & y <= p2traily6 + 25 & y >= p2traily6){r, g, b} = 24'hff00ff;
		if(cnt >= 7 &	x >= p2trailx7 - 25 & x <= p2trailx7 & y <= p2traily7 + 25 & y >= p2traily7){r, g, b} = 24'hff00ff;
		if(cnt >= 8 &	x >= p2trailx8 - 25 & x <= p2trailx8 & y <= p2traily8 + 25 & y >= p2traily8){r, g, b} = 24'hff00ff;
		if(cnt >= 9 &	x >= p2trailx9 - 25 & x <= p2trailx9 & y <= p2traily9 + 25 & y >= p2traily9){r, g, b} = 24'hff00ff;
		if(cnt >= 10 &	x >= p2trailx10 - 25 & x <= p2trailx10 & y <= p2traily10 + 25 & y >= p2traily10){r, g, b} = 24'hff00ff;
		if(cnt >= 11 &	x >= p2trailx11 - 25 & x <= p2trailx11 & y <= p2traily11 + 25 & y >= p2traily11){r, g, b} = 24'hff00ff;
		if(cnt >= 12 &	x >= p2trailx12 - 25 & x <= p2trailx12 & y <= p2traily12 + 25 & y >= p2traily12){r, g, b} = 24'hff00ff;
		if(cnt >= 13 &	x >= p2trailx13 - 25 & x <= p2trailx13 & y <= p2traily13 + 25 & y >= p2traily13){r, g, b} = 24'hff00ff;
		if(cnt >= 14 &	x >= p2trailx14 - 25 & x <= p2trailx14 & y <= p2traily14 + 25 & y >= p2traily14){r, g, b} = 24'hff00ff;
		if(cnt >= 15 &	x >= p2trailx15 - 25 & x <= p2trailx15 & y <= p2traily15 + 25 & y >= p2traily15){r, g, b} = 24'hff00ff;
		if(cnt >= 16 &	x >= p2trailx16 - 25 & x <= p2trailx16 & y <= p2traily16 + 25 & y >= p2traily16){r, g, b} = 24'hff00ff;
		if(cnt >= 17 &	x >= p2trailx17 - 25 & x <= p2trailx17 & y <= p2traily17 + 25 & y >= p2traily17){r, g, b} = 24'hff00ff;
		if(cnt >= 18 &	x >= p2trailx18 - 25 & x <= p2trailx18 & y <= p2traily18 + 25 & y >= p2traily18){r, g, b} = 24'hff00ff;
		if(cnt >= 19 &	x >= p2trailx19 - 25 & x <= p2trailx19 & y <= p2traily19 + 25 & y >= p2traily19){r, g, b} = 24'hff00ff;
		if(cnt >= 20 &	x >= p2trailx20 - 25 & x <= p2trailx20 & y <= p2traily20 + 25 & y >= p2traily20){r, g, b} = 24'hff00ff;
		if(cnt >= 21 &	x >= p2trailx21 - 25 & x <= p2trailx21 & y <= p2traily21 + 25 & y >= p2traily21){r, g, b} = 24'hff00ff;
		if(cnt >= 22 &	x >= p2trailx22 - 25 & x <= p2trailx22 & y <= p2traily22 + 25 & y >= p2traily22){r, g, b} = 24'hff00ff;
		if(cnt >= 23 &	x >= p2trailx23 - 25 & x <= p2trailx23 & y <= p2traily23 + 25 & y >= p2traily23){r, g, b} = 24'hff00ff;
		if(cnt >= 24 &	x >= p2trailx24 - 25 & x <= p2trailx24 & y <= p2traily24 + 25 & y >= p2traily24){r, g, b} = 24'hff00ff;
		if(cnt >= 25 &	x >= p2trailx25 - 25 & x <= p2trailx25 & y <= p2traily25 + 25 & y >= p2traily25){r, g, b} = 24'hff00ff;
		if(cnt >= 26 &	x >= p2trailx26 - 25 & x <= p2trailx26 & y <= p2traily26 + 25 & y >= p2traily26){r, g, b} = 24'hff00ff;
		if(cnt >= 27 &	x >= p2trailx27 - 25 & x <= p2trailx27 & y <= p2traily27 + 25 & y >= p2traily27){r, g, b} = 24'hff00ff;
		if(cnt >= 28 &	x >= p2trailx28 - 25 & x <= p2trailx28 & y <= p2traily28 + 25 & y >= p2traily28){r, g, b} = 24'hff00ff;
		if(cnt >= 29 &	x >= p2trailx29 - 25 & x <= p2trailx29 & y <= p2traily29 + 25 & y >= p2traily29){r, g, b} = 24'hff00ff;
		if(cnt >= 30 &	x >= p2trailx30 - 25 & x <= p2trailx30 & y <= p2traily30 + 25 & y >= p2traily30){r, g, b} = 24'hff00ff;
		if(cnt >= 31 &	x >= p2trailx31 - 25 & x <= p2trailx31 & y <= p2traily31 + 25 & y >= p2traily31){r, g, b} = 24'hff00ff;
		if(cnt >= 32 &	x >= p2trailx32 - 25 & x <= p2trailx32 & y <= p2traily32 + 25 & y >= p2traily32){r, g, b} = 24'hff00ff;
		if(cnt >= 33 &	x >= p2trailx33 - 25 & x <= p2trailx33 & y <= p2traily33 + 25 & y >= p2traily33){r, g, b} = 24'hff00ff;
		if(cnt >= 34 &	x >= p2trailx34 - 25 & x <= p2trailx34 & y <= p2traily34 + 25 & y >= p2traily34){r, g, b} = 24'hff00ff;
		if(cnt >= 35 &	x >= p2trailx35 - 25 & x <= p2trailx35 & y <= p2traily35 + 25 & y >= p2traily35){r, g, b} = 24'hff00ff;
		if(cnt >= 36 &	x >= p2trailx36 - 25 & x <= p2trailx36 & y <= p2traily36 + 25 & y >= p2traily36){r, g, b} = 24'hff00ff;
		if(cnt >= 37 &	x >= p2trailx37 - 25 & x <= p2trailx37 & y <= p2traily37 + 25 & y >= p2traily37){r, g, b} = 24'hff00ff;
		if(cnt >= 38 &	x >= p2trailx38 - 25 & x <= p2trailx38 & y <= p2traily38 + 25 & y >= p2traily38){r, g, b} = 24'hff00ff;
		if(cnt >= 39 &	x >= p2trailx39 - 25 & x <= p2trailx39 & y <= p2traily39 + 25 & y >= p2traily39){r, g, b} = 24'hff00ff;
		if(cnt >= 40 &	x >= p2trailx40 - 25 & x <= p2trailx40 & y <= p2traily40 + 25 & y >= p2traily40){r, g, b} = 24'hff00ff;
		if(cnt >= 41 &	x >= p2trailx41 - 25 & x <= p2trailx41 & y <= p2traily41 + 25 & y >= p2traily41){r, g, b} = 24'hff00ff;
		if(cnt >= 42 &	x >= p2trailx42 - 25 & x <= p2trailx42 & y <= p2traily42 + 25 & y >= p2traily42){r, g, b} = 24'hff00ff;
		if(cnt >= 43 &	x >= p2trailx43 - 25 & x <= p2trailx43 & y <= p2traily43 + 25 & y >= p2traily43){r, g, b} = 24'hff00ff;
		if(cnt >= 44 &	x >= p2trailx44 - 25 & x <= p2trailx44 & y <= p2traily44 + 25 & y >= p2traily44){r, g, b} = 24'hff00ff;
		if(cnt >= 45 &	x >= p2trailx45 - 25 & x <= p2trailx45 & y <= p2traily45 + 25 & y >= p2traily45){r, g, b} = 24'hff00ff;
		if(cnt >= 46 &	x >= p2trailx46 - 25 & x <= p2trailx46 & y <= p2traily46 + 25 & y >= p2traily46){r, g, b} = 24'hff00ff;
		if(cnt >= 47 &	x >= p2trailx47 - 25 & x <= p2trailx47 & y <= p2traily47 + 25 & y >= p2traily47){r, g, b} = 24'hff00ff;
		if(cnt >= 48 &	x >= p2trailx48 - 25 & x <= p2trailx48 & y <= p2traily48 + 25 & y >= p2traily48){r, g, b} = 24'hff00ff;
		if(cnt >= 49 &	x >= p2trailx49 - 25 & x <= p2trailx49 & y <= p2traily49 + 25 & y >= p2traily49){r, g, b} = 24'hff00ff;
		if(cnt >= 50 &	x >= p2trailx50 - 25 & x <= p2trailx50 & y <= p2traily50 + 25 & y >= p2traily50){r, g, b} = 24'hff00ff;
		if(	pixelx >= p2trailx - 25 & pixelx <= p2trailx & pixely <= p2traily + 25 & pixely >= p2traily){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx2 - 25 & pixelx <= p2trailx2 & pixely <= p2traily2 + 25 & pixely >= p2traily2){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx3 - 25 & pixelx <= p2trailx3 & pixely <= p2traily3 + 25 & pixely >= p2traily3){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx4 - 25 & pixelx <= p2trailx4 & pixely <= p2traily4 + 25 & pixely >= p2traily4){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx5 - 25 & pixelx <= p2trailx5 & pixely <= p2traily5 + 25 & pixely >= p2traily5){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx6 - 25 & pixelx <= p2trailx6 & pixely <= p2traily6 + 25 & pixely >= p2traily6){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx7 - 25 & pixelx <= p2trailx7 & pixely <= p2traily7 + 25 & pixely >= p2traily7){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx8 - 25 & pixelx <= p2trailx8 & pixely <= p2traily8 + 25 & pixely >= p2traily8){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx9 - 25 & pixelx <= p2trailx9 & pixely <= p2traily9 + 25 & pixely >= p2traily9){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx10 - 25 & pixelx <= p2trailx10 & pixely <= p2traily10 + 25 & pixely >= p2traily10){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx11 - 25 & pixelx <= p2trailx11 & pixely <= p2traily11 + 25 & pixely >= p2traily11){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx12 - 25 & pixelx <= p2trailx12 & pixely <= p2traily12 + 25 & pixely >= p2traily12){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx13 - 25 & pixelx <= p2trailx13 & pixely <= p2traily13 + 25 & pixely >= p2traily13){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx14 - 25 & pixelx <= p2trailx14 & pixely <= p2traily14 + 25 & pixely >= p2traily14){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx15 - 25 & pixelx <= p2trailx15 & pixely <= p2traily15 + 25 & pixely >= p2traily15){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx16 - 25 & pixelx <= p2trailx16 & pixely <= p2traily16 + 25 & pixely >= p2traily16){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx17 - 25 & pixelx <= p2trailx17 & pixely <= p2traily17 + 25 & pixely >= p2traily17){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx18 - 25 & pixelx <= p2trailx18 & pixely <= p2traily18 + 25 & pixely >= p2traily18){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx19 - 25 & pixelx <= p2trailx19 & pixely <= p2traily19 + 25 & pixely >= p2traily19){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx20 - 25 & pixelx <= p2trailx20 & pixely <= p2traily20 + 25 & pixely >= p2traily20){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx21 - 25 & pixelx <= p2trailx21 & pixely <= p2traily21 + 25 & pixely >= p2traily21){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx22 - 25 & pixelx <= p2trailx22 & pixely <= p2traily22 + 25 & pixely >= p2traily22){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx23 - 25 & pixelx <= p2trailx23 & pixely <= p2traily23 + 25 & pixely >= p2traily23){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx24 - 25 & pixelx <= p2trailx24 & pixely <= p2traily24 + 25 & pixely >= p2traily24){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx25 - 25 & pixelx <= p2trailx25 & pixely <= p2traily25 + 25 & pixely >= p2traily25){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx26 - 25 & pixelx <= p2trailx26 & pixely <= p2traily26 + 25 & pixely >= p2traily26){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx27 - 25 & pixelx <= p2trailx27 & pixely <= p2traily27 + 25 & pixely >= p2traily27){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx28 - 25 & pixelx <= p2trailx28 & pixely <= p2traily28 + 25 & pixely >= p2traily28){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx29 - 25 & pixelx <= p2trailx29 & pixely <= p2traily29 + 25 & pixely >= p2traily29){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx30 - 25 & pixelx <= p2trailx30 & pixely <= p2traily30 + 25 & pixely >= p2traily30){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx31 - 25 & pixelx <= p2trailx31 & pixely <= p2traily31 + 25 & pixely >= p2traily31){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx32 - 25 & pixelx <= p2trailx32 & pixely <= p2traily32 + 25 & pixely >= p2traily32){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx33 - 25 & pixelx <= p2trailx33 & pixely <= p2traily33 + 25 & pixely >= p2traily33){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx34 - 25 & pixelx <= p2trailx34 & pixely <= p2traily34 + 25 & pixely >= p2traily34){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx35 - 25 & pixelx <= p2trailx35 & pixely <= p2traily35 + 25 & pixely >= p2traily35){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx36 - 25 & pixelx <= p2trailx36 & pixely <= p2traily36 + 25 & pixely >= p2traily36){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx37 - 25 & pixelx <= p2trailx37 & pixely <= p2traily37 + 25 & pixely >= p2traily37){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx38 - 25 & pixelx <= p2trailx38 & pixely <= p2traily38 + 25 & pixely >= p2traily38){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx39 - 25 & pixelx <= p2trailx39 & pixely <= p2traily39 + 25 & pixely >= p2traily39){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx40 - 25 & pixelx <= p2trailx40 & pixely <= p2traily40 + 25 & pixely >= p2traily40){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx41 - 25 & pixelx <= p2trailx41 & pixely <= p2traily41 + 25 & pixely >= p2traily41){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx42 - 25 & pixelx <= p2trailx42 & pixely <= p2traily42 + 25 & pixely >= p2traily42){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx43 - 25 & pixelx <= p2trailx43 & pixely <= p2traily43 + 25 & pixely >= p2traily43){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx44 - 25 & pixelx <= p2trailx44 & pixely <= p2traily44 + 25 & pixely >= p2traily44){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx45 - 25 & pixelx <= p2trailx45 & pixely <= p2traily45 + 25 & pixely >= p2traily45){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx46 - 25 & pixelx <= p2trailx46 & pixely <= p2traily46 + 25 & pixely >= p2traily46){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx47 - 25 & pixelx <= p2trailx47 & pixely <= p2traily47 + 25 & pixely >= p2traily47){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx48 - 25 & pixelx <= p2trailx48 & pixely <= p2traily48 + 25 & pixely >= p2traily48){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx49 - 25 & pixelx <= p2trailx49 & pixely <= p2traily49 + 25 & pixely >= p2traily49){r, g, b} = 24'h00ff00;
		if(	pixelx >= p2trailx50 - 25 & pixelx <= p2trailx50 & pixely <= p2traily50 + 25 & pixely >= p2traily50){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx - 25 & pixelx2 <= trailx & pixely2 <= traily + 25 & pixely2 >= traily){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx2 - 25 & pixelx2 <= trailx2 & pixely2 <= traily2 + 25 & pixely2 >= traily2){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx3 - 25 & pixelx2 <= trailx3 & pixely2 <= traily3 + 25 & pixely2 >= traily3){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx4 - 25 & pixelx2 <= trailx4 & pixely2 <= traily4 + 25 & pixely2 >= traily4){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx5 - 25 & pixelx2 <= trailx5 & pixely2 <= traily5 + 25 & pixely2 >= traily5){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx6 - 25 & pixelx2 <= trailx6 & pixely2 <= traily6 + 25 & pixely2 >= traily6){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx7 - 25 & pixelx2 <= trailx7 & pixely2 <= traily7 + 25 & pixely2 >= traily7){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx8 - 25 & pixelx2 <= trailx8 & pixely2 <= traily8 + 25 & pixely2 >= traily8){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx9 - 25 & pixelx2 <= trailx9 & pixely2 <= traily9 + 25 & pixely2 >= traily9){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx10 - 25 & pixelx2 <= trailx10 & pixely2 <= traily10 + 25 & pixely2 >= traily10){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx11 - 25 & pixelx2 <= trailx11 & pixely2 <= traily11 + 25 & pixely2 >= traily11){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx12 - 25 & pixelx2 <= trailx12 & pixely2 <= traily12 + 25 & pixely2 >= traily12){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx13 - 25 & pixelx2 <= trailx13 & pixely2 <= traily13 + 25 & pixely2 >= traily13){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx14 - 25 & pixelx2 <= trailx14 & pixely2 <= traily14 + 25 & pixely2 >= traily14){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx15 - 25 & pixelx2 <= trailx15 & pixely2 <= traily15 + 25 & pixely2 >= traily15){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx16 - 25 & pixelx2 <= trailx16 & pixely2 <= traily16 + 25 & pixely2 >= traily16){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx17 - 25 & pixelx2 <= trailx17 & pixely2 <= traily17 + 25 & pixely2 >= traily17){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx18 - 25 & pixelx2 <= trailx18 & pixely2 <= traily18 + 25 & pixely2 >= traily18){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx19 - 25 & pixelx2 <= trailx19 & pixely2 <= traily19 + 25 & pixely2 >= traily19){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx20 - 25 & pixelx2 <= trailx20 & pixely2 <= traily20 + 25 & pixely2 >= traily20){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx21 - 25 & pixelx2 <= trailx21 & pixely2 <= traily21 + 25 & pixely2 >= traily21){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx22 - 25 & pixelx2 <= trailx22 & pixely2 <= traily22 + 25 & pixely2 >= traily22){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx23 - 25 & pixelx2 <= trailx23 & pixely2 <= traily23 + 25 & pixely2 >= traily23){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx24 - 25 & pixelx2 <= trailx24 & pixely2 <= traily24 + 25 & pixely2 >= traily24){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx25 - 25 & pixelx2 <= trailx25 & pixely2 <= traily25 + 25 & pixely2 >= traily25){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx26 - 25 & pixelx2 <= trailx26 & pixely2 <= traily26 + 25 & pixely2 >= traily26){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx27 - 25 & pixelx2 <= trailx27 & pixely2 <= traily27 + 25 & pixely2 >= traily27){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx28 - 25 & pixelx2 <= trailx28 & pixely2 <= traily28 + 25 & pixely2 >= traily28){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx29 - 25 & pixelx2 <= trailx29 & pixely2 <= traily29 + 25 & pixely2 >= traily29){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx30 - 25 & pixelx2 <= trailx30 & pixely2 <= traily30 + 25 & pixely2 >= traily30){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx31 - 25 & pixelx2 <= trailx31 & pixely2 <= traily31 + 25 & pixely2 >= traily31){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx32 - 25 & pixelx2 <= trailx32 & pixely2 <= traily32 + 25 & pixely2 >= traily32){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx33 - 25 & pixelx2 <= trailx33 & pixely2 <= traily33 + 25 & pixely2 >= traily33){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx34 - 25 & pixelx2 <= trailx34 & pixely2 <= traily34 + 25 & pixely2 >= traily34){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx35 - 25 & pixelx2 <= trailx35 & pixely2 <= traily35 + 25 & pixely2 >= traily35){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx36 - 25 & pixelx2 <= trailx36 & pixely2 <= traily36 + 25 & pixely2 >= traily36){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx37 - 25 & pixelx2 <= trailx37 & pixely2 <= traily37 + 25 & pixely2 >= traily37){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx38 - 25 & pixelx2 <= trailx38 & pixely2 <= traily38 + 25 & pixely2 >= traily38){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx39 - 25 & pixelx2 <= trailx39 & pixely2 <= traily39 + 25 & pixely2 >= traily39){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx40 - 25 & pixelx2 <= trailx40 & pixely2 <= traily40 + 25 & pixely2 >= traily40){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx41 - 25 & pixelx2 <= trailx41 & pixely2 <= traily41 + 25 & pixely2 >= traily41){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx42 - 25 & pixelx2 <= trailx42 & pixely2 <= traily42 + 25 & pixely2 >= traily42){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx43 - 25 & pixelx2 <= trailx43 & pixely2 <= traily43 + 25 & pixely2 >= traily43){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx44 - 25 & pixelx2 <= trailx44 & pixely2 <= traily44 + 25 & pixely2 >= traily44){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx45 - 25 & pixelx2 <= trailx45 & pixely2 <= traily45 + 25 & pixely2 >= traily45){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx46 - 25 & pixelx2 <= trailx46 & pixely2 <= traily46 + 25 & pixely2 >= traily46){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx47 - 25 & pixelx2 <= trailx47 & pixely2 <= traily47 + 25 & pixely2 >= traily47){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx48 - 25 & pixelx2 <= trailx48 & pixely2 <= traily48 + 25 & pixely2 >= traily48){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx49 - 25 & pixelx2 <= trailx49 & pixely2 <= traily49 + 25 & pixely2 >= traily49){r, g, b} = 24'h00ff00;
		if(	pixelx2 >= trailx50 - 25 & pixelx2 <= trailx50 & pixely2 <= traily50 + 25 & pixely2 >= traily50){r, g, b} = 24'h00ff00;

	end
	
        
endmodule

//Trail module to update the trail pixel locations
module trail(input logic          clk, reset,horizontal,verticle ,onoffx,onoffy,//horizontal2,verticle2 ,
             input logic [9:0]    pixelx, pixely,//pixelx2,pixely2,
             output logic[9:0]    trailx, traily,
             output logic         h, v, ox, oy);//,trailx2,traily2);

	logic ht, vt,oxt,oyt;
				 
    always_ff @(posedge clk)//, posedge reset)
        begin
            if(reset) begin
                trailx <= pixelx - 1;
                traily <= pixely;

               end
            else if(horizontal == 1 & verticle == 0 & onoffx ) begin
                trailx <= pixelx - 1;
                traily <= pixely;

            end
            else if(horizontal == 0 & verticle == 0 & onoffx ) begin
                trailx <= pixelx + 1;
                traily <= pixely;

            end
            else if(verticle == 1 & horizontal == 0 & onoffy ) begin 
                trailx <= pixelx ; 
                traily <= pixely - 1;

            end
            else if(verticle == 0 & horizontal == 0 & onoffy ) begin 
                trailx <= pixelx;
                traily <= pixely+1;

            end
        end

		  assign h = horizontal;
		  assign v = verticle;
		  assign ox = onoffx; 
		  assign oy = onoffy;
		  
		  
endmodule

//dirfsm for each player's direction from the controller inputs
module dirfsm(input logic clk, reset, up,down,left,right, output logic onoffx, onoffy, horizontal, verticle );

typedef enum logic [2:0] {MENU, SPAWN, ENDGAME, LEFT, RIGHT, UP, DOWN} statetype;
  statetype state, nextstate;  
 
 
 always_ff @(posedge clk, posedge reset)
    if (reset) state <= RIGHT;
    else       state <= nextstate;
	always_comb
		begin
			case (state)
			  UP:       if (right) 
							nextstate = RIGHT;
						else if (down) 
							nextstate = DOWN;
						else if (left) 
							nextstate = LEFT;
						else 
							nextstate = UP;
			  DOWN:     if (up)
							nextstate = UP;
						else if (right)
							nextstate = RIGHT;
						else if (left) 
							nextstate = LEFT;
						else 
							nextstate = DOWN;
			  LEFT:     if (up) 
							nextstate = UP;
						else if (down) 
							nextstate = DOWN;
						else if (right) 
							nextstate = RIGHT;
						else 
							nextstate = LEFT;
			  RIGHT:    if (up) 
							nextstate = UP;
						else if (down)
							nextstate = DOWN;
						else if (left) 
							nextstate = LEFT;
						else 
							nextstate = RIGHT;
			  default:  	nextstate = RIGHT;
			endcase

	end
	
	//Set the values for direction based on the state
	always_comb
	begin
		case(state)
		LEFT: begin onoffx =1; onoffy = 0;horizontal = 0; verticle = 0; end
		RIGHT:begin onoffx =1; onoffy = 0;horizontal = 1; verticle = 0; end
		UP:begin onoffx =0; onoffy = 1;horizontal = 0; verticle = 1; end
		DOWN:begin onoffx =0; onoffy = 1;horizontal = 0; verticle = 0; end
		default:  begin onoffx = 1; onoffy = 0; horizontal = 1; verticle = 0;end
		endcase
	end
endmodule 

//1 Hz clock
// Frequency = 86[(50e6)/(2^32)] = 1.001 Hz 
module slowclk1hz(input logic clk, reset,
               output logic slwclk);
               
    logic [31:0] cnt;
    
    always_ff @(posedge clk, posedge reset)
        if(reset) cnt <= 32'b0;
        else      cnt <= cnt + 32'd86; // changed from 86 to 8600 for about 100 times faster
        
    assign slwclk = cnt[31];
endmodule

//100 Hz Clock
module slowclk100hz(input logic clk, reset,
               output logic slwclk);
               
    logic [31:0] cnt;
    
    always_ff @(posedge clk, posedge reset)
        if(reset) cnt <= 32'b0;
        else      cnt <= cnt + 32'd8600; // changed from 86 to 8600 for about 100 times faster
        
    assign slwclk = cnt[31];
endmodule

//10 hz clock
module slowclk10hz(input logic clk, reset,
               output logic slwclk);
               
    logic [31:0] cnt;
    
    always_ff @(posedge clk, posedge reset)
        if(reset) cnt <= 32'b0;
        else      cnt <= cnt + 32'd860; // changed from 86 to 860 for about 10 times faster
        
    assign slwclk = cnt[31];
endmodule


// nes controller works by having a pulse sent to the latch (twice the length of the pulse the output is sent on) then it waits for half the pulse period then up for half to read
//Note this is in verilog because i could not get this working reliably in systemverilog =(
module controlfsm3 ( input  clk, reset, serialin,                                        
						output  latchpulse, controllerpulse, up, down, left, right);
	
		//for the states
	parameter LATCHPULSE =  4'b0000;
	parameter WAITA =  4'b0001;
	parameter WAITB =  4'b0010;
	parameter WAITSELECT =  4'b0011;
	parameter WAITSTART =  4'b0100;
	parameter UP =  4'b0101;
	parameter DOWN =  4'b0110;
	parameter LEFT =  4'b0111;
	parameter RIGHT =  4'b1000;
	

	 // registers for counting
	reg [10:0] count, nextcount;
	
	
	reg [3:0] state, nextstate;
	// to hold the values for the directions
	reg upin,upnext,downin,downnext,leftin,leftnext,rightin,rightnext;

	
		// nextstate logic and value logic for direction registers
	always @(posedge clk, posedge reset)
		if (reset) begin state <= LATCHPULSE; count <= 0; upin <= 0 ; downin <=0 ; leftin <= 0; rightin <= 0; end
		else begin count <= nextcount; state  <= nextstate; upin <= upnext; downin <= downnext; leftin <= leftnext; rightin <= rightnext; end
			
	
	always@*
		begin
			// below was an accident that worked, i tried putting this as the default statement and that did not work, but this does...  
			latchpulse = 0; controllerpulse = 0; nextcount = count; upnext = upin; downnext = downin; leftnext = leftin; rightnext = rightin ; nextstate = state;
		
		case(state)
			// this sends the initial latch pulse for 1200 ticks 
			LATCHPULSE: 
					begin
							// sets latchpulse high
							latchpulse = 1;
							if(count < 1200)				// count gets incremented here
								nextcount = count + 1;
							else if(count == 1200)
							begin
								nextcount = 0;				//switch to nextstate here 
								nextstate = WAITA; 
							end
							else nextstate = LATCHPULSE;		// stay in current state
					end
					
			//this initial waiting period is lower than the rest because it counts part of the initial pulse time
			WAITA:
					begin	
							if(count < 600)
								nextcount = count + 1;
							else if(count == 600)		
							begin
								nextcount = 0; 
								nextstate = WAITB; 
							end
							else
								nextstate = WAITA;
					end
			// this is when the full pulse time is taken into account for waiting it waits for count to = 1200
			WAITB:	
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;		// sends pulse to the controler to get the ball rolling, not needed for waita a, since it considers the initial latch pulse as prompt for its input
							else if(count > 600)
								controllerpulse = 0;	 //sets the pulse low again until the next state sets it high
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = WAITSELECT; 
							end
							else 
								nextstate = WAITB;
					end
			
			WAITSELECT:	
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;
							else if(count > 600)
								controllerpulse = 0;
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = WAITSTART; 
							end
							else 
								nextstate = WAITSELECT;
					end
			
			WAITSTART:	
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;
							else if(count > 600)
								controllerpulse = 0;
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = UP; 
							end
							else 
								nextstate = WAITSTART;
					end
			
			UP:	// this is the first state where we actually read a value in, 
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;
							else if(count > 600)
								controllerpulse = 0;
							if(count == 600)
								upnext = serialin;// read in up here
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = DOWN; 
							end
							else 
								nextstate = UP;
					end
					
			DOWN:	
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;
							else if(count > 600)
								controllerpulse = 0;
							if(count == 600)
								downnext = serialin; // read in down here
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = LEFT; 
							end
							else 
								nextstate = DOWN;
					end
					
			LEFT:	
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;
							else if(count > 600)
								controllerpulse = 0;
							if(count == 600)
								leftnext = serialin; // read in left here
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = RIGHT; 
							end
							else 
								nextstate = LEFT;
					end
					
			RIGHT:	
					begin
					
							if(count < 1200)
								nextcount = count + 1;
					
					
							if(count < 601)
								controllerpulse = 1;
							else if(count > 600)
								controllerpulse = 0;
							if(count == 600)
								rightnext = serialin; // read in right here
							
							if(count == 1200)
							begin
								nextcount = 0; 
								nextstate = LATCHPULSE; 
							end
							else 
								nextstate = RIGHT;
					end
			default: nextstate = LATCHPULSE;
		//	default: begin latchpulse = 0; controllerpulse = 0; nextcount = count; upnext = upin; downnext = downin; leftnext = leftin; rightnext = rightin ; nextstate = state; end

		endcase
		end
		
	
	// assign up down left right below note that by default the output values are always high hence the ~ 
	assign up     =  ~upin;
	assign down   = ~downin;
	assign left   = ~leftin;
	assign right  = ~rightin;
	
endmodule
  