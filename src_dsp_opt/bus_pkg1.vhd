
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package bus_pkg1 is

	type type_1 is array (0 to 15) of unsigned(31 downto 0);
	type type_2 is array (0 to 9) of type_1;
	type shreg_1 is array (79 downto 0) of type_1;
	type shreg_2 is array (40 downto 0) of type_1;
	type shreg_3 is array (81 downto 0) of unsigned(127 downto 0);
    type mod_red_type is array (0 to 5) of unsigned(129 downto 0);
    type mul_pipe_type is array (0 to 5) of unsigned(135 downto 0);
  
--------for version before optimization
--	type type_shreg_r1 is array (107 downto 0) of unsigned(127 downto 0);
--	type type_shreg_r2 is array (89 downto 0) of unsigned(129 downto 0);
--	type type_shreg_r4 is array (71 downto 0) of unsigned(129 downto 0);
--	type type_shreg_r8 is array (53 downto 0) of unsigned(129 downto 0);
--	type type_shreg_r16 is array (35 downto 0) of unsigned(129 downto 0);
--	type type_shreg_r32 is array (17 downto 0) of unsigned(129 downto 0);
--	type type_shreg_n is array (107 downto 0) of unsigned(6 downto 0);
-- 	type type_shreg_u3 is array (17 downto 0) of unsigned(129 downto 0);
--	type type_shreg_S_poly_top is array (164 downto 0) of unsigned(127 downto 0);
--	type type_shreg_blck_poly_top is array (164 downto 0) of unsigned(128 downto 0);
--	type type_shreg_tlast_top is array (164 downto 0) of STD_LOGIC;---one clk spare for tag
--	type type_shreg_tvalid_top is array (164 downto 0) of STD_LOGIC;
--	type type_shreg_tlast_poly is array (26 downto 0) of STD_LOGIC;---one clk spare for tag
--	type type_shreg_tvalid_poly is array (27 downto 0) of STD_LOGIC;
--	type type_shreg_blck_poly is array (26 downto 0) of unsigned(127 downto 0);
--	type type_shreg_S_poly1 is array (19 downto 0) of unsigned(127 downto 0);
--	type type_shreg_S_poly2 is array (5 downto 0) of unsigned(127 downto 0);
--  type type_shreg_header  is array (277 downto 0) of unsigned(127 downto 0);
--  type type_shreg_ciptext  is array (277 downto 0) of unsigned(127 downto 0);    
--  type type_shreg_plaintext  is array (199 downto 0) of unsigned(127 downto 0);
--  type type_n_shift_dec  is array (193 downto 0) of unsigned(6 downto 0);

-----------------------------------------------
	type type_shreg_r1 is array (113 downto 0) of unsigned(127 downto 0);
	type type_shreg_r2 is array (94 downto 0) of unsigned(129 downto 0);
	type type_shreg_r4 is array (75 downto 0) of unsigned(129 downto 0);
	type type_shreg_r8 is array (56 downto 0) of unsigned(129 downto 0);
	type type_shreg_r16 is array (37 downto 0) of unsigned(129 downto 0);
	type type_shreg_r32 is array (18 downto 0) of unsigned(129 downto 0);
	type type_shreg_n is array (113 downto 0) of unsigned(6 downto 0);
	type type_shreg_S_poly_top is array (173 downto 0) of unsigned(127 downto 0);
	type type_shreg_blck_poly_top is array (173 downto 0) of unsigned(128 downto 0);
	type type_shreg_tlast_top is array (173 downto 0) of STD_LOGIC;---one clk spare for tag
	type type_shreg_tvalid_top is array (173 downto 0) of STD_LOGIC;
	type type_shreg_tlast_poly is array (27 downto 0) of STD_LOGIC;---one clk spare for tag
	type type_shreg_tvalid_poly is array (28 downto 0) of STD_LOGIC;
	type type_shreg_blck_poly is array (27 downto 0) of unsigned(127 downto 0);
	type type_shreg_S_poly1 is array (20 downto 0) of unsigned(127 downto 0);
	type type_shreg_S_poly2 is array (6 downto 0) of unsigned(127 downto 0);
    type type_shreg_header  is array (287 downto 0) of unsigned(127 downto 0);
    type type_shreg_ciptext  is array (287 downto 0) of unsigned(127 downto 0);
    type type_shreg_plaintext  is array (209 downto 0) of unsigned(127 downto 0);
    type type_n_shift_dec  is array (203 downto 0) of unsigned(6 downto 0);

---------------------------after opt-----------------------
	
	
	
	
    


    type type_shreg_tvalid_chacha is array (81 downto 0) of STD_LOGIC;
    type type_shreg_tlast_chacha is array (82 downto 0) of STD_LOGIC;
    type type_shreg_wren_chacha is array (81 downto 0) of STD_LOGIC;
    type type_shreg_n_cnt_aead is array (81 downto 0) of unsigned(6 downto 0);
--    type type_shreg_n_in_chacha is array (81 downto 0) of unsigned(6 downto 0);

    type type_shreg_tvalid_aead is array (83 downto 0) of STD_LOGIC;
    type type_shreg_tlast_aead is array (83 downto 0) of STD_LOGIC;



end package;

--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use ieee.numeric_std.all;

--package bus_pkg2 is



--end package;


