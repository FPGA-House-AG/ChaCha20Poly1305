library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg.all;

entity Poly1305 is
  Port (clk			    : in  STD_LOGIC;
		acc				: in  unsigned(130 downto 0);
		Blck			: in  unsigned(127 downto 0);
		r				: in  unsigned(127 downto 0);
		s				: in  unsigned(127 downto 0);
		data_out		: out unsigned(129 downto 0)
        );
end Poly1305;

architecture Behavioral of Poly1305 is

function  order_128  (a : unsigned) return unsigned is
	variable a1 : unsigned(127 downto 0):=a;
	variable b1 : unsigned(127 downto 0):=(others=>'0');
begin

b1 := a1(7 downto 0)&a1(15 downto 8)&a1(23 downto 16)&a1(31 downto 24)&a1(39 downto 32)&a1(47 downto 40)&a1(55 downto 48)&a1(63 downto 56)&a1(71 downto 64)&a1(79 downto 72)&a1(87 downto 80)&a1(95 downto 88)&a1(103 downto 96)&a1(111 downto 104)&a1(119 downto 112)&a1(127 downto 120);
return b1;
end order_128;

COMPONENT mul_144 is
  Port (clk			: in  STD_LOGIC;
	    A           : in  unsigned(135 downto 0);
		B           : in  unsigned(135 downto 0);
		data_out    : out unsigned(271 downto 0)
        );
end COMPONENT;

COMPONENT mod_red_1305 is
  Port (clk			: in  STD_LOGIC;
	    data_in     : in  unsigned(260 downto 0);
		data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

signal res_1   : unsigned(131 downto 0);---132bits
signal r_clmp  : unsigned(127 downto 0);---132bits
signal A       : unsigned(135 downto 0);
signal B       : unsigned(135 downto 0);
signal res_mul : unsigned(271 downto 0);
signal mod_red_in : unsigned(260 downto 0);
signal mod_red_out : unsigned(129 downto 0);
signal res_2   : unsigned(130 downto 0);---132bits


begin

u1: mul_144 Port map
	 (clk	        => clk,
         A	        => A,
         B	        => B,
         data_out	=> res_mul
     );
     
u2: mod_red_1305 Port map
	 (clk	        => clk,
         data_in	=> mod_red_in,
         data_out	=> mod_red_out
     );
     
     

process(clk)
begin
if rising_edge(clk) then

    res_1 <= '0'&acc+('1'&Blck);---131 + 129 = 132
    r_clmp <= order_128(r) and x"0ffffffc0ffffffc0ffffffc0fffffff";
    
end if;
end process;

A <= "0000"&res_1;
B <= x"00"&r_clmp;
mod_red_in <= res_mul(260 downto 0);

process(clk)
begin
if rising_edge(clk) then
--    res_2 <= '0'&mod_red_out+s;---130 + 128 = 131
--    data_out <= res_2(127 downto 0);
data_out <= mod_red_out;--(127 downto 0);
end if;
end process;

end Behavioral;
