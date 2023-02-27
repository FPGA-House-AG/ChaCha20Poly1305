library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
      
entity Poly_1305_pipe_kar is
  Port (clk           : in  STD_LOGIC;
		Blck          : in  unsigned(128 downto 0);
		r			  : in  unsigned(129 downto 0);-----r pow n mod p
		s			  : in  unsigned(127 downto 0);
		tvalid        : in  STD_LOGIC;
		tlast         : in  STD_LOGIC;
		tvalid_out    : out  STD_LOGIC;
		tlast_out     : out  STD_LOGIC;
		data_out      : out unsigned(127 downto 0)
		);
end Poly_1305_pipe_kar;
  
architecture Behavioral of Poly_1305_pipe_kar is

function  order_128  (a : unsigned) return unsigned is
	variable a1 : unsigned(127 downto 0):=a;
	variable b1 : unsigned(127 downto 0):=(others=>'0');
begin

b1 := a1(7 downto 0)&a1(15 downto 8)&a1(23 downto 16)&a1(31 downto 24)&a1(39 downto 32)&a1(47 downto 40)&a1(55 downto 48)&a1(63 downto 56)&a1(71 downto 64)&a1(79 downto 72)&a1(87 downto 80)&a1(95 downto 88)&a1(103 downto 96)&a1(111 downto 104)&a1(119 downto 112)&a1(127 downto 120);
return b1;
end order_128;

COMPONENT mul136_mod_red is
  Port ( 
        clk         : in  STD_LOGIC;
        A_in        : in unsigned(135 downto 0);
        B_in        : in unsigned(135 downto 0);
        data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

COMPONENT mod_red_1305 is
  Port (clk			: in  STD_LOGIC;
	    data_in     : in  unsigned(260 downto 0);
		data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

signal res_1                : unsigned(131 downto 0);---132bits
signal mul_in_A,mul_in_B    : unsigned(135 downto 0);
signal mul_out, mul_out_1   : unsigned(129 downto 0):=(others=>'0');
signal acc,acc_res          : unsigned(222 downto 0):=(others=>'0');
signal p                    : unsigned(129 downto 0) :="11"&x"fffffffffffffffffffffffffffffffb";--130bit
signal i                    : natural:=0;
signal mod_red_in           : unsigned(260 downto 0);
signal mod_red_out          : unsigned(129 downto 0);
signal tag                  : unsigned(130 downto 0);
signal shreg_s1             : type_shreg_S_poly1;
signal shreg_s2             : type_shreg_S_poly2;
signal shreg_tlast          : type_shreg_tlast_poly;
signal shreg_tvalid         : type_shreg_tvalid_poly;
signal shreg_blck           : type_shreg_blck_poly;



begin

--mul_in_A <= "00000001"&Blck;--'1'&Blck--128+1
mul_in_A <= "0000000"&Blck;--'1'&Blck--128+1
mul_in_B <= "000000"&r;-----r--130

u1: mul136_mod_red Port map
    ( 
    clk         => clk,
    A_in        => mul_in_A,
    B_in        => mul_in_B,
    data_out    => mul_out
    ); 

u2: mod_red_1305 Port map
	 (clk	        => clk,
         data_in	=> mod_red_in,
         data_out	=> mod_red_out--data_out
     );

process(clk)
begin
if rising_edge(clk) then

    shreg_s1 <= shreg_s1(19 downto 0)&s;
    if shreg_tlast(20) = '1' then
        shreg_s2 <= shreg_s2(5 downto 0)&shreg_s1(20);
    else
        shreg_s2 <= shreg_s2(5 downto 0)&shreg_s2(6);
    end if;
    
    shreg_tlast <= shreg_tlast(26 downto 0)&tlast;
    shreg_tvalid <= shreg_tvalid(27 downto 0)&tvalid;
    shreg_blck <= shreg_blck(26 downto 0)&(Blck(127 downto 0));   
    

end if;
end process; 

mod_red_in <= x"000000000"&"00"&acc_res;

process(clk)
begin
if rising_edge(clk) then

mul_out_1 <= mul_out;

if shreg_tvalid(19) = '1' then
    if shreg_tlast(19) = '1' then
        acc <= (others=>'0');
    else
        acc <= (acc+mul_out_1);
    end if;
end if;

end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    acc_res <= (acc+mul_out_1);----critical
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
if shreg_tlast(26) = '1' then
    tag <= ('0'&mod_red_out + shreg_s2(5));
end if;

end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    if shreg_tlast(27) = '1' then
        data_out <= order_128(tag(127 downto 0));
    else
        data_out <= order_128(shreg_blck(27));
    end if;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    tvalid_out <= (shreg_tvalid(27)) or shreg_tlast(27);
    tlast_out <= shreg_tlast(27);
end if;
end process;


end Behavioral;
