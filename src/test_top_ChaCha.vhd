
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;

entity test_top_ChaCha is
	Port (clk					: in  STD_LOGIC;
			data_in				: in  unsigned(31 downto 0);
			data_out				: out unsigned(31 downto 0)
        );
end test_top_ChaCha;

architecture Behavioral of test_top_ChaCha is

--signal clk_in		: STD_LOGIC;
--signal DATA_IN		: unsigned(255 DOWNTO 0);

signal data_out_1	: unsigned(127 DOWNTO 0);

signal a0			: unsigned(63 downto 0);
signal i_out		: natural range 0 to 23;
signal en, done	: STD_LOGIC:='0';
signal input	: unsigned(511 DOWNTO 0);

signal key      : unsigned(255 downto 0);
signal nonce    : unsigned(95 downto 0);
signal counter  : unsigned(31 downto 0);
signal plaintext : unsigned(127 downto 0);

signal tready	: STD_LOGIC:='0';


COMPONENT ChaCha20_128 
	Port (clk			: in  STD_LOGIC;
		key                    : in  unsigned(255 downto 0);
		nonce                  : in  unsigned(95 downto 0);
		counter                : in  unsigned(31 downto 0);
--		plaintext              : in  unsigned(127 downto 0);
		axi_tvalid_in_msg    : in  STD_LOGIC;
		axi_tlast_in_msg     : in  STD_LOGIC;
		axi_tdata_in_msg     : in  unsigned(127 downto 0);
		axi_tready_in_msg    : out STD_LOGIC;
		data_out               : out unsigned(127 downto 0);
		axi_tvalid_out_msg    : out  STD_LOGIC;
		axi_tlast_out_msg     : out  STD_LOGIC;
		axi_tdata_out_msg     : out  unsigned(127 downto 0);
		axi_tready_out_msg    : in STD_LOGIC
        );
END COMPONENT;

begin
--GEN1: for i in 0 to 15 generate

--input(i) <= data_in;

--end generate GEN1;	

--input<=data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in;

key <= data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in;
nonce <= data_in&data_in&data_in;
counter <= data_in;
--plaintext<=data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in;

--u1 : ChaCha20 
--    PORT MAP (
--			clk		=>clk,
--	 key	=> key,
--	 nonce	=> nonce,
--	 counter	=> counter,
--	 plaintext => plaintext,
--			data_out	=>data_out_1
--    );

plaintext<=data_in&data_in&data_in&data_in;--&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in&data_in;

u1 : ChaCha20_128 
    PORT MAP (
			clk		=>clk,
    key	=> key,
	nonce	=> nonce,
	counter	=> counter,
--	plaintext => plaintext,
	axi_tvalid_in_msg => '1',
	axi_tlast_in_msg => '1',
	axi_tdata_in_msg => plaintext,
	axi_tready_in_msg => tready,
--	data_out	=>data_out_1,
	axi_tdata_out_msg => data_out_1,
	axi_tready_out_msg => '1'
    );


	 
--data_out<=data_out_1(0) xor data_out_1(1) xor data_out_1(2) 
--          xor data_out_1(3) xor data_out_1(4)
--	 	  xor data_out_1(5) xor data_out_1(6) xor data_out_1(7)
--	 	  xor data_out_1(8) xor data_out_1(9) xor data_out_1(10)
--	 	  xor data_out_1(11) xor data_out_1(12) xor data_out_1(13) 
--	 	  xor data_out_1(14) xor data_out_1(15);

--data_out<=data_out_1(511 downto 480) xor data_out_1(479 downto 448) xor data_out_1(447 downto 416) xor data_out_1(415 downto 384) xor data_out_1(383 downto 352) xor data_out_1(351 downto 320) xor data_out_1(319 downto 288) xor data_out_1(287 downto 256) xor data_out_1(255 downto 224) xor data_out_1(223 downto 192) xor data_out_1(191 downto 160) xor data_out_1(159 downto 128) xor data_out_1(127 downto 96) xor data_out_1(95 downto 64) xor data_out_1(63 downto 32) xor data_out_1(31 downto 0);
  
  data_out<=data_out_1(127 downto 96) xor data_out_1(95 downto 64) xor data_out_1(63 downto 32) xor data_out_1(31 downto 0);
  
end Behavioral;