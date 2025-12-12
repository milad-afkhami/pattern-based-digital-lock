--------------------------------------------------------------------------------
-- File:        button_debouncer.vhd
-- Description: Button debounce circuit with edge detection
-- Author:      VHDL Implementation
-- Date:        December 2025
-- Version:     1.0
--
-- Purpose:     Mechanical buttons "bounce" when pressed, causing multiple
--              logic transitions. This module filters the noise and outputs
--              a single clean pulse per button press.
--
-- Features:    - Counter-based stability detection
--              - Edge detection for single pulse output
--              - Configurable debounce time via generic
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity button_debouncer is
    Generic (
        DEBOUNCE_TIME : integer := 10  -- Number of clock cycles for stability
    );
    Port (
        clk        : in  std_logic;    -- System clock
        reset      : in  std_logic;    -- Asynchronous reset (active high)
        button_in  : in  std_logic;    -- Raw button input (active high)
        button_out : out std_logic     -- Debounced output (single pulse per press)
    );
end button_debouncer;

architecture Behavioral of button_debouncer is
    -- Stability counter
    signal counter       : integer range 0 to DEBOUNCE_TIME := 0;

    -- Button state tracking
    signal button_sync   : std_logic := '0';  -- Synchronized input
    signal button_stable : std_logic := '0';  -- Stable (debounced) state
    signal button_prev   : std_logic := '0';  -- Previous stable state (for edge detection)

begin

    ---------------------------------------------------------------------------
    -- Main debounce process
    -- 1. Synchronize input to clock domain
    -- 2. Count stable cycles
    -- 3. Update stable state when count reaches threshold
    -- 4. Generate edge-detected output pulse
    ---------------------------------------------------------------------------
    debounce_proc: process(clk, reset)
    begin
        if reset = '1' then
            counter       <= 0;
            button_sync   <= '0';
            button_stable <= '0';
            button_prev   <= '0';
            button_out    <= '0';

        elsif rising_edge(clk) then
            -- Synchronize input (first stage of synchronizer)
            button_sync <= button_in;

            -- Check if input is same as current stable state
            if button_sync = button_stable then
                -- Input matches stable state, reset counter
                counter <= 0;
            else
                -- Input differs from stable state
                if counter < DEBOUNCE_TIME then
                    -- Still counting, increment
                    counter <= counter + 1;
                else
                    -- Counter reached threshold, update stable state
                    button_stable <= button_sync;
                    counter <= 0;
                end if;
            end if;

            -- Edge detection: generate pulse on rising edge of stable signal
            -- Output is '1' for one clock cycle when button becomes stable high
            if button_stable = '1' and button_prev = '0' then
                button_out <= '1';  -- Rising edge detected
            else
                button_out <= '0';  -- No edge or falling edge
            end if;

            -- Update previous state for next cycle
            button_prev <= button_stable;

        end if;
    end process debounce_proc;

end Behavioral;
