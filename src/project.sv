module tt_um_alu_secuencial (
    input  wire [7:0] ui_in,    // 8-bit operand input bus (A or B)
    output wire [7:0] uo_out,   // 8-bit ALU result output bus
    input  wire [7:0] uio_in,   // Control inputs on uio_in[3:0]
    output wire [7:0] uio_out,  // NZCV flags on uio_out[7:4]
    output wire [7:0] uio_oe,   // 1 = Output (uio[7:4]), 0 = Input (uio[3:0])
    input  wire       ena,      // Design enable (always 1 when powered)
    input  wire       clk,      // System clock
    input  wire       rst_n     // Active-low asynchronous reset
);

    // Configure uio[7:4] as outputs for {flag_n, flag_z, flag_c, flag_v}
    // Configure uio[3:0] as inputs for {alu_control[2:0], reg_sel}
    assign uio_oe       = 8'b1111_0000;
    assign uio_out[3:0] = 4'b0000;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] reg_a;
    logic [WIDTH-1:0] reg_b;
    logic [2:0]       alu_ctrl;

    // uio_in[0]   : 0 = Write ui_in to reg_a, 1 = Write ui_in to reg_b
    // uio_in[3:1] : alu_control[2:0] (000=ADD, 001=SUB, 010=AND, 011=OR, 101=DIV, 110=REM)
    assign alu_ctrl = uio_in[3:1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= '0;
            reg_b <= '0;
        end else if (ena) begin
            if (uio_in[0] == 1'b0) begin
                reg_a <= ui_in;
            end else begin
                reg_b <= ui_in;
            end
        end
    end

    logic [WIDTH-1:0] alu_result;
    logic             flag_n, flag_z, flag_c, flag_v;

    Top_ALU_secuencial #(
        .width(WIDTH)
    ) u_top_alu_seq (
        .clk         (clk),
        .rst_n       (rst_n),
        .a           (reg_a),
        .b           (reg_b),
        .alu_control (alu_ctrl),
        .result      (alu_result),
        .flag_n      (flag_n),
        .flag_z      (flag_z),
        .flag_c      (flag_c),
        .flag_v      (flag_v)
    );

    assign uo_out       = alu_result;
    assign uio_out[7:4] = {flag_n, flag_z, flag_c, flag_v};

    // Prevent unused signal warnings on uio_in[7:4]
    wire _unused = &{ena, uio_in[7:4], 1'b0};

endmodule