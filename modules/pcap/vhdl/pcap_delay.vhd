--------------------------------------------------------------------------------
--  PandA Motion Project - 2016
--      Diamond Light Source, Oxford, UK
--      SOLEIL Synchrotron, GIF-sur-YVETTE, France
--
--  Author      : Dr. Isa Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------
--
--  Description : This module enables the ability to delay capture data by
--                passing whole System Bus and Position Bus through a delay line
--
--                This block is mapped on to REG address space (not PCAP)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.support.all;
use work.top_defines.all;
use work.addr_defines.all;

entity pcap_delay is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Inputs and Outputs
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t;
    sysbus_o            : out sysbus_t;
    posbus_o            : out posbus_t;
    -- Memory Bus Interface
    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0)
);
end pcap_delay;

architecture rtl of pcap_delay is

signal write_address : natural range 0 to (2**write_address_i'length - 1);

signal data_delay_array : std32_array(31 downto 0);
signal bit_delay_array  : std32_array(3 downto 0);

begin

write_address <= to_integer(unsigned(write_address_i));

--------------------------------------------------------------------------
-- Gather DELAY values for System Bus and Position Bus Fields
--------------------------------------------------------------------------
BIT_DELAY_WRITE : process(clk_i) begin

if rising_edge(clk_i) then
    if (reset_i = '1') then
        bit_delay_array <= (others => (others => '0'));
    else
        FOR I IN REG_PCAP_BIT_DELAY_0 to REG_PCAP_BIT_DELAY_3 LOOP
            if (write_strobe_i = '1') then
                -- Input Select Control Registers
                if (write_address = I) then
                    bit_delay_array(I-REG_PCAP_BIT_DELAY_0) <= write_data_i;
                end if;
            end if;
        END LOOP;
    end if;
end if;

end process;

DATA_DELAY_WRITE : process(clk_i) begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            data_delay_array <= (others => (others => '0'));
        else
            FOR I IN REG_PCAP_DATA_DELAY_0 to REG_PCAP_DATA_DELAY_31 LOOP
                if (write_strobe_i = '1') then
                    -- Input Select Control Registers
                    if (write_address = I) then
                        data_delay_array(I-REG_PCAP_DATA_DELAY_0) <= write_data_i;
                    end if;
                end if;
            END LOOP;
        end if;
    end if;
end process;

--------------------------------------------------------------------------
-- Apply Delays To System Bus,
--------------------------------------------------------------------------
BIT_DELAY_GEN : FOR I IN 0 TO 3 GENERATE

    bit_delay_inst : entity work.delay_line
    port map (
        clk_i       => clk_i,
        data_i      => sysbus_i(32*I+31 downto 32*I),
        data_o      => sysbus_o(32*I+31 downto 32*I),
        DELAY       => bit_delay_array(I)(4 downto 0)
    );

END GENERATE;

--------------------------------------------------------------------------
-- Apply Delays To Position Fields, including extended bus
--------------------------------------------------------------------------
POS_DELAY_GEN : FOR I IN 0 TO 31 GENERATE

    data_delay_inst : entity work.delay_line
    port map (
        clk_i       => clk_i,
        data_i      => posbus_i(I),
        data_o      => posbus_o(I),
        DELAY       => data_delay_array(I)(4 downto 0)
    );

END GENERATE;

end rtl;
