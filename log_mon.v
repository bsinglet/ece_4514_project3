// File        : log_mon.v
// Author      : P. Athanas
// Date        : 8/28/16
// Version     : 0.0
// Description : This model provides stimulus to the maclaurin_box model,
//               and records the results into memory.  The test values
//               are summarized in this spreadsheet: https://goo.gl/g10kFM 

// Define state bindings:
`define ST_IDLE   0
`define ST_START  1
`define ST_WAIT1  2
`define ST_WAIT2  3
`define ST_DONE   4

// Define the maximum number of states:
`define MAXTEST   12
module log_mon (  // These signals interface directly to the maclaurin_box
   input clk,
   input reset_n,
   output [31:0] x,
   input [31:0] ln,
   output reg start,
   input [1:0] status );

   reg [5:0] count;           // Determines which test currently active
   reg [31:0] stimuli;        // The actual stimulus pattern used
   reg [32:0] expected;       // The expected response from the given stim
   reg [32:0] results[0:31];  // The results produced by DUT
   reg [3:0] state;           // State vector for FSM
   reg [31:0] runtime;        // Cycle counter -- time taken to compute

   wire done;

   assign done = status[1];
   assign error = status[0];

   // This is a behavioral model of a ROM for the stimulus and expected
   // results:
   always@(count) begin
      case (count )
         5'd0: begin  // -1.2
            stimuli = 32'hbf99999a;
            expected = {1'b1, 32'hc060c5a8}; // {error, expected value}
         end
         5'd1: begin   // -1.0
            stimuli = 32'hbf800000;
            expected = {1'b0, 32'hc0122222};
         end
         5'd2: begin   // -0.8
            stimuli = 32'hbf4ccccd;
            expected = {1'b0, 32'hbfbab37e};
         end
         5'd3: begin   // -0.6
            stimuli = 32'hbf19999a;
            expected = {1'b0, 32'hbf666341};
         end
         5'd4: begin   // -0.4
            stimuli = 32'hbecccccd;
            expected = {1'b0, 32'hbf02c578};
         end
         5'd5: begin   // -0.2
            stimuli = 32'hbe4ccccd;
            expected = {1'b0, 32'hbf028108};
         end
         5'd6: begin   // 0.0
            stimuli = 32'h00000000;
            expected = {1'b0, 32'h00000000};
         end
         5'd7: begin   // 0.2
            stimuli = 32'h3e4ccccd;
            expected = {1'b0, 32'h3e3ab4e4};
         end
         5'd8: begin   // 0.4
            stimuli = 32'h3ecccccd;
            expected = {1'b0, 32'h3eac88d1};
         end
         5'd9: begin   // 0.6
            stimuli = 32'h3f19999a;
            expected = {1'b0, 32'h3ef3471f};
         end
         5'd10: begin   // 0.8
            stimuli = 32'h3f4ccccd;
            expected = {1'b0, 32'h3f1d222c};
         end
         5'd11: begin   // 1.0
            stimuli = 32'h3f800000;
            expected = {1'b0, 32'h3f488889};
         end
         5'd12: begin   // 1.2
            stimuli = 32'h3f99999a;
            expected = {1'b1, 32'h3f848388};
         end
         default: begin
            $display("Count=%d", count);
            stimuli = 32'hdeadbeef;
            expected = {1'b1, 32'hbabecafe};
         end
      endcase
   end

   // This is the FSM that controls the test:
   always@(posedge clk) begin
      if (reset_n == 0) begin
         start <= 0;
         count <= 0;
         state <= `ST_IDLE;
         runtime <= 32'd0;
      end
      else begin
         case(state) 
            // Default initial state
            `ST_IDLE: begin
                   if (done == 1'b1) state <= `ST_START;
               end
            // This state produces a start pulse for the DUT
            `ST_START: begin
                   start <= 1'b1;
                   state <= `ST_WAIT1;
               end
            // Waiting for the results, part 1
            `ST_WAIT1: begin
                  if (done == 0) begin
                     state <= `ST_WAIT2;
                     start <= 1'b0;
                     runtime <= runtime + 32'd1;
                  end
               end
            // Waiting for the results, part 2, capture the answer
            `ST_WAIT2: begin
                  if (done == 1) begin 
                     results[count] <= {error, ln};
                     state <= `ST_DONE;
                     // The following statement will obviously not synthesize:
                     $display("Test %d: Input value = 0x%x, received 0x%x error=%b, expected [0x%x - %b]",
                        count + 1, stimuli, ln, error, expected[31:0], expected[32]);
                  end
                  runtime <= runtime + 32'd1;
               end
            // Finalize things, and prepare to do it again if needed
            `ST_DONE: begin
                  if (count < `MAXTEST) begin
                     state <= `ST_IDLE;
                     count <= count + 6'b1;
                  end
                  else begin
                     results[15] <= runtime;
                     $display("Execution complete: runtime (cycles) = %d", runtime);
                  end
               end
            default:
               state <= `ST_IDLE;
         endcase
      end
   end

   assign x = stimuli;
endmodule
    

