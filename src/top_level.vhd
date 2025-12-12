--------------------------------------------------------------------------------
-- File:        top_level.vhd
-- Description: Top-level module integrating debouncers and FSM controller
-- Author:      VHDL Implementation
-- Date:        December 2025
-- Version:     1.0
--
-- Architecture: This module connects:
--               - 4 button debouncer instances (one per button)
--               - 1 digital lock FSM controller
--               - Routes debounced signals to FSM
--               - Maps lock status to LED output
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_level is
    Generic (
        DEBOUNCE_TIME : integer := 10;       -- Debounce cycles (increase for real hardware)
        UNLOCK_TIME   : integer := 50000000  -- Auto-relock cycles (~1 sec at 50MHz)
    );
    Port (
        clk          : in  std_logic;        -- System clock
        reset        : in  std_logic;        -- Asynchronous reset (active high)
        button_A_raw : in  std_logic;        -- Raw button A input
        button_B_raw : in  std_logic;        -- Raw button B input
        button_C_raw : in  std_logic;        -- Raw button C input
        button_D_raw : in  std_logic;        -- Raw button D input
        lock_status  : out std_logic;        -- Lock status output
        led          : out std_logic         -- LED indicator (mirrors lock_status)
    );
end top_level;

architecture Behavioral of top_level is

    ---------------------------------------------------------------------------
    -- Component Declarations
    ---------------------------------------------------------------------------

    component button_debouncer
        Generic (
            DEBOUNCE_TIME : integer := 10
        );
        Port (
            clk        : in  std_logic;
            reset      : in  std_logic;
            button_in  : in  std_logic;
            button_out : out std_logic
        );
    end component;

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

    ---------------------------------------------------------------------------
    -- Internal Signals (debounced buttons)
    ---------------------------------------------------------------------------
    signal button_A_clean : std_logic;
    signal button_B_clean : std_logic;
    signal button_C_clean : std_logic;
    signal button_D_clean : std_logic;

    -- Internal lock status (for routing to multiple outputs)
    signal lock_status_int : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Debouncer Instantiations
    ---------------------------------------------------------------------------

    debouncer_A: button_debouncer
        generic map (
            DEBOUNCE_TIME => DEBOUNCE_TIME
        )
        port map (
            clk        => clk,
            reset      => reset,
            button_in  => button_A_raw,
            button_out => button_A_clean
        );

    debouncer_B: button_debouncer
        generic map (
            DEBOUNCE_TIME => DEBOUNCE_TIME
        )
        port map (
            clk        => clk,
            reset      => reset,
            button_in  => button_B_raw,
            button_out => button_B_clean
        );

    debouncer_C: button_debouncer
        generic map (
            DEBOUNCE_TIME => DEBOUNCE_TIME
        )
        port map (
            clk        => clk,
            reset      => reset,
            button_in  => button_C_raw,
            button_out => button_C_clean
        );

    debouncer_D: button_debouncer
        generic map (
            DEBOUNCE_TIME => DEBOUNCE_TIME
        )
        port map (
            clk        => clk,
            reset      => reset,
            button_in  => button_D_raw,
            button_out => button_D_clean
        );

    ---------------------------------------------------------------------------
    -- FSM Controller Instantiation
    ---------------------------------------------------------------------------

    fsm_controller: digital_lock
        generic map (
            UNLOCK_TIME => UNLOCK_TIME
        )
        port map (
            clk         => clk,
            reset       => reset,
            button_A    => button_A_clean,
            button_B    => button_B_clean,
            button_C    => button_C_clean,
            button_D    => button_D_clean,
            lock_status => lock_status_int
        );

    ---------------------------------------------------------------------------
    -- Output Assignments
    ---------------------------------------------------------------------------

    lock_status <= lock_status_int;
    led         <= lock_status_int;  -- LED mirrors lock status

end Behavioral;
