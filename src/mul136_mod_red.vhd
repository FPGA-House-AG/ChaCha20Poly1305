library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity mul136_mod_red is
  Port ( 
        clk         : in  STD_LOGIC;
        A_in        : in unsigned(135 downto 0);
        B_in        : in unsigned(135 downto 0);
        data_out    : out unsigned(129 downto 0)
        );
end mul136_mod_red;

architecture Behavioral of mul136_mod_red is

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

signal mul_fsm_in_A,mul_fsm_in_B    : unsigned(135 downto 0);
signal mul_out                      : unsigned(271 downto 0);
signal mod_red_in                   : unsigned(260 downto 0);

begin

u1: mul_144 Port map
	 (clk	        => clk,
         A	        => A_in,
         B	        => B_in,
         data_out	=> mul_out
     );
     
mod_red_in <= mul_out(260 downto 0);

u2: mod_red_1305 Port map
	 (clk	        => clk,
         data_in	=> mod_red_in,
         data_out	=> data_out
     );
--data_out <= mod_red_out;


end Behavioral;
