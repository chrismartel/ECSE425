library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache_tb is
end cache_tb;

architecture behavior of cache_tb is

component cache is
generic(
    ram_size : INTEGER := 32768
);
port(
    clock : in std_logic;
    reset : in std_logic;

    -- Avalon interface --
    s_addr : in std_logic_vector (31 downto 0);
    s_read : in std_logic;
    s_readdata : out std_logic_vector (31 downto 0);
    s_write : in std_logic;
    s_writedata : in std_logic_vector (31 downto 0);
    s_waitrequest : out std_logic; 

    m_addr : out integer range 0 to ram_size-1;
    m_read : out std_logic;
    m_readdata : in std_logic_vector (7 downto 0);
    m_write : out std_logic;
    m_writedata : out std_logic_vector (7 downto 0);
    m_waitrequest : in std_logic
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 1 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO ram_size-1;
    memwrite: IN STD_LOGIC := '0';
    memread: IN STD_LOGIC := '0';
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 1 ns;

signal s_addr : std_logic_vector (31 downto 0);
signal s_read : std_logic;
signal s_readdata : std_logic_vector (31 downto 0);
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest : std_logic;

signal m_addr : integer range 0 to 2147483647;
signal m_read : std_logic;
signal m_readdata : std_logic_vector (7 downto 0);
signal m_write : std_logic;
signal m_writedata : std_logic_vector (7 downto 0);
signal m_waitrequest : std_logic; 

-- Format of last 15 bits --> TTTTTTIIIIIWWBB
-- Where T = Tag bits, I = Index bits, W = Word offset; B = Byte offset.

-- addresses
constant ADDRESS_TAG0 : std_logic_vector (31 downto 0) := "00000000000000000000000000000000"; -- first word of block 0, tag 0
constant ADDRESS_TAG1 : std_logic_vector (31 downto 0) := "00000000000000000000001000000000"; -- first word of block 0, tag 1
-- data
constant DEFAULT_DATA : std_logic_vector (31 downto 0) := "00000011000000100000000100000000"; -- default value of word 0 of block 0
constant DATA1 : std_logic_vector (31 downto 0) := "00000000000000000000000000000001"; -- data to write on first word of first block with tag 0
constant DATA2 : std_logic_vector (31 downto 0) := "00000000000000000000000000000010"; -- data to write on first word of second block with tag 0
constant DATA3 : std_logic_vector (31 downto 0) := "00000000000000000000000000000100"; -- data to write on first word of first block with tag 1

-- other values...
begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    clock => clk,
    reset => reset,

    s_addr => s_addr,
    s_read => s_read,
    s_readdata => s_readdata,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,

    m_addr => m_addr,
    m_read => m_read,
    m_readdata => m_readdata,
    m_write => m_write,
    m_writedata => m_writedata,
    m_waitrequest => m_waitrequest
);

MEM : memory
port map (
    clock => clk,
    writedata => m_writedata,
    address => m_addr,
    memwrite => m_write,
    memread => m_read,
    readdata => m_readdata,
    waitrequest => m_waitrequest
);
				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin

-- put your tests here

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for clk_period;
  reset <= '1';
  wait for clk_period;
  reset <= '0';
  wait for clk_period;
  ----------------------------------------------------------------------------------
  
  report "----- Starting tests -----";

  ----------------------------------------------------------------------------------
  -- CASE 1: Not Valid, Write
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=0, dirty=0, tag=U, first word=U
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=1, tag=0, first word=DATA1

  report "----- Case 1: Not Valid, Write -----";
  s_addr <= ADDRESS_TAG0;
  s_writedata <= DATA1;
  s_write <= '1';
  wait until falling_edge(s_waitrequest);
  s_write <= '0';

  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0;
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DATA1 report "Case 1: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- RESET
  ----------------------------------------------------------------------------------
  wait for clk_period;
  reset <= '1';
  wait for clk_period;
  reset <= '0';
  wait for clk_period;

  ----------------------------------------------------------------------------------
  -- CASE 2: Not Valid, Read
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=0, dirty=0, tag=U, first word=U
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=0, tag=0, first word=DATA_BLOCK0_DEFAULT


  report "----- Case 1: Not Valid, Read -----";
  s_addr <= ADDRESS_TAG0;
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DEFAULT_DATA report "Case 1: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- CASE 3: Valid, Tag Equal, Read
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=1, dirty=0, tag=0, first word=DATA_BLOCK0_DEFAULT
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=0, tag=0, first word=DATA_BLOCK0_DEFAULT

  report "----- Case 3: Valid, Tag equal, Read";
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0; -- read first word of block 0
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DEFAULT_DATA report "Case 3: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- CASE 4: Valid, Tag Equal, Write
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=1, dirty=0, tag=0, first word=DATA_BLOCK0_DEFAULT
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=1, tag=0, first word=DATA1

  report "----- Case 4: Valid, Tag equal, Write";
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0;
  s_writedata <= DATA1;
  s_write <= '1';
  wait until falling_edge(s_waitrequest);
  s_write <= '0';

  -- verify that write was successful
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0;
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DATA1 report "Case 4: Unsuccessful write" severity error;

  ----------------------------------------------------------------------------------
  -- CASE 5: Valid, Tag Not Equal, Dirty, Write
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=1, dirty=1, tag=0, first word=DATA1
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=1, tag=1, first word=DATA2

  report "----- Case 5: Valid, Tag not equal, dirty, Write";
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG1;
  s_writedata <= DATA2;
  s_write <= '1';
  wait until falling_edge(s_waitrequest);
  s_write <= '0';

  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG1;
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DATA2 report "Case 5: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- CASE 6: Valid, Tag Not Equal, Dirty, Read
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=1, dirty=1, tag=1, first word=DATA2
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=0, tag=0, first word=DATA1

  report "----- Case 6: Valid, Tag not equal, dirty, Read";
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0;
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DATA1 report "Case 6: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- CASE 7: Valid, Tag Not Equal, Not Dirty, Read
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=1, dirty=0, tag=0, first word=DATA2
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=0, tag=1, first word=DATA2

  report "----- Case 7: Valid, Tag not equal, not dirty, Read";
  -- Read block with index i and tag 0
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG1;
  s_read <= '1';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DATA2 report "Case 7: Unsuccessful" severity error;

  ----------------------------------------------------------------------------------
  -- CASE 8: Valid, Tag Not Equal, Not Dirty, Write
  ----------------------------------------------------------------------------------
  -- Pre:
  -- 	Block 0: valid=1, dirty=0, tag=1, first word=DATA2
  --
  -- Post:
  -- 	Block 0: valid=1, dirty=1, tag=0, first word=DATA3

  report "----- Case 8: Valid, Tag not equal, not dirty, Write";
  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0;
  s_writedata <= DATA3;
  s_write <= '1';
  wait until falling_edge(s_waitrequest);
  s_write <= '0';

  wait until rising_edge(s_waitrequest);
  s_addr <= ADDRESS_TAG0;
  s_read <= '1';
  s_write <= '0';
  wait until falling_edge(s_waitrequest);
  s_read <= '0';
  assert s_readdata = DATA3 report "Case 8: Unsuccessful" severity error;
  ----------------------------------------------------------------------------------

  report "----- Confirming all tests have ran -----";
  wait;

end process;
	
end;