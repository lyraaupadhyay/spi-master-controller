`timescale 1ns/1ps
module spi #(
    parameter DATA_WIDTH = 8,
    parameter COUNTER_WID = $clog2(DATA_WIDTH),
    parameter CLK_DIVIDER = 10 

)(
    input clk,
    input reset,
    input [DATA_WIDTH-1:0]tx_data,
    input miso,
    input start,
    input cpol,
    input cpha,
    output reg sclk,
    output reg  cs,
    output reg mosi,
    output reg [DATA_WIDTH-1:0]rx_data,
    output reg done,
    output reg busy
);
    
    reg [DATA_WIDTH-1:0]tx_shift_register;
    reg [DATA_WIDTH-1:0]rx_shift_register;
    reg [COUNTER_WID:0] bit_counter;
    reg [$clog2(CLK_DIVIDER)-1:0]clk_div_counter;
    reg sclk_register;
    reg prev_sclk_register;
    
    
    logic shift_edge;
    logic sample_edge;
    logic rising_edge;
    logic falling_edge;
    
    logic first_edge;
    logic second_edge;

    typedef enum logic [1:0]{
        IDLE,
        LOAD,
        TRANSFER,
        DONE
    }state_t;

    state_t current_state, next_state;

    //clk divider / sclk generator
    always@(posedge clk)begin
        if(reset)begin
            clk_div_counter <= 0;
            sclk_register <= cpol;
        end
        else if(current_state == TRANSFER) begin
            if(clk_div_counter == CLK_DIVIDER-1)begin
                clk_div_counter <= 0;
                sclk_register <= ~sclk_register;
            end
            else begin
                clk_div_counter <= clk_div_counter +1;
            end
        end
        else begin
           clk_div_counter <= 0;
           sclk_register <= cpol; 
        end
    end

    //edge detector
    always@(posedge clk)begin
        if(reset)begin
            prev_sclk_register <= cpol;
        end
        else begin
            prev_sclk_register <= sclk_register;
        end

    end
    assign rising_edge = ~prev_sclk_register & sclk_register;
    assign falling_edge = ~sclk_register & prev_sclk_register;

    always@(*)begin
        first_edge = 0;
        second_edge = 0;
        if(cpol == 1'b0)begin
            first_edge = rising_edge;
            second_edge = falling_edge;
        end
        else begin
            first_edge = falling_edge;
            second_edge = rising_edge;
        end
    end
    always@(*)begin
        sample_edge = 0;
        shift_edge = 0;
        if(cpha == 1'b0)begin
            sample_edge = first_edge;
            shift_edge = second_edge;
        end
        else begin
            shift_edge = first_edge;
            sample_edge = second_edge;
        end
    end

    //tx data path
    always@(posedge clk)begin
        if(reset)begin
            
            tx_shift_register <= 0;
            
        end
        else begin
            if(current_state == LOAD)begin
                tx_shift_register <= tx_data;
                
            end

            else if(current_state == TRANSFER)begin
                if(shift_edge)begin
                    tx_shift_register <= {tx_shift_register[DATA_WIDTH-2:0],1'b0};
                    
                end 
                
            end
            
        end
    end

    //rx data path
    always@(posedge clk)begin
        if(reset)begin
            rx_shift_register <= 0;
            rx_data <= 0;
            bit_counter <= 0;
        end
        else begin
            if(current_state == LOAD)begin
                rx_shift_register <= 0;
                bit_counter <= 0;
            end
            else if(current_state == TRANSFER)begin
                if(sample_edge)begin
                    rx_shift_register <= {rx_shift_register[DATA_WIDTH-2:0],miso};
                    bit_counter <= bit_counter + 1'b1;
                    
                    if(bit_counter == DATA_WIDTH-1)begin
                        rx_data <= {rx_shift_register[DATA_WIDTH-2:0], miso};
                    end
                end
            end
            
        end
            
    end

    
    

    // state register
    always@(posedge clk)begin
        if(reset)begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    //next state logic
    always@(*) begin
        next_state = current_state;
        case(current_state)
            IDLE:
            if(start)begin
                next_state = LOAD;
            end
            LOAD:
            next_state = TRANSFER;
            
            TRANSFER:
            if(sample_edge && bit_counter == DATA_WIDTH-1)begin
                next_state = DONE;
            end
            DONE:
            if(~start)begin
                next_state = IDLE;
             end
            
            default : next_state = IDLE;
        
        endcase
    end
    
    //output logic
    always@(*)begin
        case(current_state)
            IDLE:begin
                sclk = cpol;
                cs = 1;
                done = 0;
                busy = 0;
            end
            
            LOAD:begin
                sclk = cpol;
                cs = 0;
                done = 0;
                busy = 1;
            end
            
            TRANSFER:begin
                sclk = sclk_register;
                cs = 0;
                done = 0;
                busy = 1;
            end
           
            DONE:begin
                sclk = cpol;
                cs = 1;
                done =1;
                busy = 0;
            end
            
            default:begin
                sclk = cpol;
                cs = 1;
                done = 0;
                busy = 0;
            end
            
        
        endcase
        mosi = tx_shift_register[DATA_WIDTH-1];
    end
endmodule
