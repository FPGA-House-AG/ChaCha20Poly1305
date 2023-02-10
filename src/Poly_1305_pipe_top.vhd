library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
 
entity Poly_1305_pipe_top is
  Port (clk           : in  STD_LOGIC;
		Blck          : in  unsigned(128 downto 0);
		r			  : in  unsigned(127 downto 0);-----r pow n mod p
		s			  : in  unsigned(127 downto 0);
		n_in          : in  unsigned(6 downto 0);---93 max
		tvalid        : in  STD_LOGIC;
		tlast         : in  STD_LOGIC;
		tvalid_out    : out  STD_LOGIC;
		tlast_out     : out  STD_LOGIC;
		data_out      : out unsigned(127 downto 0)
		);
end Poly_1305_pipe_top;
 
architecture Behavioral of Poly_1305_pipe_top is

COMPONENT r_power_n is
  Port (clk			: in  STD_LOGIC;
        en			: in  STD_LOGIC;
	    r_in        : in  unsigned(127 downto 0);
	    n_in        : in  unsigned(6 downto 0);---93 max
		data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

COMPONENT Poly_1305_pipe is
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
end COMPONENT;

function  order_128  (a : unsigned) return unsigned is
	variable a1 : unsigned(127 downto 0):=a;
	variable b1 : unsigned(127 downto 0):=(others=>'0');
begin

b1 := a1(7 downto 0)&a1(15 downto 8)&a1(23 downto 16)&a1(31 downto 24)&a1(39 downto 32)&a1(47 downto 40)&a1(55 downto 48)&a1(63 downto 56)&a1(71 downto 64)&a1(79 downto 72)&a1(87 downto 80)&a1(95 downto 88)&a1(103 downto 96)&a1(111 downto 104)&a1(119 downto 112)&a1(127 downto 120);
return b1;
end order_128;

signal u1_out,u2_out    : unsigned(129 downto 0);
signal first            : STD_LOGIC:='1';
signal n_cnt            : unsigned(6 downto 0);
signal r_pow_in         : unsigned(127 downto 0);
signal r_pow_n          : unsigned(129 downto 0);
signal shreg_s          : type_shreg_S_poly_top;
signal shreg_blck       : type_shreg_blck_poly_top;

signal shreg_tvalid_top  : type_shreg_tvalid_top;
signal shreg_tlast_top   : type_shreg_tlast_top;


begin

u1: r_power_n Port map
       (clk			=> clk,
        en			=> '1',
	    r_in        => r_pow_in,
	    n_in        => n_cnt,--: in  unsigned(6 downto 0);---93 max
		data_out    => r_pow_n
        );

u2: Poly_1305_pipe 
  Port map 
       (clk			=> clk,
		Blck		=> shreg_blck(164),
		r			=> r_pow_n,
		s			=> shreg_s(164),
		tvalid      => shreg_tvalid_top(164),
		tlast       => shreg_tlast_top(164),
		tvalid_out  => tvalid_out,
		tlast_out   => tlast_out,
		data_out	=> data_out
        );

process(clk)
begin
if rising_edge(clk) then
    if tlast='1' then
       first <= '1';
    else
        if first='1' and tvalid='1' then
           first <= '0';
        end if;
    end if;

end if;
end process;

n_counter:process(clk)
begin
if rising_edge(clk) then
    if first = '1' and tvalid='1' then
        n_cnt <= n_in;
        r_pow_in <= r;----clamp here
    else
        if tvalid='1' then
            n_cnt <= n_cnt-1;
        end if;
    end if;
end if;
end process;

shrg_data:process(clk)
begin
if rising_edge(clk) then
    shreg_s <= shreg_s(163 downto 0)&s;
    shreg_blck <= shreg_blck(163 downto 0)&('1'&order_128(Blck(127 downto 0)));
    -- the above line fails on GHDL, possible alternative:
    -- shreg_blck(164 downto 1) <= shreg_blck(163 downto 0);
    -- shreg_blck(0) <= ('1'&order_128(Blck(127 downto 0)));
end if;
end process;

shrg_other:process(clk)
begin
if rising_edge(clk) then
    shreg_tvalid_top <= shreg_tvalid_top(163 downto 0)&tvalid;
    shreg_tlast_top <= shreg_tlast_top(163 downto 0)&tlast;

end if;
end process;

end Behavioral;
