library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
          
entity mul_36 is
  Port (clk			: in  STD_LOGIC;
	    A           : in  unsigned(33 downto 0);
		B           : in  unsigned(33 downto 0);
		data_out    : out unsigned(67 downto 0)
        );
end mul_36;

architecture Behavioral of mul_36 is

signal A0,A1,B0,B1              : unsigned(16 downto 0);
signal mul_res_0,mul_res_1,mul_res_2,mul_res_3 : STD_LOGIC_VECTOR(33 downto 0);
signal sum_0                    : unsigned(34 downto 0);
signal sum_1                    : unsigned(67 downto 0);

component mult_gen_0 IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
END component;

component mul_gen_0 IS
  PORT (
    CLK : IN STD_LOGIC;
    A : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    B : IN STD_LOGIC_VECTOR(16 DOWNTO 0);
    P : OUT STD_LOGIC_VECTOR(33 DOWNTO 0)
  );
END component;

begin



u0 : mul_gen_0
PORT MAP (
    CLK => clk,
    A  => std_logic_vector(A0),
    B  => std_logic_vector(B0),
    P  => mul_res_0
  );
  
u1 : mul_gen_0
  PORT MAP (
    CLK => clk,
    A  => std_logic_vector(A0),
    B  => std_logic_vector(B1),
    P  => mul_res_1
  );
  
u2 : mul_gen_0
  PORT MAP (
    CLK => clk,
    A  => std_logic_vector(A1),
    B  => std_logic_vector(B0),
    P  => mul_res_2
  );
  
u3 : mul_gen_0
  PORT MAP (
    CLK => clk,
    A  => std_logic_vector(A1),
    B  => std_logic_vector(B1),
    P  => mul_res_3
  );

--u0: mult_gen_0
--  PORT MAP (
--    CLK => clk,
--    A  => std_logic_vector(A0),
--    B  => std_logic_vector(B0),
--    P  => mul_res_0
--  );
  
--  u1: mult_gen_0
--  PORT MAP (
--    CLK => clk,
--    A  => std_logic_vector(A0),
--    B  => std_logic_vector(B1),
--    P  => mul_res_1
--  );
  
--  u2: mult_gen_0
--  PORT MAP (
--    CLK => clk,
--    A  => std_logic_vector(A1),
--    B  => std_logic_vector(B0),
--    P  => mul_res_2
--  );
  
--  u3: mult_gen_0
--  PORT MAP (
--    CLK => clk,
--    A  => std_logic_vector(A1),
--    B  => std_logic_vector(B1),
--    P  => mul_res_3
--  );
process(clk)
begin
if rising_edge(clk) then

A0 <= A(16 downto 0);
A1 <= A(33 downto 17);
B0 <= B(16 downto 0);
B1 <= B(33 downto 17);
end if;
end process;

process(clk)
begin
if rising_edge(clk) then


sum_0 <= unsigned('0'&mul_res_1)+unsigned(mul_res_2);---to be shifted <<18bit
sum_1 <= unsigned(mul_res_0)+(unsigned(mul_res_3)&"0000000000000000000000000000000000");---to be shifted <<34bit

end if;
end process;

process(clk)
begin
if rising_edge(clk) then

    data_out <= sum_1+(sum_0&"00000000000000000");---to be shifted <<18bit

end if;
end process;


end Behavioral;
