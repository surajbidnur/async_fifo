module async_fifo_tb();

reg        rd_clk, wr_clk, initb;                          // Declaring the clocks and reset signals
reg  [7:0] data_in;                                        // The data input
reg        write_en, read_en;                              // The write and read enable signals
reg        rand1;                                          // Random number 1 controls the read and write
reg  [7:0] rand2;                                          // Random number 2 is the data to be pushed into fifo
reg  [7:0] transctr;                                       // Keeps track of the number of push and pop in fifo
wire [7:0] data_out;                                       // Output data
wire       overflow, underflow;                            // The fifo status signals

always #47  wr_clk = !wr_clk;                              // Generating the write clock
always #143 rd_clk = !rd_clk;                              // Generating the read clock

initial begin //{                                          // Initializing the inputs to 0
  rd_clk   = 0;
  wr_clk   = 0;
  write_en = 0;
  read_en  = 0;
  initb    = 0;
  transctr = 7'b0;
  
  repeat (10) @(posedge wr_clk);
  initb = 1;                                               // De-asserting reset after some time
  
  repeat (10) @(posedge rd_clk);
  repeat (10) @(posedge wr_clk);
  
  while (transctr != 8'h60) begin //{                      // Setting the total number of push and pop operations
    rand1 = $random;                                       // If rand1 = 1, then push data else pop
    rand2 = $random;                                       // Data to be pushed
    if (rand1) begin //{                                   // rand1 = 1, push
      Tk_push(rand2);                                      // Add data to fifo
      transctr <= transctr + 1'b1;                         // Increment transaction counter
    end //}
    else begin //{                                         // rand1 = 0, pop
      Tk_pop();                                            // Read data from fifo
      transctr <= transctr + 1'b1;                         // Increment transaction counter
    end //}
  end //}
  Tk_pop();
  Tk_pop();
  Tk_pop();
  Tk_pop();
  Tk_pop();
  Tk_pop();
  $stop;
end //} 

async_fifo dut(                                            // Instance the dut
  .wr_clk(wr_clk),
  .rd_clk(rd_clk),
  .initb(initb),
  .data_in(data_in),
  .write_en(write_en),
  .read_en(read_en),
  .data_out(data_out),
  .overflow(overflow),
  .underflow(underflow)
);

task Tk_push;                                              // Task performs addition of data to fifo
input [7:0] data;
begin //{
  repeat (10) @(posedge wr_clk);
  @(posedge wr_clk) begin write_en = 1; data_in = data; end
  @(posedge wr_clk) write_en = 0;
  repeat (10) @(posedge wr_clk);
end //}
endtask

task Tk_pop;                                               // Task performs deletion/reading data from fifo
begin //{
  repeat (10) @(posedge rd_clk);
  @(posedge rd_clk) read_en = 1;
  @(posedge rd_clk) read_en = 0;
  repeat (10) @(posedge rd_clk);
end //}
endtask

endmodule
