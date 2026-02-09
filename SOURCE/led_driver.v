module led_driver #(
    parameter integer NUM_LEDS = 8,
    parameter integer ENABLE_PWM = 0,           // 0=direct, 1=PWM
    parameter integer PWM_RESOLUTION = 8,       // bits
    parameter integer CLK_FREQ_HZ = 100_000_000 // 100 MHz
) (
// Clock and reset
input  wire                  clk,
input  wire                  resetn,

// LED control input
input  wire [NUM_LEDS-1:0]   led_control,

// PWM brightness control (0-255, only used if ENABLE_PWM=1)
input  wire [PWM_RESOLUTION-1:0] pwm_duty,

// Physical LED outputs
output wire [NUM_LEDS-1:0]   leds
);

// Generate PWM or direct output based on parameter
generate
    if (ENABLE_PWM == 1) begin : gen_pwm
        // PWM generation for brightness control
        localparam integer PWM_PERIOD = (1 << PWM_RESOLUTION) - 1;
        
        reg [PWM_RESOLUTION-1:0] pwm_counter;
        reg                       pwm_active;
        reg [NUM_LEDS-1:0]       leds_reg;
        
        // PWM counter
        always @(posedge clk) begin
            if (!resetn) begin
                pwm_counter <= {PWM_RESOLUTION{1'b0}};
            end else begin
                if (pwm_counter == PWM_PERIOD[PWM_RESOLUTION-1:0]) begin
                    pwm_counter <= {PWM_RESOLUTION{1'b0}};
                end else begin
                    pwm_counter <= pwm_counter + 1'b1;
                end
            end
        end
        
        // PWM comparator
        always @(posedge clk) begin
            if (!resetn) begin
                pwm_active <= 1'b0;
            end else begin
                pwm_active <= (pwm_counter < pwm_duty) ? 1'b1 : 1'b0;
            end
        end
        
        // Apply PWM to LEDs
        always @(posedge clk) begin
            if (!resetn) begin
                leds_reg <= {NUM_LEDS{1'b0}};
            end else begin
                leds_reg <= led_control & {NUM_LEDS{pwm_active}};
            end
        end
        
        assign leds = leds_reg;
        
    end else begin : gen_direct
        // Direct LED control (no PWM)
        reg [NUM_LEDS-1:0] leds_reg;
        
        always @(posedge clk) begin
            if (!resetn) begin
                leds_reg <= {NUM_LEDS{1'b0}};
            end else begin
                leds_reg <= led_control;
            end
        end
        
        assign leds = leds_reg;
    end
endgenerate

endmodule
