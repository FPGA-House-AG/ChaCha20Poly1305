---WG T4 header insertion with adding one clock data before full packet
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
--use work.bus_pkg1.all;

entity WG_T4_header_adder is
  Port ( 
        clk                  : in  STD_LOGIC;
        rst                  : in  STD_LOGIC;
-----------------------------
--  axi_st_in_data
		sink_tdata     : in  UNSIGNED(127 downto 0);
		sink_tvalid    : in  STD_LOGIC;
		sink_tlast     : in  STD_LOGIC;
		sink_tready    : out STD_LOGIC:='1';
		header_in      : in  UNSIGNED(127 downto 0);
--  axi_st_out
		source_tdata   : out UNSIGNED(127 downto 0);
		source_tvalid  : out STD_LOGIC;
		source_tlast   : out STD_LOGIC;
		source_tready  : in  STD_LOGIC
		);
end WG_T4_header_adder;

architecture Behavioral of WG_T4_header_adder is

signal active_packet : STD_LOGIC:='0';
signal last_shift, valid_shift : STD_LOGIC:='0';
signal msg_shift    : unsigned(127 downto 0);


begin

process(clk)
begin
if rising_edge(clk) then
    msg_shift <= sink_tdata;
    last_shift <= sink_tlast;
    valid_shift <= sink_tvalid;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    if sink_tlast = '1' then
        active_packet <= '0';
    else
        if sink_tvalid = '1' then
            active_packet <= '1';
        end if;
    end if;
end if;
end process;



process(clk)
begin
if rising_edge(clk) then
    if sink_tvalid = '1' and active_packet='0' then
        source_tdata <= x"04"&x"0000"&header_in(103 downto 0);--structure of this header <= x"000000"&('0'&n_in)&Im&(nonce(63 downto 0));
        source_tvalid <= '1';
        source_tlast <= '0';
    else
        source_tdata <= msg_shift;
        source_tvalid <= valid_shift;
        source_tlast <= last_shift;
    end if;
end if;
end process;


end Behavioral;
