//After Enable is set high, delay of 1 clk we will get result on the second clk


`timescale 1ns / 1ps
//Each vector engine would get input pixels need for 1 convolution 

module Vector_Engine #(parameter PIXW = 8, 
                       parameter Output_Width = 32,
                       parameter Kernel_size = 3)(
                       input clk,
                       input rst_n,
                       input en,
                       // Total bits = (Number of Rows) * (Pixels per Row) * (Bits per Pixel)
                       // 0-7 first pixel then accrdingly
                       input [(Kernel_size * Kernel_size * PIXW)-1 : 0] ifMAP_flat,
                       input [(Kernel_size * Kernel_size * PIXW)-1 : 0] weights,
                       input [(Kernel_size * Kernel_size * Output_Width)-1 : 0] bias,
                       output reg [Output_Width-1 : 0] out
    );

//Wires to hold MAC ouputs 
wire [Output_Width-1 : 0] mac_outputs [0 : (Kernel_size*Kernel_size)-1];
wire done;
genvar row, col;

generate 
for( row = 0; row < Kernel_size; row=row+1) begin
    for(col = 0 ; col < Kernel_size; col = col+1)begin
    
    localparam integer idx = (row * Kernel_size) + col;
    
        PE#(
            .PIXW(PIXW),
            .Output_Width (Output_Width)
        ) u_pe (
            .clk(clk),
            .rst_n(rst_n),
            .a(ifMAP_flat[((idx+1)*PIXW)-1: idx*PIXW]),
            .b(weights[((idx+1)*PIXW)-1: idx*PIXW]),
            .c(bias[((idx+1)*Output_Width)-1: idx*Output_Width]),
            .en(en),
            .done(done),
            .out( mac_outputs[idx])
                );
    end
end
endgenerate

reg [Output_Width-1 : 0] temp_sum;
integer idx;
always @(*) begin
 if(done) begin
    temp_sum = 0; 
    
    // Loop through however many MACs you have based on Kernel_size
    for (idx = 0; idx < (Kernel_size * Kernel_size); idx = idx + 1) begin
        // Note: Use blocking assignment (=) in combinational logic
        temp_sum = temp_sum + mac_outputs[idx];
    end
    end
    else begin
        temp_sum <= 0;
    end
end
always @(posedge clk or negedge rst_n)begin
    if(!rst_n) out <= 0;
    else begin 
    out <= temp_sum;    
    
    end


end
endmodule
