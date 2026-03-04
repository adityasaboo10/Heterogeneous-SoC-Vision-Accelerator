`timescale 1ns / 1ps

module PE #(parameter PIXW = 8, 
            parameter Output_Width = 32)(
            input clk, 
            input rst_n,
            input [PIXW-1 :0] a,
            input [PIXW-1 :0] b,
            input [Output_Width-1 :0] c,
            input en,
            output reg done,
            output reg [Output_Width-1 :0] out
    );
    
always @(posedge clk or negedge rst_n) begin
    if(!rst_n || !en) begin
        out <= 0;
        done <= 1'b0;
    end
    else begin
        out <= (a*b) + c;
        done <= 1'b1;
    end
end
endmodule
