
module countertb();
  logic        clk, reset;
  logic        onoff, pm;
  logic [9:0]	 q;
  logic [1:0] vectornum;
  logic [1:0] testvectors[1:0];
  integer i;
  // instantiate device under test
  counter dut(clk,reset, onoff, pm, q);

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
  	reset = 1'b1; #200;
	reset = 1'b0;
    #1; {onoff, pm} = 2'b00;
	#200;
	#1; {onoff, pm} = 2'b01;
	#200;
	#1; {onoff, pm} = 2'b10;
reset = 1'b1; #200; reset = 1'b0;
	#200;
	#1; {onoff, pm} = 2'b11;
	#200;
	reset = 1'b1;
	#200;
	$stop;
    end


endmodule
