module irq_ctrl #(
    parameter integer CLK_FREQ_HZ = 100_000_000,  // 100 MHz
    parameter integer DEBOUNCE_MS = 1              // 1ms debounce for simulation
) (
// Clock and reset
input  wire  clk,
input  wire  resetn,

// External interrupt source (e.g., button)
input  wire  ext_irq_in,

// Interrupt output (clean, debounced edge)
output wire  irq_pulse_out
);

// Local parameters
localparam integer DEBOUNCE_COUNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
localparam integer COUNTER_WIDTH = $clog2(DEBOUNCE_COUNT + 1);

// Internal signals
reg [COUNTER_WIDTH-1:0] debounce_counter;
reg                      ext_irq_sync_1;
reg                      ext_irq_sync_2;
reg                      ext_irq_stable;
reg                      ext_irq_d1;
wire                     ext_irq_posedge;
reg                      irq_pulse_reg;

// Output assignment
assign irq_pulse_out = irq_pulse_reg;

// Two-stage synchronizer for async input
always @(posedge clk) begin
    if (!resetn) begin
        ext_irq_sync_1 <= 1'b0;
        ext_irq_sync_2 <= 1'b0;
    end else begin
        ext_irq_sync_1 <= ext_irq_in;
        ext_irq_sync_2 <= ext_irq_sync_1;
    end
end

// Debounce logic
always @(posedge clk) begin
    if (!resetn) begin
        debounce_counter <= {COUNTER_WIDTH{1'b0}};
        ext_irq_stable   <= 1'b0;
    end else begin
        if (ext_irq_sync_2 != ext_irq_stable) begin
            // Input changed, start/restart counter
            if (debounce_counter == DEBOUNCE_COUNT[COUNTER_WIDTH-1:0]) begin
                // Counter expired, accept new value
                ext_irq_stable   <= ext_irq_sync_2;
                debounce_counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                debounce_counter <= debounce_counter + 1'b1;
            end
        end else begin
            debounce_counter <= {COUNTER_WIDTH{1'b0}};
        end
    end
end

// Edge detection on stable signal
always @(posedge clk) begin
    if (!resetn) begin
        ext_irq_d1 <= 1'b0;
    end else begin
        ext_irq_d1 <= ext_irq_stable;
    end
end

assign ext_irq_posedge = ext_irq_stable & ~ext_irq_d1;

// Generate single-cycle pulse on positive edge
always @(posedge clk) begin
    if (!resetn) begin
        irq_pulse_reg <= 1'b0;
    end else begin
        irq_pulse_reg <= ext_irq_posedge;
    end
end

endmodule
