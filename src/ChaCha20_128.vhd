
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.bus_pkg1.all;
  
entity ChaCha20_128 is
  Port (clk				   : in  STD_LOGIC;
	    key                    : in  unsigned(255 downto 0);
	    n_in                   : in  unsigned(6 downto 0);
	    n_out                  : out  unsigned(6 downto 0);
		axi_tdata_in_nonce     : in  unsigned(95 downto 0);
        axi_tlast_in_nonce     : in  STD_LOGIC;
        axi_tlast_out_nonce    : out  STD_LOGIC;
		r_out               : out unsigned(127 downto 0);
		s_out               : out unsigned(127 downto 0);
		counter                : in  unsigned(31 downto 0);
		axi_tvalid_in_msg    : in  STD_LOGIC;
		axi_tlast_in_msg     : in  STD_LOGIC;
		axi_tdata_in_msg     : in  unsigned(127 downto 0);
		axi_tready_in_msg    : out STD_LOGIC:='1';
		
		axi_tvalid_out_msg    : out  STD_LOGIC;
		axi_tlast_out_msg     : out  STD_LOGIC;
		axi_tdata_out_msg     : out  unsigned(127 downto 0);
		axi_tready_out_msg    : in STD_LOGIC
		
        );
end ChaCha20_128;

architecture Behavioral of ChaCha20_128 is

function  order  (a : unsigned) return unsigned is
	variable a1 : unsigned(31 downto 0):=a;
	variable b1 : unsigned(31 downto 0):=(others=>'0');
begin

b1 := a1(7 downto 0)&a1(15 downto 8)&a1(23 downto 16)&a1(31 downto 24);
return b1;
end order;


signal input,output, key_output, ciphertext, key_gen	: type_1;
signal Shift_reg_input	    : shreg_1;
signal Shift_reg_plaintext  : shreg_3;
signal data_to_fifo         : STD_LOGIC_VECTOR(511 downto 0);
signal data_to_fifo_uns     : unsigned(511 downto 0);
signal data_out_fifo        : STD_LOGIC_VECTOR(127 downto 0);
signal data_out_fifo_uns    : unsigned(127 downto 0);
signal plaintext_reg        : unsigned(127 downto 0);
signal cnt_valid,cnt_valid_out    : natural range 0 to 3:=0;
signal wr_en,wr_en_1        : STD_LOGIC:='0';
signal shreg_tvalid         : type_shreg_tvalid_chacha;
signal shreg_tlast          : type_shreg_tlast_chacha;
signal shreg_wren           : type_shreg_wren_chacha;
signal shreg_n_in           : type_shreg_n_cnt_aead;--81
signal n_bytes              : unsigned(15 downto 0);



COMPONENT ChaCha_int 
  Port (clk	     : in  STD_LOGIC;
		data_in  : in  type_1;
		data_out : out type_1
        );
END COMPONENT;

begin
----------------------------------
-------input initialization-------
input(0) <= x"61707865";
input(1) <= x"3320646e";
input(2) <= x"79622d32";
input(3) <= x"6b206574";

GEN1: for i in 0 to 7 generate
    input(i+4) <= order(key((255-i*32) downto (224-i*32)));
end generate GEN1;

input(12) <= counter;
input(13) <= order(axi_tdata_in_nonce(95 downto 64));
input(14) <= order(axi_tdata_in_nonce(63 downto 32));
input(15) <= order(axi_tdata_in_nonce(31 downto 0));
----------------------------------

GEN2: for i in 0 to 15 generate
    process(clk)
    begin
    if rising_edge(clk) then
        key_output(i) <= Shift_reg_input(79)(i) + output(i);
        data_to_fifo_uns((511-i*32) downto (480-i*32)) <= order(key_output(i));
        key_gen(i) <= (key_output(i));
    end if;
    end process;
end generate GEN2;

GEN3: for j in 0 to 3 generate
    process(clk)
    begin
    if rising_edge(clk) then
        r_out(127-(32*j) downto 96-(32*j)) <= (key_gen(3-j));
        s_out(127-(32*j) downto 96-(32*j)) <= (key_gen(7-j));
    end if;
    end process;
end generate GEN3;


u1 : ChaCha_int 
    PORT MAP (
		clk		=>clk,
        data_in	=>input,
        data_out=>output
    );
    

process(clk)
begin
if rising_edge(clk) then
    if shreg_tvalid(81) = '1' then
        if (cnt_valid_out = 3) or (shreg_tlast(81) = '1') then
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
    
    Shift_reg_input <= Shift_reg_input(78 downto 0)&input;
    Shift_reg_plaintext <= Shift_reg_plaintext(80 downto 0)&axi_tdata_in_msg;
    shreg_tvalid <= shreg_tvalid(80 downto 0)&axi_tvalid_in_msg;
    shreg_tlast <= shreg_tlast(81 downto 0)&axi_tlast_in_msg;
    shreg_wren <= shreg_wren(80 downto 0)&axi_tlast_in_nonce;
    shreg_n_in <= shreg_n_in(80 downto 0)&n_in;

end if;
end process;


process(clk)
begin
if rising_edge(clk) then

    axi_tvalid_out_msg <= shreg_tvalid(81);-- or shreg_tlast(82);
    axi_tlast_out_msg <= shreg_tlast(81);
    axi_tlast_out_nonce <= shreg_wren(81); -- means new r,s value
    n_out <= shreg_n_in(81);
end if;
end process;

--process(clk)
--begin
--if rising_edge(clk) then
--    n_bytes <= "00000"&shreg_n_in(80)&"0000";
--end if;
--end process;

process(clk)
begin
if rising_edge(clk) then
--    if shreg_tlast(82) = '1' then
----        axi_tdata_out_msg <= x"0000000000000000"&x"7200000000000000";
--        axi_tdata_out_msg <= x"0000000000000000"&n_bytes(7 downto 0)&n_bytes(15 downto 8)&x"000000000000";
--    else
        axi_tdata_out_msg <= data_to_fifo_uns((128*(4-cnt_valid_out)-1) downto (128*(3-cnt_valid_out))) xor Shift_reg_plaintext(81);
--    end if;
end if;
end process;


end Behavioral;