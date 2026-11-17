`timescale 1ns / 1ps

module testbench_Top_ALU_secuencial;

    localparam int ancho = 8;

    //Testbench
    logic             clk;
    logic             rst_n;
    logic [ancho-1:0] a;
    logic [ancho-1:0] b;
    logic [2:0]       alu_control;

    logic [ancho-1:0] result;
    logic             flag_n;
    logic             flag_z;
    logic             flag_c;
    logic             flag_v;

    int pass_count = 0;
    int fail_count = 0;

    // Instancia
    Top_ALU_secuencial #(
        .width(ancho)
    ) uut (
        .clk         (clk),
        .rst_n       (rst_n),
        .a           (a),
        .b           (b),
        .alu_control (alu_control),
        .result      (result),
        .flag_n      (flag_n),
        .flag_z      (flag_z),
        .flag_c      (flag_c),
        .flag_v      (flag_v)
    );

    // Período = 10 ns (Frecuencia = 100 MHz)
    always #5 clk = ~clk;

    //
    initial begin
        $fsdbDumpfile("dump_alu.fsdb");
        $fsdbDumpvars(0, testbench_Top_ALU_secuencial, "+all");
    end

    // Pipeline 
    task automatic run_test(
        input string            test_name,
        input logic [ancho-1:0] in_a,
        input logic [ancho-1:0] in_b,
        input logic [2:0]       in_ctrl,
        input logic [ancho-1:0] exp_res,
        input logic             exp_n,
        input logic             exp_z,
        input logic             exp_c,
        input logic             exp_v
    );
        @(negedge clk);
        a           = in_a;
        b           = in_b;
        alu_control = in_ctrl;

        // Ciclo 1: Los registros de entrada capturan el dato
        @(posedge clk);

        // Si la operación es División (101 o 110), esperar los 3 ciclos del pipeline interno
        if (in_ctrl == 3'b101 || in_ctrl == 3'b110) begin
            repeat (3) @(posedge clk);
        end

        // Ciclo Final: Los registros de salida (result, flags) capturan la respuesta
        @(posedge clk);
        #1;

        if (result === exp_res &&
            flag_n === exp_n   &&
            flag_z === exp_z   &&
            flag_c === exp_c   &&
            flag_v === exp_v) begin
            $display("[PASS] %-28s | Ctrl=%b | A=0x%04h B=0x%04h | Res=0x%04h | NZCV=%b%b%b%b",
                     test_name, in_ctrl, in_a, in_b, result, flag_n, flag_z, flag_c, flag_v);
            pass_count++;
        end else begin
            $display("[FAIL] %-28s | Ctrl=%b | A=0x%04h B=0x%04h | Obtenido: Res=0x%04h NZCV=%b%b%b%b | Esperado: Res=0x%04h NZCV=%b%b%b%b",
                     test_name, in_ctrl, in_a, in_b, result, flag_n, flag_z, flag_c, flag_v,
                     exp_res, exp_n, exp_z, exp_c, exp_v);
            fail_count++;
        end
    endtask

    // Secuencia Principal de Pruebas
    initial begin
        clk         = 1'b0;
        rst_n       = 1'b0;
        a           = '0;
        b           = '0;
        alu_control = 3'b000;

        // Liberar Reset
        #15;
        rst_n = 1'b1;
        @(posedge clk);

        // SAIF final
        $set_toggle_region(testbench_Top_ALU_secuencial.uut);
        $toggle_start();

        $display(" verificacion de (8 BITS) en ALU");

        // 1. OPERACION SUMA (000)
        run_test("ADD Basica",             8'd50,   8'd30,   3'b000, 8'd80,   1'b0, 1'b0, 1'b0, 1'b0);
        run_test("ADD Carry & Zero",       8'hFF,   8'h01,   3'b000, 8'h00,   1'b0, 1'b1, 1'b1, 1'b0);
        run_test("ADD Signed Overflow",    8'h7F,   8'h01,   3'b000, 8'h80,   1'b1, 1'b0, 1'b0, 1'b1);

        // 2. OPERACION RESTA (001)
        run_test("SUB Positiva",           8'd100,  8'd35,   3'b001, 8'd65,   1'b0, 1'b0, 1'b1, 1'b0);
        run_test("SUB Resultado Cero",     8'hAB,   8'hAB,   3'b001, 8'h00,   1'b0, 1'b1, 1'b1, 1'b0);
        run_test("SUB Resultado Negativo", 8'd10,   8'd30,   3'b001, 8'hEC,   1'b1, 1'b0, 1'b0, 1'b0);
        run_test("SUB Signed Overflow",    8'h80,   8'h01,   3'b001, 8'h7F,   1'b0, 1'b0, 1'b1, 1'b1);

        // 3. OPERACIONES LOGICAS: AND (010) y OR (011)
        run_test("AND Bit a Bit",          8'hF0,   8'h3C,   3'b010, 8'h30,   1'b0, 1'b0, 1'b0, 1'b0);
        run_test("AND Resultado Cero",     8'hAA,   8'h55,   3'b010, 8'h00,   1'b0, 1'b1, 1'b0, 1'b0);
        run_test("OR Bit a Bit",           8'hF0,   8'h0F,   3'b011, 8'hFF,   1'b1, 1'b0, 1'b0, 1'b0);

        // 4. OPERACION MULTIPLICADOR NO USADA (100)
        run_test("MUL Slot (No usado)",    8'd25,   8'd4,    3'b100, 8'h00,   1'b0, 1'b1, 1'b0, 1'b0);

        // 5. OPERACION DIVISOR: COCIENTE (101) y RESIDUO (110)
        run_test("DIV Cociente Exacto/In", 8'd100,  8'd30,   3'b101, 8'd3,    1'b0, 1'b0, 1'b0, 1'b0);
        run_test("DIV Residuo",            8'd100,  8'd30,   3'b110, 8'd10,   1'b0, 1'b0, 1'b0, 1'b0);
        run_test("DIV Rango Maximo Coc",   8'hFF,   8'd15,   3'b101, 8'd17,   1'b0, 1'b0, 1'b0, 1'b0);
        run_test("DIV Rango Maximo Res",   8'hFF,   8'd15,   3'b110, 8'd0,    1'b0, 1'b1, 1'b0, 1'b0);
        run_test("DIV Por Cero Cociente",  8'd200,  8'd0,    3'b101, 8'd0,    1'b0, 1'b1, 1'b0, 1'b0);
        run_test("DIV Por Cero Residuo",   8'd200,  8'd0,    3'b110, 8'd200,  1'b0, 1'b0, 1'b0, 1'b0);

        // 6. OPERACION TODOS EN CERO (111)
        run_test("ALL ZEROS (111)",        8'hFF,   8'hFF,   3'b111, 8'h00,   1'b0, 1'b1, 1'b0, 1'b0);

        // 7. RAFAGA ALEATORIA
        for (int i = 0; i < 64; i++) begin
            @(negedge clk);
            a           = $urandom_range(0, 8'hFF);
            b           = $urandom_range(1, 8'hFF);
            alu_control = i[2:0];
            @(posedge clk);
        end
        repeat (5) @(posedge clk);


        // CIERRE Y REPORTE SAIF
        $toggle_stop();
        $toggle_report("alu_secuencial.saif", 1.0e-9, testbench_Top_ALU_secuencial.uut);

        $display(" RESUMEN FINAL: %0d Pruebas Exitosas (PASS) | %0d Pruebas Fallidas (FAIL)", pass_count, fail_count);
        $display(" Archivos 'alu_secuencial.saif' y 'dump_alu.fsdb' generados correctamente.");

        #20;
        $finish;
    end

endmodule
