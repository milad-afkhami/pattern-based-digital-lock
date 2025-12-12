# PRODUCT REQUIREMENTS DOCUMENT

# Pattern-Based Digital Lock Using Finite State Machines in VHDL

---

## PROJECT OVERVIEW

**Document Version:** 1.0  
**Date:** December 4, 2025  
**Project Type:** Educational VHDL Implementation  
**Difficulty Level:** Beginner-Friendly  
**Estimated Duration:** 2-3 weeks

---

## 1\. EXECUTIVE SUMMARY

This project implements a pattern-based digital lock system using VHDL (VHSIC Hardware Description Language). The system mimics a security lock that requires users to input a specific sequence of button presses to unlock. This is an ideal beginner project because it teaches fundamental VHDL concepts through a practical, easy-to-understand application.

**Think of it like this:** Similar to entering a PIN on your phone, but instead of numbers, you press a sequence of buttons (like A→B→C→A) to unlock.

---

## 2\. LEARNING OBJECTIVES

By completing this project, you will learn:

✓ Finite State Machine (FSM) design and implementation  
✓ VHDL syntax and structure  
✓ Sequential logic design  
✓ Simulation and testing techniques  
✓ Hardware description concepts  
✓ Debugging VHDL code

---

## 3\. WHAT IS VHDL? (ABSOLUTE BEGINNER EXPLANATION)

VHDL stands for **VHSIC Hardware Description Language**. Unlike traditional programming languages (Python, Java) that tell a computer WHAT to do step-by-step, VHDL describes HOW hardware should be physically connected and behave.

### Key Differences from Regular Programming:

**Traditional Programming (Python):**

x \= 5

y \= 10

result \= x \+ y  \# Happens sequentially, one after another

**VHDL (Hardware Description):**

signal x : integer := 5;

signal y : integer := 10;

result \<= x \+ y;  \-- All connections exist simultaneously, like wires

### Important Concepts:

- **SIGNALS** are like physical wires carrying electricity  
- Everything happens in **PARALLEL** (at the same time)  
- **CLOCK** is like a heartbeat that synchronizes everything  
- You're designing actual **hardware circuits**, not software

  ---

## 4\. WHAT IS A FINITE STATE MACHINE? (SIMPLE EXPLANATION)

A Finite State Machine (FSM) is a system that can be in one of several specific "states" and moves between states based on inputs.

### Real-World Example: Traffic Light

State 1: RED (Wait)

  → Input: Timer expires → Go to State 2

  

State 2: GREEN (Go)

  → Input: Timer expires → Go to State 3

  

State 3: YELLOW (Caution)

  → Input: Timer expires → Go to State 1

### Our Digital Lock FSM:

State 0: LOCKED (Waiting for first button)

  → Input: Press button A → Go to State 1

  → Input: Press wrong button → Stay in State 0

  

State 1: WAITING (Got A, waiting for B)

  → Input: Press button B → Go to State 2

  → Input: Press wrong button → Go back to State 0

  

State 2: WAITING (Got A→B, waiting for C)

  → Input: Press button C → Go to State 3

  → Input: Press wrong button → Go back to State 0

  

State 3: WAITING (Got A→B→C, waiting for A again)

  → Input: Press button A → UNLOCKED\!

  → Input: Press wrong button → Go back to State 0

---

## 5\. SYSTEM REQUIREMENTS

### 5.1 FUNCTIONAL REQUIREMENTS

#### FR1: Correct Sequence Detection

- System must accept a predefined button sequence (e.g., A→B→C→A)  
- Only the exact sequence in order should unlock the system  
- **Example:** If pattern is A→B→C→A, then pressing A→B→A→C should NOT unlock

  #### FR2: Wrong Input Handling

- Any incorrect button press must reset the sequence  
- User must start over from the beginning  
- **Example:** If user presses A→B→D, system resets and expects A again

  #### FR3: Visual Feedback

- LED or display shows current lock status  
- LOCKED: LED OFF or shows "LOCKED"  
- UNLOCKED: LED ON or shows "UNLOCKED"

  #### FR4: Lock Reset

- A reset button returns system to locked state  
- Reset should work at any time

  #### FR5: Unlock Duration

- After unlocking, system stays unlocked for a set time (e.g., 5 seconds)  
- Automatically re-locks after timeout

  ### 5.2 TECHNICAL REQUIREMENTS

  #### TR1: VHDL Implementation

- Must be written in VHDL (not Verilog or other HDL)  
- Should synthesize to actual hardware (not simulation-only)

  #### TR2: Synchronous Design

- All state changes happen on clock edges  
- Single clock domain (all parts use same clock)

  #### TR3: Input Handling

- 4 input buttons (A, B, C, D)  
- Buttons are active-high (pressed \= logic '1')  
- Must handle button debouncing (prevent multiple triggers)

  #### TR4: Outputs

- Lock status LED (1 bit output)  
- Optional: Multi-bit status display  
- Optional: Current state indicator (for debugging)

  #### TR5: Clock Frequency

- Designed for standard FPGA clock (e.g., 50 MHz)  
- Timing requirements must be met for synthesis

  ### 5.3 NON-FUNCTIONAL REQUIREMENTS

  #### NFR1: Simplicity

- Code should be readable and well-commented  
- Clear state names and signal names  
- Maximum 150 lines of VHDL code

  #### NFR2: Testability

- Must include comprehensive testbench  
- All states and transitions should be testable  
- Edge cases must be covered

  #### NFR3: Modularity

- Separate modules for different functions  
- Main controller, debouncer, timer as separate entities

  ---

## 6\. SYSTEM ARCHITECTURE

### 6.1 BLOCK DIAGRAM

                ┌─────────────────────────────┐

                │                             │

BUTTONS         │                             │    LED

┌────┐         │                             │   ┌────┐

│ A  ├────────►│                             ├──►│ 🔴 │

│ B  ├────────►│   DIGITAL LOCK             │   └────┘

│ C  ├────────►│   CONTROLLER               │

│ D  ├────────►│   (FSM)                    │   STATUS

└────┘         │                             │   ┌────┐

                │                             ├──►│DISP│

CLOCK          │                             │   └────┘

───────────────►│                             │

                │                             │

RESET          │                             │

───────────────►│                             │

                │                             │

                └─────────────────────────────┘

### 6.2 MODULE BREAKDOWN

#### Module 1: BUTTON DEBOUNCER

- **Purpose:** Prevents false button presses from mechanical bounce  
- **Inputs:** Raw button signal, clock  
- **Outputs:** Clean button press signal  
- **Complexity:** LOW

  #### Module 2: FSM CONTROLLER (Main)

- **Purpose:** Implements the state machine logic  
- **Inputs:** Debounced buttons, clock, reset  
- **Outputs:** Lock status, current state  
- **Complexity:** MEDIUM

  #### Module 3: TIMER MODULE

- **Purpose:** Counts clock cycles for auto-relock timeout  
- **Inputs:** Clock, enable, reset  
- **Outputs:** Timeout signal  
- **Complexity:** LOW

  #### Module 4: TOP-LEVEL MODULE

- **Purpose:** Connects all modules together  
- **Contains:** Instantiations of all above modules  
- **Complexity:** LOW

  ---

## 7\. DETAILED STATE MACHINE DESIGN

### 7.1 STATE DEFINITIONS

For a lock with pattern **A→B→C→A:**

- **STATE\_LOCKED**: Waiting for first input (A)  
- **STATE\_FIRST**: Received A, waiting for B  
- **STATE\_SECOND**: Received A→B, waiting for C  
- **STATE\_THIRD**: Received A→B→C, waiting for final A  
- **STATE\_UNLOCKED**: Correct sequence entered, lock open

  ### 7.2 STATE TRANSITION TABLE

| Current State | Input | Next State | Output (LED) |
| :---- | :---- | :---- | :---- |
| STATE\_LOCKED | A | STATE\_FIRST | OFF |
| STATE\_LOCKED | B/C/D | STATE\_LOCKED | OFF |
| STATE\_FIRST | B | STATE\_SECOND | OFF |
| STATE\_FIRST | A/C/D | STATE\_LOCKED | OFF |
| STATE\_SECOND | C | STATE\_THIRD | OFF |
| STATE\_SECOND | A/B/D | STATE\_LOCKED | OFF |
| STATE\_THIRD | A | STATE\_UNLOCKED | OFF |
| STATE\_THIRD | B/C/D | STATE\_LOCKED | OFF |
| STATE\_UNLOCKED | any | STATE\_UNLOCKED | ON |
| STATE\_UNLOCKED | timeout | STATE\_LOCKED | OFF |

  ### 7.3 STATE MACHINE DIAGRAM

                              ┌────────────┐

                              │   RESET    │

                              └──────┬─────┘

                                     │

                                     ▼

                  ┌──────────────────────────────┐

             ┌────┤       STATE\_LOCKED           │◄────┐

             │    │     (Waiting for 'A')        │     │

             │    └──────────────┬───────────────┘     │

             │                   │ Press 'A'           │

             │                   ▼                     │

             │    ┌──────────────────────────────┐     │

             │    │       STATE\_FIRST            │     │

        Wrong│    │     (Received A, need B)     │     │Wrong

        Input│    └──────────────┬───────────────┘     │Input

             │                   │ Press 'B'           │

             │                   ▼                     │

             │    ┌──────────────────────────────┐     │

             │    │       STATE\_SECOND           │     │

             │    │     (Got A→B, need C)        │     │

             │    └──────────────┬───────────────┘     │

             │                   │ Press 'C'           │

             │                   ▼                     │

             │    ┌──────────────────────────────┐     │

             │    │       STATE\_THIRD            │     │

             └───►│     (Got A→B→C, need A)      │─────┘

                  └──────────────┬───────────────┘

                                 │ Press 'A'

                                 ▼

                  ┌──────────────────────────────┐

                  │      STATE\_UNLOCKED          │

                  │        (LED ON)              │

                  └──────────────┬───────────────┘

                                 │ Timeout

                                 ▼

                             (Loop back to LOCKED)

  ---

## 8\. INPUT/OUTPUT SPECIFICATIONS

### 8.1 INPUTS

| Signal Name | Type | Description |
| :---- | :---- | :---- |
| clk | std\_logic | System clock (e.g., 50 MHz) |
| reset | std\_logic | Asynchronous reset (active high) |
| button\_A | std\_logic | Button A input (active high) |
| button\_B | std\_logic | Button B input (active high) |
| button\_C | std\_logic | Button C input (active high) |
| button\_D | std\_logic | Button D input (active high) |

### 8.2 OUTPUTS

| Signal Name | Type | Description |
| :---- | :---- | :---- |
| lock\_status | std\_logic | '1' \= Unlocked, '0' \= Locked |
| led\_indicator | std\_logic | Visual feedback LED |
| state\_display | std\_logic\_vector(2 downto 0\) | Current state (optional) |

### 8.3 INTERNAL SIGNALS

| Signal Name | Type | Description |
| :---- | :---- | :---- |
| current\_state | state\_type | FSM current state |
| next\_state | state\_type | FSM next state |
| button\_pressed | std\_logic\_vector(3 downto 0\) | Debounced buttons |
| unlock\_timer | integer | Countdown timer for auto-lock |
| timer\_expired | std\_logic | Timer reached zero flag |

---

## 9\. VHDL CODE STRUCTURE EXPLANATION

### 9.1 ENTITY DECLARATION

This is like the "black box" view of your circuit \- defines inputs and outputs.

entity digital\_lock is

    Port ( 

        clk          : in  std\_logic;           \-- Clock input

        reset        : in  std\_logic;           \-- Reset button

        button\_A     : in  std\_logic;           \-- Button inputs

        button\_B     : in  std\_logic;

        button\_C     : in  std\_logic;

        button\_D     : in  std\_logic;

        lock\_status  : out std\_logic;           \-- Lock output

        led          : out std\_logic            \-- LED output

    );

end digital\_lock;

### 9.2 ARCHITECTURE STRUCTURE

This is the "inside" of the circuit \- how it actually works.

architecture Behavioral of digital\_lock is

    \-- Type definitions

    type state\_type is (STATE\_LOCKED, STATE\_FIRST, STATE\_SECOND, 

                        STATE\_THIRD, STATE\_UNLOCKED);

    

    \-- Signal declarations

    signal current\_state, next\_state : state\_type;

    signal unlock\_timer : integer range 0 to 50000000 := 0;

    

begin

    \-- Process blocks go here

end Behavioral;

### 9.3 PROCESS BLOCKS

VHDL uses "processes" \- blocks of code that execute when specific signals change.

#### Process 1: STATE REGISTER (Sequential Logic)

Updates the current state on each clock edge. This is the "memory" of the FSM.

process(clk, reset)

begin

    if reset \= '1' then

        current\_state \<= STATE\_LOCKED;

    elsif rising\_edge(clk) then

        current\_state \<= next\_state;

    end if;

end process;

#### Process 2: NEXT STATE LOGIC (Combinational Logic)

Determines what the next state should be based on current state and inputs. This is the "decision making" logic.

process(current\_state, button\_A, button\_B, button\_C, button\_D)

begin

    case current\_state is

        when STATE\_LOCKED \=\>

            if button\_A \= '1' then

                next\_state \<= STATE\_FIRST;

            else

                next\_state \<= STATE\_LOCKED;

            end if;

        

        when STATE\_FIRST \=\>

            if button\_B \= '1' then

                next\_state \<= STATE\_SECOND;

            else

                next\_state \<= STATE\_LOCKED;

            end if;

        

        \-- More cases...

    end case;

end process;

#### Process 3: OUTPUT LOGIC

Sets the outputs based on current state.

process(current\_state)

begin

    if current\_state \= STATE\_UNLOCKED then

        lock\_status \<= '1';

        led \<= '1';

    else

        lock\_status \<= '0';

        led \<= '0';

    end if;

end process;

---

## 10\. PHASED IMPLEMENTATION PLAN

---

## PHASE 0: PREPARATION (Day 1-2)

**Duration:** 1-2 days

### 10.1 Environment Setup

#### Task 0.1: Install Required Software

**□ Install VHDL simulator (Choose ONE):**

- **ModelSim** (Industry standard, free student version)  
- **GHDL** (Free, open-source)  
- **Vivado** (For Xilinx FPGAs, includes simulator)

  **Installation Instructions:**

- ModelSim: Download from Intel/Altera website  
- GHDL: Download from ghdl.free.fr  
- Vivado: Download from Xilinx website (requires registration)

  **□ Install Text Editor with VHDL syntax highlighting:**

- VS Code with VHDL extension (Recommended)  
- Notepad++ with VHDL language support  
- Sublime Text with VHDL package

  #### Task 0.2: Learn Basic VHDL Syntax

  **□ Study these concepts (2-3 hours):**

- Entity and Architecture  
- Signal vs Variable  
- Process blocks  
- If-then-else statements  
- Case statements  
- Clock edge detection (rising\_edge)

  **Resources:**

- "VHDL Tutorial" by Peter J. Ashenden (Chapter 1-2)  
- YouTube: "VHDL Basics for Beginners" by Neso Academy  
- Website: nandland.com/vhdl (excellent beginner tutorials)

  #### Task 0.3: Create Project Directory Structure

  Create the following folder structure on your computer:

  digital\_lock\_project/

  │

  ├── docs/

  │   └── (This PRD document)

  │

  ├── src/

  │   ├── digital\_lock.vhd          (Main FSM controller)

  │   ├── button\_debouncer.vhd      (Debounce circuit)

  │   ├── timer\_module.vhd           (Timer for auto-lock)

  │   └── top\_level.vhd              (Connects everything)

  │

  ├── testbench/

  │   ├── tb\_digital\_lock.vhd       (Testbench for FSM)

  │   └── tb\_top\_level.vhd          (Full system testbench)

  │

  ├── simulation/

  │   └── (Waveform files will go here)

  │

  └── synthesis/

      └── (Synthesis outputs will go here)

  ### Deliverables for Phase 0:

  ✓ Working VHDL simulator installed  
  ✓ Text editor configured  
  ✓ Project folders created  
  ✓ Basic VHDL concepts understood

  ---

## PHASE 1: BASIC FSM IMPLEMENTATION (Day 3-5)

**Duration:** 2-3 days

### 10.2 Create Simple FSM (No Timer, No Debouncing)

#### Task 1.1: Write Entity Declaration

**□ Create file:** `src/digital_lock.vhd`  
**□ Define entity** with inputs and outputs as specified in Section 8

**Expected Code (15 lines):**

library IEEE;

use IEEE.STD\_LOGIC\_1164.ALL;

entity digital\_lock is

    Port ( 

        clk          : in  std\_logic;

        reset        : in  std\_logic;

        button\_A     : in  std\_logic;

        button\_B     : in  std\_logic;

        button\_C     : in  std\_logic;

        button\_D     : in  std\_logic;

        lock\_status  : out std\_logic

    );

end digital\_lock;

#### Task 1.2: Define State Type

**□ In architecture section,** define enumerated type for states  
**□ Declare** current\_state and next\_state signals

**Expected Code (10 lines):**

architecture Behavioral of digital\_lock is

    \-- Define states

    type state\_type is (STATE\_LOCKED, STATE\_FIRST, STATE\_SECOND, 

                        STATE\_THIRD, STATE\_UNLOCKED);

    

    \-- State signals

    signal current\_state : state\_type := STATE\_LOCKED;

    signal next\_state    : state\_type;

begin

#### Task 1.3: Implement State Register Process

**□ Create process** sensitive to clock and reset  
**□ On reset:** go to STATE\_LOCKED  
**□ On clock edge:** update current\_state to next\_state

**Expected Code (12 lines):**

\-- Process 1: State Register

state\_register: process(clk, reset)

begin

    if reset \= '1' then

        current\_state \<= STATE\_LOCKED;

    elsif rising\_edge(clk) then

        current\_state \<= next\_state;

    end if;

end process state\_register;

#### Task 1.4: Implement Next State Logic

**□ Create process** with case statement  
**□ For each state,** check button inputs  
**□ Assign** next\_state based on correct/incorrect sequence

**Expected Code (40 lines):**

\-- Process 2: Next State Logic

next\_state\_logic: process(current\_state, button\_A, button\_B, 

                          button\_C, button\_D)

begin

    \-- Default assignment

    next\_state \<= current\_state;

    

    case current\_state is

        when STATE\_LOCKED \=\>

            if button\_A \= '1' then

                next\_state \<= STATE\_FIRST;

            elsif button\_B \= '1' or button\_C \= '1' or button\_D \= '1' then

                next\_state \<= STATE\_LOCKED;

            end if;

        

        when STATE\_FIRST \=\>

            if button\_B \= '1' then

                next\_state \<= STATE\_SECOND;

            elsif button\_A \= '1' or button\_C \= '1' or button\_D \= '1' then

                next\_state \<= STATE\_LOCKED;

            end if;

        

        when STATE\_SECOND \=\>

            if button\_C \= '1' then

                next\_state \<= STATE\_THIRD;

            elsif button\_A \= '1' or button\_B \= '1' or button\_D \= '1' then

                next\_state \<= STATE\_LOCKED;

            end if;

        

        when STATE\_THIRD \=\>

            if button\_A \= '1' then

                next\_state \<= STATE\_UNLOCKED;

            elsif button\_B \= '1' or button\_C \= '1' or button\_D \= '1' then

                next\_state \<= STATE\_LOCKED;

            end if;

        

        when STATE\_UNLOCKED \=\>

            next\_state \<= STATE\_UNLOCKED;  \-- Stay unlocked for now

        

        when others \=\>

            next\_state \<= STATE\_LOCKED;

    end case;

end process next\_state\_logic;

#### Task 1.5: Implement Output Logic

**□ Create process** to assign outputs based on current\_state  
**□ lock\_status** \= '1' when STATE\_UNLOCKED, else '0'

**Expected Code (10 lines):**

\-- Process 3: Output Logic

output\_logic: process(current\_state)

begin

    if current\_state \= STATE\_UNLOCKED then

        lock\_status \<= '1';

    else

        lock\_status \<= '0';

    end if;

end process output\_logic;

#### Task 1.6: Compile and Check Syntax

**□ Open simulator** (ModelSim/GHDL/Vivado)  
**□ Compile** the VHDL file  
**□ Fix** any syntax errors

**Commands (Example for ModelSim):**

vlib work

vcom \-93 src/digital\_lock.vhd

**Expected Outcome:** "Compile successful, no errors"

### Testing Checkpoint:

□ Code compiles without errors  
□ All processes are syntactically correct  
□ States are properly defined

### Deliverables for Phase 1:

✓ Complete digital\_lock.vhd file (\~90 lines)  
✓ Code compiles successfully  
✓ State machine logic implemented

---

## PHASE 2: TESTBENCH CREATION AND SIMULATION (Day 6-7)

**Duration:** 2 days

### 10.3 Write Basic Testbench

#### Task 2.1: Create Testbench File

**□ Create file:** `testbench/tb_digital_lock.vhd`  
**□ Testbench** has no ports (it's a test wrapper)

**Expected Code Structure (80 lines):**

library IEEE;

use IEEE.STD\_LOGIC\_1164.ALL;

entity tb\_digital\_lock is

\-- Testbench has no ports

end tb\_digital\_lock;

architecture Behavioral of tb\_digital\_lock is

    \-- Component declaration

    component digital\_lock

        Port ( 

            clk          : in  std\_logic;

            reset        : in  std\_logic;

            button\_A     : in  std\_logic;

            button\_B     : in  std\_logic;

            button\_C     : in  std\_logic;

            button\_D     : in  std\_logic;

            lock\_status  : out std\_logic

        );

    end component;

    

    \-- Test signals

    signal clk         : std\_logic := '0';

    signal reset       : std\_logic := '0';

    signal button\_A    : std\_logic := '0';

    signal button\_B    : std\_logic := '0';

    signal button\_C    : std\_logic := '0';

    signal button\_D    : std\_logic := '0';

    signal lock\_status : std\_logic;

    

    \-- Clock period definition

    constant clk\_period : time := 10 ns;

    

begin

    \-- Instantiate the Unit Under Test (UUT)

    uut: digital\_lock port map (

        clk         \=\> clk,

        reset       \=\> reset,

        button\_A    \=\> button\_A,

        button\_B    \=\> button\_B,

        button\_C    \=\> button\_C,

        button\_D    \=\> button\_D,

        lock\_status \=\> lock\_status

    );

    

    \-- Clock generation process

    clk\_process: process

    begin

        clk \<= '0';

        wait for clk\_period/2;

        clk \<= '1';

        wait for clk\_period/2;

    end process;

    

    \-- Stimulus process

    stim\_proc: process

    begin

        \-- Test Case 1: Reset

        reset \<= '1';

        wait for 20 ns;

        reset \<= '0';

        wait for 20 ns;

        

        \-- Test Case 2: Correct Sequence A→B→C→A

        button\_A \<= '1';  \-- Press A

        wait for 20 ns;

        button\_A \<= '0';  \-- Release A

        wait for 20 ns;

        

        button\_B \<= '1';  \-- Press B

        wait for 20 ns;

        button\_B \<= '0';  \-- Release B

        wait for 20 ns;

        

        button\_C \<= '1';  \-- Press C

        wait for 20 ns;

        button\_C \<= '0';  \-- Release C

        wait for 20 ns;

        

        button\_A \<= '1';  \-- Press A

        wait for 20 ns;

        button\_A \<= '0';  \-- Release A

        wait for 40 ns;

        

        \-- At this point lock\_status should be '1'

        assert lock\_status \= '1' 

            report "ERROR: Lock should be unlocked\!" 

            severity error;

        

        \-- Test Case 3: Wrong Sequence A→B→D

        reset \<= '1';

        wait for 20 ns;

        reset \<= '0';

        wait for 20 ns;

        

        button\_A \<= '1';

        wait for 20 ns;

        button\_A \<= '0';

        wait for 20 ns;

        

        button\_B \<= '1';

        wait for 20 ns;

        button\_B \<= '0';

        wait for 20 ns;

        

        button\_D \<= '1';  \-- Wrong button\!

        wait for 20 ns;

        button\_D \<= '0';

        wait for 20 ns;

        

        \-- Lock should still be locked

        assert lock\_status \= '0' 

            report "ERROR: Lock should be locked after wrong sequence\!" 

            severity error;

        

        \-- End simulation

        wait;

    end process;

end Behavioral;

#### Task 2.2: Compile Testbench

**□ Compile** both digital\_lock.vhd and tb\_digital\_lock.vhd

**Commands (ModelSim):**

vcom \-93 src/digital\_lock.vhd

vcom \-93 testbench/tb\_digital\_lock.vhd

#### Task 2.3: Run Simulation

**□ Load testbench**  
**□ Add signals** to waveform viewer  
**□ Run simulation** for sufficient time

**Commands (ModelSim):**

vsim tb\_digital\_lock

add wave \-radix binary sim:/tb\_digital\_lock/\*

run 1000 ns

#### Task 2.4: Analyze Waveforms

**□ Verify** state transitions match expected behavior  
**□ Check** timing of state changes  
**□ Verify** output signals

**What to Look For:**

- States progress: LOCKED → FIRST → SECOND → THIRD → UNLOCKED  
- After wrong button, state returns to LOCKED  
- lock\_status goes to '1' only in UNLOCKED state  
- All transitions happen on rising clock edge

  #### Task 2.5: Debug Issues

  **Common Problems and Solutions:**

| Problem | Solution |
| :---- | :---- |
| States not changing | Check that all buttons are properly connected in testbench |
| Lock unlocks on wrong sequence | Review next\_state\_logic process, check all button conditions |
| Multiple state changes per button press | Add button release (set to '0') between presses |

  ### Testing Checkpoint:

  □ Correct sequence (A→B→C→A) unlocks the system  
  □ Wrong sequence keeps system locked  
  □ Reset returns to LOCKED state  
  □ All assertions pass in testbench

  ### Deliverables for Phase 2:

  ✓ Working testbench file  
  ✓ Successful simulation showing correct behavior  
  ✓ Waveform screenshots saved  
  ✓ All test cases passing

  ---

## PHASE 3: ADD AUTO-RELOCK TIMER (Day 8-9)

**Duration:** 2 days

### 10.4 Implement Unlock Timeout Feature

#### Task 3.1: Modify FSM to Include Timer

**□ Add** unlock\_timer signal to digital\_lock.vhd  
**□ Add** timer counting logic

**Code to Add (in architecture declaration):**

signal unlock\_timer : integer range 0 to 50000000 := 0;

signal timer\_expired : std\_logic := '0';

constant UNLOCK\_TIME : integer := 5;  \-- 5 clock cycles for simulation

#### Task 3.2: Create Timer Process

**□ Add new process** to count down unlock timer  
**□ Timer starts** when entering UNLOCKED state  
**□ Sets** timer\_expired flag when reaches zero

**Code to Add:**

\-- Process 4: Unlock Timer

unlock\_timer\_proc: process(clk, reset)

begin

    if reset \= '1' then

        unlock\_timer \<= 0;

        timer\_expired \<= '0';

    elsif rising\_edge(clk) then

        if current\_state \= STATE\_UNLOCKED then

            if unlock\_timer \< UNLOCK\_TIME then

                unlock\_timer \<= unlock\_timer \+ 1;

                timer\_expired \<= '0';

            else

                timer\_expired \<= '1';

            end if;

        else

            unlock\_timer \<= 0;

            timer\_expired \<= '0';

        end if;

    end if;

end process unlock\_timer\_proc;

#### Task 3.3: Modify Next State Logic for Timer

**□ Update** UNLOCKED state case to check timer\_expired

**Code Modification:**

when STATE\_UNLOCKED \=\>

    if timer\_expired \= '1' then

        next\_state \<= STATE\_LOCKED;

    else

        next\_state \<= STATE\_UNLOCKED;

    end if;

#### Task 3.4: Update Testbench for Timer

**□ Modify testbench** to wait for auto-relock  
**□ Add assertion** to verify automatic locking

**Code to Add to Testbench:**

\-- Test Case 4: Auto-relock after timeout

reset \<= '1';

wait for 20 ns;

reset \<= '0';

wait for 20 ns;

\-- Enter correct sequence

button\_A \<= '1'; wait for 20 ns; button\_A \<= '0'; wait for 20 ns;

button\_B \<= '1'; wait for 20 ns; button\_B \<= '0'; wait for 20 ns;

button\_C \<= '1'; wait for 20 ns; button\_C \<= '0'; wait for 20 ns;

button\_A \<= '1'; wait for 20 ns; button\_A \<= '0'; wait for 20 ns;

\-- Verify unlocked

assert lock\_status \= '1' report "Should be unlocked" severity error;

\-- Wait for timeout (UNLOCK\_TIME \* clk\_period)

wait for 150 ns;

\-- Verify locked again

assert lock\_status \= '0' report "Should be locked after timeout" severity error;

#### Task 3.5: Test Timer Functionality

**□ Recompile** all files  
**□ Run simulation**  
**□ Verify** auto-relock works

### Testing Checkpoint:

□ System unlocks with correct sequence  
□ System automatically locks after timer expires  
□ Timer resets when returning to LOCKED state

### Deliverables for Phase 3:

✓ Updated digital\_lock.vhd with timer  
✓ Updated testbench  
✓ Successful simulation showing auto-relock  
✓ Timer operates correctly

---

## PHASE 4: BUTTON DEBOUNCING MODULE (Day 10-11)

**Duration:** 2 days

### 10.5 Create Debouncer Module

**Why Debouncing is Needed:**

Mechanical buttons "bounce" \- when pressed, they make/break contact multiple times in milliseconds. This causes multiple logic level changes. Debouncing ensures one press \= one clean signal.

#### Task 4.1: Create Debouncer Entity

**□ Create file:** `src/button_debouncer.vhd`  
**□ Define** generic debounce counter

**Expected Code (50 lines):**

library IEEE;

use IEEE.STD\_LOGIC\_1164.ALL;

entity button\_debouncer is

    Generic (

        DEBOUNCE\_TIME : integer := 10  \-- Number of clock cycles

    );

    Port ( 

        clk          : in  std\_logic;

        reset        : in  std\_logic;

        button\_in    : in  std\_logic;  \-- Raw button input

        button\_out   : out std\_logic   \-- Debounced output

    );

end button\_debouncer;

architecture Behavioral of button\_debouncer is

    signal counter : integer range 0 to DEBOUNCE\_TIME := 0;

    signal button\_stable : std\_logic := '0';

    signal button\_prev : std\_logic := '0';

begin

    process(clk, reset)

    begin

        if reset \= '1' then

            counter \<= 0;

            button\_stable \<= '0';

            button\_prev \<= '0';

            button\_out \<= '0';

        elsif rising\_edge(clk) then

            \-- If button state is same as previous

            if button\_in \= button\_prev then

                if counter \< DEBOUNCE\_TIME then

                    counter \<= counter \+ 1;

                else

                    \-- Button has been stable long enough

                    button\_stable \<= button\_in;

                end if;

            else

                \-- Button changed, reset counter

                counter \<= 0;

                button\_prev \<= button\_in;

            end if;

            

            \-- Generate edge detection (one pulse per press)

            if button\_stable \= '1' and button\_out \= '0' then

                button\_out \<= '1';

            else

                button\_out \<= '0';

            end if;

        end if;

    end process;

end Behavioral;

#### Task 4.2: Create Top-Level Module

**□ Create file:** `src/top_level.vhd`  
**□ Instantiate** debouncers for all buttons  
**□ Connect** to FSM controller

**Expected Code Structure (70 lines):**

library IEEE;

use IEEE.STD\_LOGIC\_1164.ALL;

entity top\_level is

    Port ( 

        clk          : in  std\_logic;

        reset        : in  std\_logic;

        button\_A\_raw : in  std\_logic;

        button\_B\_raw : in  std\_logic;

        button\_C\_raw : in  std\_logic;

        button\_D\_raw : in  std\_logic;

        lock\_status  : out std\_logic;

        led          : out std\_logic

    );

end top\_level;

architecture Behavioral of top\_level is

    \-- Component declarations

    component button\_debouncer

        Generic (DEBOUNCE\_TIME : integer := 10);

        Port ( 

            clk        : in  std\_logic;

            reset      : in  std\_logic;

            button\_in  : in  std\_logic;

            button\_out : out std\_logic

        );

    end component;

    

    component digital\_lock

        Port ( 

            clk          : in  std\_logic;

            reset        : in  std\_logic;

            button\_A     : in  std\_logic;

            button\_B     : in  std\_logic;

            button\_C     : in  std\_logic;

            button\_D     : in  std\_logic;

            lock\_status  : out std\_logic

        );

    end component;

    

    \-- Internal signals (debounced buttons)

    signal button\_A\_clean : std\_logic;

    signal button\_B\_clean : std\_logic;

    signal button\_C\_clean : std\_logic;

    signal button\_D\_clean : std\_logic;

    

begin

    \-- Debouncer instantiations

    debouncer\_A: button\_debouncer

        generic map (DEBOUNCE\_TIME \=\> 10\)

        port map (

            clk \=\> clk,

            reset \=\> reset,

            button\_in \=\> button\_A\_raw,

            button\_out \=\> button\_A\_clean

        );

    

    debouncer\_B: button\_debouncer

        generic map (DEBOUNCE\_TIME \=\> 10\)

        port map (

            clk \=\> clk,

            reset \=\> reset,

            button\_in \=\> button\_B\_raw,

            button\_out \=\> button\_B\_clean

        );

    

    debouncer\_C: button\_debouncer

        generic map (DEBOUNCE\_TIME \=\> 10\)

        port map (

            clk \=\> clk,

            reset \=\> reset,

            button\_in \=\> button\_C\_raw,

            button\_out \=\> button\_C\_clean

        );

    

    debouncer\_D: button\_debouncer

        generic map (DEBOUNCE\_TIME \=\> 10\)

        port map (

            clk \=\> clk,

            reset \=\> reset,

            button\_in \=\> button\_D\_raw,

            button\_out \=\> button\_D\_clean

        );

    

    \-- FSM controller instantiation

    fsm: digital\_lock

        port map (

            clk \=\> clk,

            reset \=\> reset,

            button\_A \=\> button\_A\_clean,

            button\_B \=\> button\_B\_clean,

            button\_C \=\> button\_C\_clean,

            button\_D \=\> button\_D\_clean,

            lock\_status \=\> lock\_status

        );

    

    \-- Connect lock status to LED

    led \<= lock\_status;

    

end Behavioral;

#### Task 4.3: Create Top-Level Testbench

**□ Create file:** `testbench/tb_top_level.vhd`  
**□ Test** with noisy button inputs

**Expected Code Addition to Testbench:**

\-- Test Case 5: Bouncy button press

button\_A\_raw \<= '1';

wait for 5 ns;

button\_A\_raw \<= '0';  \-- Bounce

wait for 3 ns;

button\_A\_raw \<= '1';  \-- Bounce

wait for 15 ns;

button\_A\_raw \<= '0';  \-- Release

wait for 30 ns;

\-- Should still register as single clean press

#### Task 4.4: Test Complete System

**□ Compile** all files  
**□ Run** top-level testbench  
**□ Verify** debouncing works

### Testing Checkpoint:

□ Bouncy inputs produce single clean pulses  
□ FSM receives clean button signals  
□ System still unlocks correctly

### Deliverables for Phase 4:

✓ Button debouncer module  
✓ Top-level integration module  
✓ Complete system testbench  
✓ Verified debouncing functionality

---

## PHASE 5: TESTING AND VALIDATION (Day 12-13)

**Duration:** 2 days

### 10.6 Comprehensive Testing

#### Task 5.1: Create Comprehensive Test Cases

**Test Case List:**

TC1: Basic Unlock \- Correct sequence A→B→C→A

     Expected: System unlocks, LED ON

TC2: Wrong First Button \- Press B first

     Expected: Stay locked

TC3: Wrong Middle Button \- A→B→D

     Expected: Reset to locked

TC4: Wrong Last Button \- A→B→C→B

     Expected: Reset to locked

TC5: Auto-Relock \- Unlock then wait

     Expected: Automatically locks after timeout

TC6: Reset During Sequence \- A→B→\[RESET\]

     Expected: Return to locked state immediately

TC7: Repeated Correct Sequence

     Expected: Can unlock multiple times

TC8: Button Held Down \- Press and hold A

     Expected: Single press registered (edge detection)

TC9: Multiple Simultaneous Buttons \- Press A+B together

     Expected: Treat as wrong input

TC10: Fast Button Presses \- Press buttons quickly

      Expected: System keeps up, no missed inputs

#### Task 5.2: Implement Test Cases in Testbench

**□ Add** all test cases to tb\_top\_level.vhd  
**□ Include** assertions for each expected result

#### Task 5.3: Run Full Test Suite

**□ Execute** complete testbench  
**□ Record** results for each test case  
**□ Fix** any failures

#### Task 5.4: Timing Analysis

**□ Measure** propagation delays  
**□ Check** setup and hold times  
**□ Verify** meets timing constraints

#### Task 5.5: Code Coverage Analysis

**□ Ensure** all states are visited  
**□ Verify** all transitions are tested  
**□ Check** all edge cases

### Testing Checkpoint:

□ All 10 test cases pass  
□ No timing violations  
□ 100% code coverage achieved

### Deliverables for Phase 5:

✓ Comprehensive test results document  
✓ All tests passing  
✓ Timing analysis report  
✓ Code coverage report

---

## PHASE 6: DOCUMENTATION AND CLEANUP (Day 14\)

**Duration:** 1 day

### 10.7 Final Documentation

#### Task 6.1: Code Documentation

**□ Add** header comments to all files  
**□ Comment** all signal declarations  
**□ Add** inline comments for complex logic  
**□ Document** timing parameters

**Example Header Comment:**

\--------------------------------------------------------------------------------

\-- File:        digital\_lock.vhd

\-- Description: Pattern-based digital lock using FSM

\-- Author:      \[Your Name\]

\-- Date:        \[Date\]

\-- Version:     1.0

\-- 

\-- Pattern:     A → B → C → A

\-- States:      5 (LOCKED, FIRST, SECOND, THIRD, UNLOCKED)

\-- Auto-lock:   Yes, after 5 seconds

\-- Features:    \- Sequential pattern detection

\--              \- Wrong input recovery

\--              \- Automatic re-lock timer

\--------------------------------------------------------------------------------

#### Task 6.2: Create User Manual

**□ Write** operating instructions  
**□ Include** state diagram  
**□ Document** pattern sequence  
**□ Explain** LED indicators

#### Task 6.3: Create Technical Report

**Document should include:**

- System overview and architecture  
- State machine design details  
- Implementation challenges and solutions  
- Test results summary  
- Waveform screenshots  
- Synthesis results (if applicable)  
- Lessons learned

  #### Task 6.4: Code Cleanup

  **□ Remove** unused signals  
  **□ Standardize** naming conventions  
  **□ Format** code consistently  
  **□ Remove** debug code

  #### Task 6.5: Create README File

  **□ Project** description  
  **□ File** structure explanation  
  **□ Compilation** instructions  
  **□ Simulation** instructions  
  **□ Synthesis** instructions (if applicable)

  ### Testing Checkpoint:

  □ All files properly commented  
  □ Documentation complete  
  □ Code is clean and organized

  ### Deliverables for Phase 6:

  ✓ Fully commented source code  
  ✓ User manual  
  ✓ Technical report  
  ✓ README file  
  ✓ Clean, organized project

  ---

## PHASE 7: ADVANCED FEATURES (OPTIONAL) (Day 15+)

**Duration:** As desired

### 10.8 Enhancement Options

#### Enhancement 1: Multiple Pattern Support

□ Allow pattern to be programmable  
□ Store pattern in memory  
□ Switch between different patterns

#### Enhancement 2: Pattern Length Configuration

□ Use generics to set pattern length  
□ Support 3-10 button sequences  
□ Dynamic state generation

#### Enhancement 3: Visual State Display

□ Add 7-segment display showing current state  
□ Binary LED indicators  
□ LCD display integration

#### Enhancement 4: Alarm System

□ Add buzzer for wrong attempts  
□ Count failed attempts  
□ Lockout after 3 failures

#### Enhancement 5: FPGA Implementation

□ Synthesize for actual FPGA board  
□ Connect physical buttons  
□ Add real LED indicators  
□ Deploy and test on hardware

#### Enhancement 6: Pattern Recording Mode

□ Allow user to set custom pattern  
□ Press special button sequence to enter programming mode  
□ Record new pattern  
□ Save to memory

---

## 11\. COMMON MISTAKES AND HOW TO AVOID THEM

### 11.1 VHDL-Specific Mistakes

#### Mistake 1: Signal vs Variable Confusion

**❌ WRONG:**

process(clk)

    variable temp : integer;

begin

    temp := 5;

    output \<= temp;  \-- Variable used outside process\!

end process;

**✓ CORRECT:**

signal temp : integer;

process(clk)

begin

    temp \<= 5;

    output \<= temp;

end process;

#### Mistake 2: Missing Sensitivity List

**❌ WRONG:**

process  \-- Missing sensitivity list

begin

    if input \= '1' then

        output \<= '1';

    end if;

end process;

**✓ CORRECT:**

process(input)

begin

    if input \= '1' then

        output \<= '1';

    end if;

end process;

#### Mistake 3: Incomplete If Statement (Latch Inference)

**❌ WRONG:**

process(sel)

begin

    if sel \= '1' then

        output \<= input;

    end if;

    \-- What happens when sel \= '0'? Creates latch\!

end process;

**✓ CORRECT:**

process(sel, input)

begin

    if sel \= '1' then

        output \<= input;

    else

        output \<= '0';

    end if;

end process;

#### Mistake 4: Multiple Clock Edge Detection

**❌ WRONG:**

if rising\_edge(clk) and enable \= '1' then

    \-- BAD\! Trying to detect two events

**✓ CORRECT:**

if rising\_edge(clk) then

    if enable \= '1' then

        \-- Good\! Clock edge, then check enable

### 11.2 FSM Design Mistakes

#### Mistake 5: Uninitialized State

**❌ WRONG:**

signal current\_state : state\_type;  \-- No initial value\!

**✓ CORRECT:**

signal current\_state : state\_type := STATE\_LOCKED;

#### Mistake 6: Missing Default Case

**❌ WRONG:**

case current\_state is

    when STATE\_LOCKED \=\> ...

    when STATE\_FIRST \=\> ...

    \-- Missing: when others

end case;

**✓ CORRECT:**

case current\_state is

    when STATE\_LOCKED \=\> ...

    when STATE\_FIRST \=\> ...

    when others \=\> next\_state \<= STATE\_LOCKED;

end case;

#### Mistake 7: Combinational Loop

**❌ WRONG:**

process(current\_state)

begin

    current\_state \<= next\_state;  \-- Creates loop\!

end process;

**✓ CORRECT:**

process(clk)

begin

    if rising\_edge(clk) then

        current\_state \<= next\_state;

    end if;

end process;

### 11.3 Testbench Mistakes

#### Mistake 8: No Wait Statements

**❌ WRONG:**

button\_A \<= '1';

button\_A \<= '0';  \-- Happens immediately\!

button\_B \<= '1';

**✓ CORRECT:**

button\_A \<= '1';

wait for 20 ns;

button\_A \<= '0';

wait for 20 ns;

#### Mistake 9: Wrong Time Units

**❌ WRONG:**

wait for 20;  \-- 20 what? Error\!

**✓ CORRECT:**

wait for 20 ns;  \-- Clear time unit

---

## 12\. DEBUGGING STRATEGIES

### 12.1 Simulation Debugging

#### Strategy 1: Wave Form Analysis

- Add ALL signals to waveform viewer  
- Look for unexpected transitions  
- Check timing relationships  
- Verify state progression

  #### Strategy 2: Assert Statements

- Add assertions at critical points  
- Check expected values  
- Use severity levels (warning, error, failure)

  **Example:**

  assert lock\_status \= '1' 

      report "Lock should be open\!" 

      severity error;

  #### Strategy 3: Report Statements

- Print signal values at key moments  
- Track state transitions  
- Monitor counter values

  **Example:**

  report "Entered STATE\_FIRST" severity note;

  ### 12.2 Common Issues and Solutions

  #### Issue: States Don't Change

  **Possible Causes:**

- Clock not toggling in testbench  
- Reset held active  
- Next state logic incorrect

  **Debug Steps:**

1. Check clock waveform  
2. Verify reset releases  
3. Add reports in next\_state process

   #### Issue: Multiple Transitions per Clock

   **Possible Causes:**

- Multiple processes updating same signal  
- No edge detection on inputs

  **Debug Steps:**

1. Check all processes  
2. Add edge detection on buttons  
3. Verify sensitivity lists

   #### Issue: Wrong State Reached

   **Possible Causes:**

- Case statement logic error  
- Missing button condition  
- Wrong comparison

  **Debug Steps:**

1. Add reports in each case  
2. Verify button signals  
3. Check all conditions carefully

   ---

## 13\. SYNTHESIS CONSIDERATIONS

### 13.1 Synthesis vs Simulation Differences

**Simulation:**

- Can use real numbers, floating point  
- Timing is idealized  
- Can use behavioral descriptions

  **Synthesis:**

- Must use synthesizable constructs  
- Real hardware delays exist  
- Must map to actual gates/flip-flops

  ### 13.2 Synthesizable VHDL Guidelines

  **✓ DO:**

- Use std\_logic and std\_logic\_vector  
- Use rising\_edge(clk) for clock edges  
- Initialize all signals  
- Use synchronous resets  
- Keep combinational logic simple

  **✗ DON'T:**

- Use after delays (synthesis ignores them)  
- Use wait for (except in testbenches)  
- Create combinational loops  
- Use file I/O operations  
- Use real or floating point types

  ### 13.3 Resource Utilization Estimates

  For this project on typical FPGA:

- **Flip-flops:** \~20-30 (for state register, counters)  
- **LUTs:** \~50-100 (for next state logic)  
- **I/O pins:** 7 (4 buttons \+ 1 reset \+ 1 clock \+ 1 LED)  
- **Block RAM:** 0 (not needed for this project)

  ---

## 14\. ADDITIONAL RESOURCES

### 14.1 Recommended Reading

**Books:**

- "Free Range VHDL" by Bryan Mealy and Fabrizio Tappero (FREE PDF)  
- "Circuit Design with VHDL" by Volnei A. Pedroni  
- "VHDL for Engineers" by Kenneth Short

  **Online Tutorials:**

- nandland.com \- Excellent beginner tutorials  
- VHDL Tutorial by Peter Ashenden (PDF)  
- surf-vhdl.com \- Interactive VHDL learning

  **Video Courses:**

- Neso Academy \- VHDL Tutorial Series (YouTube)  
- FPGAs for Beginners (Udemy)

  ### 14.2 VHDL Quick Reference

  **Signal Assignment:**

  signal\_name \<= value;              \-- Concurrent

  signal\_name \<= value after 10 ns;  \-- With delay (sim only)

  **Process Template:**

  process(sensitivity\_list)

  begin

      \-- Sequential statements

  end process;

  **Clocked Process:**

  process(clk, reset)

  begin

      if reset \= '1' then

          \-- Reset actions

      elsif rising\_edge(clk) then

          \-- Clocked actions

      end if;

  end process;

  **Case Statement:**

  case expression is

      when value1 \=\> statements;

      when value2 \=\> statements;

      when others \=\> statements;

  end case;

  **If Statement:**

  if condition1 then

      statements;

  elsif condition2 then

      statements;

  else

      statements;

  end if;

  ### 14.3 Helpful Commands

  **ModelSim:**

  vlib work                      \-- Create work library

  vcom file.vhd                  \-- Compile VHDL file

  vsim entity\_name               \-- Start simulation

  add wave \*                     \-- Add all signals

  run 1000 ns                    \-- Run simulation

  restart \-f                     \-- Restart simulation

  quit \-f                        \-- Exit

  **GHDL:**

  ghdl \-a file.vhd               \-- Analyze file

  ghdl \-e entity\_name            \-- Elaborate entity

  ghdl \-r entity\_name \--wave=output.ghw  \-- Run and save waveform

  gtkwave output.ghw             \-- View waveform

  ---

## 15\. GRADING RUBRIC (For Academic Use)

If submitting as academic project:

| Component | Points |
| :---- | :---- |
| **1\. FSM Design (20 points)** |  |
| • Correct state definitions | 5 |
| • Proper state transitions | 10 |
| • Reset functionality | 5 |
| **2\. VHDL Implementation (25 points)** |  |
| • Syntax correctness | 5 |
| • Coding style and comments | 5 |
| • Synthesizable code | 5 |
| • Proper signal usage | 5 |
| • No warnings during compilation | 5 |
| **3\. Testbench (20 points)** |  |
| • Comprehensive test cases | 10 |
| • Correct assertions | 5 |
| • Good test coverage | 5 |
| **4\. Functionality (25 points)** |  |
| • Correct sequence detection | 10 |
| • Wrong input handling | 5 |
| • Auto-relock feature | 5 |
| • Debouncing (if implemented) | 5 |
| **5\. Documentation (10 points)** |  |
| • Code comments | 3 |
| • Technical report | 4 |
| • User manual | 3 |
| **TOTAL:** | **100 points** |

**Bonus Points (up to 10):**

- FPGA implementation: \+5  
- Advanced features: \+5

  ---

## 16\. TROUBLESHOOTING GUIDE

### 16.1 Compilation Errors

| Error | Solution |
| :---- | :---- |
| "cannot open file" | Check file path, ensure file exists |
| "type mismatch" | Verify signal types match in assignments |
| "sensitivity list incomplete" | Add all read signals to process sensitivity list |
| "multiple drivers" | Ensure signal is assigned in only one process |

### 16.2 Simulation Errors

**Error: No waveform shows up**

**Solution:**

- Check if signals were added to wave window  
- Verify simulation actually ran (check console)

  **Error: Clock not toggling**

  **Solution:**

- Check clock generation process  
- Verify clk\_period constant is defined

  **Error: All signals are 'X' or 'U'**

  **Solution:**

- Initialize all signals  
- Check reset logic  
- Verify testbench connectivity

  ### 16.3 Functional Errors

  **Error: Lock unlocks on wrong sequence**

  **Solution:**

- Review case statement logic  
- Add reports to track state  
- Verify button conditions

  **Error: States don't transition**

  **Solution:**

- Check next\_state assignments  
- Verify state register process  
- Ensure clock is running

  **Error: Multiple state changes per button press**

  **Solution:**

- Implement edge detection  
- Add button release between presses in testbench

  ---

## 17\. PROJECT COMPLETION CHECKLIST

### PHASE 0: PREPARATION

- □ VHDL simulator installed and tested  
- □ Text editor configured  
- □ Project directory structure created  
- □ Basic VHDL concepts understood

  ### PHASE 1: BASIC FSM

- □ Entity declaration complete  
- □ State type defined  
- □ State register process implemented  
- □ Next state logic implemented  
- □ Output logic implemented  
- □ Code compiles without errors

  ### PHASE 2: TESTBENCH

- □ Testbench file created  
- □ Clock generation working  
- □ Test stimuli written  
- □ Simulation runs successfully  
- □ Correct sequence test passes  
- □ Wrong sequence test passes

  ### PHASE 3: AUTO-RELOCK

- □ Timer signal added  
- □ Timer process implemented  
- □ Next state logic updated for timer  
- □ Testbench updated  
- □ Auto-relock verified in simulation

  ### PHASE 4: DEBOUNCING

- □ Debouncer module created  
- □ Top-level module created  
- □ All modules connected  
- □ Top-level testbench created  
- □ Debouncing verified

  ### PHASE 5: TESTING

- □ All 10 test cases implemented  
- □ All tests passing  
- □ Timing verified  
- □ Code coverage checked

  ### PHASE 6: DOCUMENTATION

- □ Code fully commented  
- □ User manual written  
- □ Technical report complete  
- □ README created  
- □ Code cleaned up

  ### FINAL DELIVERABLES

- □ All source files organized  
- □ All testbenches included  
- □ Documentation complete  
- □ Waveform screenshots saved  
- □ Project ready for submission

  ---

## 18\. EXPECTED PROJECT OUTCOMES

Upon completion, you will have:

### 1\. Working VHDL Files:

- digital\_lock.vhd (\~100 lines)  
- button\_debouncer.vhd (\~60 lines)  
- top\_level.vhd (\~80 lines)  
- tb\_digital\_lock.vhd (\~150 lines)  
- tb\_top\_level.vhd (\~200 lines)

  ### 2\. Skills Acquired:

  ✓ VHDL syntax and structure  
  ✓ FSM design methodology  
  ✓ Testbench creation  
  ✓ Waveform analysis  
  ✓ Debugging techniques  
  ✓ Hardware description thinking

  ### 3\. Deliverables:

  ✓ Complete source code  
  ✓ Simulation results  
  ✓ Waveform screenshots  
  ✓ Technical documentation  
  ✓ Test reports

  ### 4\. Total Project Size:

- **Lines of code:** \~590 lines  
- **Files:** 5 VHDL files  
- **Documentation:** 20+ pages  
- **Time invested:** 30-40 hours

  ---

## 19\. NEXT STEPS AFTER COMPLETION

Once you've completed this project, consider:

### 1\. FPGA Implementation

- Purchase development board (e.g., Basys 3, DE10-Lite)  
- Learn synthesis tools (Vivado, Quartus)  
- Deploy to real hardware

  ### 2\. More Complex Projects

- Try the elevator controller (\#5 from original list)  
- Implement a traffic light controller  
- Design a UART communication module

  ### 3\. Advanced VHDL Topics

- Learn about IP cores  
- Study AXI interfaces  
- Explore high-level synthesis

  ### 4\. Digital Design Theory

- Study timing analysis in depth  
- Learn about metastability  
- Explore clock domain crossing

  ---

## 20\. SUPPORT AND HELP

If you get stuck:

### 1\. Check This Document

- Review relevant section  
- Check troubleshooting guide  
- Look at code examples

  ### 2\. Simulator Documentation

- ModelSim User Manual  
- GHDL Documentation  
- Vivado Simulator Guide

  ### 3\. Online Resources

- Stack Overflow (tag: vhdl)  
- Reddit: r/FPGA  
- EDN Network forums

  ### 4\. Ask for Help

- Instructor/Teaching Assistant  
- Study group members  
- Online communities

  **Remember:** Everyone struggles with VHDL at first. It's normal to feel confused. The key is persistence and practice\!

  ---

## CONCLUSION

This PRD provides everything you need to successfully implement a pattern-based digital lock in VHDL. Follow the phases sequentially, don't skip steps, and take time to understand each concept before moving forward.

**Good luck with your project\! You're about to learn one of the most valuable skills in digital design.**

---

**Document Version:** 1.0  
**Last Updated:** December 4, 2025  
**Author:** Claude (Anthropic AI Assistant)  
**License:** Educational Use

---

