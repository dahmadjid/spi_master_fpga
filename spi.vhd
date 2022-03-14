library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Tested on FPGA
entity spi_master is
    generic (
        transaction_length : natural := 8 * 8);
    port (
        clock :in std_logic;
        clr : in std_logic;

        data_tx : in std_logic_vector(transaction_length - 1 downto 0);  -- data to be sent
        data_tx_rdy : in std_logic; -- data ready to be written from data_tx register and starts the transimision in the next clock cycle

        --data_reg : out std_logic_vector(transaction_length - 1 downto 0);

        data_rx : out std_logic_vector(transaction_length - 1 downto 0);  -- data recieved from slave
        data_rx_rdy : out std_logic; -- data ready to be read from data_rx register

        sck : out std_logic;
        mosi :out std_logic;
        miso :in std_logic;
        cs :out std_logic

  ) ;
end spi_master;

architecture arch of spi_master is
    signal clock_count: integer range 0 to 9;
    signal sck_s : std_logic := '0';
    signal data_rx_reg : std_logic_vector(transaction_length - 1 downto 0) := (others => '0');
    signal data_tx_reg : std_logic_vector(transaction_length - 1 downto 0) := (others => '0');
    signal bit_count : integer range 0 to transaction_length := 0;

    signal miso_busy : std_logic:='0';
    signal data_tx_rdy_s : std_logic;
    signal cs_s :std_logic := '1';

    
begin

    data_rx <= data_rx_reg;
    cs <= cs_s;
    sck <= sck_s;
    mosi <= data_tx(transaction_length - 1 - bit_count);

    --chip select 
    chip_select : process(data_tx_rdy,bit_count)
    begin
        if bit_count = transaction_length or clr = '0' then
            cs_s <= '1';

        elsif falling_edge(data_tx_rdy)  then
            cs_s <= '0';
            --data_tx_reg <= data_tx; -- x"31323334353637383930415A4552545955494F505153444647484A4B4C4D57584356424E617A6572747975696F707173646667686A6B6C6D77786376626E3F00";  -- "hello from fpga\0" --data_tx;
        end if;
    end process ; -- chip_select

    -- spiclk gen (divide by 10 to get 5mhz)
    spiclk_gen:process(clock,clr,cs_s)
    begin          
        if clr = '0' or cs_s = '1' then
            sck_s <= '0';
            clock_count <= 0;
        elsif rising_edge(clock) then 
            if clock_count = 4 then
                clock_count <= 0;
                sck_s <= not sck_s;
            else
                clock_count <= clock_count + 1; 
            end if;
        end if;
    end process;

    -- bit count 
    bit_count_pr : process(cs_s,sck_s,clr)
    begin
        if clr = '0' or cs_s = '1' then
            bit_count <= 0;
        elsif falling_edge(sck_s) then
            bit_count <= bit_count + 1;
        end if ;
    end process ; -- bit_count_pr

    -- miso 
    -- miso_pr : process(sck_s,clr)
    --     begin
    --         if clr = '0' then
    --             data_rx_reg <= (others => '0');
    --         elsif falling_edge(sck_s) and cs_s = '0' then
    --             data_rx_reg(0) <= miso;
    --             data_rx_reg(transaction_length - 1 downto 1) <= data_rx_reg(transaction_length - 2 downto 0);
    --             -- data_rx_reg(transaction_length - 1 - bit_count) <= miso;
    --         end if;
    -- end process ; -- miso_pr

    data_rx_rdy <= cs_s;


end arch ; -- arch

