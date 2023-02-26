library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
       
entity diag_round is
	Port (clk		: in  STD_LOGIC;
		data_in		: in  type_1;
		data_out	: out type_1
        );
end diag_round;

architecture Behavioral of diag_round is

--function  order  (a : unsigned) return unsigned is
--	variable a1 : unsigned(63 downto 0):=a;
--	variable b1 : unsigned(63 downto 0):=(others=>'0');
--begin
--	for i in 0 to 7 loop
--		b1(((i+1)*8-1) downto i*8):=a1((((7-i)+1)*8-1) downto (7-i)*8);
--	end loop;
--return b1;
--end order;

signal a_1,d_1,d_2 : unsigned(31 downto 0);

component q_round is
	Port (clk		: in  STD_LOGIC;
		a_in		: in  unsigned(31 downto 0);
		b_in		: in  unsigned(31 downto 0);
		c_in		: in  unsigned(31 downto 0);
		d_in		: in  unsigned(31 downto 0);
		a_out		: out unsigned(31 downto 0);
		b_out		: out unsigned(31 downto 0);
		c_out		: out unsigned(31 downto 0);
		d_out		: out unsigned(31 downto 0)
        );
end component;

begin

u1: q_round 
	Port map (clk	=>clk,
		a_in		=>data_in(0),
		b_in		=>data_in(5),
		c_in		=>data_in(10),
		d_in		=>data_in(15),
		a_out		=>data_out(0),
		b_out		=>data_out(5),
		c_out		=>data_out(10),
		d_out		=>data_out(15)
        );
u2: q_round 
	Port map (clk	=>clk,
		a_in		=>data_in(1),
		b_in		=>data_in(6),
		c_in		=>data_in(11),
		d_in		=>data_in(12),
		a_out		=>data_out(1),
		b_out		=>data_out(6),
		c_out		=>data_out(11),
		d_out		=>data_out(12)
        );
u3: q_round 
	Port map (clk	=>clk,
		a_in		=>data_in(2),
		b_in		=>data_in(7),
		c_in		=>data_in(8),
		d_in		=>data_in(13),
		a_out		=>data_out(2),
		b_out		=>data_out(7),
		c_out		=>data_out(8),
		d_out		=>data_out(13)
        );
u4: q_round 
	Port map (clk	=>clk,
		a_in		=>data_in(3),
		b_in		=>data_in(4),
		c_in		=>data_in(9),
		d_in		=>data_in(14),
		a_out		=>data_out(3),
		b_out		=>data_out(4),
		c_out		=>data_out(9),
		d_out		=>data_out(14)
        );

end Behavioral;