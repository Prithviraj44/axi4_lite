module sevenseg_mux #(
    parameter integer CLK_FREQ_HZ = 100_000_000,  // 100 MHz
    parameter integer REFRESH_RATE_HZ = 1000       // 1 kHz per digit
) (
// Clock and reset
input  wire        clk,
input  wire        resetn,

// 16-bit input data (4 hex digits)
input  wire [15:0] seg_data,

// 7-segment outputs (active low for common anode)
output wire [6:0]  seg_cathode,  // {g,f,e,d,c,b,a}

// Digit select outputs (active low for common anode)
output wire [3:0]  seg_anode     // {dig3,dig2,dig1,dig0}
);

// Local parameters
localparam integer COUNTER_MAX = CLK_FREQ_HZ / (REFRESH_RATE_HZ * 4) - 1;
localparam integer COUNTER_WIDTH = $clog2(COUNTER_MAX + 1);

// Internal signals
reg [COUNTER_WIDTH-1:0] counter_reg;
reg [1:0]               digit_sel_reg;
reg [3:0]               current_digit;
reg [6:0]               seg_cathode_reg;
reg [3:0]               seg_anode_reg;

// Output assignments
assign seg_cathode = seg_cathode_reg;
assign seg_anode   = seg_anode_reg;

// Counter for digit refresh
always @(posedge clk) begin
    if (!resetn) begin
        counter_reg   <= {COUNTER_WIDTH{1'b0}};
        digit_sel_reg <= 2'b00;
    end else begin
        if (counter_reg == COUNTER_MAX[COUNTER_WIDTH-1:0]) begin
            counter_reg   <= {COUNTER_WIDTH{1'b0}};
            digit_sel_reg <= digit_sel_reg + 2'b01;
        end else begin
            counter_reg   <= counter_reg + 1'b1;
            digit_sel_reg <= digit_sel_reg;
        end
    end
end

// Digit selection multiplexer
always @(*) begin
    case (digit_sel_reg)
        2'b00: current_digit = seg_data[3:0];
        2'b01: current_digit = seg_data[7:4];
        2'b10: current_digit = seg_data[11:8];
        2'b11: current_digit = seg_data[15:12];
        default: current_digit = 4'h0;
    endcase
end

// 7-segment decoder (hex to 7-segment)
// Active low outputs 

always @(*) begin
    case (current_digit)
        4'h0: seg_cathode_reg = 7'b1000000;  // 0
        4'h1: seg_cathode_reg = 7'b1111001;  // 1
        4'h2: seg_cathode_reg = 7'b0100100;  // 2
        4'h3: seg_cathode_reg = 7'b0110000;  // 3
        4'h4: seg_cathode_reg = 7'b0011001;  // 4
        4'h5: seg_cathode_reg = 7'b0010010;  // 5
        4'h6: seg_cathode_reg = 7'b0000010;  // 6
        4'h7: seg_cathode_reg = 7'b1111000;  // 7
        4'h8: seg_cathode_reg = 7'b0000000;  // 8
        4'h9: seg_cathode_reg = 7'b0010000;  // 9
        4'hA: seg_cathode_reg = 7'b0001000;  // A
        4'hB: seg_cathode_reg = 7'b0000011;  // b
        4'hC: seg_cathode_reg = 7'b1000110;  // C
        4'hD: seg_cathode_reg = 7'b0100001;  // d
        4'hE: seg_cathode_reg = 7'b0000110;  // E
        4'hF: seg_cathode_reg = 7'b0001110;  // F
        default: seg_cathode_reg = 7'b1111111;  // blank
    endcase
end

// Anode control (active low - only one digit on at a time)
always @(*) begin
    case (digit_sel_reg)
        2'b00: seg_anode_reg = 4'b1110;  // Digit 0 active
        2'b01: seg_anode_reg = 4'b1101;  // Digit 1 active
        2'b10: seg_anode_reg = 4'b1011;  // Digit 2 active
        2'b11: seg_anode_reg = 4'b0111;  // Digit 3 active
        default: seg_anode_reg = 4'b1111;  // All off
    endcase
end

endmodule
