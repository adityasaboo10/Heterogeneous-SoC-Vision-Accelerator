`timescale 1ns / 1ps



`timescale 1ns / 1ps

module AXI_DMA_test();
localparam PIXW         = 8;
localparam Output_Width = 32;
localparam K_size       = 3;
localparam LB_size      = 20;

reg clk_50M, rst, master_start;
reg [(K_size*K_size*PIXW)-1:0]         weights;
reg [(K_size*K_size*Output_Width)-1:0] bias;
reg [PIXW-1:0] s_axis_tdata;
reg s_axis_tvalid, s_axis_tlast;
wire s_axis_tready;
wire [Output_Width-1:0] out;

reg [Output_Width-1:0] out_capture [0:LB_size-1];
integer capture_idx;
integer i;

Pipelining #(.PIXW(PIXW), .Output_Width(Output_Width),
             .K_size(K_size), .Lb_size(LB_size)) uut
    (.clk_50M(clk_50M), .rst(rst), .master_start(master_start),
     .s_axis_tdata(s_axis_tdata), .s_axis_tvalid(s_axis_tvalid),
     .s_axis_tlast(s_axis_tlast), .s_axis_tready(s_axis_tready),
     .weights(weights), .bias(bias), .out(out));

always #10 clk_50M = ~clk_50M;

// capture outputs
always @(posedge clk_50M) begin
    #1;
    if(out !== 0 && out !== out_capture[capture_idx]) begin
        out_capture[capture_idx] <= out;
        capture_idx <= capture_idx + 1;
    end
end

initial begin
    clk_50M       = 0;
    rst           = 0;
    master_start  = 0;
    s_axis_tdata  = 0;
    s_axis_tvalid = 0;
    s_axis_tlast  = 0;
    capture_idx   = 0;

    weights = {9{8'd1}};
    bias    = 0;

    // release reset
    repeat(2) @(posedge clk_50M); #1;
    rst = 1;

    // assert master_start
    @(posedge clk_50M); #1;
    master_start = 1;

    @(posedge clk_50M); #1;

    // send all 4 rows sequentially
    // row0: 1..20, row1: 21..40, row2: 41..60, row3: 61..80
    // tlast only on very last pixel
    for(i = 0; i < LB_size * 4; i = i + 1) begin
        // wait for tready with #1 after clock edge
        @(posedge clk_50M); #1;
        while(!s_axis_tready) begin
            @(posedge clk_50M); #1;
        end
        s_axis_tdata  = i + 1;
        s_axis_tvalid = 1'b1;
        s_axis_tlast  = (i == LB_size * 4 - 1) ? 1'b1 : 1'b0;
    end

    // deassert after last pixel
    @(posedge clk_50M); #1;
    s_axis_tvalid = 1'b0;
    s_axis_tlast  = 1'b0;
    s_axis_tdata  = 0;

    // wait for all convolution outputs to come through
    repeat(100) @(posedge clk_50M); #1;

    $display("--- Convolution Outputs ---");
    for(i = 0; i < capture_idx; i = i + 1)
        $display("Output[%0d] = %0d", i, out_capture[i]);

    $finish;
end

endmodule
