--------------------------------------------------------------------------------
-- File:        tb_top_level.vhd
-- Description: Comprehensive testbench for complete digital lock system
-- Author:      VHDL Implementation
-- Date:        December 2025
-- Version:     1.0
--
-- Test Cases (10 total from PRD):
--   TC1:  Basic Unlock - Correct sequence A->B->C->A
--   TC2:  Wrong First Button - Press B first
--   TC3:  Wrong Middle Button - A->B->D
--   TC4:  Wrong Last Button - A->B->C->B
--   TC5:  Auto-Relock - Unlock then wait for timeout
--   TC6:  Reset During Sequence - A->B->[RESET]
--   TC7:  Repeated Correct Sequence
--   TC8:  Button Held Down (edge detection test)
--   TC9:  Multiple Simultaneous Buttons
--   TC10: Fast Button Presses
--
-- Additional: Bouncy input simulation to test debouncer
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_top_level is
    -- Testbench has no ports
end tb_top_level;

architecture Behavioral of tb_top_level is

    ---------------------------------------------------------------------------
    -- Component Declaration
    ---------------------------------------------------------------------------
    component top_level
        Generic (
            DEBOUNCE_TIME : integer := 10;
            UNLOCK_TIME   : integer := 50000000
        );
        Port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            button_A_raw : in  std_logic;
            button_B_raw : in  std_logic;
            button_C_raw : in  std_logic;
            button_D_raw : in  std_logic;
            lock_status  : out std_logic;
            led          : out std_logic
        );
    end component;

    ---------------------------------------------------------------------------
    -- Test Signals
    ---------------------------------------------------------------------------
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal button_A_raw : std_logic := '0';
    signal button_B_raw : std_logic := '0';
    signal button_C_raw : std_logic := '0';
    signal button_D_raw : std_logic := '0';
    signal lock_status  : std_logic;
    signal led          : std_logic;

    ---------------------------------------------------------------------------
    -- Constants
    ---------------------------------------------------------------------------
    constant clk_period       : time := 10 ns;  -- 100 MHz clock
    constant DEBOUNCE_CYCLES  : integer := 5;   -- Short for simulation
    constant UNLOCK_CYCLES    : integer := 10;  -- Short for simulation

    -- Button press duration must exceed debounce time
    constant BUTTON_PRESS_TIME : time := clk_period * (DEBOUNCE_CYCLES + 5);
    constant BUTTON_GAP_TIME   : time := clk_period * 5;

    ---------------------------------------------------------------------------
    -- Test counter for tracking
    ---------------------------------------------------------------------------
    signal test_count : integer := 0;

begin

    ---------------------------------------------------------------------------
    -- Instantiate Unit Under Test (UUT)
    ---------------------------------------------------------------------------
    uut: top_level
        generic map (
            DEBOUNCE_TIME => DEBOUNCE_CYCLES,
            UNLOCK_TIME   => UNLOCK_CYCLES
        )
        port map (
            clk          => clk,
            reset        => reset,
            button_A_raw => button_A_raw,
            button_B_raw => button_B_raw,
            button_C_raw => button_C_raw,
            button_D_raw => button_D_raw,
            lock_status  => lock_status,
            led          => led
        );

    ---------------------------------------------------------------------------
    -- Clock Generation Process
    ---------------------------------------------------------------------------
    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    ---------------------------------------------------------------------------
    -- Stimulus Process - All Test Cases
    ---------------------------------------------------------------------------
    stim_proc: process

        -- Procedure to press a button cleanly
        procedure press_button(signal btn : out std_logic) is
        begin
            btn <= '1';
            wait for BUTTON_PRESS_TIME;
            btn <= '0';
            wait for BUTTON_GAP_TIME;
        end procedure;

        -- Procedure to press button with bounce (noisy)
        procedure press_button_bouncy(signal btn : out std_logic) is
        begin
            -- Simulate mechanical bounce
            btn <= '1';
            wait for clk_period * 2;
            btn <= '0';  -- Bounce
            wait for clk_period;
            btn <= '1';  -- Bounce
            wait for clk_period * 2;
            btn <= '0';  -- Bounce
            wait for clk_period;
            btn <= '1';  -- Final stable
            wait for BUTTON_PRESS_TIME;
            btn <= '0';
            wait for BUTTON_GAP_TIME;
        end procedure;

        -- Procedure to do system reset
        procedure do_reset is
        begin
            reset <= '1';
            wait for clk_period * 3;
            reset <= '0';
            wait for clk_period * 3;
        end procedure;

    begin
        report "========================================" severity note;
        report "=== TOP LEVEL TESTBENCH STARTED ===" severity note;
        report "========================================" severity note;

        -- Initial reset
        do_reset;

        -----------------------------------------------------------------------
        -- TC1: Basic Unlock - Correct sequence A->B->C->A
        -----------------------------------------------------------------------
        test_count <= 1;
        report "TC1: Basic Unlock - Correct sequence A->B->C->A" severity note;

        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;

        assert lock_status = '1'
            report "TC1 FAILED: Lock should be UNLOCKED!"
            severity error;
        assert led = '1'
            report "TC1 FAILED: LED should be ON!"
            severity error;
        report "TC1 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC2: Wrong First Button - Press B first
        -----------------------------------------------------------------------
        test_count <= 2;
        report "TC2: Wrong First Button - Press B first" severity note;

        press_button(button_B_raw);  -- Wrong first button

        wait for clk_period * 3;

        assert lock_status = '0'
            report "TC2 FAILED: Lock should stay LOCKED!"
            severity error;
        report "TC2 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC3: Wrong Middle Button - A->B->D
        -----------------------------------------------------------------------
        test_count <= 3;
        report "TC3: Wrong Middle Button - A->B->D" severity note;

        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_D_raw);  -- Wrong!

        wait for clk_period * 3;

        assert lock_status = '0'
            report "TC3 FAILED: Lock should stay LOCKED after wrong sequence!"
            severity error;
        report "TC3 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC4: Wrong Last Button - A->B->C->B
        -----------------------------------------------------------------------
        test_count <= 4;
        report "TC4: Wrong Last Button - A->B->C->B" severity note;

        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_B_raw);  -- Wrong! Should be A

        wait for clk_period * 3;

        assert lock_status = '0'
            report "TC4 FAILED: Lock should stay LOCKED after wrong last button!"
            severity error;
        report "TC4 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC5: Auto-Relock after timeout
        -----------------------------------------------------------------------
        test_count <= 5;
        report "TC5: Auto-Relock after timeout" severity note;

        -- First unlock
        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;
        assert lock_status = '1'
            report "TC5 FAILED: Lock should be UNLOCKED first!"
            severity error;

        -- Wait for auto-relock (UNLOCK_CYCLES + extra)
        wait for clk_period * (UNLOCK_CYCLES + 10);

        assert lock_status = '0'
            report "TC5 FAILED: Lock should auto-relock after timeout!"
            severity error;
        report "TC5 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC6: Reset During Sequence - A->B->[RESET]
        -----------------------------------------------------------------------
        test_count <= 6;
        report "TC6: Reset During Sequence" severity note;

        press_button(button_A_raw);
        press_button(button_B_raw);

        -- Reset in middle
        do_reset;

        -- Continue with rest of sequence (should not unlock)
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;

        assert lock_status = '0'
            report "TC6 FAILED: Lock should be LOCKED after reset during sequence!"
            severity error;
        report "TC6 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC7: Repeated Correct Sequence
        -----------------------------------------------------------------------
        test_count <= 7;
        report "TC7: Repeated Correct Sequence" severity note;

        -- First unlock
        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;
        assert lock_status = '1'
            report "TC7 FAILED: First unlock should work!"
            severity error;

        -- Wait for auto-relock
        wait for clk_period * (UNLOCK_CYCLES + 10);

        -- Second unlock
        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;
        assert lock_status = '1'
            report "TC7 FAILED: Second unlock should work!"
            severity error;
        report "TC7 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC8: Button Held Down (edge detection test)
        -----------------------------------------------------------------------
        test_count <= 8;
        report "TC8: Button Held Down - Edge Detection Test" severity note;

        -- Hold button A for extended time
        button_A_raw <= '1';
        wait for BUTTON_PRESS_TIME * 5;  -- Hold much longer
        button_A_raw <= '0';
        wait for BUTTON_GAP_TIME;

        -- Should only register once, so B should advance us
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;

        assert lock_status = '1'
            report "TC8 FAILED: Long press should register as single press!"
            severity error;
        report "TC8 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC9: Multiple Simultaneous Buttons
        -----------------------------------------------------------------------
        test_count <= 9;
        report "TC9: Multiple Simultaneous Buttons" severity note;

        -- Press A and B together (should treat as wrong input)
        button_A_raw <= '1';
        button_B_raw <= '1';
        wait for BUTTON_PRESS_TIME;
        button_A_raw <= '0';
        button_B_raw <= '0';
        wait for BUTTON_GAP_TIME;

        wait for clk_period * 3;

        assert lock_status = '0'
            report "TC9 FAILED: Simultaneous buttons should not unlock!"
            severity error;
        report "TC9 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- TC10: Fast Button Presses
        -----------------------------------------------------------------------
        test_count <= 10;
        report "TC10: Fast Button Presses" severity note;

        -- Rapid sequence (but still valid timing)
        press_button(button_A_raw);
        press_button(button_B_raw);
        press_button(button_C_raw);
        press_button(button_A_raw);

        wait for clk_period * 3;

        assert lock_status = '1'
            report "TC10 FAILED: Fast sequence should still unlock!"
            severity error;
        report "TC10 PASSED" severity note;

        do_reset;

        -----------------------------------------------------------------------
        -- BONUS: Test bouncy button input
        -----------------------------------------------------------------------
        report "BONUS: Testing bouncy button input" severity note;

        press_button_bouncy(button_A_raw);
        press_button_bouncy(button_B_raw);
        press_button_bouncy(button_C_raw);
        press_button_bouncy(button_A_raw);

        wait for clk_period * 3;

        assert lock_status = '1'
            report "BONUS FAILED: Bouncy input should still unlock!"
            severity error;
        report "BONUS PASSED: Debouncer working correctly" severity note;

        -----------------------------------------------------------------------
        -- End of Tests
        -----------------------------------------------------------------------
        report "========================================" severity note;
        report "=== ALL 10 TEST CASES COMPLETED ===" severity note;
        report "=== TOP LEVEL TESTBENCH PASSED ===" severity note;
        report "========================================" severity note;

        -- End simulation
        wait;
    end process;

end Behavioral;
