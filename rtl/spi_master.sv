`timescale 1ns / 1ps

module spi_master (
input logic iclk,
input logic [7:0] address_in,
input logic [7:0] data_in,
input logic rw_in,
input logic miso,
input logic rst,
input  logic start_spi,
output logic cs, 
output logic mosi,
output logic sclk,    
output logic [7:0] data_out,
output logic busy
);

logic [1:0] hold_cnt;
logic [7:0] instruction_reg;
logic [2:0] bit_counter;
logic [3:0] clk_cnt;
logic [7:0] address_reg;
logic [7:0] data_reg;
logic rw_reg;

typedef enum logic [2:0]{
IDLE,
INSTRUCTION,
ADDRESS,
DATA,
HOLD,
DISABLE
} state_t;
state_t current_state, next_state;

always_ff @(posedge iclk)
begin  
 
    if (rst == 1) 
    begin
        clk_cnt <= 0;
        sclk <= 0;
    end
    
    else if (cs == 1 || current_state == HOLD) 
    begin
        clk_cnt <= 0;
        sclk <= 0;       
    end
    
    else if (clk_cnt == 9) 
    begin
        sclk <=~ sclk;
        clk_cnt <= 0;  
    end
    
    else
    begin 
        clk_cnt <= clk_cnt +1;  
    end
    
end 

always_ff @(posedge iclk)
begin  
    if (rst == 1)
    begin
        current_state <= IDLE;
    end
    else
    begin 
        current_state <= next_state;
    end
end

always_comb 
begin
    next_state = current_state;
    case (current_state)
        IDLE        : next_state = (start_spi) ? INSTRUCTION : IDLE;
        INSTRUCTION : next_state = (bit_counter == 7 && clk_cnt == 9 && sclk) ? ADDRESS : INSTRUCTION;  
        ADDRESS     : next_state = (bit_counter == 7 && clk_cnt == 9 && sclk) ? DATA : ADDRESS;
        DATA        : next_state = (bit_counter == 7 && clk_cnt == 9 && sclk) ? HOLD : DATA;
        HOLD        : next_state = (hold_cnt == 2) ? DISABLE : HOLD;
        DISABLE     : next_state = (hold_cnt == 2) ? IDLE : DISABLE;
        default     : next_state = IDLE;
endcase        
end

always_ff @(posedge iclk)
begin 
    if (rst)
        begin
             hold_cnt <= 0;
        end
    else if (hold_cnt == 2)
        begin
             hold_cnt <= 0;
        end
    else if (current_state != HOLD && current_state != DISABLE)
        begin
             hold_cnt <= 0;
        end
    else
        begin 
            hold_cnt <= hold_cnt +1;
        end
end

always_ff @(posedge iclk)
begin 
        if (rst)
            begin
               bit_counter <= 0; 
            end
        else if (current_state == IDLE)
            begin
                bit_counter <= 0;
            end        
        else if (clk_cnt == 9 && sclk)
            begin
                bit_counter <= bit_counter + 1; 
            end        
end

always_ff @(posedge iclk)
begin
    if (rst) 
        begin
            instruction_reg <= 0;
            rw_reg <= 0;
            address_reg <= 0;
            data_reg <= 0;              
        end
    else if (start_spi && current_state == IDLE)
        begin
            instruction_reg  <= rw_in == 0 ? 8'h0B: 8'h0A;
            rw_reg <= rw_in;
            address_reg <= address_in;
            data_reg <= data_in; 
        end
end

always_comb 
begin
    case (current_state)
        IDLE        : mosi = 1;
        INSTRUCTION : mosi = instruction_reg [7 - bit_counter];
        ADDRESS     : mosi = address_reg [7 - bit_counter];
        DATA        : mosi = rw_reg == 0 ? 1 : data_reg [7 - bit_counter]; 
        HOLD        : mosi = 1; 
        DISABLE     : mosi = 1;
        default     : mosi = 1;
endcase
end

always_ff @(posedge iclk)
begin
    if(rst)
        begin
            data_out <= 8'hFF; 
        end
    else if (current_state == DATA && rw_reg == 0 && clk_cnt == 9 && !sclk)
        begin 
            data_out [7 - bit_counter] <= miso; 
        end 
end 

assign cs = (current_state == IDLE || current_state == DISABLE) ? 1:0; 
assign busy = current_state != IDLE ? 1:0;

endmodule

