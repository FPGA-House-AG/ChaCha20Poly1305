
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package bus_pkg is

	type type_1 is array (0 to 15) of unsigned(31 downto 0);
	type type_2 is array (0 to 9) of type_1;
	type shreg_1 is array (39 downto 0) of type_1;
	type shreg_2 is array (40 downto 0) of type_1;
	type type_shreg_u3 is array (17 downto 0) of unsigned(129 downto 0);
    type mod_red_type is array (0 to 5) of unsigned(129 downto 0);
    type mul_pipe_type is array (0 to 5) of unsigned(135 downto 0);
	type type_shreg_r1 is array (107 downto 0) of unsigned(127 downto 0);
	type type_shreg_r2 is array (89 downto 0) of unsigned(129 downto 0);
	type type_shreg_r4 is array (71 downto 0) of unsigned(129 downto 0);
	type type_shreg_r8 is array (53 downto 0) of unsigned(129 downto 0);
	type type_shreg_r16 is array (35 downto 0) of unsigned(129 downto 0);
	type type_shreg_r32 is array (17 downto 0) of unsigned(129 downto 0);
	type type_shreg_n is array (107 downto 0) of unsigned(6 downto 0);
	type type_shreg_S_poly1 is array (19 downto 0) of unsigned(127 downto 0);
	type type_shreg_S_poly2 is array (5 downto 0) of unsigned(127 downto 0);
	type type_shreg_tlast_poly is array (28 downto 0) of STD_LOGIC;---one clk spare for tag
	type type_shreg_tvalid_poly is array (27 downto 0) of STD_LOGIC;
	type type_shreg_S_poly_top is array (164 downto 0) of unsigned(127 downto 0);
	type type_shreg_blck_poly_top is array (164 downto 0) of unsigned(128 downto 0);

	type type_shreg_blck_poly is array (25 downto 0) of unsigned(127 downto 0);
	
	type type_shreg_tlast_top is array (164 downto 0) of STD_LOGIC;---one clk spare for tag
	type type_shreg_tvalid_top is array (164 downto 0) of STD_LOGIC;


end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg.all;

entity ChaCha20 is
	Port (clk				   : in  STD_LOGIC;
	    key                    : in  unsigned(255 downto 0);
		nonce                  : in  unsigned(95 downto 0);
		counter                : in  unsigned(31 downto 0);
		plaintext              : in  unsigned(511 downto 0);
		data_out               : out unsigned(511 downto 0)
        );
end ChaCha20;


architecture Behavioral of ChaCha20 is

function  order  (a : unsigned) return unsigned is
	variable a1 : unsigned(31 downto 0):=a;
	variable b1 : unsigned(31 downto 0):=(others=>'0');
begin

b1 := a1(7 downto 0)&a1(15 downto 8)&a1(23 downto 16)&a1(31 downto 24);
return b1;
end order;

signal input,output, key_output, ciphertext,plaintext_reg	: type_1;
signal Shift_reg_input	     : shreg_1;
signal Shift_reg_plaintext	 : shreg_2;
COMPONENT ChaCha_int 
  Port (clk	     : in  STD_LOGIC;
		data_in  : in  type_1;
		data_out : out type_1
        );
END COMPONENT;

begin

input(0) <= x"61707865";
input(1) <= x"3320646e";
input(2) <= x"79622d32";
input(3) <= x"6b206574";

GEN1: for i in 0 to 7 generate
    input(i+4) <= order(key((255-i*32) downto (224-i*32)));
end generate GEN1;

input(12) <= counter;
input(13) <= order(nonce(95 downto 64));
input(14) <= order(nonce(63 downto 32));
input(15) <= order(nonce(31 downto 0));


GEN2: for i in 0 to 15 generate
plaintext_reg(i) <= plaintext((511-i*32) downto (480-i*32));
process(clk)
begin
if rising_edge(clk) then
    key_output(i) <= Shift_reg_input(39)(i) + output(i);
    ciphertext(i) <= order(key_output(i)) xor Shift_reg_plaintext(40)(i);
    data_out((511-i*32) downto (480-i*32)) <= ciphertext(i);
end if;
end process;
end generate GEN2;

u1 : ChaCha_int 
    PORT MAP (
			clk		=>clk,
			data_in	=>input,
			data_out=>output
    );
    
    
process(clk)
begin
if rising_edge(clk) then
    Shift_reg_input <= Shift_reg_input(38 downto 0)&input;
    Shift_reg_plaintext <= Shift_reg_plaintext(39 downto 0)&plaintext_reg;
end if;
end process;

end Behavioral;