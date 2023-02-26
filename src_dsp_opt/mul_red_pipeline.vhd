--max value of power r is 93 due to packet length
--when we have r,r**2,r**4,r**8,r**16,r**32,r**64 then we can 
--calculate any power of r no more then with 5 multiplication
--in this module we push data via three cascades
--A/B - most significant words 2**64/2**32 and 2**16
--E/F - Least significant words 2**1 and 2**0
--here 2**n means power of r (r**(2**n))
     
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;

entity mul_red_pipeline is
  Port (
        clk			: in  STD_LOGIC;
  	    A_in           : in  unsigned(135 downto 0);
		B_in           : in  unsigned(135 downto 0);
		C_in           : in  unsigned(135 downto 0);
		D_in           : in  unsigned(135 downto 0);
		E_in           : in  unsigned(135 downto 0);
		F_in           : in  unsigned(135 downto 0);
		data_out    : out unsigned(129 downto 0)
  );
end mul_red_pipeline;
    
architecture Behavioral of mul_red_pipeline is

COMPONENT mul136_mod_red is
  Port ( 
        clk         : in  STD_LOGIC;
        A_in        : in unsigned(135 downto 0);
        B_in        : in unsigned(135 downto 0);
        data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

signal u1_out,u2_out        : unsigned(129 downto 0);
signal u3_out,u4_out,u5_out : unsigned(129 downto 0);
signal u4_A_in,u4_B_in      : unsigned(135 downto 0);
signal u5_A_in,u5_B_in      : unsigned(135 downto 0);
signal Shift_reg_u3         : type_shreg_r32;--type_shreg_u3;

begin
-------first parallel cascade--------
u1: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => A_in,
        B_in        => B_in,
        data_out    => u1_out
        );
        
u2: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => C_in,
        B_in        => D_in,
        data_out    => u2_out
        );
        
u3: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => E_in,
        B_in        => F_in,
        data_out    => u3_out
        );
-------second parallel cascade mul+shift register--------
u4_A_in <= "000000"&u1_out;
u4_B_in <= "000000"&u2_out;


u4: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => u4_A_in,
        B_in        => u4_B_in,
        data_out    => u4_out
        );
        
--shreg for u3_out with length equal to u4 in clocks
process(clk)
begin
if rising_edge(clk) then
    Shift_reg_u3 <= Shift_reg_u3(17 downto 0)&u3_out;
end if;
end process;
 
u5_A_in <= "000000"&(Shift_reg_u3(18));
u5_B_in <= "000000"&u4_out;

-------third parallel cascade - last mul-----------------
u5: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => u5_A_in,
        B_in        => u5_B_in,
        data_out    => data_out
        );


--process(clk)
--begin
--if rising_edge(clk) then

--end if;
--end process;


end Behavioral;
