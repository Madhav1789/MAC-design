`timescale 1ns/1ps

module tb;

// Inputs
reg clk;
reg rst;
reg start;

reg [7:0] data_in_0;
reg [7:0] data_in_1;

reg [7:0] weight_in_0;
reg [7:0] weight_in_1;

// Outputs
wire [15:0] out_00, out_01, out_10, out_11;
wire done;

// Instantiate TOP module
top uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .data_in_0(data_in_0),
    .data_in_1(data_in_1),
    .weight_in_0(weight_in_0),
    .weight_in_1(weight_in_1),
    .out_00(out_00),
    .out_01(out_01),
    .out_10(out_10),
    .out_11(out_11),
    .done(done)
);

// Clock generation (10ns period)
always #5 clk = ~clk;

// Dump waveform
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
end

// Stimulus
initial begin
    $display("Time\t d0 d1 w0 w1 | o00 o01 o10 o11 done");
    $monitor("%0t\t %d %d %d %d | %d %d %d %d %b",
        $time, data_in_0, data_in_1, weight_in_0, weight_in_1,
        out_00, out_01, out_10, out_11, done);

    // Initialize
    clk = 0;
    rst = 1;
    start = 0;

    data_in_0 = 0;
    data_in_1 = 0;
    weight_in_0 = 0;
    weight_in_1 = 0;

    #10 rst = 0;

    // Start operation
    #10 start = 1;
    #10 start = 0;

    // Apply inputs (cycle by cycle)
    #10 data_in_0 = 1; data_in_1 = 2; weight_in_0 = 1; weight_in_1 = 2;
    #10 data_in_0 = 3; data_in_1 = 4; weight_in_0 = 3; weight_in_1 = 4;
    #10 data_in_0 = 5; data_in_1 = 6; weight_in_0 = 5; weight_in_1 = 6;
    #10 data_in_0 = 7; data_in_1 = 8; weight_in_0 = 7; weight_in_1 = 8;

    // wait for computation to complete
    #100;

    $finish;
end

endmodule
