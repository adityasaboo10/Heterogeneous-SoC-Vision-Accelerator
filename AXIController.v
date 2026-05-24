module AXIController #(parameter PIXW = 8,parameter K_size = 3, parameter LB_size = 20)
                 (input clk_50M,
                  input rst,
                  input WVALID1, WVALID2, WVALID3,WVALID4,
                  input all_strides_done,
                  input master_start,
                  output reg rd_start, 
                  output reg [1:0] lb_state,
                  output wire write_en1, write_en2, write_en3, write_en4
                  );
//--------------------             
reg [4:0] counter;
//----------------------
//----Start State Param---
reg start_State;
localparam START = 1'b0;
localparam BTW = 1'b1;
//----------------------
//-----BTW state param----
localparam buf1 = 2'd0;
localparam buf2 = 2'd1;
localparam buf3 = 2'd2;
localparam buf4 = 2'd3;
//------------------------------
 reg WREADY1, WREADY2, WREADY3, WREADY4;
 //-------------------
 
 // Combinational write enables based on AXI handshake
assign write_en1 = WVALID1 && WREADY1;
assign write_en2 = WVALID2 && WREADY2;
assign write_en3 = WVALID3 && WREADY3;
assign write_en4 = WVALID4 && WREADY4;


always @(posedge clk_50M or negedge rst) begin
    if(!rst) begin
        rd_start    <= 1'b0;
        start_State <= START;
        lb_state    <= buf4;
        counter     <= 0;
        WREADY1     <= 1'b1;
        WREADY2     <= 1'b1;
        WREADY3     <= 1'b1;
        WREADY4     <= 1'b1;
    end 
    else if(!master_start) begin
    // IDLE 
    WREADY1   <= 1'b0;
    WREADY2   <= 1'b0;
    WREADY3   <= 1'b0;
    WREADY4   <= 1'b0;
    rd_start  <= 1'b0;
    end
    else begin
        case(start_State)
            START: begin
                WREADY1     <= 1'b1;
                WREADY2     <= 1'b1;
                WREADY3     <= 1'b1;
                WREADY4     <= 1'b1;
                if(counter < LB_size) begin
                    if(WVALID1 && WREADY1) begin
                        counter = counter + 1;
                    end
                   if(counter == K_size) rd_start <= 1'b1;  //for the first input counter is 1 then for second 2 thus for 3 valid pixels counter = 3
                    else rd_start <= 1'b0;
                end
                else begin
                    counter     <= 0;
                    start_State <= BTW;
                    lb_state <= buf1;
                    WREADY1     <= 1'b0;
                    WREADY2     <= 1'b0;
                    WREADY3     <= 1'b0;
                    WREADY4     <= 1'b0;
                end
            end
//----------------------------------
            BTW: begin
            rd_start <= 1'b0;  // add this at top of BTW case
                case(lb_state)
                    buf1: begin
                        WREADY1 <= 1'b1;
                        WREADY2 <= 1'b0;
                        WREADY3 <= 1'b0;
                        WREADY4 <= 1'b0;
                        if(counter < LB_size) begin
                            if(WVALID1) begin
                                counter   <= counter + 1;
                            end
                        end
                        else begin
                            WREADY1 <= 1'b0;
                            if(all_strides_done) begin
                                counter  <= 0;
                                lb_state <= buf2;
                            end
                        end
                    end
//--------------------------------
                    buf2: begin
                        WREADY1 <= 1'b0;
                        WREADY2 <= 1'b1;
                        WREADY3 <= 1'b0;
                        WREADY4 <= 1'b0;
                        if(counter < LB_size) begin
                            if(WVALID2) begin
                                counter   <= counter + 1;
                            end
                        end
                        else begin
                            WREADY2 <= 1'b0;
                            if(all_strides_done) begin
                                counter  <= 0;
                                lb_state <= buf3;
                            end
                        end
                    end
//-----------------------------
                    buf3: begin
                        WREADY1 <= 1'b0;
                        WREADY2 <= 1'b0;
                        WREADY3 <= 1'b1;
                        WREADY4 <= 1'b0;
                        if(counter < LB_size) begin
                            if(WVALID3) begin
                                counter   <= counter + 1;
                            end
                        end
                        else begin
                            WREADY3 <= 1'b0;
                            if(all_strides_done) begin
                                counter  <= 0;
                                lb_state <= buf4;
                            end
                        end
                    end
//----------------------------
                    buf4: begin
                        WREADY1 <= 1'b0;
                        WREADY2 <= 1'b0;
                        WREADY3 <= 1'b0;
                        WREADY4 <= 1'b1;
                        if(counter < LB_size) begin
                            if(WVALID4) begin
                                counter   <= counter + 1;
                            end
                        end
                        else begin
                            WREADY4 <= 1'b0;
                            if(all_strides_done) begin
                                counter  <= 0;
                                lb_state <= buf1;
                            end
                        end
                    end
                endcase
            end
        endcase
    end
end

endmodule
