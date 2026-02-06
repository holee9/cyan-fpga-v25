//-----------------------------------------------------------------------------
// Module: fifo_1b
// Description: Single-clock synchronous FIFO with configurable data width
//              and depth. Uses distributed RAM for storage. Provides
//              standard FIFO signals (full, empty) and supports concurrent
//              read/write operations.
//
// Features:
//   - Configurable data width and depth
//   - Distributed RAM storage (inferred)
//   - Registered read data output
//   - Full/empty status flags
//   - Simultaneous read/write support
//
// Author: CYAN-FPGA Team
// Company: DRK Technologies
// Creation Date: 2025-01-15
// Version: 1.0
//
// Parameters:
//   - DATA_WIDTH: Width of data bus (default: 8)
//   - DEPTH: FIFO depth in entries (default: 16, must be power of 2)
//
// Ports:
//   Inputs:
//     - rst: Reset signal (active-high)
//     - clk: Clock signal
//     - wr_en: Write enable
//     - rd_en: Read enable
//     - din: Data input
//   Outputs:
//     - dout: Data output (registered)
//     - full: FIFO full flag
//     - empty: FIFO empty flag
//
// Revision History:
//   1.0 (2025-01-15) - Initial creation
//-----------------------------------------------------------------------------

module fifo_1b #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
) (
    input  logic                  rst,
    input  logic                  clk,
    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] din,
    output logic [DATA_WIDTH-1:0] dout,
    output logic                  full,
    output logic                  empty
);

    (* ram_style = "distributed" *)
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [$clog2(DEPTH):0] wr_ptr, rd_ptr, count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    logic wr_en_internal, rd_en_internal;
    assign wr_en_internal = wr_en && !full;
    assign rd_en_internal = rd_en && !empty;

    // Memory write (no reset needed for RAM)
    always_ff @(posedge clk) begin
        if (wr_en_internal) begin
            mem[wr_ptr] <= din;
        end
    end

    // Pointer and count management
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end else begin
            case ({wr_en_internal, rd_en_internal})
                2'b10: begin  // write only
                    wr_ptr <= wr_ptr + 1'b1;
                    count  <= count + 1'b1;
                end
                2'b01: begin  // read only
                    rd_ptr <= rd_ptr + 1'b1;
                    count  <= count - 1'b1;
                end
                2'b11: begin  // simultaneous read/write
                    wr_ptr <= wr_ptr + 1'b1;
                    rd_ptr <= rd_ptr + 1'b1;
                    // count unchanged
                end
            endcase
        end
    end

    // Read data output
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= '0;
        end else if (rd_en_internal) begin
            dout <= mem[rd_ptr];
        end
    end

endmodule
