
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

package bus_pkg1 is

	type type_1 is array (0 to 15) of unsigned(31 downto 0);
	type type_2 is array (0 to 9) of type_1;
	type shreg_1 is array (79 downto 0) of type_1;
	type shreg_2 is array (40 downto 0) of type_1;
	type shreg_3 is array (81 downto 0) of unsigned(127 downto 0);
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
	type type_shreg_tlast_poly is array (26 downto 0) of STD_LOGIC;---one clk spare for tag
	type type_shreg_tvalid_poly is array (27 downto 0) of STD_LOGIC;
	type type_shreg_S_poly_top is array (164 downto 0) of unsigned(127 downto 0);
	type type_shreg_blck_poly_top is array (164 downto 0) of unsigned(128 downto 0);
	type type_shreg_blck_poly is array (26 downto 0) of unsigned(127 downto 0);
	type type_shreg_tlast_top is array (164 downto 0) of STD_LOGIC;---one clk spare for tag
	type type_shreg_tvalid_top is array (164 downto 0) of STD_LOGIC;
    type type_shreg_tvalid_chacha is array (81 downto 0) of STD_LOGIC;
    type type_shreg_tlast_chacha is array (82 downto 0) of STD_LOGIC;

    type type_shreg_wren_chacha is array (81 downto 0) of STD_LOGIC;
    type type_shreg_n_cnt_aead is array (81 downto 0) of unsigned(6 downto 0);
--    type type_shreg_n_in_chacha is array (81 downto 0) of unsigned(6 downto 0);
    type type_shreg_ciptext  is array (277 downto 0) of unsigned(127 downto 0);
    
    type type_shreg_plaintext  is array (199 downto 0) of unsigned(127 downto 0);
    type type_shreg_tvalid_aead is array (83 downto 0) of STD_LOGIC;
    type type_shreg_tlast_aead is array (83 downto 0) of STD_LOGIC;
    type type_n_shift_dec  is array (193 downto 0) of unsigned(6 downto 0);

    type type_shreg_header  is array (277 downto 0) of unsigned(127 downto 0);


end package;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;

entity AEAD_ChaCha_Poly is
  Port ( 
        clk					: in  STD_LOGIC;
-----------------------------
--  axi_st_in_data
		axi_tvalid_in_msg    : in  STD_LOGIC;
		axi_tlast_in_msg     : in  STD_LOGIC;
		axi_tdata_in_msg     : in  UNSIGNED(127 downto 0);
		axi_tready_in_msg    : out STD_LOGIC:='1';
-----------------------------
--  axi_st_in_key
--		axi_tvalid_in_key    : in  STD_LOGIC;
--		axi_tlast_in_key     : in  STD_LOGIC;
		axi_tdata_in_key     : in  UNSIGNED(255 downto 0);
--		axi_tready_in_key    : out STD_LOGIC;
------------------------------
--  axi_st_in_nonce
		axi_tvalid_in_nonce    : in  STD_LOGIC;
		axi_tlast_in_nonce     : in  STD_LOGIC;
		axi_tdata_in_nonce     : in  UNSIGNED(95 downto 0);
--		axi_tready_in_nonce    : out STD_LOGIC;
------------------------------
--  axi_st_out
		axi_tvalid_out    : out  STD_LOGIC;
		axi_tlast_out     : out  STD_LOGIC;
		axi_tdata_out     : out  UNSIGNED(127 downto 0);
		axi_tready_out    : in STD_LOGIC;
------------------------------
-- additional ports		
		n_in              : in  unsigned(6 downto 0)--; --- to be calculated before or during chacha20
--        counter           : in  unsigned(31 downto 0)----to be deleted. for 29_08 calculates inside the algorithm
----------------------------
        );
end AEAD_ChaCha_Poly;

architecture Behavioral of AEAD_ChaCha_Poly is


COMPONENT ChaCha20_128 
    Port (clk			      : in  STD_LOGIC;
		key                   : in  unsigned(255 downto 0);
		n_in                   : in  unsigned(6 downto 0);
	    n_out                  : out  unsigned(6 downto 0);
--		nonce                  : in  unsigned(95 downto 0);
		axi_tdata_in_nonce    : in  unsigned(95 downto 0);
        axi_tlast_in_nonce    : in  STD_LOGIC;
        axi_tlast_out_nonce   : out  STD_LOGIC;
		r_out                 : out unsigned(127 downto 0);
		s_out                 : out unsigned(127 downto 0);
		counter               : in  unsigned(31 downto 0);
--		plaintext              : in  unsigned(127 downto 0);
		axi_tvalid_in_msg     : in  STD_LOGIC;
		axi_tlast_in_msg      : in  STD_LOGIC;
		axi_tdata_in_msg      : in  unsigned(127 downto 0);
		axi_tready_in_msg     : out STD_LOGIC;
--		data_out              : out unsigned(127 downto 0);
		axi_tvalid_out_msg    : out  STD_LOGIC;
		axi_tlast_out_msg     : out  STD_LOGIC;
		axi_tdata_out_msg     : out  unsigned(127 downto 0);
		axi_tready_out_msg    : in STD_LOGIC
        );
END COMPONENT;

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

function  order_128  (a : unsigned) return unsigned is
	variable a1 : unsigned(127 downto 0):=a;
	variable b1 : unsigned(127 downto 0):=(others=>'0');
begin

b1 := a1(7 downto 0)&a1(15 downto 8)&a1(23 downto 16)&a1(31 downto 24)&a1(39 downto 32)&a1(47 downto 40)&a1(55 downto 48)&a1(63 downto 56)&a1(71 downto 64)&a1(79 downto 72)&a1(87 downto 80)&a1(95 downto 88)&a1(103 downto 96)&a1(111 downto 104)&a1(119 downto 112)&a1(127 downto 120);
return b1;
end order_128;

signal key                   : unsigned(255 downto 0);
signal nonce                 : unsigned(95 downto 0);
signal counter1              : unsigned(31 downto 0):=(others => '0');
signal ChaCha_data_out       : unsigned(127 downto 0);
signal Blck                  : unsigned(128 downto 0);
signal r,s,r_ordered,s_ordered  : unsigned(127 downto 0);
signal axi_tvalid_out_chacha : STD_LOGIC:='0';
signal axi_tlast_out_chacha  : STD_LOGIC:='0';
signal shreg_n_cnt           : type_shreg_n_cnt_aead;
signal r_s_ready             : STD_LOGIC:='0';
signal cnt_valid             : natural range 0 to 3:=0;
signal n_out                  : unsigned(6 downto 0);

signal axi_tlast_in_poly     : STD_LOGIC:='0'; 
signal axi_tlast_in_poly1     : STD_LOGIC:='0'; 
signal axi_tvalid_in_poly    : STD_LOGIC:='0';
signal n_bytes,n_bytes2               : unsigned(15 downto 0);

begin

u1 : ChaCha20_128 
    PORT MAP (
	clk		           => clk,
    key	               => axi_tdata_in_key,--key,
    n_in               => n_in,
	n_out              => n_out,
--	nonce	           => nonce,
	axi_tdata_in_nonce => axi_tdata_in_nonce,
    axi_tlast_in_nonce => axi_tlast_in_nonce,
    axi_tlast_out_nonce=> r_s_ready,
    r_out              => r,
	s_out              => s,
	counter	           => counter1,
--	plaintext => plaintext,
	axi_tvalid_in_msg  => axi_tvalid_in_msg,
	axi_tlast_in_msg   => axi_tlast_in_msg,
	axi_tdata_in_msg   => axi_tdata_in_msg,
	axi_tready_in_msg  => axi_tready_in_msg,
--	data_out	=>data_out_1,
	axi_tdata_out_msg  => ChaCha_data_out,
	axi_tvalid_out_msg => axi_tvalid_out_chacha,
	axi_tlast_out_msg  => axi_tlast_out_chacha,
	axi_tready_out_msg => '1'
    );
    
u2: Poly_1305_pipe_top 
  Port map 
       (clk			=> clk,
		Blck		=> Blck,
		r			=> r_ordered,
		s			=> s_ordered,
		n_in        => n_bytes(10 downto 4),--n_out,--shreg_n_cnt(81),
		tvalid      => axi_tvalid_in_poly,--axi_tvalid_out_chacha,
		tlast       => axi_tlast_in_poly,--axi_tlast_out_chacha,
		tvalid_out  => axi_tvalid_out,
		tlast_out   => axi_tlast_out,
		data_out	=> axi_tdata_out
        );
    


process(clk)
begin
if rising_edge(clk) then


    axi_tvalid_in_poly <= axi_tvalid_out_chacha or axi_tlast_in_poly1;
    axi_tlast_in_poly1 <= axi_tlast_out_chacha;
    axi_tlast_in_poly <= axi_tlast_in_poly1;
    
    if axi_tlast_in_poly1 = '1' then
        Blck <= '1'&x"0000000000000000"&n_bytes2(7 downto 0)&n_bytes2(15 downto 8)&x"000000000000";
    else
        Blck <= '1'&ChaCha_data_out;
    end if;
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    n_bytes <= "00000"&(n_out+1)&"0000";
    n_bytes2 <= "00000"&(n_out)&"0000";
end if;
end process;
----shift n_out throught Poly and output it together with
--n_counter:process(clk)
--begin
--if rising_edge(clk) then
----shift register for n_cnt
--    shreg_n_cnt <= shreg_n_cnt(80 downto 0)&n_out;

--end if;
--end process;

counter_logic:process(clk)
begin
if rising_edge(clk) then
    if axi_tlast_in_msg = '1' then
        counter1 <= (others => '0');
    elsif axi_tlast_in_nonce='1' then--axi_tlast_in_key='1' or 
        counter1 <= x"00000001";
        cnt_valid <= 0;
    elsif axi_tvalid_in_msg = '1' then
        if (cnt_valid = 3) or (axi_tlast_in_msg = '1') then
            cnt_valid <= 0;
            counter1 <= counter1+1;
        else
            cnt_valid <= cnt_valid+1;
        end if;
    end if;

end if;
end process;

r_s_storage:process(clk)---must add preparing r and s (reversing and clamping)
begin
if rising_edge(clk) then

    if r_s_ready='1' then
        r_ordered <= r and x"0ffffffc0ffffffc0ffffffc0fffffff";--order_128(r);
        s_ordered <= s;
    end if;
end if;
end process;

end Behavioral;
