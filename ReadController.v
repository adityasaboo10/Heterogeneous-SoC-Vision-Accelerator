module ReadController#(parameter PIXW = 8,parameter K_size = 3, parameter LB_size = 20)
                 (input clk_50M,
                  input rst,
                  input rd_start,  //axi controller
                  input [1:0] lb_state, //from AXI controller
                  input [(3*PIXW)-1:0] out_pix1, out_pix2, out_pix3, out_pix4,  //from line buffers
                  input      vec_done, // -> done signal from vector engine
                  input master_start,
                  output reg all_strides_done,
                  output reg [4:0] base_pos,
                  output reg [(K_size * K_size * PIXW)-1:0] ifMAP_flat,  //output to vec engine
                  output vec_valid  //-> to en of vector engine
                  );

//-----------------------
localparam buf1 = 2'd0;
localparam buf2 = 2'd1;
localparam buf3 = 2'd2;
localparam buf4 = 2'd3;

//-----------------
reg [4:0] rd_counter;
reg reading_active;  //set high when rd_Start is high

assign vec_valid = (rst && master_start)? (reading_active) : 0 ;

always @(posedge clk_50M or negedge rst) begin
if(!rst) begin
    base_pos <= 0;
    all_strides_done <= 0;
    rd_counter <= 0;
    reading_active <= 0;
    ifMAP_flat <= 0;
end
else if(!master_start) begin
    base_pos         <= 0;
    all_strides_done <= 0;
    rd_counter       <= 0;
    reading_active   <= 0;
    ifMAP_flat       <= 0;
end
else begin
    all_strides_done <= 1'b0;

    if(reading_active) begin
        if(rd_counter < LB_size - K_size) begin
            base_pos   <= base_pos + 1;
            rd_counter <= rd_counter + 1;
        end
        else begin
                all_strides_done <= 1'b1;
                rd_counter       <= 0;
                base_pos         <= 0;
                reading_active   <= 1'b0;
        end
    end
    end
end

always @(*) begin
    if(rd_start) reading_active <= 1;
    ifMAP_flat <= 0;
    case(lb_state)
        buf1: ifMAP_flat <= {out_pix2, out_pix3, out_pix4};
        buf2: ifMAP_flat <= {out_pix3, out_pix4, out_pix1};
        buf3: ifMAP_flat <= {out_pix4, out_pix1, out_pix2};
        buf4: ifMAP_flat <= {out_pix1, out_pix2, out_pix3};
    endcase
end
endmodule
