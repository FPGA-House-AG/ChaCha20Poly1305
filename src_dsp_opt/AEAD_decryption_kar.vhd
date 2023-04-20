--30.01.2023 - changed n_in
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;

entity AEAD_decryption_kar is
 Port ( 
        clk					: in  STD_LOGIC;
-----------------------------
--  axi_st_in_data
		axi_tvalid_in_ciptext    : in  STD_LOGIC;
		axi_tlast_in_ciptext     : in  STD_LOGIC;
		axi_tdata_in_ciptext     : in  UNSIGNED(127 downto 0);
		axi_tready_in_ciptext    : out STD_LOGIC:='1';
-----------------------------
--  axi_st_in_key
		axi_tdata_in_key     : in  UNSIGNED(255 downto 0);
------------------------------
--  axi_st_in_nonce
		axi_tvalid_in_nonce   : in  STD_LOGIC;
		axi_tlast_in_nonce    : in  STD_LOGIC;
		axi_tdata_in_nonce    : in  UNSIGNED(95 downto 0);
		axi_tready_in_nonce   : out STD_LOGIC;
------------------------------
--  axi_st_out
		axi_tvalid_out        : out  STD_LOGIC:='0';
		axi_tlast_out         : out  STD_LOGIC:='0';
		axi_tdata_out         : out  UNSIGNED(127 downto 0);
		axi_tready_out        : in STD_LOGIC;
------------------------------
-- additional ports		
        tag_valid             : out STD_LOGIC:='0';
		n_in                  : in  unsigned(6 downto 0)
		);
end AEAD_decryption_kar;

architecture Behavioral of AEAD_decryption_kar is

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

COMPONENT Poly_1305_pipe_top_kar is
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

signal key                      : unsigned(255 downto 0);
signal nonce                    : unsigned(95 downto 0);
signal counter1,counter2        : unsigned(31 downto 0):=(others => '0');
signal ChaCha_data_out          : unsigned(127 downto 0);
signal Blck                     : unsigned(128 downto 0);
signal r,s,r_ordered,s_ordered  : unsigned(127 downto 0);
signal axi_tvalid_out_chacha    : STD_LOGIC:='0';
signal axi_tlast_out_chacha     : STD_LOGIC:='0';
--signal shreg_n_cnt              : type_shreg_n_cnt_aead;
signal r_s_ready                : STD_LOGIC:='0';
signal cnt_valid                : natural range 0 to 3:=0;
signal n_out                    : unsigned(6 downto 0);
signal axi_tlast_in_poly        : STD_LOGIC:='0'; 
signal axi_tlast_in_poly1       : STD_LOGIC:='0'; 
signal axi_tvalid_in_poly       : STD_LOGIC:='0';
signal n_bytes,n_bytes2         : unsigned(15 downto 0);
signal shreg_ciptext            : type_shreg_ciptext;
signal shreg_plaintext          : type_shreg_plaintext;
signal tag_out                  : unsigned(127 downto 0):=(others=>'0');
signal axi_tlast_poly_out       : STD_LOGIC:='0';
signal axi_tvalid_poly_out      : STD_LOGIC:='0';
--signal axi_tlast_in_chacha      : STD_LOGIC:='0'; 
signal axi_tlast_in_chacha1     : STD_LOGIC:='0'; 
--signal axi_tvalid_in_chacha     : STD_LOGIC:='0';
signal axi_tvalid_in_chacha1    : STD_LOGIC:='0';
signal axi_tdata_in_chacha1     : unsigned(127 downto 0);
signal cnt_valid_chacha         : natural range 0 to 2000:=0;
signal shreg_tvalid_aead        : type_shreg_tvalid_aead;
signal shreg_tlast_aead         : type_shreg_tlast_aead;
signal n_shift_dec              : type_n_shift_dec;
signal cnt_valid_out            : natural range 0 to 2000:=0;




begin

u1 : ChaCha20_128 
    PORT MAP (
	clk		           => clk,
    key	               => axi_tdata_in_key,--key,
    n_in               => n_in,
	n_out              => n_out,

	axi_tdata_in_nonce => axi_tdata_in_nonce,
    axi_tlast_in_nonce => axi_tlast_in_nonce,
    axi_tlast_out_nonce=> r_s_ready,
    r_out              => r,
	s_out              => s,
	counter	           => counter2,

	axi_tvalid_in_msg  => axi_tvalid_in_chacha1,
	axi_tlast_in_msg   => axi_tlast_in_chacha1,
	axi_tdata_in_msg   => axi_tdata_in_chacha1,
	axi_tready_in_msg  => axi_tready_in_ciptext,

	axi_tdata_out_msg  => ChaCha_data_out,
	axi_tvalid_out_msg => axi_tvalid_out_chacha,
	axi_tlast_out_msg  => axi_tlast_out_chacha,
	axi_tready_out_msg => '1'
    );
    
u2: Poly_1305_pipe_top_kar 
  Port map 
       (clk			=> clk,
		Blck		=> Blck,
		r			=> r_ordered,
		s			=> s_ordered,
		n_in        => n_bytes(10 downto 4),
		tvalid      => axi_tvalid_in_poly,
		tlast       => axi_tlast_in_poly,
		tvalid_out  => axi_tvalid_poly_out,
		tlast_out   => axi_tlast_poly_out,
		data_out	=> tag_out
        );

n_counter:process(clk)
begin
if rising_edge(clk) then
--shift register for ciptext
    shreg_ciptext <= shreg_ciptext(286 downto 0)&axi_tdata_in_ciptext;
    shreg_plaintext <= shreg_plaintext(208 downto 0)&ChaCha_data_out;---after chacha
    
    shreg_tvalid_aead <= shreg_tvalid_aead(82 downto 0)&axi_tvalid_in_ciptext;
    shreg_tlast_aead <= shreg_tlast_aead(82 downto 0)&axi_tlast_in_ciptext;
    
    axi_tdata_out <= shreg_plaintext(203);
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then

--    if n_in=0 then
        
--    else
--        n_shift_dec <= n_shift_dec(192 downto 0)&(n_out);
--    end if;
    
    if (cnt_valid_chacha <= (n_in-1) or n_in=0) and axi_tvalid_in_ciptext='1' then----less or equal
        axi_tvalid_in_chacha1 <= '1';
    else
        axi_tvalid_in_chacha1 <= '0';
    end if;
    
    if (cnt_valid_chacha = (n_in-1) or n_in=0) and axi_tvalid_in_ciptext='1' then---
	   axi_tlast_in_chacha1 <= '1';
	else
	   axi_tlast_in_chacha1 <= '0';
	end if;
	
	
	axi_tdata_in_chacha1 <= axi_tdata_in_ciptext;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    if axi_tvalid_in_ciptext='1' then
        if axi_tlast_in_ciptext='1' then
            cnt_valid_chacha <= 0;
        else
            cnt_valid_chacha <= cnt_valid_chacha+1;
        end if;
    
    end if;
end if;
end process;



process(clk)
begin
if rising_edge(clk) then

    axi_tvalid_in_poly <= shreg_tvalid_aead(83);
    axi_tlast_in_poly <= shreg_tlast_aead(83);

    if shreg_tlast_aead(83) = '1' then
        Blck <= '1'&x"0000000000000000"&n_bytes2(7 downto 0)&n_bytes2(15 downto 8)&x"000000000000";
    else
        Blck <= '1'&shreg_ciptext(83);
    end if;
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then

    n_bytes <= "00000"&(n_out+1)&"0000";
    n_bytes2 <= "00000"&(n_out)&"0000";
    if n_out=0 then
        n_shift_dec <= n_shift_dec(202 downto 0)&("0000001");
    else
        n_shift_dec <= n_shift_dec(202 downto 0)&(n_out);
    end if;
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    if axi_tvalid_poly_out = '1' then
        if (axi_tlast_poly_out = '1') then
            cnt_valid_out <= 0;
        else
            cnt_valid_out <= cnt_valid_out+1;
        end if;
    end if;
end if;
end process;


process(clk)
begin
if rising_edge(clk) then
    
    if (cnt_valid_out <= n_shift_dec(203)-1) and axi_tvalid_poly_out='1' then----less or equal
        axi_tvalid_out <= '1';
    else
        axi_tvalid_out <= '0';
    end if;
    
  if (cnt_valid_out = n_shift_dec(203)-1) and axi_tvalid_poly_out='1' then---
	   axi_tlast_out <= '1';
	else
	   axi_tlast_out <= '0';
	end if;
    
--axi_tlast_out <= axi_tlast_poly_out;    
--axi_tvalid_out <= axi_tvalid_poly_out;
    
end if;
end process;

process(clk)
begin
if rising_edge(clk) then
    if axi_tlast_poly_out = '1' then
        if shreg_ciptext(287) = (tag_out) then
            tag_valid <= '1';
        else
            tag_valid <= '0';
        end if;
    end if;
    
end if;
end process;

counter_logic:process(clk)
begin
if rising_edge(clk) then
    if axi_tlast_in_ciptext = '1' then
        counter1 <= (others => '0');
    elsif axi_tlast_in_nonce='1' then---axi_tlast_in_key='1' or 
        counter1 <= x"00000001";
        cnt_valid <= 0;
    elsif axi_tvalid_in_ciptext = '1' then
        if (cnt_valid = 3) or (axi_tlast_in_ciptext = '1') then
            cnt_valid <= 0;
            counter1 <= counter1+1;
        else
            cnt_valid <= cnt_valid+1;
        end if;
    end if;
counter2<=counter1;
end if;
end process;

r_s_storage:process(clk)
begin
if rising_edge(clk) then

    if r_s_ready='1' then
        r_ordered <= r and x"0ffffffc0ffffffc0ffffffc0fffffff";--order_128(r);
        s_ordered <= s;
    end if;
end if;
end process;

end Behavioral;

