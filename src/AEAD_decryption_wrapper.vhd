

--in this module we have to split first clock out of next data

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;

entity AEAD_decryption_wrapper is
  Port ( 
        clk                  : in  STD_LOGIC;
        rst                  : in  STD_LOGIC;
------------------------------
--  axi_st_in_data
		axi_tvalid_in_msg    : in  STD_LOGIC;
		axi_tlast_in_msg     : in  STD_LOGIC;
		axi_tdata_in_msg     : in  UNSIGNED(127 downto 0);
		axi_tready_in_msg    : out STD_LOGIC:='1';
------------------------------
		axi_tdata_in_key     : in  UNSIGNED(255 downto 0);
------------------------------
--  axi_st_out
		axi_tvalid_out       : out STD_LOGIC;
		axi_tlast_out        : out STD_LOGIC;
		axi_tdata_out        : out UNSIGNED(127 downto 0);
		axi_tready_out       : in  STD_LOGIC;
------------------------------
		tag_valid            : out STD_LOGIC
		
		);
end AEAD_decryption_wrapper;

architecture Behavioral of AEAD_decryption_wrapper is

COMPONENT AEAD_decryption_wrapper is
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
--		axi_tvalid_in_key    : in  STD_LOGIC;
--		axi_tlast_in_key     : in  STD_LOGIC;
		axi_tdata_in_key     : in  UNSIGNED(255 downto 0);
--		axi_tready_in_key    : out STD_LOGIC;
------------------------------
--  axi_st_in_nonce
		axi_tvalid_in_nonce  : in  STD_LOGIC;
		axi_tlast_in_nonce   : in  STD_LOGIC;
		axi_tdata_in_nonce   : in  UNSIGNED(95 downto 0);
		axi_tready_in_nonce  : out STD_LOGIC;
------------------------------
--  axi_st_out
		axi_tvalid_out       : out STD_LOGIC;
		axi_tlast_out        : out STD_LOGIC;
		axi_tdata_out        : out UNSIGNED(127 downto 0);
		axi_tready_out       : in  STD_LOGIC;
------------------------------
-- additional ports		
        tag_valid             : out STD_LOGIC;
		n_in                 : in  unsigned(6 downto 0)--; --- to be calculated before or during chacha20
--        counter           : in  unsigned(31 downto 0)

----------------------------
        );
end COMPONENT;

COMPONENT AEAD_decryption is
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
--		axi_tvalid_in_key    : in  STD_LOGIC;
--		axi_tlast_in_key     : in  STD_LOGIC;
		axi_tdata_in_key     : in  UNSIGNED(255 downto 0);
--		axi_tready_in_key    : out STD_LOGIC;
------------------------------
--  axi_st_in_nonce
		axi_tvalid_in_nonce   : in  STD_LOGIC;
		axi_tlast_in_nonce    : in  STD_LOGIC;
		axi_tdata_in_nonce    : in  UNSIGNED(95 downto 0);
		axi_tready_in_nonce   : out STD_LOGIC;
------------------------------
--  axi_st_out
		axi_tvalid_out        : out  STD_LOGIC;
		axi_tlast_out         : out  STD_LOGIC;
		axi_tdata_out         : out  UNSIGNED(127 downto 0);
		axi_tready_out        : in STD_LOGIC;
------------------------------
-- additional ports		
        tag_valid             : out STD_LOGIC;
		n_in                  : in  unsigned(6 downto 0)
		);
end  COMPONENT;

function  order_128  (a : unsigned(127 downto 0)) return unsigned is
	variable b1 : unsigned(127 downto 0):=(others=>'0');
begin
		for i in 0 to 15 loop
			b1(((i+1)*8-1) downto i*8):=a((((15-i)+1)*8-1) downto (15-i)*8);
		end loop;
	return b1;
end order_128;

function  order_256  (a : unsigned(255 downto 0)) return unsigned is
	variable b1 : unsigned(255 downto 0):=(others=>'0');
begin
		for i in 0 to 31 loop
			b1(((i+1)*8-1) downto i*8):=a((((31-i)+1)*8-1) downto (31-i)*8);
		end loop;
	return b1;
end order_256;

signal active_packet : STD_LOGIC:='0';
----AEAD_ChaCha_Poly inputs
signal tvalid_key   : STD_LOGIC:='0';
signal tlast_key    : STD_LOGIC:='0';
signal key          : unsigned(255 downto 0);

signal tvalid_msg   : STD_LOGIC:='0';
signal tlast_msg    : STD_LOGIC:='0';
signal plaintext    : unsigned(127 downto 0);

signal tvalid_nonce : STD_LOGIC:='0';
signal tlast_nonce  : STD_LOGIC:='0';
signal nonce        : unsigned(95 downto 0);

signal n_in         : unsigned(6 downto 0);

signal msg_shift    : unsigned(127 downto 0);
signal tvalid_shift : STD_LOGIC:='0';
signal tlast_shift  : STD_LOGIC:='0';
signal n_in_int         : unsigned(6 downto 0);
signal msg_reordered    : unsigned(127 downto 0);


begin

    
u1 : AEAD_decryption 
    port map(
	    clk		                => clk,
        axi_tvalid_in_ciptext   => tvalid_msg,
        axi_tlast_in_ciptext    => tlast_msg,
        axi_tdata_in_ciptext    => plaintext,
--        axi_tready_in_ciptext   => tready,
-----------------------------
--  axi_st_in_key
--		axi_tvalid_in_key   => '1',
--		axi_tlast_in_key    => '1',
		axi_tdata_in_key    => key,
--		axi_tready_in_key    : out STGIC;
------------------------------
--  axi_st_in_nonce
		axi_tvalid_in_nonce => tvalid_nonce,
		axi_tlast_in_nonce  => tlast_nonce,
		axi_tdata_in_nonce  => nonce,
--		axi_tready_in_nonce => axi_tready_in_nonce,
------------------------------
--  axi_st_out
        axi_tvalid_out      => axi_tvalid_out,
        axi_tlast_out       => axi_tlast_out,
        axi_tdata_out       => axi_tdata_out,
        axi_tready_out      => '1',
        tag_valid           => tag_valid,
        n_in                => n_in_int--n_in

    );
    
n_in_int <=  (n_in+1);
--msg_reordered <= order_128(axi_tdata_in_msg);
msg_reordered <= (axi_tdata_in_msg);

process(clk)
begin
if rising_edge(clk) then
    msg_shift <= msg_reordered;
    tlast_msg  <= axi_tlast_in_msg;
end if;
end process;


process(clk)
begin
if rising_edge(clk) then
    if axi_tlast_in_msg = '1' then
        active_packet <= '0';
    else
        if axi_tvalid_in_msg = '1' then
            active_packet <= '1';
        end if;
    end if;
end if;
end process;

key_load:process(clk)
begin
if rising_edge(clk) then

    if axi_tvalid_in_msg = '1' and active_packet='0' then
--        key         <= order_256(axi_tdata_in_key);--for corundum
        key         <= (axi_tdata_in_key);---for Big endian TB
    end if;

end if;
end process;

nonce_load:process(clk)
begin
if rising_edge(clk) then

    if axi_tvalid_in_msg = '1' and active_packet='0' then
        tvalid_nonce  <= '1';
        tlast_nonce   <= '1';
--        nonce         <= x"00000000"&msg_reordered(63 downto 0);
        nonce <= x"070000004041424344454647";---for testbench compatible to RFC7539
        n_in          <= msg_reordered(106 downto 100);
    else
        tvalid_nonce  <= '0';
        tlast_nonce   <= '0';
    end if;

end if;
end process;

msg_load:process(clk)
begin
if rising_edge(clk) then

    if axi_tvalid_in_msg = '1' then
        if active_packet='0' then
            tvalid_msg <= '0';
        else
            tvalid_msg <= '1';
            plaintext <= msg_reordered;
        end if;
    else
        tvalid_msg <= '0';
    end if;
end if;
end process;

end Behavioral;
