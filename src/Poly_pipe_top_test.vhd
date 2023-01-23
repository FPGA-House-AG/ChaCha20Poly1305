
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg.all;

entity Poly_pipe_top_test is
	Port (clk				: in  STD_LOGIC;
			data_in			: in  unsigned(31 downto 0);
			data_out		: out unsigned(31 downto 0);
			tlast			: in  STD_LOGIC;
			tvalid			: in  STD_LOGIC;
			tvalid_out    : out  STD_LOGIC;
		    tlast_out     : out  STD_LOGIC
        );
end Poly_pipe_top_test;

architecture Behavioral of Poly_pipe_top_test is
COMPONENT Poly_1305_pipe_top is
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
end COMPONENT;

signal acc                      : unsigned(130 downto 0);
signal acc_1                    : unsigned(131 downto 0);
signal Blck                     : unsigned(128 downto 0);
signal r                        : unsigned(127 downto 0);
signal s                        : unsigned(127 downto 0);
signal data_out_1               : unsigned(127 DOWNTO 0);

signal n_cnt            : unsigned(6 downto 0);

begin

u1: Poly_1305_pipe_top 
  Port map 
       (clk			=> clk,
		Blck		=> Blck,
		r			=> r,
		s			=> s,
		n_in        => n_cnt,
		tvalid      => tvalid,
		tlast       => tlast,
		tvalid_out  => tvalid_out,
		tlast_out   => tlast_out,
		data_out	=> data_out_1
        );
        
acc <= data_in&data_in&data_in&data_in&data_in(2 downto 0);
Blck <= '1'&data_in&data_in&data_in&data_in;
r <= data_in&data_in&data_in&data_in;
s <= data_in&data_in&data_in&data_in;
n_cnt <= data_in(6 downto 0);

data_out<=data_out_1(127 downto 96) xor data_out_1(95 downto 64) xor data_out_1(63 downto 32) xor data_out_1(31 downto 0);
   
end Behavioral;
