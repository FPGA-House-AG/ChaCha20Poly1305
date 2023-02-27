library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
       
entity half_round is
	Port (clk		: in  STD_LOGIC;
		data_in		: in  type_1;
		data_out	: out type_1
        );
end half_round;

architecture Behavioral of half_round is

--function  order  (a : unsigned) return unsigned is
--	variable a1 : unsigned(63 downto 0):=a;
--	variable b1 : unsigned(63 downto 0):=(others=>'0');
--begin
--	for i in 0 to 7 loop
--		b1(((i+1)*8-1) downto i*8):=a1((((7-i)+1)*8-1) downto (7-i)*8);
--	end loop;
--return b1;
--end order;

signal data_col_diag : type_1;

component col_round is
	Port (clk		: in  STD_LOGIC;
		data_in		: in  type_1;
		data_out	: out type_1
        );
end component;

component diag_round is
	Port (clk		: in  STD_LOGIC;
		data_in		: in  type_1;
		data_out	: out type_1
        );
end component;

begin

u1: col_round 
	Port map (clk	=>clk,
		data_in		=>data_in,
		data_out	=>data_col_diag
        );
u2: diag_round 
	Port map (clk	=>clk,
		data_in		=>data_col_diag,
		data_out	=>data_out
        );


end Behavioral;