--------------------------------------------------------------------------------
--  File:       panda_posenc_ctrl.vhd
--  Desc:       Position compare output pulse generator
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.type_defines.all;
use work.addr_defines.all;
use work.top_defines.all;
entity panda_posenc_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    INP       : out std_logic_vector(31 downto 0);
    INP_WSTB  : out std_logic;
    QPERIOD       : out std_logic_vector(31 downto 0);
    QPERIOD_WSTB  : out std_logic;
    ENABLE       : out std_logic_vector(31 downto 0);
    ENABLE_WSTB  : out std_logic;
    PROTOCOL       : out std_logic_vector(31 downto 0);
    PROTOCOL_WSTB  : out std_logic;
    QSTATE       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_posenc_ctrl;
architecture rtl of panda_posenc_ctrl is

signal mem_addr : natural range 0 to (2**mem_addr_i'length - 1);

begin

mem_addr <= to_integer(unsigned(mem_addr_i));

--
-- Control System Interface
--
REG_WRITE : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            INP <= (others => '0');
            INP_WSTB <= '0';
            QPERIOD <= (others => '0');
            QPERIOD_WSTB <= '0';
            ENABLE <= (others => '0');
            ENABLE_WSTB <= '0';
            PROTOCOL <= (others => '0');
            PROTOCOL_WSTB <= '0';
        else
            INP_WSTB <= '0';
            QPERIOD_WSTB <= '0';
            ENABLE_WSTB <= '0';
            PROTOCOL_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = POSENC_INP) then
                    INP <= mem_dat_i;
                    INP_WSTB <= '1';
                end if;
                if (mem_addr = POSENC_QPERIOD) then
                    QPERIOD <= mem_dat_i;
                    QPERIOD_WSTB <= '1';
                end if;
                if (mem_addr = POSENC_ENABLE) then
                    ENABLE <= mem_dat_i;
                    ENABLE_WSTB <= '1';
                end if;
                if (mem_addr = POSENC_PROTOCOL) then
                    PROTOCOL <= mem_dat_i;
                    PROTOCOL_WSTB <= '1';
                end if;

            end if;
        end if;
    end if;
end process;

--
-- Status Register Read
--
REG_READ : process(clk_i)
begin
    if rising_edge(clk_i) then
        if (reset_i = '1') then
            mem_dat_o <= (others => '0');
        else
            case (mem_addr) is
                when POSENC_QSTATE =>
                    mem_dat_o <= QSTATE;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;