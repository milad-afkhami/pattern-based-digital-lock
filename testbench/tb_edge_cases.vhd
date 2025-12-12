--------------------------------------------------------------------------------
-- File:        tb_edge_cases.vhd
-- Description: Edge case and stress test for digital lock
-- Tests:       Rapid inputs, glitches, boundary conditions, timing
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_edge_cases is
end tb_edge_cases;

architecture Behavioral of tb_edge_cases is

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
    signal test_pass_count : integer := 0;
    signal test_fail_count : integer := 0;

begin

    uut: digital_lock
        generic map (UNLOCK_TIME => 5)
        port map (
            clk => clk, reset => reset,
            button_A => button_A, button_B => button_B,
            button_C => button_C, button_D => button_D,
            lock_status => lock_status
        );

    clk_process: process
    begin
        clk <= '0'; wait for clk_period/2;
        clk <= '1'; wait for clk_period/2;
    end process;

    stim_proc: process
        procedure pulse(signal btn : out std_logic) is
        begin
            btn <= '1'; wait for clk_period;
            btn <= '0'; wait for clk_period * 2;
        end procedure;

        procedure do_reset is
        begin
            reset <= '1'; wait for clk_period * 2;
            reset <= '0'; wait for clk_period * 2;
        end procedure;

        procedure unlock_sequence is
        begin
            pulse(button_A);
            pulse(button_B);
            pulse(button_C);
            pulse(button_A);
        end procedure;

        procedure check(condition : boolean; msg : string) is
        begin
            if condition then
                test_pass_count <= test_pass_count + 1;
                report "PASS: " & msg severity note;
            else
                test_fail_count <= test_fail_count + 1;
                report "FAIL: " & msg severity error;
            end if;
        end procedure;

    begin
        report "=== EDGE CASE TESTS ===" severity note;
        do_reset;

        -----------------------------------------------------------------------
        -- TEST 1: Reset during UNLOCKED state
        -----------------------------------------------------------------------
        report "TEST 1: Reset during UNLOCKED state" severity note;
        unlock_sequence;
        check(lock_status = '1', "Lock is unlocked");
        do_reset;
        check(lock_status = '0', "Reset locks the system");

        -----------------------------------------------------------------------
        -- TEST 2: Multiple resets in sequence
        -----------------------------------------------------------------------
        report "TEST 2: Multiple consecutive resets" severity note;
        do_reset;
        do_reset;
        do_reset;
        check(lock_status = '0', "Multiple resets keep system locked");

        -----------------------------------------------------------------------
        -- TEST 3: Button press exactly at reset release
        -----------------------------------------------------------------------
        report "TEST 3: Button at reset release boundary" severity note;
        reset <= '1';
        wait for clk_period * 2;
        button_A <= '1';
        reset <= '0';
        wait for clk_period;
        button_A <= '0';
        wait for clk_period * 3;
        -- Should be in STATE_FIRST now
        pulse(button_B);
        pulse(button_C);
        pulse(button_A);
        check(lock_status = '1', "Boundary timing works");
        do_reset;

        -----------------------------------------------------------------------
        -- TEST 4: All buttons pressed simultaneously
        -----------------------------------------------------------------------
        report "TEST 4: All buttons pressed at once" severity note;
        button_A <= '1';
        button_B <= '1';
        button_C <= '1';
        button_D <= '1';
        wait for clk_period;
        button_A <= '0';
        button_B <= '0';
        button_C <= '0';
        button_D <= '0';
        wait for clk_period * 3;
        check(lock_status = '0', "Simultaneous buttons don't unlock");
        do_reset;

        -----------------------------------------------------------------------
        -- TEST 5: Rapid button presses (stress test)
        -----------------------------------------------------------------------
        report "TEST 5: Rapid button stress test (10 sequences)" severity note;
        for i in 1 to 10 loop
            unlock_sequence;
            check(lock_status = '1', "Rapid unlock " & integer'image(i));
            do_reset;
        end loop;

        -----------------------------------------------------------------------
        -- TEST 6: Timer boundary - unlock just before timeout
        -----------------------------------------------------------------------
        report "TEST 6: Timer boundary test" severity note;
        unlock_sequence;
        check(lock_status = '1', "Initially unlocked");
        wait for clk_period * 4;  -- Just before timeout (UNLOCK_TIME=5)
        check(lock_status = '1', "Still unlocked before timeout");
        wait for clk_period * 5;  -- After timeout
        check(lock_status = '0', "Locked after timeout");

        -----------------------------------------------------------------------
        -- TEST 7: Partial sequence then timeout (should stay locked)
        -----------------------------------------------------------------------
        report "TEST 7: Partial sequence stays locked" severity note;
        pulse(button_A);
        pulse(button_B);
        wait for clk_period * 20;  -- Wait a while
        check(lock_status = '0', "Partial sequence stays locked");
        do_reset;

        -----------------------------------------------------------------------
        -- TEST 8: Wrong button then correct sequence
        -----------------------------------------------------------------------
        report "TEST 8: Recovery after wrong button" severity note;
        pulse(button_D);  -- Wrong
        pulse(button_C);  -- Wrong
        pulse(button_B);  -- Wrong
        unlock_sequence;  -- Now correct
        check(lock_status = '1', "Recovery from wrong buttons works");
        do_reset;

        -----------------------------------------------------------------------
        -- TEST 9: Repeated same button
        -----------------------------------------------------------------------
        report "TEST 9: Repeated same button" severity note;
        pulse(button_A);
        pulse(button_A);  -- Wrong - should reset
        pulse(button_A);
        pulse(button_A);
        check(lock_status = '0', "Repeated A doesn't unlock");
        do_reset;

        -----------------------------------------------------------------------
        -- TEST 10: Long sequence with errors
        -----------------------------------------------------------------------
        report "TEST 10: Long sequence with recovery" severity note;
        pulse(button_A);
        pulse(button_B);
        pulse(button_D);  -- Error - reset
        pulse(button_A);
        pulse(button_B);
        pulse(button_C);
        pulse(button_B);  -- Error - reset
        pulse(button_A);
        pulse(button_B);
        pulse(button_C);
        pulse(button_A);  -- Finally correct!
        check(lock_status = '1', "Long sequence with recovery works");
        do_reset;

        -----------------------------------------------------------------------
        -- Final Summary
        -----------------------------------------------------------------------
        report "=== EDGE CASE TEST SUMMARY ===" severity note;
        report "PASSED: " & integer'image(test_pass_count) severity note;
        report "FAILED: " & integer'image(test_fail_count) severity note;

        if test_fail_count = 0 then
            report "=== ALL EDGE CASE TESTS PASSED ===" severity note;
        else
            report "=== SOME TESTS FAILED ===" severity error;
        end if;

        wait;
    end process;

end Behavioral;
