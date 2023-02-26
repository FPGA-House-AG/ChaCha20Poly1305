---(r**n) mod 2**130-5
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
--use work.bus_pkg2.all;
        
--Library UNISIM;
--use UNISIM.vcomponents.all;
   
entity r_power_n_kar is
  Port (clk			: in  STD_LOGIC;
        en			: in  STD_LOGIC;
	    r_in        : in  unsigned(127 downto 0);
	    n_in        : in  unsigned(6 downto 0);---93 max
		data_out    : out unsigned(129 downto 0)
        );
end r_power_n_kar;

architecture Behavioral of r_power_n_kar is

--type Tstates is (idle, m_exp, rounds,stop);

signal shreg_r1 :  type_shreg_r1;
signal shreg_r2 :  type_shreg_r2;
signal shreg_r4 :  type_shreg_r4;
signal shreg_r8 :  type_shreg_r8;
signal shreg_r16 :  type_shreg_r16;
signal shreg_r32 :  type_shreg_r32;
signal shreg_n :  type_shreg_n;




--signal FSM_state                        : Tstates:=idle;
--signal cnt_mul_fsm,i, n                 : natural:=0;
--signal round_en, round_done,sw          : std_logic:='0';
signal mul_in_A,mul_in_B                : unsigned(135 downto 0);
signal mul_fsm_out                      : unsigned(271 downto 0);
signal r2,r4,r8,r16,r32,r64          : unsigned(129 downto 0);
signal r1                               : unsigned(127 downto 0);
signal pipe_A_in,pipe_B_in,pipe_C_in    : unsigned(135 downto 0);
signal pipe_D_in,pipe_E_in,pipe_F_in    : unsigned(135 downto 0);
signal mod_red_out                      : mod_red_type;
signal mul_pipe_in_A,mul_pipe_in_B      : mul_pipe_type;
signal n_val                            : unsigned(6 downto 0);



COMPONENT mul136_mod_red is
  Port ( 
        clk         : in  STD_LOGIC;
        A_in        : in unsigned(135 downto 0);
        B_in        : in unsigned(135 downto 0);
        data_out    : out unsigned(129 downto 0)
        );
end COMPONENT;

COMPONENT mul_red_pipeline is
  Port (
        clk			: in  STD_LOGIC;
  	    A_in           : in  unsigned(135 downto 0);
		B_in           : in  unsigned(135 downto 0);
		C_in           : in  unsigned(135 downto 0);
		D_in           : in  unsigned(135 downto 0);
		E_in           : in  unsigned(135 downto 0);
		F_in           : in  unsigned(135 downto 0);
		data_out       : out unsigned(129 downto 0)
  );
end COMPONENT;

begin

mul_in_A <= x"00"&r_in;
mul_in_B <= x"00"&r_in;

 GEN1: for i in 0 to 5 generate
 
 mul_pipe_in_A(i) <= "000000"&mod_red_out(i);
 mul_pipe_in_B(i) <= "000000"&mod_red_out(i);

	first: if i =0 generate
		u1: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => mul_in_A,
        B_in        => mul_in_B,
        data_out    => mod_red_out(0)
        ); 
		
	end generate first;

	other: if i >0 generate
		u2: mul136_mod_red Port map
        ( 
        clk         => clk,
        A_in        => mul_pipe_in_A(i-1),
        B_in        => mul_pipe_in_A(i-1),
        data_out    => mod_red_out(i)
        ); 
	end generate other;
  
end generate GEN1;	
 
pipe: mul_red_pipeline Port map
   (
        clk			=> clk,
  	    A_in        => pipe_A_in,
		B_in        => pipe_B_in,
		C_in        => pipe_C_in,
		D_in        => pipe_D_in,
		E_in        => pipe_E_in,
		F_in        => pipe_F_in,
		data_out    => data_out
  );     
  
process(clk)
begin
if rising_edge(clk) then

    shreg_r1 <= shreg_r1(112 downto 0)&r_in;
    shreg_r2 <= shreg_r2(93 downto 0)&mod_red_out(0);
    shreg_r4 <= shreg_r4(74 downto 0)&mod_red_out(1);
    shreg_r8 <= shreg_r8(55 downto 0)&mod_red_out(2);
    shreg_r16 <= shreg_r16(36 downto 0)&mod_red_out(3);
    shreg_r32 <= shreg_r32(17 downto 0)&mod_red_out(4);
    shreg_n <= shreg_n(112 downto 0)&n_in;

 
end if;
end process; 
         
process(clk)
begin
if rising_edge(clk) then

   r1 <= shreg_r1(113);
   r2 <= shreg_r2(94);
   r4 <= shreg_r4(75);
   r8 <= shreg_r8(56);
   r16 <= shreg_r16(37);
   r32 <= shreg_r32(18);
   r64 <= mod_red_out(5);
   n_val<= shreg_n(113);
end if;
end process;

--process(clk)
--begin
--if rising_edge(clk) then
 
--    shreg_r1 <= shreg_r1(106 downto 0)&r_in;
--    shreg_r2 <= shreg_r2(88 downto 0)&mod_red_out(0);
--    shreg_r4 <= shreg_r4(70 downto 0)&mod_red_out(1);
--    shreg_r8 <= shreg_r8(52 downto 0)&mod_red_out(2);
--    shreg_r16 <= shreg_r16(34 downto 0)&mod_red_out(3);
--    shreg_r32 <= shreg_r32(16 downto 0)&mod_red_out(4);
--    shreg_n <= shreg_n(106 downto 0)&n_in;

--end if;
--end process; 
        
--process(clk)
--begin
--if rising_edge(clk) then

--   r1 <= shreg_r1(107);
--   r2 <= shreg_r2(89);
--   r4 <= shreg_r4(71);
--   r8 <= shreg_r8(53);
--   r16 <= shreg_r16(35);
--   r32 <= shreg_r32(17);
--   r64 <= mod_red_out(5);
--   n_val<= shreg_n(107);
--end if;
--end process;

-----we need fsm here which can track n_val as input
process(clk)
begin
if rising_edge(clk) then
--    sw <= not sw;
--    if sw = '0' then
-------95
        if n_val(6) = '1' then
            pipe_A_in <= "000000"&r64;
        elsif n_val(5) = '1' then
            pipe_A_in <= "000000"&r32;
        else
            pipe_A_in <= x"0000000000000000000000000000000001";
        end if;
--        pipe_A_in <= "000000"&r64;
        if n_val(4) = '1' then
            pipe_B_in <= "000000"&r16;
        else
            pipe_B_in <= x"0000000000000000000000000000000001";
        end if;
        
        if n_val(3) = '1' then
            pipe_C_in <= "000000"&r8;
        else
            pipe_C_in <= x"0000000000000000000000000000000001";
        end if;
        
        if n_val(2) = '1' then
            pipe_D_in <= "000000"&r4;
        else
            pipe_D_in <= x"0000000000000000000000000000000001";
        end if;
        
        if n_val(1) = '1' then
            pipe_E_in <= "000000"&r2;
        else
            pipe_E_in <= x"0000000000000000000000000000000001";
        end if;
        
        if n_val(0) = '1' then
            pipe_F_in <= "00000000"&r1;
        else
            pipe_F_in <= x"0000000000000000000000000000000001";
        end if;
        
end if;
end process;

end Behavioral;
