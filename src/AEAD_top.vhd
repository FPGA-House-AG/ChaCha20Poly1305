
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;

entity AEAD_top is
	Port (clk				: in  STD_LOGIC;
			data_in			: in  unsigned(31 downto 0);
			data_out		: out unsigned(31 downto 0);
			tlast			: in  STD_LOGIC;
			tvalid			: in  STD_LOGIC;
			tvalid_out    : out  STD_LOGIC;
		    tlast_out     : out  STD_LOGIC
        );
end AEAD_top;

architecture Behavioral of AEAD_top is


COMPONENT AEAD_ChaCha_Poly is
  Port ( 
        clk                  : in  STD_LOGIC;
-----------------------------
--  axi_st_in_data
		axi_tvalid_in_msg    : in  STD_LOGIC;
		axi_tlast_in_msg     : in  STD_LOGIC;
		axi_tdata_in_msg     : in  UNSIGNED(127 downto 0);
		axi_tready_in_msg    : out STD_LOGIC:='1';
-----------------------------
--  axi_st_in_key
		axi_tvalid_in_key    : in  STD_LOGIC;
		axi_tlast_in_key     : in  STD_LOGIC;
		axi_tdata_in_key     : in  UNSIGNED(255 downto 0);
		axi_tready_in_key    : out STD_LOGIC;
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
		n_in                 : in  unsigned(6 downto 0); --- to be calculated before or during chacha20
        counter           : in  unsigned(31 downto 0)

----------------------------
        );
end COMPONENT;

signal clk_in,tready		         : STD_LOGIC;
--signal data_in,data_out  : type_1;
signal key                  : unsigned(255 downto 0);
signal nonce                : unsigned(95 downto 0);
signal counter              : unsigned(31 downto 0);
--signal data_out             : unsigned(127 downto 0);
signal plaintext            : unsigned(127 downto 0);

signal axi_tvalid,axi_tlast	: STD_LOGIC:='0';

--signal tvalid_out,tlast_out	: STD_LOGIC:='0';

signal axi_tlast_in_nonce	: STD_LOGIC:='0';
signal axi_tready_in_nonce	: STD_LOGIC:='0';
signal axi_tvalid_in_nonce	: STD_LOGIC:='0';

signal axi_tlast_in_key	    : STD_LOGIC:='0';
--signal axi_tready_in_key	: STD_LOGIC:='0';
signal axi_tvalid_in_key	: STD_LOGIC:='0';

signal n_in                 : unsigned(6 downto 0);
signal data_out_1               : unsigned(127 DOWNTO 0);



begin

u1 : AEAD_ChaCha_Poly 
    port map(
	   clk		            =>clk,

        axi_tvalid_in_msg   => tvalid,
        axi_tlast_in_msg    => tlast,
        axi_tdata_in_msg    => plaintext,
        axi_tready_in_msg   => tready,
-----------------------------
--  axi_st_in_key
		axi_tvalid_in_key   => tvalid,
		axi_tlast_in_key    => tlast,
		axi_tdata_in_key    => key,
--		axi_tready_in_key    : out STGIC;
------------------------------
--  axi_st_in_nonce
		axi_tvalid_in_nonce => tvalid,
		axi_tlast_in_nonce  => tlast,
		axi_tdata_in_nonce  => nonce,
		axi_tready_in_nonce => axi_tready_in_nonce,
------------------------------
--  axi_st_out
        axi_tvalid_out      => tvalid_out,
        axi_tlast_out       => tlast_out,
        axi_tdata_out       => data_out_1,
        axi_tready_out      => '1',
        n_in                => n_in,
        counter             => counter

    );

plaintext <= data_in&data_in&data_in&data_in;
key <= plaintext&plaintext;
nonce <= data_in&data_in&data_in;
n_in <= data_in(6 downto 0);
counter <= data_in;
data_out<=data_out_1(127 downto 96) xor data_out_1(95 downto 64) xor data_out_1(63 downto 32) xor data_out_1(31 downto 0);
   

end Behavioral;
