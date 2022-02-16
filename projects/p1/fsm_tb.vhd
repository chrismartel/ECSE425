-- ECSE 425 Project Part 1 Testbench
-- McGill University, W2022
-- Sam Perreault, 260829298
-- Christian Martel, 260867191
-- Joseph Cotnareanu, 260838160

LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;

ENTITY fsm_tb IS
END fsm_tb;

ARCHITECTURE behaviour OF fsm_tb IS

COMPONENT comments_fsm IS
PORT (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
END COMPONENT;

--The input signals with their initial values
SIGNAL clk, s_reset, s_output: STD_LOGIC := '0';
SIGNAL s_input: std_logic_vector(7 downto 0) := (others => '0');

CONSTANT clk_period : time := 1 ns;
CONSTANT SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
CONSTANT STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
CONSTANT NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

BEGIN
dut: comments_fsm
PORT MAP(clk, s_reset, s_input, s_output);

 --clock process
clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;
 
--TODO: Thoroughly test your FSM
stim_process: PROCESS
BEGIN    
	REPORT "Example case, reading a meaningless character";
	s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;
	REPORT "_______________________";
    
    -- ensure that it stays the same at 0
    
    s_input <= "01111010";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should be '0'" SEVERITY ERROR;
    
    -- test reset by starting comment
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a single line comment 1st character, the output should remain the same '0'" SEVERITY ERROR;
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a single line comment 2nd character, the output should remain the same '0'" SEVERITY ERROR;
    
    s_input <= "01011011";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When a single line comment is started, the output should be '1'" SEVERITY ERROR;
    
    s_reset <= '1';
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When the reset line is active, the output should be '0'" SEVERITY ERROR;
    
    s_reset <= '0';
    
    -- fake start comment
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a comment, the output should remain the same '0'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When canceling a start comment, the output should remain the same '0'" SEVERITY ERROR;
    
    -- confirm that start comment failed
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When start comment was cancelled, the output should remain '0'" SEVERITY ERROR;
    
    -- start SLC for real
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a single line comment 1st character, the output should remain the same '0'" SEVERITY ERROR;
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a single line comment 2nd character, the output should remain the same '0'" SEVERITY ERROR;
    
    -- single line comment for a bit
    
    s_input <= "01011011";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When a single line comment is started, the output should be '1'" SEVERITY ERROR;
    
    -- check MLC end does not end comment
    
    s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When in a single line comment, multi-line comment end should be ignored 1st character, the output should be '1'" SEVERITY ERROR;
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When in a single line comment, multi-line comment end should be ignored 2nd character, the output should be '1'" SEVERITY ERROR;
    
    -- confirm MLC does not end comment
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When in a single line comment, multi-line comment end should be ignored, the output should stay '1'" SEVERITY ERROR;
    
    -- end SLC
    
    s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When ending a single-line comment, the output should remain the same '1'" SEVERITY ERROR;
    
    -- confirm end SLC
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When a single-line comment has ended, the output should be '0'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should remain the same '0'" SEVERITY ERROR;
    
    -- start MLC
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a multi-line comment 1st character, the output should remain the same '0'" SEVERITY ERROR;
    
    s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When starting a multi-line comment 2nd character, the output should remain the same '0'" SEVERITY ERROR;
    
    -- confirm MLC start
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When a multi-line comment has started, the output should be '1'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a meaningless character, the output should remain the same '1'" SEVERITY ERROR;
    
    -- check newline does not end MLC
    
    s_input <= NEW_LINE_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When in a multi-line comment, newlines should be ignored, the output should remain the same '1'" SEVERITY ERROR;
    
    -- confirm newline does not end MLC
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When in a multi-line comment, confirm the newlines should be ignored, the output should remain the same '1'" SEVERITY ERROR;
    
    -- fake end MLC
    
    s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When attempting to end a multi-line comment, the output should remain the same '1'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When aborting ending a multi-line comment, the output should remain the same '1'" SEVERITY ERROR;
    
    -- confirm MLC continues
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When multi-line comment end was aborted, the output should remain the same '1'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When reading a meaningless character, the output should remain the same '1'" SEVERITY ERROR;
    
    -- end MLC for real
    
    s_input <= STAR_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When ending a multi-line comment 1st character, the output should remain the same '1'" SEVERITY ERROR;
    
    s_input <= SLASH_CHARACTER;
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '1') REPORT "When ending a multi-line comment 2nd character, the output should remain the same '1'" SEVERITY ERROR;
    
    -- confirm end MLC
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When a multi-line comment is ended, the output should be '0'" SEVERITY ERROR;
    
    s_input <= "01011000";
	WAIT FOR 1 * clk_period;
	ASSERT (s_output = '0') REPORT "When reading a meaningless character, the output should remain the same '0'" SEVERITY ERROR;
    
	WAIT;
END PROCESS stim_process;
END;
