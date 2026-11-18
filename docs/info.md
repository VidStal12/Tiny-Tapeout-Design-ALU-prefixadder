<!---
This file is used to generate your project datasheet. Please fill in the information below and delete any unused sections.
-->

## How it works

This project implements an 8-bit Sequential Arithmetic Logic Unit (ALU) in SystemVerilog (`Top_ALU_secuencial`). It integrates a 3-stage Kogge-Stone parallel prefix adder (`prefix_adder`) for addition and two's complement subtraction, bitwise `AND`/`OR` logic units, a 4-stage pipelined unsigned divider (`divisor`) with clock-gating enable and division-by-zero protection, and an architectural condition-flag generator (`flags_nzcv`) producing Negative (`N`), Zero (`Z`), Carry (`C`), and Signed Overflow (`V`) flags.

 Input bus `ui_in[7:0]` loads 8-bit Operand A (`reg_a`) when `uio_in[0] = 0` and 8-bit Operand B (`reg_b`) when `uio_in[0] = 1`. The 3-bit control bus `uio_in[3:1]` selects the ALU operation (`000` = ADD, `001` = SUB, `010` = AND, `011` = OR, `101` = DIV quotient, `110` = REM remainder). The 8-bit registered result is output on `uo_out[7:0]` and the 4 status flags `{N, Z, C, V}` are output on `uio_out[7:4]`.

## How to test

1. Set `ena = 1`, `rst_n = 0`, `ui_in = 0`, and `uio_in = 0` for 5 clock cycles, then release reset (`rst_n = 1`).
2. Load Operand A by placing the 8-bit value on `ui_in[7:0]`, setting `uio_in[0] = 0`, and advancing 1 clock cycle.
3. Load Operand B and select the operation by placing the 8-bit value on `ui_in[7:0]`, setting `uio_in[0] = 1`, setting `uio_in[3:1]` to `alu_control[2:0]`, and advancing 1 clock cycle.
4. Wait 2 clock cycles for standard operations (`ADD`, `SUB`, `AND`, `OR`) or 5 clock cycles for pipelined division (`DIV`, `REM`), then read the 8-bit result on `uo_out[7:0]` and the `{N, Z, C, V}` flags on `uio_out[7:4]`.

## External hardware

No external hardware is required.