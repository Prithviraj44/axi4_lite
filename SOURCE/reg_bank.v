module reg_bank #(
    parameter integer C_DATA_WIDTH = 32,
    parameter integer C_ADDR_WIDTH = 32
) (
// Clock and reset
input  wire                         clk,
input  wire                         resetn,

// Write interface from AXI
input  wire                         write_en,
input  wire [C_ADDR_WIDTH-1:0]     write_addr,
input  wire [C_DATA_WIDTH-1:0]     write_data,
input  wire [(C_DATA_WIDTH/8)-1:0] write_strb,

// Read interface to AXI
input  wire                         read_en,
input  wire [C_ADDR_WIDTH-1:0]     read_addr,
output wire [C_DATA_WIDTH-1:0]     read_data,
output wire                         read_valid,

// LED control output
output wire [7:0]                   led_control,

// 7-segment display output
output wire [15:0]                  seg_data,

// Interrupt control
input  wire                         ext_interrupt,
output wire                         irq_out
);

// Address map - Word aligned (byte address / 4)
localparam [C_ADDR_WIDTH-1:0] ADDR_LED_CTRL   = 32'h00000000;  // 0x00
localparam [C_ADDR_WIDTH-1:0] ADDR_SEG_DATA   = 32'h00000004;  // 0x04
localparam [C_ADDR_WIDTH-1:0] ADDR_IRQ_ENABLE = 32'h00000008;  // 0x08
localparam [C_ADDR_WIDTH-1:0] ADDR_IRQ_STATUS = 32'h0000000C;  // 0x0C
localparam [C_ADDR_WIDTH-1:0] ADDR_IRQ_CLEAR  = 32'h00000010;  // 0x10

// Internal registers
reg [7:0]  led_ctrl_reg;
reg [15:0] seg_data_reg;
reg        irq_enable_reg;
reg        irq_status_reg;
reg [C_DATA_WIDTH-1:0] read_data_reg;
reg read_valid_reg;

// Edge detection for external interrupt
reg ext_interrupt_d1;
reg ext_interrupt_d2;
wire ext_interrupt_posedge;

// Output assignments
assign led_control = led_ctrl_reg;
assign seg_data    = seg_data_reg;
assign read_data   = read_data_reg;
assign read_valid  = read_valid_reg;
assign irq_out     = irq_status_reg & irq_enable_reg;

// Edge detection for interrupt
assign ext_interrupt_posedge = ext_interrupt_d1 & ~ext_interrupt_d2;

always @(posedge clk) begin
    if (!resetn) begin
        ext_interrupt_d1 <= 1'b0;
        ext_interrupt_d2 <= 1'b0;
    end else begin
        ext_interrupt_d1 <= ext_interrupt;
        ext_interrupt_d2 <= ext_interrupt_d1;
    end
end

// Write logic with byte enables
always @(posedge clk) begin
    if (!resetn) begin
        led_ctrl_reg   <= 8'h00;
        seg_data_reg   <= 16'h0000;
        irq_enable_reg <= 1'b0;
    end else begin
        if (write_en) begin
            case (write_addr)
                ADDR_LED_CTRL: begin
                    if (write_strb[0]) led_ctrl_reg <= write_data[7:0];
                end
                
                ADDR_SEG_DATA: begin
                    if (write_strb[0]) seg_data_reg[7:0]  <= write_data[7:0];
                    if (write_strb[1]) seg_data_reg[15:8] <= write_data[15:8];
                end
                
                ADDR_IRQ_ENABLE: begin
                    if (write_strb[0]) irq_enable_reg <= write_data[0];
                end
                
                default: begin
                    // No operation for other addresses
                end
            endcase
        end else begin
            // Hold current values
        end
    end
end

// Interrupt status logic
always @(posedge clk) begin
    if (!resetn) begin
        irq_status_reg <= 1'b0;
    end else begin
        // Clear on write to IRQ_CLEAR with bit 0 set
        if (write_en && (write_addr == ADDR_IRQ_CLEAR) && write_strb[0] && write_data[0]) begin
            irq_status_reg <= 1'b0;
        // Set on external interrupt edge
        end else if (ext_interrupt_posedge) begin
            irq_status_reg <= 1'b1;
        end else begin
            // Hold current value
        end
    end
end

// Read logic
always @(posedge clk) begin
    if (!resetn) begin
        read_data_reg  <= {C_DATA_WIDTH{1'b0}};
        read_valid_reg <= 1'b0;
    end else begin
        if (read_en) begin
            read_valid_reg <= 1'b1;
            case (read_addr)
                ADDR_LED_CTRL: begin
                    read_data_reg <= {{(C_DATA_WIDTH-8){1'b0}}, led_ctrl_reg};
                end
                
                ADDR_SEG_DATA: begin
                    read_data_reg <= {{(C_DATA_WIDTH-16){1'b0}}, seg_data_reg};
                end
                
                ADDR_IRQ_ENABLE: begin
                    read_data_reg <= {{(C_DATA_WIDTH-1){1'b0}}, irq_enable_reg};
                end
                
                ADDR_IRQ_STATUS: begin
                    read_data_reg <= {{(C_DATA_WIDTH-1){1'b0}}, irq_status_reg};
                end
                
                default: begin
                    read_data_reg <= {C_DATA_WIDTH{1'b0}};
                end
            endcase
        end else begin
            read_valid_reg <= 1'b0;
            read_data_reg  <= read_data_reg;  // Hold
        end
    end
end

endmodule
