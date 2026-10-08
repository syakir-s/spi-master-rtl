`timescale 1ns / 1ps

module spi_master_tb;

logic iclk;
logic [7:0] address_in;
logic [7:0] data_in;
logic rw_in;
logic miso;
logic rst;
logic start_spi;
logic cs; 
logic mosi;
logic sclk;
logic [7:0] data_out;
logic busy;

spi_master dut(
    .iclk(iclk),
    .address_in(address_in),
    .data_in(data_in),
    .rw_in(rw_in),
    .miso(miso),
    .rst(rst),
    .start_spi(start_spi),
    .cs(cs),
    .mosi(mosi),
    .sclk(sclk),
    .data_out(data_out),
    .busy(busy)
);
 
logic [4:0] counter;
logic [7:0] command_byte, address_byte, write_byte, read_byte;
logic [7:0] memory [0:63];

initial 
    begin
        for (int i = 0; i < 64 ;i++)
            memory [i]       = 8'h00;
        memory [8'h00]   = 8'hAD; 
        memory [8'h02]   = 8'hF2;
        memory [8'h2C]   = 8'h13;
    end  
    
always @(negedge cs)
    begin
        counter <= 0;
    end

always @(posedge sclk) 
    begin
       if (cs == 0)
        begin
            counter <= counter + 1; 
            case (counter [4:3]) 
                    2'd0    : command_byte [7 - counter[2:0]]   <= mosi; 
                    2'd1    : address_byte [7 - counter[2:0]]   <= mosi;
                    2'd2    : write_byte [7 - counter[2:0]]     <= mosi; 
                endcase
        end
    end   
endmodule
