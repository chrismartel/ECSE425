-- ECSE 425 Project Part 1 Testbench
-- McGill University, W2022
-- Sam Perreault, 260829298
-- Christian Martel, 260867191
-- Joseph Cotnareanu, 260838160

library ieee;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

-- Do not modify the port map of this structure
entity comments_fsm is
port (clk : in std_logic;
      reset : in std_logic;
      input : in std_logic_vector(7 downto 0);
      output : out std_logic
  );
end comments_fsm;

architecture behavioral of comments_fsm is
type state_type is (
	NOT_COMMENT, 	-- Not in a comment section

 	MID_ENTRY,	-- Begin of the comment opening sequence,
			-- i.e '/' is last character inputted.

	SINGLE_LINE, 	-- Inside a single line comment section, 
			-- i.e, between '//' and '\n' sequences.

        MULTI_LINE,	-- Inside a multi-line comment section, 
			-- i.e, between '/*/ and '*/' sequences.

	MULTI_MID_EXIT  -- Begin of the multi-line comment closing sequence,
			-- i.e '*' is last character inputted.
);
signal current_state: state_type;
-- The ASCII value for the '/', '*' and end-of-line characters
constant SLASH_CHARACTER : std_logic_vector(7 downto 0) := "00101111";
constant STAR_CHARACTER : std_logic_vector(7 downto 0) := "00101010";
constant NEW_LINE_CHARACTER : std_logic_vector(7 downto 0) := "00001010";

begin

-- Insert your processes here
 process (clk, reset)
begin
-- Asynchronous reset active-high
if reset'event and reset = '1' then
    current_state <= NOT_COMMENT;

-- Synchronous active-high clock signal
elsif clk'event and clk = '1' then
    case current_state is
	-- State transition and output per cycle
	-- depending on the current state and input.
        when NOT_COMMENT =>
	    if input = SLASH_CHARACTER then
	        output <= '0';
		current_state <= MID_ENTRY;
            else
	        output <= '0';
		current_state <= NOT_COMMENT;
            end if;

        when MID_ENTRY =>
	    if input = SLASH_CHARACTER then
		current_state <= SINGLE_LINE;
	        output <= '0';
            elsif input = STAR_CHARACTER then
		current_state <= MULTI_LINE;
	        output <= '0';
            else
        current_state <= NOT_COMMENT;
	        output <= '0';
            end if;

        when SINGLE_LINE =>
	    if input = NEW_LINE_CHARACTER then
		current_state <= NOT_COMMENT;
                output <= '1';
            else
		current_state <= SINGLE_LINE;        
		output <= '1';
            end if;

        when MULTI_LINE =>
	    if input = STAR_CHARACTER then
		current_state <= MULTI_MID_EXIT;
		output <= '1';
            else
		current_state <= MULTI_LINE;
		output <= '1';
            end if;

	when MULTI_MID_EXIT =>
	    if input = SLASH_CHARACTER then
		current_state <= NOT_COMMENT;
		output <= '1';
            else
		current_state <= MULTI_LINE;
		output <= '1';
            end if;
    end case;
end if;
end process;
end behavioral;