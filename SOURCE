module axi_peripheral_top #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer CLK_FREQ_HZ        = 100_000_000,
    parameter integer NUM_LEDS           = 8
) (
// Global signals
input  wire                                  S_AXI_ACLK,
input  wire                                  S_AXI_ARESETN,

// Write address channel
input  wire [C_S_AXI_ADDR_WIDTH-1:0]        S_AXI_AWADDR,
input  wire [2:0]                            S_AXI_AWPROT,
input  wire                                  S_AXI_AWVALID,
output wire                                  S_AXI_AWREADY,

// Write data channel
input  wire [C_S_AXI_DATA_WIDTH-1:0]        S_AXI_WDATA,
input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]    S_AXI_WSTRB,
input  wire                                  S_AXI_WVALID,
output wire                                  S_AXI_WREADY,

// Write response channel
output wire [1:0]                            S_AXI_BRESP,
output wire                                  S_AXI_BVALID,
input  wire                                  S_AXI_BREADY,

// Read address channel
input  wire [C_S_AXI_ADDR_WIDTH-1:0]        S_AXI_ARADDR,
input  wire [2:0]                            S_AXI_ARPROT,
input  wire                                  S_AXI_ARVALID,
output wire                                  S_AXI_ARREADY,

// Read data channel
output wire [C_S_AXI_DATA_WIDTH-1:0]        S_AXI_RDATA,
output wire [1:0]                            S_AXI_RRESP,
output wire                                  S_AXI_RVALID,
input  wire                                  S_AXI_RREADY,


// LED outputs
output wire [NUM_LEDS-1:0]                   leds,

// 7-segment display outputs
output wire [6:0]                            seg_cathode,
output wire [3:0]                            seg_anode,

// Interrupt output to PS
output wire                                  irq_out,

// External interrupt input (e.g., button)
input  wire                                  ext_irq_in
);

//==========================================================================
// Internal signals - AXI to Register Bank
wire                                 reg_write_en;
wire [C_S_AXI_ADDR_WIDTH-1:0]       reg_write_addr;
wire [C_S_AXI_DATA_WIDTH-1:0]       reg_write_data;
wire [(C_S_AXI_DATA_WIDTH/8)-1:0]   reg_write_strb;

wire                                 reg_read_en;
wire [C_S_AXI_ADDR_WIDTH-1:0]       reg_read_addr;
wire [C_S_AXI_DATA_WIDTH-1:0]       reg_read_data;
wire                                 reg_read_valid;

// Internal signals - Register Bank to Peripherals
wire [7:0]  led_control;
wire [15:0] seg_data;
wire        irq_from_regbank;
wire        ext_interrupt_clean;

// AXI4-Lite Interface Instance
axi_lite_if #(
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH)
) u_axi_lite_if (
    // Global signals
    .S_AXI_ACLK         (S_AXI_ACLK),
    .S_AXI_ARESETN      (S_AXI_ARESETN),
    
    // AXI4-Lite slave interface
    .S_AXI_AWADDR       (S_AXI_AWADDR),
    .S_AXI_AWPROT       (S_AXI_AWPROT),
    .S_AXI_AWVALID      (S_AXI_AWVALID),
    .S_AXI_AWREADY      (S_AXI_AWREADY),
    .S_AXI_WDATA        (S_AXI_WDATA),
    .S_AXI_WSTRB        (S_AXI_WSTRB),
    .S_AXI_WVALID       (S_AXI_WVALID),
    .S_AXI_WREADY       (S_AXI_WREADY),
    .S_AXI_BRESP        (S_AXI_BRESP),
    .S_AXI_BVALID       (S_AXI_BVALID),
    .S_AXI_BREADY       (S_AXI_BREADY),
    .S_AXI_ARADDR       (S_AXI_ARADDR),
    .S_AXI_ARPROT       (S_AXI_ARPROT),
    .S_AXI_ARVALID      (S_AXI_ARVALID),
    .S_AXI_ARREADY      (S_AXI_ARREADY),
    .S_AXI_RDATA        (S_AXI_RDATA),
    .S_AXI_RRESP        (S_AXI_RRESP),
    .S_AXI_RVALID       (S_AXI_RVALID),
    .S_AXI_RREADY       (S_AXI_RREADY),
    
    // Register interface
    .reg_write_en       (reg_write_en),
    .reg_write_addr     (reg_write_addr),
    .reg_write_data     (reg_write_data),
    .reg_write_strb     (reg_write_strb),
    .reg_read_en        (reg_read_en),
    .reg_read_addr      (reg_read_addr),
    .reg_read_data      (reg_read_data),
    .reg_read_valid     (reg_read_valid)
);

// Register Bank Instance
reg_bank #(
    .C_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) u_reg_bank (
    .clk            (S_AXI_ACLK),
    .resetn         (S_AXI_ARESETN),
    
    // Write interface
    .write_en       (reg_write_en),
    .write_addr     (reg_write_addr),
    .write_data     (reg_write_data),
    .write_strb     (reg_write_strb),
    
    // Read interface
    .read_en        (reg_read_en),
    .read_addr      (reg_read_addr),
    .read_data      (reg_read_data),
    .read_valid     (reg_read_valid),
    
    // Peripheral interfaces
    .led_control    (led_control),
    .seg_data       (seg_data),
    .ext_interrupt  (ext_interrupt_clean),
    .irq_out        (irq_from_regbank)
);

// LED Driver Instance
led_driver #(
    .NUM_LEDS       (NUM_LEDS),
    .ENABLE_PWM     (0),
    .PWM_RESOLUTION (8),
    .CLK_FREQ_HZ    (CLK_FREQ_HZ)
) u_led_driver (
    .clk            (S_AXI_ACLK),
    .resetn         (S_AXI_ARESETN),
    .led_control    (led_control),
    .pwm_duty       (8'd128),  // 50% duty cycle (unused in direct mode)
    .leds           (leds)
);

// Seven-Segment Multiplexer Instance
sevenseg_mux #(
    .CLK_FREQ_HZ      (CLK_FREQ_HZ),
    .REFRESH_RATE_HZ  (1000)
) u_sevenseg_mux (
    .clk              (S_AXI_ACLK),
    .resetn           (S_AXI_ARESETN),
    .seg_data         (seg_data),
    .seg_cathode      (seg_cathode),
    .seg_anode        (seg_anode)
);

// Interrupt Controller Instance
irq_ctrl #(
    .CLK_FREQ_HZ  (CLK_FREQ_HZ),
    .DEBOUNCE_MS  (1)  // 1ms for fast simulation
) u_irq_ctrl (
    .clk            (S_AXI_ACLK),
    .resetn         (S_AXI_ARESETN),
    .ext_irq_in     (ext_irq_in),
    .irq_pulse_out  (ext_interrupt_clean)
);

// Interrupt output assignment
assign irq_out = irq_from_regbank;

endmodule
