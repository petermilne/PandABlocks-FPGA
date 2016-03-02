--------------------------------------------------------------------------------
--  File:       panda_inenc_ctrl.vhd
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
entity panda_inenc_ctrl is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    reset_i             : in  std_logic;
    -- Block Parameters
    PROTOCOL       : out std_logic_vector(31 downto 0);
    PROTOCOL_WSTB  : out std_logic;
    CLK_PERIOD       : out std_logic_vector(31 downto 0);
    CLK_PERIOD_WSTB  : out std_logic;
    FRAME_PERIOD       : out std_logic_vector(31 downto 0);
    FRAME_PERIOD_WSTB  : out std_logic;
    BITS       : out std_logic_vector(31 downto 0);
    BITS_WSTB  : out std_logic;
    SETP       : out std_logic_vector(31 downto 0);
    SETP_WSTB  : out std_logic;
    RST_ON_Z       : out std_logic_vector(31 downto 0);
    RST_ON_Z_WSTB  : out std_logic;
    EXTENSION       : in  std_logic_vector(31 downto 0);
    ERR_FRAME       : in  std_logic_vector(31 downto 0);
    ERR_RESPONSE       : in  std_logic_vector(31 downto 0);
    ENC_STATUS       : in  std_logic_vector(31 downto 0);
    -- Memory Bus Interface
    mem_cs_i            : in  std_logic;
    mem_wstb_i          : in  std_logic;
    mem_addr_i          : in  std_logic_vector(BLK_AW-1 downto 0);
    mem_dat_i           : in  std_logic_vector(31 downto 0);
    mem_dat_o           : out std_logic_vector(31 downto 0)
);
end panda_inenc_ctrl;
architecture rtl of panda_inenc_ctrl is

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
            PROTOCOL <= (others => '0');
            PROTOCOL_WSTB <= '0';
            CLK_PERIOD <= (others => '0');
            CLK_PERIOD_WSTB <= '0';
            FRAME_PERIOD <= (others => '0');
            FRAME_PERIOD_WSTB <= '0';
            BITS <= (others => '0');
            BITS_WSTB <= '0';
            SETP <= (others => '0');
            SETP_WSTB <= '0';
            RST_ON_Z <= (others => '0');
            RST_ON_Z_WSTB <= '0';
        else
            PROTOCOL_WSTB <= '0';
            CLK_PERIOD_WSTB <= '0';
            FRAME_PERIOD_WSTB <= '0';
            BITS_WSTB <= '0';
            SETP_WSTB <= '0';
            RST_ON_Z_WSTB <= '0';

            if (mem_cs_i = '1' and mem_wstb_i = '1') then
                -- Input Select Control Registers
                if (mem_addr = INENC_PROTOCOL) then
                    PROTOCOL <= mem_dat_i;
                    PROTOCOL_WSTB <= '1';
                end if;
                if (mem_addr = INENC_CLK_PERIOD) then
                    CLK_PERIOD <= mem_dat_i;
                    CLK_PERIOD_WSTB <= '1';
                end if;
                if (mem_addr = INENC_FRAME_PERIOD) then
                    FRAME_PERIOD <= mem_dat_i;
                    FRAME_PERIOD_WSTB <= '1';
                end if;
                if (mem_addr = INENC_BITS) then
                    BITS <= mem_dat_i;
                    BITS_WSTB <= '1';
                end if;
                if (mem_addr = INENC_SETP) then
                    SETP <= mem_dat_i;
                    SETP_WSTB <= '1';
                end if;
                if (mem_addr = INENC_RST_ON_Z) then
                    RST_ON_Z <= mem_dat_i;
                    RST_ON_Z_WSTB <= '1';
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
                when INENC_EXTENSION =>
                    mem_dat_o <= EXTENSION;
                when INENC_ERR_FRAME =>
                    mem_dat_o <= ERR_FRAME;
                when INENC_ERR_RESPONSE =>
                    mem_dat_o <= ERR_RESPONSE;
                when INENC_ENC_STATUS =>
                    mem_dat_o <= ENC_STATUS;
                when others =>
                    mem_dat_o <= (others => '0');
            end case;
        end if;
    end if;
end process;

end rtl;