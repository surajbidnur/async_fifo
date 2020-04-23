`define WORDSIZE 8                                         // Size of input data
`define PTR_SIZE 3                                         // Size of fifo pointer
`define QSIZE 8                                            // Size of fifo

module async_fifo(
  input                      wr_clk, rd_clk,               // Read clock to read data and write clock to write data
  input                      initb,                        // Active low aynchronous reset
  input      [`WORDSIZE-1:0] data_in,                      // Input data
  input                      write_en, read_en,            // Write and read control signals
  output reg [`WORDSIZE-1:0] data_out,                     // Output data after reading from fifo
  output reg                 overflow, underflow           // Fifo full and empty signals
);

reg  [`PTR_SIZE:0] rd_ptr, wr_ptr;                         // read and write pointers with 1 extra bit
reg  [`QSIZE-1:0]  qdata [`WORDSIZE-1:0];                  // Declaring the fifo memory
reg  [`PTR_SIZE:0] sync1_rd, sync2_rd, sync1_wr, sync2_wr; // The flops used for synchronizing the read and write pointers
wire [`PTR_SIZE:0] rd_ptr_gray, wr_ptr_gray;               // Gray converted read and write pointers
wire               qfull, qempty;                          // Fifo full and empty status wires

integer file1, file2;                                      // Write and read file descriptors

function [`PTR_SIZE:0] bin2gray;                           // Function to convert binary to gray code
input [`PTR_SIZE:0] ptr;                                   // Input is the pointer
begin //{
  bin2gray = ptr ^ (ptr >> 1);
end //}
endfunction

assign rd_ptr_gray = bin2gray(rd_ptr);                     // Read pointer in gray code
assign wr_ptr_gray = bin2gray(wr_ptr);                     // Write pointer in gray code

// This is to generate the full signal
// Fifo is full when the wr ptr wraps around and points to the rd ptr i.e MSB of rd ptr and wr ptr are different (gray code values)
// Since we are using one extra bit, the second last bit of both the pointers should be different and the rest of the bits should be the same
assign qfull  = ((sync2_rd[`PTR_SIZE]     != rd_ptr_gray[`PTR_SIZE]) &&
                 (sync2_rd[`PTR_SIZE-1]   != rd_ptr_gray[`PTR_SIZE-1]) &&
                 (sync2_rd[`PTR_SIZE-2:0] == rd_ptr_gray[`PTR_SIZE-2:0])) ? 1'b1 : 1'b0;

// When the read pointer catches up to or is the same as the write pointer then fifo empty
assign qempty = (sync2_wr[`PTR_SIZE:0] == wr_ptr_gray[`PTR_SIZE:0]) ? 1'b1 : 1'b0;

initial begin                                              // These set of statements to open the 2 files
// synthesis translate_off
file1 = $fopen("C:\\Users\\admin\\Documents\\Verilog_Proj\\Altera\\async_fifo\\writedata.text","w");
file2 = $fopen("C:\\Users\\admin\\Documents\\Verilog_Proj\\Altera\\async_fifo\\readdata.text","w");
// synthesis translate_on
end

// To write the data in the write clock domain
// Overflow signal set here
always @(posedge wr_clk or negedge initb) begin //{
  if (!initb) begin //{
    wr_ptr   <= `PTR_SIZE'b0;                              // Resetting the write pointer to 0
    overflow <= qfull;                                     // Setting overflow
  end //}
  else begin //{
    if (write_en) begin //{                                // If write enable signal is 1 then write to fifo
      if (!qfull) begin //{                                // Before writing check if fifo has space
        qdata[wr_ptr[`PTR_SIZE-1:0]] <= data_in;           // Add data to the location pointed by the wr ptr
        wr_ptr                       <= wr_ptr + 1'b1;     // Increment wr ptr to point to next location
        overflow                     <= qfull;             // Overflow gets value of qfull signal
        // synthesis translate_off
        $fwrite(file1,"%h\n",data_in);                     // Write the data to the file
        // synthesis translate_on
      
	  end //}
      else begin //{
        overflow <= qfull;                                 // If fifo full set overflow and do nothing else
      end //}
    end //}
  end //}
end //}

// To read the data in the read clock domain
// Underflow signal set here
always @(posedge rd_clk or negedge initb) begin //{
  if (!initb) begin //{
    data_out  <= `WORDSIZE'b0;                             // Reset the output to 0
    rd_ptr    <= `PTR_SIZE'b0;                             // Reset rea pointer to 0
    underflow <= qempty;                                   // Set underflow
  end //}
  else begin //{
    if (read_en) begin //{                                 // If read enable signal is 1, then only read data
      if (!qempty) begin //{                               // Check if fifo is empty
        data_out  <= qdata[rd_ptr[`PTR_SIZE-1:0]];         // Read the data pointed by the read pointer
        rd_ptr    <= rd_ptr + 1'b1;                        // Increment the read pointer
        underflow <= qempty;                               // Set undeflow
        // synthesis translate_off
        $fwrite(file2,"%h\n",qdata[rd_ptr[`PTR_SIZE-1:0]]);// Write the data read to file
        // synthesis translate_on
	  end //}
      else begin //{
        underflow <= qempty;                               // Set underflow
      end //}
    end //}
  end //}
end //}

// write pointer(gray) gets synchronized in the read clock domain
always @(posedge rd_clk) begin //{
  sync1_rd <= wr_ptr_gray;
  sync2_rd <= sync1_rd;
end //}

// read pointer(gray) gets synchronized in the write clock domain
always @(posedge wr_clk) begin //{
  sync1_wr <= rd_ptr_gray;
  sync2_wr <= sync1_wr;
end //}

endmodule
