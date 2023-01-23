
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg.all;

entity test_top_mod_red is
	Port (clk					: in  STD_LOGIC;
			data_in				: in  unsigned(31 downto 0);
			data_out				: out unsigned(31 downto 0)
        );
end test_top_mod_red;

architecture Behavioral of test_top_mod_red is

--signal clk_in		: STD_LOGIC;
--signal DATA_IN		: unsigned(255 DOWNTO 0);

signal data_out_1	: unsigned(129 DOWNTO 0);

signal a0			: unsigned(63 downto 0);
signal i_out		: natural range 0 to 23;
signal en, done	: STD_LOGIC:='0';
signal input	: unsigned(511 DOWNTO 0);

signal key      : unsigned(255 downto 0);
signal nonce    : unsigned(95 downto 0);
signal counter  : unsigned(31 downto 0);
signal plaintext : unsigned(511 downto 0);

signal A      : unsigned(260 downto 0);
signal B      : unsigned(135 downto 0);
signal res    : unsigned(271 downto 0);


COMPONENT mod_red_1305 is
  Port (clk			: in  STD_LOGIC;
	    data_in     : in  unsigned(260 downto 0);
		data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

--COMPONENT ChaCha20 
--	Port (clk			: in  STD_LOGIC;
--		key                    : in  unsigned(255 downto 0);
--		nonce                  : in  unsigned(95 downto 0);
--		counter                : in  unsigned(31 downto 0);
--		plaintext              : in  unsigned(511 downto 0);
--		data_out               : out unsigned(511 downto 0)
--        );
--END COMPONENT;

begin
--GEN1: for i in 0 to 15 generate

--input(i) <= data_in;

--end generate GEN1;	

--input<=data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in;

A <= data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in(4 downto 0);


u1: mod_red_1305 Port map
	 (clk	        => clk,
         data_in	=> A,
         data_out	=> data_out_1
     );

data_out<=(x"0000000"&"00"&data_out_1(129 downto 128)) xor data_out_1(127 downto 96) xor data_out_1(95 downto 64) xor data_out_1(63 downto 32) xor data_out_1(31 downto 0);
   
end Behavioral;