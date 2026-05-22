//Pipelines everything together
module Pipelining#(parameter PIXW = 8, 
                   parameter Output_Width = 32,
                   parameter K_size = 3, //size of kernel is 3x3
                   parameter Lb_size = 20
                   )(
                   input clk_50M,
                   input rst,
                   input master_start,
                   input WVALID1, WVALID2, WVALID3,WVALID4,
                   input [(K_size * K_size * PIXW)-1 : 0] weights,
                   input [(K_size * K_size * Output_Width)-1 : 0] bias,
                   input [PIXW-1:0] inp_pix1, inp_pix2, inp_pix3, inp_pix4,
                   output [Output_Width-1 : 0] out
    );
//-------------------------------
//----------Line Buffers--------
wire [(3*PIXW)-1:0] out_pix1, out_pix2, out_pix3, out_pix4;

Line_Buffer LB1 (.clk_50M(clk_50M), .rst(rst), .inp_pix(inp_pix1), .write_en(write_en1), .base_pos(base_pos), .out_pix(out_pix1));
Line_Buffer LB2 (.clk_50M(clk_50M), .rst(rst), .inp_pix(inp_pix2), .write_en(write_en2), .base_pos(base_pos), .out_pix(out_pix2));
Line_Buffer LB3 (.clk_50M(clk_50M), .rst(rst), .inp_pix(inp_pix3), .write_en(write_en3), .base_pos(base_pos), .out_pix(out_pix3));                 
Line_Buffer LB4 (.clk_50M(clk_50M), .rst(rst), .inp_pix(inp_pix4), .write_en(write_en4), .base_pos(base_pos), .out_pix(out_pix4));     

//------------------------------
//------AXI Controller---------
wire rd_start, write_en1, write_en2, write_en3, write_en4; 
wire [1:0] lb_state;

AXIController #(.PIXW(PIXW),. K_size(K_size), . LB_size(Lb_size)) axc(.clk_50M(clk_50M), .rst(rst), .WVALID1(WVALID1), .WVALID2(WVALID2), 
                  .WVALID3(WVALID3), .WVALID4(WVALID4),
                  .inp_pix1(inp_pix1), .inp_pix2(inp_pix2),
                  .inp_pix3(inp_pix3),.inp_pix4(inp_pix4),
                  .all_strides_done(all_strides_done), .master_start(master_start),
                  .rd_start(rd_start), .lb_state(lb_state),
                  .write_en1(write_en1),.write_en2(write_en2),
                  .write_en3(write_en3),.write_en4(write_en4));
                  
//--------------------------------
//-----------Read Controller------
wire vec_valid;
wire all_strides_done;
wire [4:0] base_pos;
wire [(K_size * K_size * PIXW)-1:0] ifMAP_flat;

ReadController #(.PIXW(PIXW),. K_size(K_size), . LB_size(Lb_size)) rdc (.clk_50M(clk_50M), .rst(rst), .rd_start(rd_start), .lb_state(lb_state),
                   .out_pix1(out_pix1), .out_pix2(out_pix2), .master_start(master_start),
                   .out_pix3(out_pix3),.out_pix4(out_pix4), .vec_done(vec_done),
                   .all_strides_done(all_strides_done), .base_pos(base_pos),
                   .ifMAP_flat(ifMAP_flat), .vec_valid(vec_valid));
                   
//--------------------------------------    
//--------Vector Engine----------------
wire vec_done;
Vector_Engine   #(.PIXW(PIXW),.Output_Width (Output_Width), .Kernel_size(K_size)) VE
                 (.clk_50M(clk_50M), .rst(rst), .en(vec_valid), .ifMAP_flat(ifMAP_flat),
                .weights(weights), .bias(bias), .out(out), .done(vec_done));
//-----------------------
endmodule
