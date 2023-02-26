library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
            
entity mod_red_1305 is
  Port (clk			: in  STD_LOGIC;
	    data_in     : in  unsigned(260 downto 0);
		data_out    : out unsigned(129 downto 0)
        );
end mod_red_1305;

architecture Behavioral of mod_red_1305 is

signal A_1                : unsigned(129 downto 0);
signal B_1                : unsigned(133 downto 0);
signal A_2                : unsigned(129 downto 0);
signal B_2                : unsigned(7 downto 0);
signal A_3                : unsigned(129 downto 0);
signal B_3                : unsigned(3 downto 0);

signal temp_1           : unsigned(130 downto 0);

signal res_1        : unsigned(134 downto 0);
signal res_1_1      : unsigned(80 downto 0);
signal res_1_2      : unsigned(54 downto 0);
signal res_2        : unsigned(130 downto 0);
signal res_2_1      : unsigned(80 downto 0);
signal res_3        : unsigned(130 downto 0);
signal res_3_1      : unsigned(80 downto 0);
signal data_in_1    :unsigned(130 downto 0);
signal data_in_2    :unsigned(132 downto 0);
signal B_1_1        :unsigned(80 downto 0);
signal B_1_2        :unsigned(53 downto 0);

begin

--temp_1 <= ;

data_in_1 <= data_in(260 downto 130);
data_in_2 <= data_in(260 downto 130)&"00";

process(clk)
begin
if rising_edge(clk) then

    A_1 <= data_in(129 downto 0);
    
--    B_1_1 <= '0'&data_in_2(79 downto 0) + data_in_1(79 downto 0);
--    B_1_2 <= '0'&data_in_2(132 downto 80) + data_in_1(130 downto 80);
    
    B_1 <= '0'&data_in_2 + data_in_1;-- * to_unsigned(5, 3);
    
end if;
end process;

--process(clk)
--begin
--if rising_edge(clk) then

--    A_1_1 <= A_1;
--    B_1 <= B_1_2&x"00000000000000000000" + B_1_1;-- * to_unsigned(5, 3);
    
----    B_1 <= data_in_2 + data_in_1;-- * to_unsigned(5, 3);
    
----res_1 <= ('0'&B_1)+A_1;
--end if;
--end process;

process(clk)
begin
if rising_edge(clk) then
    res_1 <= ('0'&B_1)+A_1;
end if;
end process;


process(clk)
begin
if rising_edge(clk) then
    A_2 <= res_1(129 downto 0);
    B_2 <= '0'&res_1(134 downto 130)&"00" + res_1(134 downto 130);-- * to_unsigned(5, 3);
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    res_2   <= '0'&A_2+B_2;
end if;
end process;

--process(clk)
--begin
--if rising_edge(clk) then
--    A_2_1<=A_2;
--    res_2_1 <= ('0'&A_2(79 downto 0))+B_2;
--end if;
--end process;

--process(clk)
--begin
--if rising_edge(clk) then
--    res_2   <= '0'&A_2_1(129 downto 80)&x"00000000000000000000"+res_2_1;
--end if;
--end process;

process(clk)
begin
if rising_edge(clk) then
    A_3 <= res_2(129 downto 0);
--    B_3 <= ("0000"&res_2(130)) * to_unsigned(5, 3);
    B_3 <= ('0'&res_2(130))&"00" + ('0'&res_2(130));-- * to_unsigned(5, 3);
--    res_3 <= ('0'&A_3)+B_3;
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    res_3 <= ('0'&A_3)+B_3;
end if;
end process;


--process(clk)
--begin
--if rising_edge(clk) then
--    A_3_1 <= A_3;
--    res_3_1 <= '0'&A_3(79 downto 0)+B_3;
--end if;
--end process;

--process(clk)
--begin
--if rising_edge(clk) then
--    res_3 <= ('0'&A_3_1(129 downto 80))&x"00000000000000000000"+res_3_1;
--end if;
--end process;

data_out <= res_3(129 downto 0);

end Behavioral;
