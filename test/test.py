import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

async def run_alu_op(dut, a_val, b_val, ctrl):
    # Cycle 1: Load Operand A (uio_in[0] = 0)
    dut.ui_in.value = a_val
    dut.uio_in.value = (ctrl << 1) | 0
    await ClockCycles(dut.clk, 1)

    # Cycle 2: Load Operand B (uio_in[0] = 1) and set alu_control
    dut.ui_in.value = b_val
    dut.uio_in.value = (ctrl << 1) | 1
    await ClockCycles(dut.clk, 1)

    # Wait for pipeline registers (3 cycles for ADD/SUB/AND/OR, 6 cycles for DIV/REM)
    wait_cycles = 6 if ctrl in (5, 6) else 3
    await ClockCycles(dut.clk, wait_cycles)

    res = int(dut.uo_out.value)
    flags = (int(dut.uio_out.value) >> 4) & 0xF
    return res, flags

@cocotb.test()
async def test_project(dut):
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    # 1. ADD (000): 50 + 30 = 80
    res, _ = await run_alu_op(dut, 50, 30, 0b000)
    assert res == 80, f"ADD failed: got {res}, expected 80"

    # 2. SUB (001): 100 - 35 = 65
    res, _ = await run_alu_op(dut, 100, 35, 0b001)
    assert res == 65, f"SUB failed: got {res}, expected 65"

    # 3. AND (010): 0xF0 & 0x3C = 0x30
    res, _ = await run_alu_op(dut, 0xF0, 0x3C, 0b010)
    assert res == 0x30, f"AND failed: got {res}, expected 0x30"

    # 4. DIV Quotient (101): 100 / 30 = 3
    res, _ = await run_alu_op(dut, 100, 30, 0b101)
    assert res == 3, f"DIV failed: got {res}, expected 3"

    # 5. DIV Remainder (110): 100 % 30 = 10
    res, _ = await run_alu_op(dut, 100, 30, 0b110)
    assert res == 10, f"REM failed: got {res}, expected 10"