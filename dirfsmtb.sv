module dirfsmtb();
  logic        clk, reset;
  logic        up, down,left,right;
  logic 	onoffx,onoffy;
  logic 	horizontal,verticle;
  
  integer i;
  // instantiate device under test
  fsm dut( clk, reset, up,down,left,right, onoffx, onoffy, horizontal, verticle );

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      
      reset = 0;
      
    end

  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {up,down,left,right} = 4'b0000;
	#20;
	#1; {up,down,left,right} = 4'b0001;
	#20;
	#1; {up,down,left,right} = 4'b0010;
	#20;
	#1; {up,down,left,right} = 4'b0100;
	#20;
      #1; {up,down,left,right} = 4'b1000;
	#20;
	#1; {up,down,left,right} = 4'b0100;
	#20;
	#1; {up,down,left,right} = 4'b0010;
	#20;
	#1; {up,down,left,right} = 4'b0001;
	#20;
     #1; {up,down,left,right} = 4'b0000;
	#20;
	#1; {up,down,left,right} = 4'b1000;
	#20;
	#1; {up,down,left,right} = 4'b0001;
	#20;
	#1; {up,down,left,right} = 4'b1000;
	#20;
      #1; {up,down,left,right} = 4'b0010;
	#20;
	#1; {up,down,left,right} = 4'b0001;
	#20;
//	#1; {up,down,left,right} = 4'b1110;
	#20;
//	#1; {up,down,left,right} = 4'b1111;
	#20;
	reset = 1'b1;
	#20;
	$stop;
    end


endmodule
