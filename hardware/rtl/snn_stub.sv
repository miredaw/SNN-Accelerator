`timescale 1ns / 1ps

module snn_stub (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Stream slave: receives AER events from DMA (via width converter)
    input  logic [31:0] s_axis_tdata,
    input  logic        s_axis_tvalid,
    output logic        s_axis_tready,
    input  logic        s_axis_tlast,

    // AXI4-Stream master: sends processed AER events to DMA (S2MM)
    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic        m_axis_tlast,

    // CSR-driven configuration (from csr_block)
    input  logic [15:0] cfg_mask,    // XOR mask applied to address field
    input  logic [7:0]  cfg_delay,   // future: pipeline delay in cycles

    // Status signal back to CSR / interrupt
    output logic        done         // high for one cycle after burst completes
);

    // -- Unpack input AER packet ------------------------------------------
    logic [15:0] in_address, in_timestamp;
    assign in_address   = s_axis_tdata[15:0];
    assign in_timestamp = s_axis_tdata[31:16];

    // -- Transform: XOR address with configurable mask --------------------
    // This is verifiable: output addr = input addr XOR cfg_mask
    logic [15:0] out_address;
    assign out_address = in_address ^ cfg_mask;

    // -- Pass-through with transform --------------------------------------
    // Stub is combinationally transparent; backpressure from output side
    // propagates directly to input side via tready.
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tdata  = {in_timestamp, out_address};
    assign m_axis_tvalid = s_axis_tvalid;
    assign m_axis_tlast  = s_axis_tlast;  // propagate burst end marker

    // -- Done pulse: one cycle after last event is output -----------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            done <= 1'b0;
        else
            // done when the last event of the burst is accepted by downstream
            done <= s_axis_tvalid && s_axis_tready && s_axis_tlast;
    end

endmodule