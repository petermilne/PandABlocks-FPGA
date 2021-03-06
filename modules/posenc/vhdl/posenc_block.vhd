library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;

entity posenc_block is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Memory Bus Interface
    read_strobe_i       : in  std_logic;
    read_address_i      : in  std_logic_vector(BLK_AW-1 downto 0);
    read_data_o         : out std_logic_vector(31 downto 0);
    read_ack_o          : out std_logic;

    write_strobe_i      : in  std_logic;
    write_address_i     : in  std_logic_vector(BLK_AW-1 downto 0);
    write_data_i        : in  std_logic_vector(31 downto 0);
    write_ack_o         : out std_logic;
    -- Encoder I/O Pads
    a_o                 : out std_logic;
    b_o                 : out std_logic;
    -- Position Field interface
    sysbus_i            : in  sysbus_t;
    posbus_i            : in  posbus_t
);
end entity;

architecture rtl of posenc_block is

-- Block Configuration Registers
signal PROTOCOL         : std_logic_vector(31 downto 0);
signal QPERIOD          : std_logic_vector(31 downto 0);
signal QPERIOD_WSTB     : std_logic;
signal QSTATE           : std_logic_vector(31 downto 0);

signal enable           : std_logic;
signal posn             : std_logic_vector(31 downto 0);

begin

--
-- Control System Interface
--
posenc_ctrl : entity work.posenc_ctrl
port map (
    clk_i               => clk_i,
    reset_i             => reset_i,
    sysbus_i            => sysbus_i,
    posbus_i            => posbus_i,
    enable_o            => enable,
    inp_o               => posn,

    read_strobe_i       => read_strobe_i,
    read_address_i      => read_address_i,
    read_data_o         => read_data_o,
    read_ack_o          => read_ack_o,

    write_strobe_i      => write_strobe_i,
    write_address_i     => write_address_i,
    write_data_i        => write_data_i,
    write_ack_o         => write_ack_o,

    -- Block Parameters
    PROTOCOL            => PROTOCOL,
    PROTOCOL_WSTB       => open,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    QSTATE              => QSTATE
);

--
-- Core instantiation
--
posenc_inst : entity work.posenc
port map (
    -- Clock and Reset
    clk_i               => clk_i,
    reset_i             => reset_i,
    --
    posn_i              => posn,
    enable_i            => enable,
    a_o                 => a_o,
    b_o                 => b_o,
    -- Block Parameters
    PROTOCOL            => PROTOCOL,
    QPERIOD             => QPERIOD,
    QPERIOD_WSTB        => QPERIOD_WSTB,
    QSTATE              => QSTATE
);

end rtl;

