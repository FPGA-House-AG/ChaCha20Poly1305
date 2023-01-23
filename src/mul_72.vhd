library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity mul_72 is
  Port (clk			: in  STD_LOGIC;
	    A           : in  unsigned(67 downto 0);
		B           : in  unsigned(67 downto 0);
		data_out    : out unsigned(135 downto 0)
        );
end mul_72;

architecture Behavioral of mul_72 is

signal A0,A1,B0,B1              : unsigned(33 downto 0);
signal mul_res_0,mul_res_1,mul_res_2,mul_res_3 : unsigned(67 downto 0);
signal sum_0                    : unsigned(68 downto 0);
signal sum_1,temp,temp_1        : unsigned(135 downto 0);
signal sum_0_1,sum_0_2          : unsigned(34 downto 0);
signal sum_0_0                  : unsigned(102 downto 0);
signal data_temp                : unsigned(103 downto 0);


component mul_36 IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN unsigned(33 DOWNTO 0);
    B : IN unsigned(33 DOWNTO 0);
    data_out : OUT unsigned(67 DOWNTO 0)
  );
END component;

begin



u0: mul_36
  PORT MAP (
    CLK => clk,
    A  => (A0),
    B  => (B0),
    data_out  => mul_res_0
  );
  
u1: mul_36
  PORT MAP (
    CLK => clk,
    A  => (A0),
    B  => (B1),
    data_out  => mul_res_1
  );
  
  u2: mul_36
  PORT MAP (
    CLK => clk,
    A  => (A1),
    B  => (B0),
    data_out  => mul_res_2
  );
  
  u3: mul_36
  PORT MAP (
    CLK => clk,
    A  => (A1),
    B  => (B1),
    data_out  => mul_res_3
  );
  
  
  process(clk)
begin
if rising_edge(clk) then
A0 <= A(33 downto 0);
A1 <= A(67 downto 34);
B0 <= B(33 downto 0);
B1 <= B(67 downto 34);
end if;
end process;



process(clk)
begin
if rising_edge(clk) then

sum_0 <= unsigned('0'&mul_res_1)+unsigned(mul_res_2);---to be shifted <<34bit
sum_1 <= unsigned(mul_res_0)+(unsigned(mul_res_3)&x"00000000000000000");---to be shifted <<68bit

end if;
end process;

process(clk)
begin
if rising_edge(clk) then

    data_out <= sum_1+(sum_0&x"00000000"&"00");--34

end if;
end process;

end Behavioral;
