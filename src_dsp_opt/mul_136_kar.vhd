library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
              
entity mul_136_kar is
  Port (clk			: in  STD_LOGIC;
	    A           : in  unsigned(135 downto 0);
		B           : in  unsigned(135 downto 0);
		data_out    : out unsigned(271 downto 0)
        );
end mul_136_kar;

architecture Behavioral of mul_136_kar is
signal A0,A1,B0,B1,C0,C1                : unsigned(67 downto 0);
signal mul_res_0,mul_res_1,mul_res_2    : unsigned(135 downto 0);
signal sum_0                            : unsigned(136 downto 0);
signal sum_1,temp_1                     : unsigned(265 downto 0);
signal temp_2                           : unsigned(206 downto 0);
signal res_out                           : unsigned(265 downto 0);



component mul_68_kar IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN unsigned(67 DOWNTO 0);
    B : IN unsigned(67 DOWNTO 0);
    data_out : OUT unsigned(135 DOWNTO 0)
  );
END component;

begin

---------[129:0]--our real input
---------[129:65] and [64:0]


u0: mul_68_kar
  PORT MAP (
    CLK => clk,
    A  => (A1),
    B  => (B1),
    data_out  => mul_res_0
  );
  
u1: mul_68_kar
  PORT MAP (
    CLK => clk,
    A  => (A0),
    B  => (B0),
    data_out  => mul_res_1
  );
  
  u2: mul_68_kar
  PORT MAP (
    CLK => clk,
    A  => (C1),
    B  => (C0),
    data_out  => mul_res_2
  );


process(clk)
begin
if rising_edge(clk) then

    A0 <= "000"&A(64 downto 0);-----00&[65:0]
    A1 <= "000"&A(129 downto 65);
    B0 <= "000"&B(64 downto 0);
    B1 <= "000"&B(129 downto 65);
    C0 <= "000"&A(129 downto 65) + A(64 downto 0);
    C1 <= "000"&B(129 downto 65) + B(64 downto 0);

end if;
end process;


process(clk)
begin
if rising_edge(clk) then

    sum_1 <= unsigned(mul_res_1)+(unsigned(mul_res_0)&x"00000000000000000000000000000000"&"00");---to be shifted <<130bit
    sum_0 <= unsigned('0'&mul_res_2) - unsigned(mul_res_0) - unsigned(mul_res_1);---to be shifted <<65bit
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then

    temp_1 <= sum_1;
    temp_2 <= '0'&sum_1(205 downto 0)+(sum_0&x"0000000000000000"&'0');--68

end if;
end process;

process(clk)
begin
if rising_edge(clk) then

    res_out <= temp_1(265 downto 206)&x"000000000000000000000000000000000000000000000000000"&"00"+temp_2;

end if;
end process;

data_out <= "000000"&res_out;

end Behavioral;
