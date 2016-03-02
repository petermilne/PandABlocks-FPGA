--------------------------------------------------------------------------------
--  File:       panda_clocks_ctrl.vhd
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
entity panda_clocks_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    A_PERIOD       : out std_logic_vector(31 downto 0);
    A_PERIOD_WSTB  : out std_logic;
    B_PERIOD       : out std_logic_vector(31 downto 0);
    B_PERIOD_WSTB  : out std_logic;
    C_PERIOD       : out std_logic_vector(31 downto 0);
    C_PERIOD_WSTB  : out std_logic;
    D_PERIOD       : out std_logic_vector(31 downto 0);
    D_PERIOD_WSTB  : out std_logic;
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_clocks_ctrl;
architecture rtl of panda_clocks_ctrl is

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
            A_PERIOD <= (others => '0');
            A_PERIOD_WSTB <= '0';
            B_PERIOD <= (others => '0');
            B_PERIOD_WSTB <= '0';
            C_PERIOD <= (others => '0');
            C_PERIOD_WSTB <= '0';
            D_PERIOD <= (others => '0');
            D_PERIOD_WSTB <= '0';
        else
            A_PERIOD_WSTB <= '0';
            B_PERIOD_WSTB <= '0';
            C_PERIOD_WSTB <= '0';
            D_PERIOD_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = CLOCKS_A_PERIOD) then
                    A_PERIOD <= mem_dat_i;
                    A_PERIOD_WSTB <= '1';
                end if;
                if (mem_addr = CLOCKS_B_PERIOD) then
                    B_PERIOD <= mem_dat_i;
                    B_PERIOD_WSTB <= '1';
                end if;
                if (mem_addr = CLOCKS_C_PERIOD) then
                    C_PERIOD <= mem_dat_i;
                    C_PERIOD_WSTB <= '1';
                end if;
                if (mem_addr = CLOCKS_D_PERIOD) then
                    D_PERIOD <= mem_dat_i;
                    D_PERIOD_WSTB <= '1';
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
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;