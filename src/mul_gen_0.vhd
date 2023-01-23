library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity mult_gen_0 IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
END mult_gen_0;
  

architecture Behavioral of mult_gen_0 is

signal A0,B0              : unsigned(16 downto 0);
signal sum0,sum1,sum2                    : unsigned(33 downto 0);

begin

A0 <= unsigned(A);
B0 <= unsigned(B);


process(clk)
begin
if rising_edge(clk) then
-- 3 pipeline stages
sum0 <= A0 * B0;
sum1 <= sum0;
sum2 <= sum1;
end if;
end process;

P <= std_logic_vector(sum2);

end Behavioral;
