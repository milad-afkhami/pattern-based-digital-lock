--------------------------------------------------------------------------------
-- File:        digital_lock.vhd
-- Description: Pattern-based digital lock using FSM
-- Author:      VHDL Implementation
-- Date:        December 2025
-- Version:     1.0
--
-- Pattern:     A -> B -> C -> A
-- States:      5 (LOCKED, FIRST, SECOND, THIRD, UNLOCKED)
-- Auto-lock:   Yes, after UNLOCK_TIME clock cycles
-- Features:    - Sequential pattern detection
--              - Wrong input recovery
--              - Automatic re-lock timer
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity digital_lock is
    Generic (
        UNLOCK_TIME : integer := 5  -- Clock cycles before auto-relock (set low for simulation)
    );
    Port (
        clk          : in  std_logic;           -- System clock
        reset        : in  std_logic;           -- Asynchronous reset (active high)
        button_A     : in  std_logic;           -- Button A input (active high)
        button_B     : in  std_logic;           -- Button B input (active high)
        button_C     : in  std_logic;           -- Button C input (active high)
        button_D     : in  std_logic;           -- Button D input (active high)
        lock_status  : out std_logic            -- Lock output: '1' = Unlocked, '0' = Locked
    );
end digital_lock;

architecture Behavioral of digital_lock is
    -- State type definition
    type state_type is (STATE_LOCKED, STATE_FIRST, STATE_SECOND,
                        STATE_THIRD, STATE_UNLOCKED);

    -- State signals
    signal current_state : state_type := STATE_LOCKED;
    signal next_state    : state_type;

    -- Timer signals for auto-relock
    signal unlock_timer  : integer range 0 to UNLOCK_TIME := 0;
    signal timer_expired : std_logic := '0';

begin

    ---------------------------------------------------------------------------
    -- Process 1: State Register (Sequential Logic)
    -- Updates current state on each clock edge, handles async reset
    ---------------------------------------------------------------------------
    state_register: process(clk, reset)
    begin
        if reset = '1' then
            current_state <= STATE_LOCKED;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process state_register;

    ---------------------------------------------------------------------------
    -- Process 2: Next State Logic (Combinational Logic)
    -- Determines next state based on current state and button inputs
    -- Pattern: A -> B -> C -> A
    ---------------------------------------------------------------------------
    next_state_logic: process(current_state, button_A, button_B,
                              button_C, button_D, timer_expired)
    begin
        -- Default: stay in current state
        next_state <= current_state;

        case current_state is
            when STATE_LOCKED =>
                -- Waiting for first button 'A'
                if button_A = '1' then
                    next_state <= STATE_FIRST;
                elsif button_B = '1' or button_C = '1' or button_D = '1' then
                    next_state <= STATE_LOCKED;  -- Wrong button, stay locked
                end if;

            when STATE_FIRST =>
                -- Received A, waiting for 'B'
                if button_B = '1' then
                    next_state <= STATE_SECOND;
                elsif button_A = '1' or button_C = '1' or button_D = '1' then
                    next_state <= STATE_LOCKED;  -- Wrong button, reset
                end if;

            when STATE_SECOND =>
                -- Received A->B, waiting for 'C'
                if button_C = '1' then
                    next_state <= STATE_THIRD;
                elsif button_A = '1' or button_B = '1' or button_D = '1' then
                    next_state <= STATE_LOCKED;  -- Wrong button, reset
                end if;

            when STATE_THIRD =>
                -- Received A->B->C, waiting for final 'A'
                if button_A = '1' then
                    next_state <= STATE_UNLOCKED;
                elsif button_B = '1' or button_C = '1' or button_D = '1' then
                    next_state <= STATE_LOCKED;  -- Wrong button, reset
                end if;

            when STATE_UNLOCKED =>
                -- Lock is open, wait for timer to expire
                if timer_expired = '1' then
                    next_state <= STATE_LOCKED;
                else
                    next_state <= STATE_UNLOCKED;
                end if;

            when others =>
                next_state <= STATE_LOCKED;
        end case;
    end process next_state_logic;

    ---------------------------------------------------------------------------
    -- Process 3: Output Logic
    -- Sets lock_status based on current state
    ---------------------------------------------------------------------------
    output_logic: process(current_state)
    begin
        if current_state = STATE_UNLOCKED then
            lock_status <= '1';  -- Unlocked
        else
            lock_status <= '0';  -- Locked
        end if;
    end process output_logic;

    ---------------------------------------------------------------------------
    -- Process 4: Unlock Timer
    -- Counts clock cycles while in UNLOCKED state, sets timer_expired flag
    ---------------------------------------------------------------------------
    unlock_timer_proc: process(clk, reset)
    begin
        if reset = '1' then
            unlock_timer <= 0;
            timer_expired <= '0';
        elsif rising_edge(clk) then
            if current_state = STATE_UNLOCKED then
                if unlock_timer < UNLOCK_TIME then
                    unlock_timer <= unlock_timer + 1;
                    timer_expired <= '0';
                else
                    timer_expired <= '1';
                end if;
            else
                unlock_timer <= 0;
                timer_expired <= '0';
            end if;
        end if;
    end process unlock_timer_proc;

end Behavioral;
