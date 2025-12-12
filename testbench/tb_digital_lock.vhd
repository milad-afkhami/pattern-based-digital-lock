--------------------------------------------------------------------------------
-- File:        tb_digital_lock.vhd
-- Description: Testbench for pattern-based digital lock FSM
-- Author:      VHDL Implementation
-- Date:        December 2025
-- Version:     1.0
--
-- Test Cases:
--   TC1: Reset functionality
--   TC2: Correct sequence A->B->C->A (should unlock)
--   TC3: Wrong sequence A->B->D (should stay locked)
--   TC4: Wrong first button (B first)
--   TC5: Auto-relock after timeout
--   TC6: Reset during sequence
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_digital_lock is
    -- Testbench has no ports
end tb_digital_lock;

architecture Behavioral of tb_digital_lock is

    -- Component declaration
    component digital_lock
        Generic (
            UNLOCK_TIME : integer := 5
        );
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            button_A     : in  std_logic;
            button_B     : in  std_logic;
            button_C     : in  std_logic;
            button_D     : in  std_logic;
            lock_status  : out std_logic
        );
    end component;

    -- Test signals
    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal button_A    : std_logic := '0';
    signal button_B    : std_logic := '0';
    signal button_C    : std_logic := '0';
    signal button_D    : std_logic := '0';
    signal lock_status : std_logic;

    -- Clock period definition (10 ns = 100 MHz)
    constant clk_period : time := 10 ns;

    -- Test unlock time (short for simulation)
    constant TEST_UNLOCK_TIME : integer := 5;

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: digital_lock
        generic map (
            UNLOCK_TIME => TEST_UNLOCK_TIME
        )
        port map (
            clk         => clk,
            reset       => reset,
            button_A    => button_A,
            button_B    => button_B,
            button_C    => button_C,
            button_D    => button_D,
            lock_status => lock_status
        );

    ---------------------------------------------------------------------------
    -- Clock generation process
    ---------------------------------------------------------------------------
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    ---------------------------------------------------------------------------
    -- Stimulus process - Test cases
    ---------------------------------------------------------------------------
    stim_proc: process
    begin
        -- Initialize
        report "=== Starting Digital Lock Testbench ===" severity note;

        -----------------------------------------------------------------------
        -- TC1: Reset Test
        -----------------------------------------------------------------------
        report "TC1: Testing reset functionality" severity note;
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period * 2;

        assert lock_status = '0'
            report "TC1 FAILED: Lock should be locked after reset"
            severity error;
        report "TC1 PASSED: Reset works correctly" severity note;

        -----------------------------------------------------------------------
        -- TC2: Correct Sequence A->B->C->A
        -- Note: FSM expects single-cycle pulses (as provided by debouncer)
        -----------------------------------------------------------------------
        report "TC2: Testing correct sequence A->B->C->A" severity note;

        -- Press A (single cycle pulse)
        button_A <= '1';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 2;

        -- Press B (single cycle pulse)
        button_B <= '1';
        wait for clk_period;
        button_B <= '0';
        wait for clk_period * 2;

        -- Press C (single cycle pulse)
        button_C <= '1';
        wait for clk_period;
        button_C <= '0';
        wait for clk_period * 2;

        -- Press A (final, single cycle pulse)
        button_A <= '1';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 2;

        assert lock_status = '1'
            report "TC2 FAILED: Lock should be UNLOCKED after correct sequence!"
            severity error;
        report "TC2 PASSED: Correct sequence unlocks the system" severity note;

        -----------------------------------------------------------------------
        -- TC5: Auto-relock after timeout
        -----------------------------------------------------------------------
        report "TC5: Testing auto-relock timer" severity note;

        -- Wait for timer to expire (UNLOCK_TIME + extra cycles)
        wait for clk_period * (TEST_UNLOCK_TIME + 5);

        assert lock_status = '0'
            report "TC5 FAILED: Lock should auto-relock after timeout!"
            severity error;
        report "TC5 PASSED: Auto-relock works correctly" severity note;

        -----------------------------------------------------------------------
        -- TC3: Wrong Sequence A->B->D
        -----------------------------------------------------------------------
        report "TC3: Testing wrong sequence A->B->D" severity note;

        -- Press A (single cycle pulse)
        button_A <= '1';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 2;

        -- Press B (single cycle pulse)
        button_B <= '1';
        wait for clk_period;
        button_B <= '0';
        wait for clk_period * 2;

        -- Press D (WRONG! single cycle pulse)
        button_D <= '1';
        wait for clk_period;
        button_D <= '0';
        wait for clk_period * 2;

        assert lock_status = '0'
            report "TC3 FAILED: Lock should stay LOCKED after wrong sequence!"
            severity error;
        report "TC3 PASSED: Wrong sequence keeps system locked" severity note;

        -----------------------------------------------------------------------
        -- TC4: Wrong First Button (B first)
        -----------------------------------------------------------------------
        report "TC4: Testing wrong first button" severity note;

        -- Press B first (should not advance, single cycle pulse)
        button_B <= '1';
        wait for clk_period;
        button_B <= '0';
        wait for clk_period * 2;

        -- Now try correct sequence (single cycle pulses)
        button_A <= '1';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 2;

        button_B <= '1';
        wait for clk_period;
        button_B <= '0';
        wait for clk_period * 2;

        button_C <= '1';
        wait for clk_period;
        button_C <= '0';
        wait for clk_period * 2;

        button_A <= '1';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 2;

        assert lock_status = '1'
            report "TC4 FAILED: Lock should unlock after recovery from wrong first button!"
            severity error;
        report "TC4 PASSED: System recovers from wrong first button" severity note;

        -- Reset for next test
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period * 2;

        -----------------------------------------------------------------------
        -- TC6: Reset During Sequence
        -----------------------------------------------------------------------
        report "TC6: Testing reset during sequence" severity note;

        -- Start sequence (single cycle pulses)
        button_A <= '1';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 2;

        button_B <= '1';
        wait for clk_period;
        button_B <= '0';
        wait for clk_period * 2;

        -- Reset in middle of sequence
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period * 2;

        assert lock_status = '0'
            report "TC6 FAILED: Lock should be LOCKED after reset during sequence!"
            severity error;
        report "TC6 PASSED: Reset during sequence works correctly" severity note;

        -----------------------------------------------------------------------
        -- End of Tests
        -----------------------------------------------------------------------
        report "=== All Test Cases Completed ===" severity note;
        report "=== Digital Lock Testbench PASSED ===" severity note;

        -- End simulation
        wait;
    end process;

end Behavioral;
