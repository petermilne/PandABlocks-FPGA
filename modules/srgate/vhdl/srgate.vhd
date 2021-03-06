--------------------------------------------------------------------------------
--  File:       srgate.vhd
--  Desc:       SR Gate Generator.
--
--  Author:     Isa S. Uzun (isa.uzun@diamond.ac.uk)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity srgate is
port (
    -- Clock and Reset
    clk_i               : in  std_logic;
    -- Block Input and Outputs
    set_i               : in  std_logic;
    rst_i               : in  std_logic;
    out_o               : out std_logic;
    -- Block Parameters
    SET_EDGE            : in  std_logic;
    RST_EDGE            : in  std_logic;
    FORCE_SET           : in  std_logic;
    FORCE_RST           : in  std_logic
);
end srgate;

architecture rtl of srgate is

signal set_prev         : std_logic;
signal rst_prev         : std_logic;
signal set_rise         : std_logic;
signal rst_rise         : std_logic;
signal set_fall         : std_logic;
signal rst_fall         : std_logic;

signal set              : std_logic;
signal rst              : std_logic;
signal pulse            : std_logic := '0';

begin

-- Register inputs
process(clk_i)
begin
    if rising_edge(clk_i) then
        set_prev <= set_i;
        rst_prev <= rst_i;
    end if;
end process;

-- Detect rising and falling edge of set and reset inputs
set_rise  <= set_i and not set_prev;
rst_rise  <= rst_i and not rst_prev;
set_fall  <= not set_i and set_prev;
rst_fall  <= not rst_i and rst_prev;

set <= set_fall when (SET_EDGE = '0') else set_rise;
rst <= rst_fall when (RST_EDGE = '0') else rst_rise;

--
-- Special SRGate with support for forcing the output.
--
process(clk_i)
begin
    if rising_edge(clk_i) then
        -- Simple SRGate logic
        if (FORCE_RST = '1') then
            pulse <= '0';
        elsif (FORCE_SET = '1') then
            pulse <= '1';
        elsif (rst = '1') then
            pulse <= '0';
        elsif (set = '1') then
            pulse <= '1';
        end if;
    end if;
end process;

out_o <= pulse;

end rtl;
