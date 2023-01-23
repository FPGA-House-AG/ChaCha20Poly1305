library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity q_round is
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
end q_round;

architecture Behavioral of q_round is

signal a_1,b_1,c_1,d_1 : unsigned(31 downto 0);
signal a_2,b_2,c_2,d_2 : unsigned(31 downto 0);
signal a_3,b_3,c_3,d_3 : unsigned(31 downto 0);

begin
	  	
process(clk)
begin
if rising_edge(clk) then
a_1 <= a_in + b_in;
d_1 <= ((d_in xor (a_in+b_in)) rol 16);
c_1 <= c_in + ((d_in xor (a_in+b_in)) rol 16);
--b_1 <= ((b_in xor (c_in + ((d_in xor (a_in+b_in)) rol 16))) rol 12);
b_1 <= b_in;
end if;
end process;


process(clk)
begin
if rising_edge(clk) then
    a_2 <= a_1;
    d_2 <= d_1;
    c_2 <= c_1;
    b_2 <= ((b_1 xor c_1) rol 12);
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    a_3 <= a_2 + b_2;
    d_3 <= ((d_2 xor (a_2+b_2)) rol 8);
    c_3 <= c_2 + ((d_2 xor (a_2+b_2)) rol 8);
    b_3 <= b_2;--
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    a_out <= a_3;
    d_out <= d_3;
    c_out <= c_3;
    b_out <= ((b_3 xor c_3) rol 7);
end if;
end process;


--process(clk)
--begin
--if rising_edge(clk) then
--a_out <= a_1 + b_1;
--d_out <= ((d_1 xor (a_1+b_1)) rol 8);
--c_out <= c_1 + ((d_1 xor (a_1+b_1)) rol 8);
--b_out <= ((b_1 xor (c_1 + ((d_1 xor (a_1+b_1)) rol 8))) rol 7);
--end if;
--end process;


end Behavioral;

--architecture Behavioral of q_round is

----function  order  (a : unsigned) return unsigned is
----	variable a1 : unsigned(63 downto 0):=a;
----	variable b1 : unsigned(63 downto 0):=(others=>'0');
----begin
----	for i in 0 to 7 loop
----		b1(((i+1)*8-1) downto i*8):=a1((((7-i)+1)*8-1) downto (7-i)*8);
----	end loop;
----return b1;
----end order;

--signal a_1,d_1,d_2 : unsigned(31 downto 0);
--signal c_1,b_1,b_2 : unsigned(31 downto 0);
--signal a_2,d_3,d_4 : unsigned(31 downto 0);
--signal c_2,b_3,b_4 : unsigned(31 downto 0);

--signal a_3,a_4,a_5 : unsigned(31 downto 0);
--signal d_5,d_6,c_3 : unsigned(31 downto 0);


--signal d_in_1,c_in_1,b_in_1,c_in_2,b_in_2,b_in_3 : unsigned(31 downto 0);

--signal a_1_1,a_1_2,a_1_3,d_2_1,d_2_2,c_1_1,c_1_2,c_1_3,b_2_1,b_2_2,b_2_3,d_2_3 : unsigned(31 downto 0);


--begin
	  	
--process(clk)

--begin
--if rising_edge(clk) then

--a_1 <= a_in + b_in;
--d_in_1 <= d_in;
--c_in_1 <= c_in;
--b_in_1 <= b_in;
--------------------------
--d_2 <= ((d_in_1 xor a_1) rol 16);
--c_in_2 <= c_in_1;
--b_in_2 <= b_in_1;
--a_1_1 <= a_1;

----d_1 <= ((d_in_1 xor a_1) rol 16);
----d_2 <= (d_1 rol 16);
----d_2 <= (d_1 rol 7);------test
---------------------------
--c_1<= c_in_2+d_2;
--d_2_1 <= d_2;
--b_in_3 <= b_in_2;
--a_1_2 <= a_1_1;
---------------------------

--b_2 <= ((b_in_3 xor c_1) rol 12);
--a_1_3 <= a_1_2;
--d_2_2 <= d_2_1;
--c_1_1 <= c_1;

----b_1 <= (b_in_3 xor c_1) rol 12);
----b_2 <= (b_1 rol 12);
---------------------------------
--a_2 <= a_1_3+b_2;
--d_2_3 <= d_2_2;
--c_1_2 <= c_1_1;
--b_2_1 <= b_2;
---------------------------------

--d_4 <= ((d_2_3 xor a_2) rol 8);
----d_3 <= ((d_2_3 xor a_2) rol 8);
----d_4 <= (d_3 rol 8);
--c_1_3 <= c_1_2;
--b_2_2 <= b_2_1;
--a_3<=a_2;
-----------------------------------
--c_2<= c_1_3+d_4;
--b_2_3 <= b_2_2;
--a_4<=a_3;
--d_5<=d_4;
-----------------------------------
--b_4 <= ((b_2_3 xor c_2) rol 7);
----b_4 <= (b_3 rol 7);
--a_5<=a_4;
--c_3<=c_2;
--d_6<=d_5;

--end if;
--end process;

--a_out <= a_5;
--b_out <= b_4;
--c_out <= c_3;
--d_out <= d_6;

--end Behavioral;