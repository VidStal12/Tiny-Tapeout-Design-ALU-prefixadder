<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Explain how your project works

My project is an ALU type of hardware wich does an adding operation base on a prefixadder wich helps with performance by minimizing the amount of time a cycle has to budget for the specific action , the prefix adder is done via this part of the code wich generates and propagets the bit necesary when doing the addition ; by enabling a heirarchical tree , the adder can perform base on the amount just limited by the width of the bits :  

//Matriz para generar y propagar las señales
logic [ancho-1:0] g[estados:0];
logic [ancho-1:0] p[estados:0];
logic [ancho:0] c;
 
 //generacion y propagacion del bit
 always_comb begin 
    for(int i=0;i<ancho;i++) begin 
        g[0][i] = a[i]& b[i];
        p[0][i] = a[i]^ b[i];
        end 
 end
 
 //prefijos del sumador 
 generate
    for (genvar s =0;s<estados;s++)begin : gen_estados
    localparam int offset = (1<<s);
    always_comb begin
        for (int i =0;i<ancho;i++)begin 
            if (i>=offset) begin
                g[s+1][i]=g[s][i]|(p[s][i]&g[s][i-offset]);
                p[s+1][i]=p[s][i]&p[s][i-offset];
            end else begin
                g[s+1][i]=g[s][i];
                p[s+1][i]=p[s][i];
            end
        end
    end
end
endgenerate
[AI was used in corroborating this part]
Because Tiny Tapeout provides 8 dedicated input pins (`ui_in[7:0]`), a register-loading wrapper (`tt_um_alu_secuencial`) is used to capture the two 8-bit operands (`reg_a` and `reg_b`) before feeding `Top_ALU_secuencial`:
* **`ui_in[7:0]`**: 8-bit input data bus used to load Operand A or Operand B.
* **`uio_in[0]`**: Register select (`0` = load `ui_in` into `reg_a` on the rising clock edge; `1` = load `ui_in` into `reg_b` on the rising clock edge).
* **`uio_in[3:1]`**: 3-bit operation selector (`alu_control[2:0]`):
  * `000`: Addition (`A + B`) via Kogge-Stone prefix adder
  * `001`: Subtraction (`A - B`) in two's complement (`A + ~B + 1`)
  * `010`: Bitwise AND (`A & B`)[cite: 8, 14]
  * `011`: Bitwise OR (`A | B`)[cite: 8, 14]
  * `100`: Unused / Reserved (outputs `0x00`)
  * `101`: Unsigned Division Quotient (`A / B`) via 4-stage pipeline
  * `110`: Unsigned Division Remainder (`A % B`) via 4-stage pipeline
  * `111`: Clear / All zeros (`0x00`)
* **`uo_out[7:0]`**: 8-bit registered ALU result (`result[7:0]`).
* **`uio_out[7:4]`**: 4-bit registered status flags (`uio_out[7]` = `flag_n`, `uio_out[6]` = `flag_z`, `uio_out[5]` = `flag_c`, `uio_out[4]` = `flag_v`).

## How to test

Explain how to use your project

#### SET and Reset 
1. Set `ena = 1`, `ui_in = 0x00`, and `uio_in[3:0] = 0b0000`.
2. Pulse active-low reset (`rst_n = 0`) for at least 2 clock cycles, then release (`rst_n = 1`)[cite: 7, 15]. Verify that `uo_out = 0x00` and `uio_out[7:4] = 0b0000`.

[AI was used in corroborating this part]
##### Testing operation of the project 
1. **Cycle 1 (Load Operand A):** Place the 8-bit value of `A` on `ui_in[7:0]` and set `uio_in[0] = 0` (with `uio_in[3:1] = alu_control`). Advance 1 rising clock edge (`posedge clk`) so `reg_a` captures `A`.
2. **Cycle 2 (Load Operand B):** Place the 8-bit value of `B` on `ui_in[7:0]` and set `uio_in[0] = 1` while keeping `uio_in[3:1] = alu_control`. Advance 1 rising clock edge (`posedge clk`) so `reg_b` captures `B`.
3. **Wait for Pipeline Latency:**
   * **Standard Operations (`ADD`, `SUB`, `AND`, `OR` — `alu_control` = `000`, `001`, `010`, `011`):** Wait **2 clock cycles** after loading `B` (Cycle 1 latches `a_reg` and `b_reg` inside `Top_ALU_secuencial`; Cycle 2 latches the combinational result into the output registers `result` and `flag_n/z/c/v`)[cite: 7, 15].
   * **Division Operations (`DIV`, `REM` — `alu_control` = `101`, `110`):** Wait **5 clock cycles** after loading `B` (1 cycle for input registration + 3 cycles for the 4-stage internal divider pipeline `gen_div_pipe` + 1 cycle for output registration).
4. **Read Outputs:** Read the 8-bit result on `uo_out[7:0]` and the status flags `{N, Z, C, V}` on `uio_out[7:4]`.

[AI was used in corroborating this part]
#### Sample verification 
* **Addition (`alu_control = 000`):** Load `A = 50` (`0x32`), `B = 30` (`0x1E`). After 2 cycles, `uo_out = 80` (`0x50`) and `NZCV = 0000`.
* **Signed Overflow Addition (`alu_control = 000`):** Load `A = 127` (`0x7F`), `B = 1` (`0x01`). After 2 cycles, `uo_out = 128` (`0x80`) and `NZCV = 1001` (`N = 1`, `V = 1`).
* **Subtraction to Zero (`alu_control = 001`):** Load `A = 100` (`0x64`), `B = 100` (`0x64`). After 2 cycles, `uo_out = 0` (`0x00`) and `NZCV = 0110` (`Z = 1`, `C = 1`).
* **Division Quotient (`alu_control = 101`):** Load `A = 100` (`0x64`), `B = 30` (`0x1E`). After 5 cycles, `uo_out = 3` (`0x03`) and `NZCV = 0000`.
* **Division Remainder (`alu_control = 110`):** Load `A = 100` (`0x64`), `B = 30` (`0x1E`). After 5 cycles, `uo_out = 10` (`0x0A`) and `NZCV = 0000`.
* **Division by Zero Protection (`alu_control = 101` / `110`):** Load `A = 200` (`0xC8`), `B = 0` (`0x00`). Quotient (`101`) safely returns `0x00` (`Z = 1`), and Remainder (`110`) returns the dividend `200` (`0xC8`).

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any

There is no need of external hardware 