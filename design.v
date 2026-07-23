module top (
    input clk,
    input rst,
    input start,

    input  [7:0] data_in_0,
    input  [7:0] data_in_1,

    input  [7:0] weight_in_0,
    input  [7:0] weight_in_1,

    output [15:0] out_00,
    output [15:0] out_01,
    output [15:0] out_10,
    output [15:0] out_11,

    output done
);

    wire enable;

    // Controller
    controller ctrl (
        .clk(clk),
        .rst(rst),
        .start(start),
        .enable(enable),
        .done(done)
    );

    // Systolic Array
    systolic_array_2x2 sa (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in_0(data_in_0),
        .data_in_1(data_in_1),
        .weight_in_0(weight_in_0),
        .weight_in_1(weight_in_1),
        .out_00(out_00),
        .out_01(out_01),
        .out_10(out_10),
        .out_11(out_11)
    );

endmodule

module pe (
    input clk,
    input rst,
    input enable,

    input  [7:0] in_data,
    input  [7:0] in_weight,

    output reg [7:0]  out_data,
    output reg [7:0]  out_weight,
    output reg [15:0] out_psum
);

    // Internal registers
    reg [7:0]  data_reg;
    reg [7:0]  weight_reg;
    reg [15:0] psum_reg;

    // Multiplier output
    wire [15:0] mult;

    assign mult = data_reg * weight_reg;

    always @(posedge clk) begin
        if (rst) begin
            data_reg   <= 8'd0;
            weight_reg <= 8'd0;
            psum_reg   <= 16'd0;

            out_data   <= 8'd0;
            out_weight <= 8'd0;
            out_psum   <= 16'd0;

        end else if (enable) begin
            // Latch inputs
            data_reg   <= in_data;
            weight_reg <= in_weight;

            // MAC operation
            psum_reg <= psum_reg + mult;

            // Forward to next PE
            out_data   <= data_reg;
            out_weight <= weight_reg;

            // Output accumulated result
            out_psum   <= psum_reg;
        end
    end

endmodule

module systolic_array_2x2 (
    input clk,
    input rst,
    input enable,

    input  [7:0] data_in_0,
    input  [7:0] data_in_1,

    input  [7:0] weight_in_0,
    input  [7:0] weight_in_1,

    output [15:0] out_00,
    output [15:0] out_01,
    output [15:0] out_10,
    output [15:0] out_11
);

    // Internal wires for connections
    wire [7:0] d00_to_01;
    wire [7:0] d10_to_11;

    wire [7:0] w00_to_10;
    wire [7:0] w01_to_11;

    // PE00
    pe PE00 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .in_data(data_in_0),
        .in_weight(weight_in_0),
        .out_data(d00_to_01),
        .out_weight(w00_to_10),
        .out_psum(out_00)
    );

    // PE01
    pe PE01 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .in_data(d00_to_01),
        .in_weight(weight_in_1),
        .out_data(), // no further PE
        .out_weight(w01_to_11),
        .out_psum(out_01)
    );

    // PE10
    pe PE10 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .in_data(data_in_1),
        .in_weight(w00_to_10),
        .out_data(d10_to_11),
        .out_weight(),
        .out_psum(out_10)
    );

    // PE11
    pe PE11 (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .in_data(d10_to_11),
        .in_weight(w01_to_11),
        .out_data(),
        .out_weight(),
        .out_psum(out_11)
    );

endmodule

module controller (
    input clk,
    input rst,
    input start,

    output reg enable,
    output reg done
);

    reg [1:0] state;
    reg [2:0] count;  // can count up to 7

    parameter IDLE    = 2'b00;
    parameter LOAD    = 2'b01;
    parameter COMPUTE = 2'b10;
    parameter DONE    = 2'b11;

    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            count  <= 0;
            enable <= 0;
            done   <= 0;
        end else begin
            case (state)

                IDLE: begin
                    enable <= 0;
                    done   <= 0;
                    count  <= 0;
                    if (start)
                        state <= LOAD;
                end

                LOAD: begin
                    enable <= 0;
                    count  <= 0;
                    state  <= COMPUTE;
                end

                COMPUTE: begin
                    enable <= 1;
                    count  <= count + 1;

                    if (count == 4)  // total 5 cycles: 0,1,2,3,4
                        state <= DONE;
                end

                DONE: begin
                    enable <= 0;
                    done   <= 1;
                    state  <= IDLE;
                end

            endcase
        end
    end

endmodule 


