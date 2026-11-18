`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.10.2026 11:08:45
// Design Name: 
// Module Name: prefix_adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////                


module divisor #(
    parameter ancho = 8
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,       // activar Clock Gating
    input  logic [ancho-1:0] a,
    input  logic [ancho-1:0] b,
    output logic [ancho-1:0] cociente,
    output logic [ancho-1:0] residuo
);

    localparam int STAGES         = 4;
    localparam int BITS_PER_STAGE = ancho / STAGES;

    logic [ancho-1:0] a_pipe [0:STAGES-1];
    logic [ancho-1:0] b_pipe [0:STAGES-1];
    logic [ancho-1:0] q_comb [0:STAGES-1];
    logic [ancho:0]   r_comb [0:STAGES-1];

    logic [ancho-1:0] q_reg  [0:STAGES-2];
    logic [ancho:0]   r_reg  [0:STAGES-2];

    genvar s;
    generate
        for (s = 0; s < STAGES; s = s + 1) begin : gen_div_pipe
            localparam int HIGH_BIT = ancho - 1 - (s * BITS_PER_STAGE);
            localparam int LOW_BIT  = ancho - ((s + 1) * BITS_PER_STAGE);

            logic [ancho-1:0] a_in;
            logic [ancho-1:0] b_in;
            logic [ancho-1:0] q_temp;
            logic [ancho:0]   r_temp;
            logic [ancho:0]   diff;

            always_comb begin

                if (s == 0) begin
                    a_in   = a;
                    b_in   = b;
                    q_temp = '0;
                    r_temp = '0;
                end else begin
                    a_in   = a_pipe[s-1];
                    b_in   = b_pipe[s-1];
                    q_temp = q_reg[s-1];
                    r_temp = r_reg[s-1];
                end

                diff = '0;

                if (b_in == '0) begin
                    q_temp = '0;
                    r_temp = {1'b0, a_in};
                end else begin
                    for (int i = HIGH_BIT; i >= LOW_BIT; i = i - 1) begin
                        r_temp = {r_temp[ancho-1:0], a_in[i]};
                        diff   = r_temp - {1'b0, b_in};

                        if (~diff[ancho]) begin
                            r_temp    = {1'b0, diff[ancho-1:0]};
                            q_temp[i] = 1'b1;
                        end else begin
                            q_temp[i] = 1'b0;
                        end
                    end
                end

                q_comb[s] = q_temp;
                r_comb[s] = r_temp;
            end

            // Clock Gating
            if (s < STAGES - 1) begin : gen_pipe_regs
                always_ff @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        a_pipe[s] <= '0;
                        b_pipe[s] <= '0;
                        q_reg[s]  <= '0;
                        r_reg[s]  <= '0;
                    end else if (en) begin 
                        a_pipe[s] <= (s == 0) ? a : a_pipe[s-1];
                        b_pipe[s] <= (s == 0) ? b : b_pipe[s-1];
                        q_reg[s]  <= q_comb[s];
                        r_reg[s]  <= r_comb[s];
                    end
                end
            end
        end
    endgenerate

    assign cociente = q_comb[STAGES-1];
    assign residuo  = r_comb[STAGES-1][ancho-1:0];

endmodule
