library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768;
	number_of_blocks : INTEGER := 32; -- number of blocks in cache
	block_size : INTEGER := 16	-- number of bytes in a block
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
end cache;

architecture arch of cache is

-- declare signals here
	type cache_block is array(block_size-1 downto 0) of std_logic_vector(7 downto 0); 	-- block of bytes
	type flag_array is array(number_of_blocks-1 downto 0) of std_logic;			-- single bit array
	type tag_array is array(number_of_blocks-1 downto 0) of std_logic_vector(5 downto 0);	-- 6-bit segments array
	type cache_data is array(number_of_blocks-1 downto 0) of cache_block;			-- array of cache blocks

	type cache_state is (
		IDLE, 			-- cache waits for commands

 		READ_CACHE, 		-- try to read a word from cache

		WRITE_CACHE, 		-- try to write a word to cache

		READ_MEM_WAIT,		-- wait for memory read operation to complete
		
		WRITE_MEM_WAIT,		-- wait for memory write operation to complete

        	READ_MEM,		-- init byte-read transaction from memory

		WRITE_MEM		-- init byte-write transaction to memory
	); 

	signal data : cache_data; 	-- cache data blocks
	signal tag : tag_array;		-- tag bits for each cache block
	signal valid : flag_array; 	-- valid bits for each cache block
	signal dirty : flag_array; 	-- dirty bits for each cache block

	signal query_tag: std_logic_vector(5 downto 0); 	-- tag of the query block		
	signal index: integer range 0 to 31;		-- block index
	signal query_byte_offset: integer range 0 to 3;		-- block offset
	
	signal current_state: cache_state;		-- current cache state
	signal mem_byte_offset: integer range 0 to 15;	-- byte offset in a memory block
begin

-- make circuits here
	cache_process: process(clock, reset)
	begin
	-- Asynchronous reset active-high
	-- All blocks are not valid anymore and are not dirty
	if reset'event and reset = '1' then
		For i in 0 to number_of_blocks-1 loop
			valid(i) <= '0'; -- blocks are initially invalid
			dirty(i) <= '0'; -- all blocks are initially clean
		end loop;
		-- Assert wait request to high
		s_waitrequest <= '1';
		current_state <= IDLE;
		
		m_read <= '0';
		m_write <= '0';

	-- Synchronous active-high clock signal
	elsif clock'event and clock = '1' then
		case current_state is
			when IDLE =>
				s_waitrequest <= '1';
				if s_read = '1' then
					current_state <= READ_CACHE;
				elsif s_write = '1' then
					current_state <= WRITE_CACHE;
				else
					current_state <= IDLE;
				end if;
			-- Read data from cache
			when READ_CACHE =>
				query_byte_offset <= to_integer(unsigned(s_addr(3 downto 0)));
				index <= to_integer(unsigned(s_addr(8 downto 4)));
				query_tag <= s_addr(14 downto 9);
				-- check valid bit
				if valid(index) = '1' then
					-- check tag
					if query_tag = tag(index) then
						-- tag match --> cache hit!
				
						-- read word
						-- TODO: read whole word at once
						s_readdata(31 downto 24) <= data(index)(query_byte_offset+3);
						s_readdata(23 downto 16) <= data(index)(query_byte_offset+2);
						s_readdata(15 downto 8) <= data(index)(query_byte_offset+1);
						s_readdata(7 downto 0) <= data(index)(query_byte_offset);

						-- signal to master that data is ready
						s_waitrequest <= '0';
						current_state <= IDLE;
					else
						-- tag fail --> cache miss...
						-- check dirty flag
						if dirty(index) = '1' then
							-- write old block to memory
							current_state <= WRITE_MEM;
							mem_byte_offset <= 0;
						else
							-- read new block from memory 
							current_state <= READ_MEM;
							mem_byte_offset <= 0;
						end if;
					end if;
				else
					-- invalid block --> cache miss...
					-- read block from memory
					current_state <= READ_MEM;
					mem_byte_offset <= 0;
				end if;
			-- Write data to cache
			when WRITE_CACHE =>
				query_byte_offset <= to_integer(unsigned(s_addr(3 downto 0)));
				index <= to_integer(unsigned(s_addr(8 downto 4)));
				query_tag <= s_addr(14 downto 9);
				-- check valid flag
				if valid(index) = '1' then
					-- check tag
					if query_tag = tag(index) then
						-- tag match --> cache hit!

						-- write data to cache
						data(index)(query_byte_offset+3) <= s_writedata(31 downto 24);
						data(index)(query_byte_offset+2) <= s_writedata(23 downto 16);
						data(index)(query_byte_offset+1) <= s_writedata(15 downto 8);
						data(index)(query_byte_offset) <= s_writedata(7 downto 0);
					
						-- set dirty flag
						dirty(index) <= '1';

						-- signal to master that write is complete
						s_waitrequest <= '0';
						current_state <= IDLE;
					else
						-- tag fail --> cache miss...
						-- check dirty flag
						if dirty(index) = '1' then
							-- write old block to memory
							current_state <= WRITE_MEM;
							mem_byte_offset <= 0;
						else
							-- read new block from memory
							current_state <= READ_MEM;
							mem_byte_offset <= 0;
						end if;
					end if;
				else
					-- invalid block --> cache miss...
					-- read block from memory
					current_state <= READ_MEM;
					mem_byte_offset <= 0;
				end if;
			when READ_MEM =>
				-- signal to memory that we want to perform a read
				m_read <= '1';
				-- build byte address: tag + index + offset
				m_addr <= to_integer(unsigned(std_logic_vector'(query_tag & std_logic_vector(to_unsigned(index,5)) & std_logic_vector(to_unsigned(mem_byte_offset,4)))));
				current_state <= READ_MEM_WAIT;
				
			when READ_MEM_WAIT =>
				if m_waitrequest'event and m_waitrequest = '0' then
					-- word transaction complete
					m_read <= '0';
					-- update cache block
					data(index)(mem_byte_offset) <= m_readdata;

					-- state transition
					if mem_byte_offset = (block_size-1) then
						-- block transaction complete
							
						-- update tag and flags
						tag(index) <= query_tag;
						valid(index) <= '1';
						dirty(index) <= '0';

						-- transit back to read/write cache 
						if s_read = '1' then
							current_state <= READ_CACHE;
						elsif s_write = '1' then
							current_state <= WRITE_CACHE;
						end if;
					else
						-- read next byte
						mem_byte_offset <= mem_byte_offset + 1;
						current_state <= READ_MEM;
					end if;
				else
					-- keep waiting
					current_state <= READ_MEM_WAIT;
				end if;
			when WRITE_MEM =>
				m_write <= '1';
				-- build byte address: tag + index + offset
				m_addr <= to_integer(unsigned(std_logic_vector'(tag(index) & std_logic_vector(to_unsigned(index,5)) & std_logic_vector(to_unsigned(mem_byte_offset,4)))));
				m_writedata <= data(index)(mem_byte_offset);
				current_state <= WRITE_MEM_WAIT;
			when WRITE_MEM_WAIT =>
				if m_waitrequest'event and m_waitrequest = '0' then
					-- byte transaction complete
					m_write <= '0';

					-- state transition
					if mem_byte_offset = (block_size-1) then
						-- block transaction complete

						-- update dirty flag
						dirty(index) <= '0';

						-- come back to read/write cache 
						if s_read = '1' then
							current_state <= READ_CACHE;
						elsif s_write = '1' then
							current_state <= WRITE_CACHE;
						end if;
					else
						-- read next word
						mem_byte_offset <= mem_byte_offset + 1;
						current_state <= WRITE_MEM;
					end if;
				else
					-- keep waiting
					current_state <= WRITE_MEM_WAIT;
				end if;
		end case;
	end if;
	end process;

end arch;