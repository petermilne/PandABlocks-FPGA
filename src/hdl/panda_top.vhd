--------------------------------------------------------------------------------
--  File:       panda_top.vhd
--  Desc:       PandA top-level design
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library work;
use work.top_defines.all;
use work.type_defines.all;
use work.addr_defines.all;

entity panda_top is
port (
    DDR_addr            : inout std_logic_vector (14 downto 0);
    DDR_ba              : inout std_logic_vector (2 downto 0);
    DDR_cas_n           : inout std_logic;
    DDR_ck_n            : inout std_logic;
    DDR_ck_p            : inout std_logic;
    DDR_cke             : inout std_logic;
    DDR_cs_n            : inout std_logic;
    DDR_dm              : inout std_logic_vector (3 downto 0);
    DDR_dq              : inout std_logic_vector (31 downto 0);
    DDR_dqs_n           : inout std_logic_vector (3 downto 0);
    DDR_dqs_p           : inout std_logic_vector (3 downto 0);
    DDR_odt             : inout std_logic;
    DDR_ras_n           : inout std_logic;
    DDR_reset_n         : inout std_logic;
    DDR_we_n            : inout std_logic;
    FIXED_IO_ddr_vrn    : inout std_logic;
    FIXED_IO_ddr_vrp    : inout std_logic;
    FIXED_IO_mio        : inout std_logic_vector (53 downto 0);
    FIXED_IO_ps_clk     : inout std_logic;
    FIXED_IO_ps_porb    : inout std_logic;
    FIXED_IO_ps_srstb   : inout std_logic;

    -- RS485 Channel 0 Encoder I/O
    Am0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zm0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    As0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Bs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    Zs0_pad_io          : inout std_logic_vector(ENC_NUM-1 downto 0);
    enc0_ctrl_pad_i     : in    std_logic_vector(3  downto 0);
    enc0_ctrl_pad_o     : out   std_logic_vector(11 downto 0);

    -- Discrete I/O
    ttlin_pad_i         : in    std_logic_vector(TTLIN_NUM-1 downto 0);
    ttlout_pad_o        : out   std_logic_vector(TTLOUT_NUM-1 downto 0);
    lvdsin_pad_i        : in    std_logic_vector(LVDSIN_NUM-1 downto 0);
    lvdsout_pad_o       : out   std_logic_vector(LVDSOUT_NUM-1 downto 0);

    -- Status I/O
    leds                : out   std_logic_vector(1 downto 0)
);
end panda_top;

architecture rtl of panda_top is

component ila_0
port (
    clk             : in  std_logic;
    probe0          : in  std_logic_vector(63 downto 0)
);
end component;

-- Signal declarations
signal FCLK_CLK0            : std_logic;
signal FCLK_RESET0_N        : std_logic_vector(0 downto 0);
signal FCLK_RESET0          : std_logic;
signal FCLK_LEDS            : std_logic_vector(31 downto 0);

signal M00_AXI_awaddr       : std_logic_vector ( 31 downto 0 );
signal M00_AXI_awprot       : std_logic_vector ( 2 downto 0 );
signal M00_AXI_awvalid      : std_logic;
signal M00_AXI_awready      : std_logic;
signal M00_AXI_wdata        : std_logic_vector ( 31 downto 0 );
signal M00_AXI_wstrb        : std_logic_vector ( 3 downto 0 );
signal M00_AXI_wvalid       : std_logic;
signal M00_AXI_wready       : std_logic;
signal M00_AXI_bresp        : std_logic_vector ( 1 downto 0 );
signal M00_AXI_bvalid       : std_logic;
signal M00_AXI_bready       : std_logic;
signal M00_AXI_araddr       : std_logic_vector ( 31 downto 0 );
signal M00_AXI_arprot       : std_logic_vector ( 2 downto 0 );
signal M00_AXI_arvalid      : std_logic;
signal M00_AXI_arready      : std_logic;
signal M00_AXI_rdata        : std_logic_vector ( 31 downto 0 );
signal M00_AXI_rresp        : std_logic_vector ( 1 downto 0 );
signal M00_AXI_rvalid       : std_logic;
signal M00_AXI_rready       : std_logic;

signal mem_cs               : std_logic_vector(2**PAGE_NUM-1 downto 0);
signal mem_addr             : std_logic_vector(PAGE_AW-1 downto 0);
signal mem_odat             : std_logic_vector(31 downto 0);
signal mem_wstb             : std_logic;
signal mem_rstb             : std_logic;
signal mem_read_data        : std32_array(2**PAGE_NUM-1 downto 0) :=
                                (others => (others => '0'));

signal IRQ_F2P              : std_logic_vector(0 downto 0);

signal probe0               : std_logic_vector(63 downto 0);

signal encin_buf_ctrl       : std_logic_vector(5 downto 0);
signal outenc_buf_ctrl      : std_logic_vector(5 downto 0);
signal enc0_ctrl_opad       : std_logic_vector(11 downto 0);

signal As0_ipad, As0_opad   : std_logic;
signal Bs0_ipad, Bs0_opad   : std_logic;
signal Zs0_ipad, Zs0_opad   : std_logic;

signal A_o, B_o, Z_o        : std_logic;
signal mclk_o               : std_logic;
signal mdat_i               : std_logic;
signal sclk_i               : std_logic;
signal sdat_o               : std_logic;
signal encin_mode           : std_logic_vector(2 downto 0);
signal outenc_mode          : std_logic_vector(2 downto 0);
signal endat_mdir           : std_logic;
signal endat_sdir           : std_logic;

signal soft_input           : std_logic_vector(3 downto 0)  := "0000";
signal soft_posn            : std_logic_vector(31 downto 0) := (others =>'0');

-- Design Level Busses :
signal sysbus               : sysbus_t := (others => '0');
signal posbus               : posbus_t := (others => (others => '0'));
-- Position Block Outputs :
signal encin_posn           : std32_array(ENC_NUM-1 downto 0);

-- Discrete Block Outputs :
signal ttlin_val            : std_logic_vector(TTLIN_NUM-1 downto 0);
signal lvdsin_val           : std_logic_vector(LVDSIN_NUM-1 downto 0);
signal lut_val              : std_logic_vector(LUT_NUM-1 downto 0);
signal srgate_val           : std_logic_vector(SRGATE_NUM-1 downto 0);
signal div_val              : std_logic_vector(2*DIV_NUM-1 downto 0);
signal pulse_val            : std_logic_vector(2*PULSE_NUM-1 downto 0);
signal seq_val              : seq_out_array(SEQ_NUM-1 downto 0);
signal seq_active           : std_logic_vector(SEQ_NUM-1 downto 0);

signal pcomp_act            : std_logic_vector(PCOMP_NUM-1 downto 0);
signal pcomp_pulse          : std_logic_vector(PCOMP_NUM-1 downto 0);

signal panda_spbram_wea     : std_logic := '0';
signal irq_enable           : std_logic := '0';

begin

-- Physical diagnostics outputs
leds <= FCLK_LEDS(26 downto 25);

-- Internal clocks and resets
FCLK_RESET0 <= not FCLK_RESET0_N(0);

--
-- Panda Processor System Block design instantiation
--
ps : entity work.panda_ps
port map (
    FCLK_CLK0                   => FCLK_CLK0,
    FCLK_RESET0_N               => FCLK_RESET0_N,
    FCLK_LEDS                   => FCLK_LEDS,

    DDR_addr(14 downto 0)       => DDR_addr(14 downto 0),
    DDR_ba(2 downto 0)          => DDR_ba(2 downto 0),
    DDR_cas_n                   => DDR_cas_n,
    DDR_ck_n                    => DDR_ck_n,
    DDR_ck_p                    => DDR_ck_p,
    DDR_cke                     => DDR_cke,
    DDR_cs_n                    => DDR_cs_n,
    DDR_dm(3 downto 0)          => DDR_dm(3 downto 0),
    DDR_dq(31 downto 0)         => DDR_dq(31 downto 0),
    DDR_dqs_n(3 downto 0)       => DDR_dqs_n(3 downto 0),
    DDR_dqs_p(3 downto 0)       => DDR_dqs_p(3 downto 0),
    DDR_odt                     => DDR_odt,
    DDR_ras_n                   => DDR_ras_n,
    DDR_reset_n                 => DDR_reset_n,
    DDR_we_n                    => DDR_we_n,

    FIXED_IO_ddr_vrn            => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp            => FIXED_IO_ddr_vrp,
    FIXED_IO_mio(53 downto 0)   => FIXED_IO_mio(53 downto 0),
    FIXED_IO_ps_clk             => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb            => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb           => FIXED_IO_ps_srstb,
    IRQ_F2P                     => IRQ_F2P,

    M00_AXI_araddr(31 downto 0) => M00_AXI_araddr(31 downto 0),
    M00_AXI_arprot(2 downto 0)  => M00_AXI_arprot(2 downto 0),
    M00_AXI_arready             => M00_AXI_arready,
    M00_AXI_arvalid             => M00_AXI_arvalid,
    M00_AXI_awaddr(31 downto 0) => M00_AXI_awaddr(31 downto 0),
    M00_AXI_awprot(2 downto 0)  => M00_AXI_awprot(2 downto 0),
    M00_AXI_awready             => M00_AXI_awready,
    M00_AXI_awvalid             => M00_AXI_awvalid,
    M00_AXI_bready              => M00_AXI_bready,
    M00_AXI_bresp(1 downto 0)   => M00_AXI_bresp(1 downto 0),
    M00_AXI_bvalid              => M00_AXI_bvalid,
    M00_AXI_rdata(31 downto 0)  => M00_AXI_rdata(31 downto 0),
    M00_AXI_rready              => M00_AXI_rready,
    M00_AXI_rresp(1 downto 0)   => M00_AXI_rresp(1 downto 0),
    M00_AXI_rvalid              => M00_AXI_rvalid,
    M00_AXI_wdata(31 downto 0)  => M00_AXI_wdata(31 downto 0),
    M00_AXI_wready              => M00_AXI_wready,
    M00_AXI_wstrb(3 downto 0)   => M00_AXI_wstrb(3 downto 0),
    M00_AXI_wvalid              => M00_AXI_wvalid,
    S_AXI_HP0_araddr            => (others => '0'),
    S_AXI_HP0_arburst           => (others => '0'),
    S_AXI_HP0_arcache           => (others => '0'),
    S_AXI_HP0_arid              => (others => '0'),
    S_AXI_HP0_arlen             => (others => '0'),
    S_AXI_HP0_arlock            => (others => '0'),
    S_AXI_HP0_arprot            => (others => '0'),
    S_AXI_HP0_arqos             => (others => '0'),
    S_AXI_HP0_arready           => open,
    S_AXI_HP0_arsize            => (others => '0'),
    S_AXI_HP0_arvalid           => '0',
    S_AXI_HP0_awaddr            => (others => '0'),
    S_AXI_HP0_awburst           => (others => '0'),
    S_AXI_HP0_awcache           => (others => '0'),
    S_AXI_HP0_awid              => (others => '0'),
    S_AXI_HP0_awlen             => (others => '0'),
    S_AXI_HP0_awlock            => (others => '0'),
    S_AXI_HP0_awprot            => (others => '0'),
    S_AXI_HP0_awqos             => (others => '0'),
    S_AXI_HP0_awready           => open,
    S_AXI_HP0_awsize            => (others => '0'), 
    S_AXI_HP0_awvalid           => '0',
    S_AXI_HP0_bid               => open,
    S_AXI_HP0_bready            => '0',
    S_AXI_HP0_bresp             => open,
    S_AXI_HP0_bvalid            => open,
    S_AXI_HP0_rdata             => open,
    S_AXI_HP0_rid               => open,
    S_AXI_HP0_rlast             => open,
    S_AXI_HP0_rready            => '0', 
    S_AXI_HP0_rresp             => open,
    S_AXI_HP0_rvalid            => open,
    S_AXI_HP0_wdata             => (others => '0'),
    S_AXI_HP0_wid               => (others => '0'),
    S_AXI_HP0_wlast             => '0',
    S_AXI_HP0_wready            => open,
    S_AXI_HP0_wstrb             => (others => '0'),
    S_AXI_HP0_wvalid            => '0'
);

--
-- Control and Status Memory Interface
--
-- 0x43c00000
panda_csr_if_inst : entity work.panda_csr_if
generic map (
    MEM_CSWIDTH                 => PAGE_NUM,
    MEM_AWIDTH                  => PAGE_AW
)
port map (
    S_AXI_CLK                   => FCLK_CLK0,
    S_AXI_RST                   => FCLK_RESET0,
    S_AXI_AWADDR                => M00_AXI_awaddr,
--    S_AXI_AWPROT                => M00_AXI_awprot,
    S_AXI_AWVALID               => M00_AXI_awvalid,
    S_AXI_AWREADY               => M00_AXI_awready,
    S_AXI_WDATA                 => M00_AXI_wdata,
    S_AXI_WSTRB                 => M00_AXI_wstrb,
    S_AXI_WVALID                => M00_AXI_wvalid,
    S_AXI_WREADY                => M00_AXI_wready,
    S_AXI_BRESP                 => M00_AXI_bresp,
    S_AXI_BVALID                => M00_AXI_bvalid,
    S_AXI_BREADY                => M00_AXI_bready,
    S_AXI_ARADDR                => M00_AXI_araddr,
--    S_AXI_ARPROT                => M00_AXI_arprot,
    S_AXI_ARVALID               => M00_AXI_arvalid,
    S_AXI_ARREADY               => M00_AXI_arready,
    S_AXI_RDATA                 => M00_AXI_rdata,
    S_AXI_RRESP                 => M00_AXI_rresp,
    S_AXI_RVALID                => M00_AXI_rvalid,
    S_AXI_RREADY                => M00_AXI_rready,
    -- Bus Memory Interface
    mem_addr_o                  => mem_addr,
    mem_dat_i                   => mem_read_data,
    mem_dat_o                   => mem_odat,
    mem_cs_o                    => mem_cs,
    mem_rstb_o                  => mem_rstb,
    mem_wstb_o                  => mem_wstb
);

--
-- TTL
--
panda_ttl_inst : entity work.panda_ttl_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(TTL_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,

    sysbus_i            => sysbus,

    pad_i               => ttlin_pad_i,
    val_o               => ttlin_val,
    pad_o               => ttlout_pad_o
);

--
-- LVDS
--
panda_lvds_inst : entity work.panda_lvds_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(LVDS_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,

    sysbus_i            => sysbus,

    pad_i               => lvdsin_pad_i,
    val_o               => lvdsin_val,
    pad_o               => lvdsout_pad_o
);

--
-- 5-Input LUT
--
panda_lut_inst : entity work.panda_lut_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(LUT_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,

    sysbus_i            => sysbus,

    out_o               => lut_val
);

--
-- 5-Input LUT
--
panda_srgate_inst : entity work.panda_srgate_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(SRGATE_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,

    sysbus_i            => sysbus,

    out_o               => srgate_val
);

--
-- DIVIDER
--
panda_div_inst : entity work.panda_div_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(DIV_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(DIV_CS),

    sysbus_i            => sysbus,

    outd_o              => div_val(3 downto 0),
    outn_o              => div_val(7 downto 4)
);

--
-- PULSE GENERATOR
--
panda_pulse_inst : entity work.panda_pulse_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(PULSE_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(PULSE_CS),

    sysbus_i            => sysbus,

    out_o               => pulse_val(3 downto 0),
    perr_o              => pulse_val(7 downto 4)
);

--
-- SEQEUENCER
--
panda_seq_inst : entity work.panda_sequencer_top
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(SEQ_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(SEQ_CS),

    sysbus_i            => sysbus,

    out_o               => seq_val,
    active_o            => seq_active
);

--
-- STATUS
--
panda_status_inst : entity work.panda_status
port map (
    clk_i               => FCLK_CLK0,
    reset_i             => FCLK_RESET0,

    mem_addr_i          => mem_addr,
    mem_cs_i            => mem_cs(STA_CS),
    mem_wstb_i          => mem_wstb,
    mem_rstb_i          => mem_rstb,
    mem_dat_i           => mem_odat,
    mem_dat_o           => mem_read_data(STA_CS),

    sysbus_i            => sysbus
);


--
-- System Bus   : Assignments
--
sysbus <= '0'                   &
          FCLK_RESET0           &
          ZEROS(SBUS_AVAIL-2)   &
          seq_active            &
          seq_val(3)            &
          seq_val(2)            &
          seq_val(1)            &
          seq_val(0)            &
          pulse_val             &
          div_val               &
          srgate_val            &   --  15: 8
          lut_val               &   --  15: 8
          lvdsin_val            &   --   7: 6
          ttlin_val;                --   5: 0

end rtl;
