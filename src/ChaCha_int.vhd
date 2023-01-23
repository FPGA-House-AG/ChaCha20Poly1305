library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity ChaCha_int is
	Port (clk				   : in  STD_LOGIC;
		data_in                : in  type_1;
		data_out               : out type_1
        );
end ChaCha_int;

architecture Behavioral of ChaCha_int is

--function  order  (a : unsigned) return unsigned is
--	variable a1 : unsigned(63 downto 0):=a;
--	variable b1 : unsigned(63 downto 0):=(others=>'0');
--begin
--	for i in 0 to 7 loop
--		b1(((i+1)*8-1) downto i*8):=a1((((7-i)+1)*8-1) downto (7-i)*8);
--	end loop;
--return b1;
--end order;

signal state		: type_2;
signal reg			: std_logic_vector(144 downto 0):=(others=>'0');

component half_round is
	Port (clk		: in  STD_LOGIC;
		data_in		: in  type_1;
		data_out	: out type_1
        );
end component;



function  order  (a : unsigned) return unsigned is
	variable a1 : unsigned(63 downto 0):=a;
	variable b1 : unsigned(63 downto 0):=(others=>'0');
begin
	for i in 0 to 7 loop
		b1(((i+1)*8-1) downto i*8):=a1((((7-i)+1)*8-1) downto (7-i)*8);
	end loop;
return b1;
end order;


begin

GEN1: for i in 0 to 9 generate

	first: if i =0 generate
		u1: half_round 
		Port map  (clk		 => clk,
					data_in	 => data_in,
					data_out => state(0)
				  );
	end generate first;

	other: if i >0 generate
		u2: half_round 
		Port map  (clk		=> clk,
					data_in	 => state(i-1),
					data_out => state(i)
				  );
	end generate other;

end generate GEN1;	
data_out <= state(9);
	  
end Behavioral;