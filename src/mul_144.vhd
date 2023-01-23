library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity mul_144 is
  Port (clk			: in  STD_LOGIC;
	    A           : in  unsigned(135 downto 0);
		B           : in  unsigned(135 downto 0);
		data_out    : out unsigned(271 downto 0)
        );
end mul_144;

architecture Behavioral of mul_144 is
signal A0,A1,B0,B1              : unsigned(67 downto 0);
signal mul_res_0,mul_res_1,mul_res_2,mul_res_3 : unsigned(135 downto 0);
signal sum_0                    : unsigned(136 downto 0);
signal sum_1,temp_1             : unsigned(271 downto 0);
signal temp_2                   : unsigned(206 downto 0);


component mul_72 IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN unsigned(67 DOWNTO 0);
    B : IN unsigned(67 DOWNTO 0);
    data_out : OUT unsigned(135 DOWNTO 0)
  );
END component;

begin

A0 <= A(67 downto 0);
A1 <= A(135 downto 68);
B0 <= B(67 downto 0);
B1 <= B(135 downto 68);

u0: mul_72
  PORT MAP (
    CLK => clk,
    A  => (A0),
    B  => (B0),
    data_out  => mul_res_0
  );
  
u1: mul_72
  PORT MAP (
    CLK => clk,
    A  => (A0),
    B  => (B1),
    data_out  => mul_res_1
  );
  
  u2: mul_72
  PORT MAP (
    CLK => clk,
    A  => (A1),
    B  => (B0),
    data_out  => mul_res_2
  );
  
  u3: mul_72
  PORT MAP (
    CLK => clk,
    A  => (A1),
    B  => (B1),
    data_out  => mul_res_3
  );


process(clk)
begin
if rising_edge(clk) then

--sum_0_1 <= unsigned('0'&mul_res_1(67 downto 0)) + unsigned(mul_res_2(67 downto 0));
--sum_0_2 <= unsigned('0'&mul_res_1(135 downto 68)) + unsigned(mul_res_2(135 downto 68));

sum_0 <= unsigned('0'&mul_res_1)+unsigned(mul_res_2);---to be shifted <<68bit
sum_1 <= unsigned(mul_res_0)+(unsigned(mul_res_3)&x"0000000000000000000000000000000000");---to be shifted <<136bit


end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    temp_1 <= sum_1;
    temp_2 <= '0'&sum_1(205 downto 0)+(sum_0&x"00000000000000000");--68

end if;
end process;

process(clk)
begin
if rising_edge(clk) then

--    data_out <= sum_1+(sum_0&x"00000000000000000");--68
data_out <= temp_1(271 downto 206)&x"000000000000000000000000000000000000000000000000000"&"00"+temp_2;
end if;
end process;

end Behavioral;
