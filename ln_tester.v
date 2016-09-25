// File: ln_tester.v
// Author: P. Athanas
// Date: 2/8/2016
// Description: This test instances a student's Device Under Test (DUT) as a working 
// circuit.  The test proceeds as follows: the {a,b,c} inputs are set to numbers and 
// start is asserted.  New values are presented every clock cycle.  
// The results are compared (within a tolerance).  If a mismatch occurs, an error 
// count is incremented.  

`define VALCNT 140
`define ITERATIONS 2000 /* Number of iterations to run the test */
`define MAXCOMPTIME 1000  /* Max number of clock cycles to compute one iteration */

`timescale 1ns/1ns

module ln_tester();
  	 
   reg [31:0] x;  // x value input (32-bit floating point)
   reg clk;       // Free-running clock
   reg reset_n;   // Active-low synchronous reset
   reg start;     // True when data valid on input

   // Signals that are produced by the device-under-test circuit:
   wire signed [31:0] ln;
   wire done;
   wire error;

   integer testcount;
   reg rc;
   integer i;
   integer waitcount;
   integer errorcount;

   // Instance the Design Under Test
   maclaurin_box u1 (
      .clk_clk(clk),
      .reset_reset_n(reset_n),
      .start_export(start),
      .x_export(x),
      .ln_export(ln),
      .status_export( {done, error} ) );

   // Generate a free-running clock:
   initial begin
      clk = 1;
      forever #500 clk = !clk;
   end

   // Write block
   initial begin
      // Synchronous reset
      errorcount = 0;
      start = 0;
      reset_n = 0;
      @(posedge clk);
      reset_n = 1;
      @(posedge clk);
      @(posedge clk);

      // Assert START
      start = 1;
      waitcount = 0;
      while (done == 1) begin
         @(posedge clk);
         waitcount = waitcount + 1;
         if (waitcount == `MAXCOMPTIME) begin
            $display("Error: done for DUT never arrived. Quitting.");
            $finish();
         end
      end
      // Done is now 0.  Feed in values.
      for (i=0; i<`VALCNT; i=i+1) begin
         $getValues(x);
         @(posedge clk);
      end
      $display("All inputs submitted to DUT, negating START, waitiing for pipe to empty.");
      start = 0;
   end

   // Read block
   initial begin
      // Initialize
      testcount = 0;
      @(posedge clk);
      // Wait for start to go
      while (start == 0) begin
         @(posedge clk);
         // Is DONE properly initialized?
         if ((done === 1'bx) || (done === 1'bz)) begin
            $display("\n#################################################################");
            $display("DONE is not initialized to 0.  Your system must use RESET_N to initialize the logic that generates this signal.");
            $display("\n#################################################################");
            $finish();
         end
      end
      // Wait for pipeline to flush
      while (done == 0) @(posedge clk);
      // Pipeline now producing results
      while (done == 1) begin
         $checkResults(ln, error, testcount, rc);
         if (rc) begin
            errorcount = errorcount + 1;
            $display("Mismatch #%3d on test vector %3d at time=%8d ln=0x%x, err=%1d", 
               errorcount, testcount,$time, ln, error);
         end
         // Give it a clock
         @(posedge clk);
         testcount = testcount + 1;
      end
      $display("\n#################################################################");
      if (errorcount > 0) begin
         $display("Finished %4d tests, %4d errors detected.", testcount, errorcount);
      end
      else begin
         $display("Finished %4d tests.  Congratulations -- no errors detected.", testcount);
      end
      $display("#################################################################\n");
      $finish();
   end

endmodule
