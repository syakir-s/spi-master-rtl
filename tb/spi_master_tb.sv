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
logic [7:0] command_byte, address_byte, write_byte;
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

always @(negedge sclk)
    begin
        if (command_byte == 8'h0B && counter [4:3] == 2 && cs == 0)
            begin
                miso <= memory [address_byte][7 - counter [2:0]];
            end
    end
      
always @(posedge cs)
    begin
        if (command_byte == 8'h0A && counter [4:3] == 3) 
            begin
                memory [address_byte] <= write_byte; 
            end
    end          
always
    begin
        #5
        iclk = ~iclk;
    end
    
initial iclk = 0; 
initial
    begin 
        rst         = 1;
        start_spi   = 0;
        address_in  = 0;
        data_in     = 0;
        rw_in       = 0;
        miso        = 0;
        #20;
        rst         = 0;
        do_read(8'h00) ;    // T1 test read of DEVID_AD (0x00)                    
        if (command_byte !== 8'h0B) 
            begin 
                $error("T1 command_byte MISMATCH: expected_output =8'h0B actual_output =%h", command_byte);
            end
        else
            begin 
                $display("T1 command_byte PASS: output =8'h0B");
            end
         
         if (address_byte !== 8'h00)
            begin 
                $error("T1 address_byte MISMATCH: expected_output =8'h00 actual_output =%h", address_byte);
            end
        else
            begin 
                $display("T1 address_byte PASS: output =8'h00");
            end
              
        if (data_out !== 8'hAD)
            begin 
                $error("T1 data_out MISMATCH: expected_output =8'hAD actual_output =%h", data_out);
            end
        else
            begin 
                $display("T1 data_out PASS: output =8'hAD");                
            end
            
        do_write(8'h2C, 8'hAB ); // T2 test write 0xAB to 0x2C
        
        if (command_byte !== 8'h0A) 
            begin 
                $error("T2 command_byte MISMATCH: expected_output =8'h0A actual_output =%h", command_byte);
            end
        else
            begin 
                $display("T2 command_byte PASS: output =8'h0A");
            end   
        
        if (address_byte !== 8'h2C)
            begin 
                $error("T2 address_byte MISMATCH: expected_output =8'h2C actual_output =%h", address_byte);
            end
        else
            begin 
                $display("T2 address_byte PASS: output =8'h2C");
            end
                 
        if (data_out !== 8'hAD)
            begin 
                $error("T2 data_out MISMATCH: expected_output =8'hAD actual_output =%h", data_out);
            end
        else
            begin 
                $display("T2 data_out PASS: output =8'hAD");                
            end
                 
        if (write_byte !== 8'hAB)
            begin 
                $error("T2 write_byte MISMATCH: expected_output =8'hAB actual_output =%h", write_byte);
            end
        else
            begin 
                $display("T2 write_byte PASS: output =8'hAB");                
            end    
        
                if (memory[8'h2C] !== 8'hAB)
            begin 
                $error("T2 memory[8'h2C] MISMATCH: expected_output =8'hAB actual_output =%h", memory[8'h2C]);
            end
        else
            begin 
                $display("T2 memory[8'h2C] PASS: output =8'hAB");                
            end

         $finish;
         end  
           
task automatic do_read(input [7:0] addr); 
    @(posedge iclk);
        address_in  = addr;
        rw_in       = 0;
        #1;
        start_spi   = 1;
        @(posedge iclk); 
        #1;
        start_spi   = 0;
        @(negedge busy);        
    endtask
    
task automatic do_write(input [7:0] addr, input [7:0] scnd);
    @(posedge iclk);
        address_in  = addr;
        rw_in       = 1;
        data_in     = scnd; 
        #1;
        start_spi   = 1;
        @(posedge iclk); 
        #1;
        start_spi   = 0;
        @(negedge busy);
    endtask    
       
endmodule
