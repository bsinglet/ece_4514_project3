// File        : maclaurin_box_combination.v
// Author      : Benjamin Singleton
// Date        : 9/20/16
// Version     : 1
// Description : This is the combinational logic 'maclaurin_box' design.  This
//               instances the IP cores and regiser delays for the operation. At
//               this level, operations run continuously. The state machine up on
//               the maclaurin_box.v layer determine when the outputs of this
//               module are valid.

//`timescale 1ns/100ps
module maclaurin_box_combinational(
      // These signal names are a litle odd, but intended to match those from
      // QSYS
		input 	      clk_clk, //   clk.clk
		input 	      reset_reset_n, // reset.reset_n
		input [31:0]  x_export, //     x.export -- input
		output [31:0] ln_export, // root1.export-- output
		output 	      error
);

   // 32-bit floating point constants
   wire [31:0] one_third, one_fourth, one_fifth, two;

   assign one_third = 32'h3eaaaaab;
   assign one_fourth = 32'h3e800000;
   assign one_fifth = 32'h3e4ccccd;
   assign two = 32'h40000000;
   
   // intermediate values
   wire [31:0] x_squared, x_cubed, x_quintic, x_third, x_fourth, x_fifth, x_two;
   wire [31:0] positive_x_sum, x_negatives, x_minus;

   // registers for delaying propagation
   reg [31:0]  r1 [2:0];
   reg [31:0]  r2 [5:0];
   reg [31:0]  r3 [3:0];
   reg [31:0]  r4 [5:0];
   integer     i;
   
   //assign done = 1'b1; // ERROR: NEED A REAL THING HERE
   assign error = ~(~x_export[1] & (~x_export[2] | ~x_export[8]));

   reg [5:0] count;
   
   always@(posedge clk_clk) begin
      if (~reset_reset_n) begin
	 //r1 = {96{1'b0}};
	 //r2 = {192{1'b0}};
	 //r3 = {128{1'b0}};
	 //r4 = {192{1'b0}};
      end
      else begin
	    r1[0] = x_fourth;
	    r2[0] = x_third;
	    r3[0] = x_minus;
	    r4[0] = x_squared;
	    for (i = 1; i < 6; i = i + 1) begin
	       r2[i] = r2[i-1];
	       r4[i] = r4[i-1];
	    end
	    for (i = 1; i < 3; i = i + 1) begin
	       r1[i] = r1[i-1];
	    end
	    for (i = 1; i < 4; i = i + 1) begin
	       r3[i] = r3[i-1];
	    end
      end // else: !if(~reset_reset_n)
   end // always@ (posedge clk_clk)
   
   // instantiations of the multipliers and adders
   altfp_mult mult0 (.clock ( clk_clk ),
		     .dataa ( x_export ),
		     .datab ( x_export ),
		     .result ( x_squared ));

   altfp_mult mult1 (.clock ( clk_clk ),
		     .dataa ( x_squared ),
		     .datab ( x_export ),
		     .result ( x_cubed ));

   altfp_mult mult2 (.clock ( clk_clk ),
		     .dataa ( x_cubed ),
		     .datab ( one_third ),
		     .result ( x_third ));

   altfp_mult mult3 (.clock ( clk_clk ),
		     .dataa ( x_cubed ),
		     .datab ( r4[5] ),
		     .result ( x_quintic ));

   altfp_mult mult4 (.clock ( clk_clk ),
		     .dataa ( x_quintic ),
		     .datab ( one_fifth ),
		     .result ( x_fifth ));

   altfp_add add0 (.clock ( clk_clk ),
		     .dataa ( r2[5] ),
		     .datab ( x_fifth ),
		     .result ( positive_x_sum ));

   // right-hand branch of diagram
   altfp_mult mult5 (.clock ( clk_clk ),
		     .dataa ( x_squared ),
		     .datab ( one_fourth ),
		     .result ( x_fourth ));

   altfp_add add1 (.clock ( clk_clk ),
		     .dataa ( two ),
		     .datab ( x_squared ),
		     .result ( x_two ));

   altfp_mult mult6 (.clock ( clk_clk ),
		     .dataa ( r1[2] ),
		     .datab ( x_two ),
		     .result ( x_negatives ));

   altfp_sub sub0 (.clock ( clk_clk ),
		   .dataa ( x_export ), // need register here???
		   .datab ( x_negatives ),
		   .result ( x_minus ));

   altfp_add add2 (.clock ( clk_clk ),
		   .dataa ( positive_x_sum ),
		   .datab ( r3[3] ),
		   .result ( ln_export ));
   
endmodule // maclaurin_box_combinational

