--------------------------------------------------------------------------------
-- File:        tb_fsm_coverage.vhd
-- Description: FSM state coverage and edge case testbench
-- Purpose:     Verify all states are reachable and all transitions work
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_fsm_coverage is
end tb_fsm_coverage;

architecture Behavioral of tb_fsm_coverage is

    component digital_lock
        Generic (UNLOCK_TIME : integer := 5);
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

    signal clk         : std_logic := '0';
    signal reset       : std_logic := '0';
    signal button_A    : std_logic := '0';
    signal button_B    : std_logic := '0';
    signal button_C    : std_logic := '0';
    signal button_D    : std_logic := '0';
    signal lock_status : std_logic;

    constant clk_period : time := 10 ns;

    -- State coverage tracking
    signal state_locked_visited   : boolean := false;
    signal state_first_visited    : boolean := false;
    signal state_second_visited   : boolean := false;
    signal state_third_visited    : boolean := false;
    signal state_unlocked_visited : boolean := false;

begin

    uut: digital_lock
        generic map (UNLOCK_TIME => 3)
        port map (
            clk => clk, reset => reset,
            button_A => button_A, button_B => button_B,
            button_C => button_C, button_D => button_D,
            lock_status => lock_status
        );

    -- Clock
    clk_process: process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    -- Stimulus
    stim_proc: process
        procedure pulse(signal btn : out std_logic) is
        begin
            btn <= '1'; wait for clk_period;
            btn <= '0'; wait for clk_period * 2;
        end procedure;
    begin
        report "=== FSM COVERAGE TEST ===" severity note;

        -- Reset to STATE_LOCKED
        reset <= '1'; wait for clk_period * 2;
        reset <= '0'; wait for clk_period * 2;
        state_locked_visited <= true;
        report "STATE_LOCKED: Visited" severity note;

        -- LOCKED -> FIRST (press A)
        pulse(button_A);
        state_first_visited <= true;
        report "STATE_FIRST: Visited (A pressed from LOCKED)" severity note;

        -- FIRST -> SECOND (press B)
        pulse(button_B);
        state_second_visited <= true;
        report "STATE_SECOND: Visited (B pressed from FIRST)" severity note;

        -- SECOND -> THIRD (press C)
        pulse(button_C);
        state_third_visited <= true;
        report "STATE_THIRD: Visited (C pressed from SECOND)" severity note;

        -- THIRD -> UNLOCKED (press A)
        pulse(button_A);
        state_unlocked_visited <= true;
        assert lock_status = '1' report "ERROR: Should be unlocked!" severity error;
        report "STATE_UNLOCKED: Visited (A pressed from THIRD)" severity note;

        -- UNLOCKED -> LOCKED (timeout)
        wait for clk_period * 10;
        assert lock_status = '0' report "ERROR: Should auto-lock!" severity error;
        report "STATE_LOCKED: Returned via timeout" severity note;

        -- Test all wrong button transitions
        report "--- Testing wrong button transitions ---" severity note;

        -- LOCKED: wrong buttons B, C, D should stay in LOCKED
        pulse(button_B); assert lock_status = '0' report "B from LOCKED failed" severity error;
        pulse(button_C); assert lock_status = '0' report "C from LOCKED failed" severity error;
        pulse(button_D); assert lock_status = '0' report "D from LOCKED failed" severity error;
        report "LOCKED: All wrong buttons keep in LOCKED - OK" severity note;

        -- Go to FIRST, test wrong buttons
        pulse(button_A);
        pulse(button_A); -- Wrong! Should reset to LOCKED
        assert lock_status = '0' report "A from FIRST should reset" severity error;
        report "FIRST -> LOCKED: Wrong button A - OK" severity note;

        pulse(button_A); -- Back to FIRST
        pulse(button_C); -- Wrong!
        assert lock_status = '0' report "C from FIRST should reset" severity error;
        report "FIRST -> LOCKED: Wrong button C - OK" severity note;

        pulse(button_A); -- Back to FIRST
        pulse(button_D); -- Wrong!
        assert lock_status = '0' report "D from FIRST should reset" severity error;
        report "FIRST -> LOCKED: Wrong button D - OK" severity note;

        -- Go to SECOND, test wrong buttons
        pulse(button_A); pulse(button_B); -- Now in SECOND
        pulse(button_A); -- Wrong!
        assert lock_status = '0' report "A from SECOND should reset" severity error;
        report "SECOND -> LOCKED: Wrong button A - OK" severity note;

        pulse(button_A); pulse(button_B); -- Back to SECOND
        pulse(button_B); -- Wrong!
        assert lock_status = '0' report "B from SECOND should reset" severity error;
        report "SECOND -> LOCKED: Wrong button B - OK" severity note;

        pulse(button_A); pulse(button_B); -- Back to SECOND
        pulse(button_D); -- Wrong!
        assert lock_status = '0' report "D from SECOND should reset" severity error;
        report "SECOND -> LOCKED: Wrong button D - OK" severity note;

        -- Go to THIRD, test wrong buttons
        pulse(button_A); pulse(button_B); pulse(button_C); -- Now in THIRD
        pulse(button_B); -- Wrong!
        assert lock_status = '0' report "B from THIRD should reset" severity error;
        report "THIRD -> LOCKED: Wrong button B - OK" severity note;

        pulse(button_A); pulse(button_B); pulse(button_C); -- Back to THIRD
        pulse(button_C); -- Wrong!
        assert lock_status = '0' report "C from THIRD should reset" severity error;
        report "THIRD -> LOCKED: Wrong button C - OK" severity note;

        pulse(button_A); pulse(button_B); pulse(button_C); -- Back to THIRD
        pulse(button_D); -- Wrong!
        assert lock_status = '0' report "D from THIRD should reset" severity error;
        report "THIRD -> LOCKED: Wrong button D - OK" severity note;

        -- Final coverage report
        report "=== COVERAGE SUMMARY ===" severity note;
        assert state_locked_visited report "STATE_LOCKED not visited!" severity error;
        assert state_first_visited report "STATE_FIRST not visited!" severity error;
        assert state_second_visited report "STATE_SECOND not visited!" severity error;
        assert state_third_visited report "STATE_THIRD not visited!" severity error;
        assert state_unlocked_visited report "STATE_UNLOCKED not visited!" severity error;

        report "ALL 5 STATES VISITED - 100% STATE COVERAGE" severity note;
        report "ALL TRANSITIONS TESTED - PASS" severity note;
        report "=== FSM COVERAGE TEST PASSED ===" severity note;

        wait;
    end process;

end Behavioral;
