// File        : maclaurin_box.v
// Author      : P. Athanas
// Date        : 9/8/16
// Version     : 1
// Description : This is the model of the 'maclaurin_box' design.  This
//               instances the necessary operation to calculate the Maclaurin
//               series for ln() function.
//               ---------------------
//               Insert your model
//               ---------------------

module maclaurin_box(
      // These signal names are a litle odd, but intended to match those from
      // QSYS
		input 	      clk_clk, //   clk.clk
		input 	      reset_reset_n, // reset.reset_n
		input [31:0]  x_export, //     x.export -- input
		input 	      start_export, // start.export -- inputvi
		output [31:0] ln_export, // root1.export-- output
		output [1:0]  status_export   //  status.export-- output
);
   
   reg  done;
   wire error;
   //assign done = 1'b1; // ERROR: NEED A REAL THING HERE
   //assign error = ~(~x_export[1] & (~x_export[2] | ~x_export[8]));
   assign status_export = {done, error};

   reg [5:0] count, next_count;
   //assign done = ((count > 6'd32) | error) ? 1'b1 : 1'b0;

   reg [2:0] state, next_state;
   parameter WAITING = 3'b001, READING_X = 3'b010, CALCULATING = 3'b100;

   wire [31:0] ln_result;
   assign ln_export = ln_result;
   
   maclaurin_box_combinational my_combinational(.clk_clk(clk_clk), .reset_reset_n(reset_reset_n), .x_export(x_export), .ln_export(ln_result), .error(error));
    
   always@(posedge clk_clk) begin
      if (~reset_reset_n) begin
	 state <= WAITING;
	 count <= 6'd0;
	 // error <= 1'b0; ????
      end
      else begin
	 state <= next_state;
	 count <= next_count;
      end
   end

   always @(state or start_export or count) begin
      next_state <= 3'b000;
      next_count <= 6'd0;
      case (state)
	WAITING: begin 
	   done <= 1'b1;
	   if (start_export == 1)
	      next_state <= READING_X;
	   else
	     next_state <= WAITING;
	end
	READING_X: begin
	   next_state <= CALCULATING;
	   done <= 1'b0;
	   next_count <= 6'd0;
	end
	CALCULATING: begin
	   next_count <= count + 1;
	   if (count == 6'd34) begin
	      next_state <= WAITING;
	   end
	   else
	     next_state <= CALCULATING;
	end
      endcase // case (state)
   end // always @ (state)
   
endmodule
