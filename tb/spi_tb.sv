`timescale 1ns/1ps
module spi_tb;
    parameter DATA_WIDTH = 4'd8;
    parameter  CLK_PERIOD = 10;
    logic clk;
    logic reset;
    logic cs;
    logic [DATA_WIDTH-1:0]tx_data;
    logic mosi;
    logic miso;
    logic [DATA_WIDTH-1:0]rx_data;
    logic done;
    logic busy;
    logic sclk;
    logic start;
    logic cpol;
    logic cpha;

    spi #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut(
        .clk(clk),
        .reset(reset),
        .cs(cs),
        .tx_data(tx_data),
        .mosi(mosi),
        .miso(miso),
        .rx_data(rx_data),
        .done(done),
        .busy(busy),
        .sclk(sclk),
        .start(start),
        .cpol(cpol),
        .cpha(cpha)
    );

    
    

    always #(CLK_PERIOD/2) clk = ~clk;

    task apply_reset;
        tx_data = 0;
        miso = 0;
        start = 0;
        cpol = 0;
        cpha = 0;

        reset = 1;
        repeat(2)@(posedge clk);
        reset = 0;
        @(posedge clk);
        $display("[%0t] Reset complete.", $time);
    endtask

    
    integer i;
    
    integer test_count = 0;
    task spi_transfer(
        input logic [DATA_WIDTH-1:0]master_byte,
        input logic [DATA_WIDTH-1:0]slave_byte);
        
        wait(~busy);
        
        @(posedge clk);
        
        tx_data = master_byte;
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(busy);
        
        if(cpha == 0)begin
            miso = slave_byte[DATA_WIDTH-1];
            for(i= DATA_WIDTH-2;i>=0;i=i-1)begin
                wait_edge;
                miso = slave_byte[i];
            end
        end
        else begin
            for(i=DATA_WIDTH-1;i>=0;i=i-1)begin
                wait_edge;
                miso = slave_byte[i];
            end
        end

        
        @(posedge done);
        

        @(posedge clk);

       
        $display("[%0t] Transfer complete.", $time);
        test_count = test_count +1;
    endtask

    task wait_edge;
        if(cpha^cpol)begin
            @(posedge sclk);

        end
        else begin
            @(negedge sclk);
        end
    endtask

    integer pass_count = 0;
    integer fail_count = 0;
    task check_result(input logic [DATA_WIDTH-1:0]slave_byte);
        if(slave_byte === rx_data)begin
          $display("[%0t] PASS ", $time); 
          $display("MASTER TX = %0h   SLAVE TX = %0h   MASTER RX = %0h",tx_data,slave_byte,rx_data);
          pass_count = pass_count +1; 
          
        end
        else begin
            $display("[%0t] FAIL ", $time); 
            $display("MASTER TX = %0h   SLAVE TX = %0h    MASTER RX = %0h",tx_data,slave_byte,rx_data);
            fail_count = fail_count +1;
        end
    endtask

    logic [DATA_WIDTH-1:0] random_master;
    logic [DATA_WIDTH-1:0] random_slave;
    
    initial begin
        clk = 0;
        apply_reset();
        cpol = 0;
        cpha = 0;
        $display("Calling transfer 1");
        spi_transfer(8'b10011010,  8'b11001001);
        
        check_result(8'b11001001);
        
        cpol = 0;
        cpha = 1;
        $display("Calling transfer 2");
        spi_transfer(8'h00, 8'hFF);
        
        check_result(8'hFF);
        
        cpol = 1;
        cpha = 0;
        spi_transfer(8'hFF, 8'h00);
        
        check_result(8'h00);
        
        cpol = 1;
        cpha = 1;
        spi_transfer(8'hAA, 8'h55);
        
        check_result(8'h55);
        

        repeat(20) begin
           random_master = $urandom();
           random_slave = $urandom();

           spi_transfer(random_master, random_slave);
           
           check_result(random_slave);
           
 
        end

        

        
        @(posedge clk);
        $display("TEST CASES = %0d     PASSED = %0d     FAILED = %0d",test_count,pass_count,fail_count);
        $finish;
    end
endmodule
