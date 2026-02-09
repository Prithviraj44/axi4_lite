module axi_lite_if #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer C_S_AXI_DATA_WIDTH = 32
) (
// Global signals
input  wire                                S_AXI_ACLK,
input  wire                                S_AXI_ARESETN,
// Write address channel
input  wire [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_AWADDR,
input  wire [2:0]                          S_AXI_AWPROT,
input  wire                                S_AXI_AWVALID,
output wire                                S_AXI_AWREADY,
// Write data channel
input  wire [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_WDATA,
input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  S_AXI_WSTRB,
input  wire                                S_AXI_WVALID,
output wire                                S_AXI_WREADY,
// Write response channel
output wire [1:0]                          S_AXI_BRESP,
output wire                                S_AXI_BVALID,
input  wire                                S_AXI_BREADY,
// Read address channel
input  wire [C_S_AXI_ADDR_WIDTH-1:0]      S_AXI_ARADDR,
input  wire [2:0]                          S_AXI_ARPROT,
input  wire                                S_AXI_ARVALID,
output wire                                S_AXI_ARREADY,
// Read data channel
output wire [C_S_AXI_DATA_WIDTH-1:0]      S_AXI_RDATA,
output wire [1:0]                          S_AXI_RRESP,
output wire                                S_AXI_RVALID,
input  wire                                S_AXI_RREADY,
// Register interface to reg_bank
output wire                                reg_write_en,
output wire [C_S_AXI_ADDR_WIDTH-1:0]      reg_write_addr,
output wire [C_S_AXI_DATA_WIDTH-1:0]      reg_write_data,
output wire [(C_S_AXI_DATA_WIDTH/8)-1:0]  reg_write_strb,

output wire                                reg_read_en,
output wire [C_S_AXI_ADDR_WIDTH-1:0]      reg_read_addr,
input  wire [C_S_AXI_DATA_WIDTH-1:0]      reg_read_data,
input  wire                                reg_read_valid
);

// Local parameters
localparam [1:0] RESP_OKAY   = 2'b00;
localparam [1:0] RESP_SLVERR = 2'b10;

// Write FSM states
localparam [1:0] W_IDLE      = 2'b00;
localparam [1:0] W_WAIT_DATA = 2'b01;
localparam [1:0] W_WAIT_ADDR = 2'b10;
localparam [1:0] W_RESPOND   = 2'b11;

// Read FSM states
localparam [1:0] R_IDLE      = 2'b00;
localparam [1:0] R_WAIT_DATA = 2'b01;
localparam [1:0] R_RESPOND   = 2'b10;

// Internal signals
reg [1:0] write_state_reg, write_state_next;
reg [1:0] read_state_reg, read_state_next;

reg [C_S_AXI_ADDR_WIDTH-1:0]      awaddr_reg;
reg [C_S_AXI_DATA_WIDTH-1:0]      wdata_reg;
reg [(C_S_AXI_DATA_WIDTH/8)-1:0]  wstrb_reg;
reg [C_S_AXI_ADDR_WIDTH-1:0]      araddr_reg;

reg awready_reg;
reg wready_reg;
reg bvalid_reg;
reg arready_reg;
reg rvalid_reg;
reg [C_S_AXI_DATA_WIDTH-1:0] rdata_reg;
reg [1:0] bresp_reg;
reg [1:0] rresp_reg;

reg reg_write_en_reg;
reg reg_read_en_reg;

// Output 
assign S_AXI_AWREADY = awready_reg;
assign S_AXI_WREADY  = wready_reg;
assign S_AXI_BVALID  = bvalid_reg;
assign S_AXI_BRESP   = bresp_reg;
assign S_AXI_ARREADY = arready_reg;
assign S_AXI_RVALID  = rvalid_reg;
assign S_AXI_RDATA   = rdata_reg;
assign S_AXI_RRESP   = rresp_reg;

assign reg_write_en   = reg_write_en_reg;
assign reg_write_addr = awaddr_reg;
assign reg_write_data = wdata_reg;
assign reg_write_strb = wstrb_reg;

assign reg_read_en   = reg_read_en_reg;
assign reg_read_addr = araddr_reg;

// Write FSM - State register
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        write_state_reg <= W_IDLE;
    end else begin
        write_state_reg <= write_state_next;
    end
end

// Write FSM - Next state logic
always @(*) begin
    write_state_next = write_state_reg;
    
    case (write_state_reg)
        W_IDLE: begin
            if (S_AXI_AWVALID && S_AXI_WVALID) begin
                write_state_next = W_RESPOND;
            end else if (S_AXI_AWVALID) begin
                write_state_next = W_WAIT_DATA;
            end else if (S_AXI_WVALID) begin
                write_state_next = W_WAIT_ADDR;
            end else begin
                write_state_next = W_IDLE;
            end
        end
        
        W_WAIT_DATA: begin
            if (S_AXI_WVALID) begin
                write_state_next = W_RESPOND;
            end else begin
                write_state_next = W_WAIT_DATA;
            end
        end
        
        W_WAIT_ADDR: begin
            if (S_AXI_AWVALID) begin
                write_state_next = W_RESPOND;
            end else begin
                write_state_next = W_WAIT_ADDR;
            end
        end
        
        W_RESPOND: begin
            if (S_AXI_BREADY) begin
                write_state_next = W_IDLE;
            end else begin
                write_state_next = W_RESPOND;
            end
        end
        
        default: begin
            write_state_next = W_IDLE;
        end
    endcase
end

// Write FSM - Output logic
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        awready_reg      <= 1'b0;
        wready_reg       <= 1'b0;
        bvalid_reg       <= 1'b0;
        bresp_reg        <= RESP_OKAY;
        awaddr_reg       <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        wdata_reg        <= {C_S_AXI_DATA_WIDTH{1'b0}};
        wstrb_reg        <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
        reg_write_en_reg <= 1'b0;
    end else begin
        // Default values
        awready_reg      <= 1'b0;
        wready_reg       <= 1'b0;
        reg_write_en_reg <= 1'b0;
        
        case (write_state_reg)
            W_IDLE: begin
                if (S_AXI_AWVALID && S_AXI_WVALID) begin
                    awready_reg      <= 1'b1;
                    wready_reg       <= 1'b1;
                    awaddr_reg       <= S_AXI_AWADDR;
                    wdata_reg        <= S_AXI_WDATA;
                    wstrb_reg        <= S_AXI_WSTRB;
                    reg_write_en_reg <= 1'b1;
                    bvalid_reg       <= 1'b1;
                    bresp_reg        <= RESP_OKAY;
                end else if (S_AXI_AWVALID) begin
                    awready_reg <= 1'b1;
                    awaddr_reg  <= S_AXI_AWADDR;
                end else if (S_AXI_WVALID) begin
                    wready_reg <= 1'b1;
                    wdata_reg  <= S_AXI_WDATA;
                    wstrb_reg  <= S_AXI_WSTRB;
                end else begin
                    awready_reg <= 1'b0;
                    wready_reg  <= 1'b0;
                end
            end
            
            W_WAIT_DATA: begin
                if (S_AXI_WVALID) begin
                    wready_reg       <= 1'b1;
                    wdata_reg        <= S_AXI_WDATA;
                    wstrb_reg        <= S_AXI_WSTRB;
                    reg_write_en_reg <= 1'b1;
                    bvalid_reg       <= 1'b1;
                    bresp_reg        <= RESP_OKAY;
                end else begin
                    wready_reg <= 1'b0;
                end
            end
            
            W_WAIT_ADDR: begin
                if (S_AXI_AWVALID) begin
                    awready_reg      <= 1'b1;
                    awaddr_reg       <= S_AXI_AWADDR;
                    reg_write_en_reg <= 1'b1;
                    bvalid_reg       <= 1'b1;
                    bresp_reg        <= RESP_OKAY;
                end else begin
                    awready_reg <= 1'b0;
                end
            end
            
            W_RESPOND: begin
                if (S_AXI_BREADY) begin
                    bvalid_reg <= 1'b0;
                end else begin
                    bvalid_reg <= 1'b1;
                end
            end
            
            default: begin
                awready_reg      <= 1'b0;
                wready_reg       <= 1'b0;
                bvalid_reg       <= 1'b0;
                reg_write_en_reg <= 1'b0;
            end
        endcase
    end
end

// Read FSM - State register
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        read_state_reg <= R_IDLE;
    end else begin
        read_state_reg <= read_state_next;
    end
end

// Read FSM - Next state logic
always @(*) begin
    read_state_next = read_state_reg;
    
    case (read_state_reg)
        R_IDLE: begin
            if (S_AXI_ARVALID) begin
                read_state_next = R_WAIT_DATA;
            end else begin
                read_state_next = R_IDLE;
            end
        end
        
        R_WAIT_DATA: begin
            if (reg_read_valid) begin
                read_state_next = R_RESPOND;
            end else begin
                read_state_next = R_WAIT_DATA;
            end
        end
        
        R_RESPOND: begin
            if (S_AXI_RREADY) begin
                read_state_next = R_IDLE;
            end else begin
                read_state_next = R_RESPOND;
            end
        end
        
        default: begin
            read_state_next = R_IDLE;
        end
    endcase
end

// Read FSM - Output logic
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        arready_reg     <= 1'b0;
        rvalid_reg      <= 1'b0;
        rdata_reg       <= {C_S_AXI_DATA_WIDTH{1'b0}};
        rresp_reg       <= RESP_OKAY;
        araddr_reg      <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        reg_read_en_reg <= 1'b0;
    end else begin
        // Default values
        arready_reg     <= 1'b0;
        reg_read_en_reg <= 1'b0;
        
        case (read_state_reg)
            R_IDLE: begin
                if (S_AXI_ARVALID) begin
                    arready_reg     <= 1'b1;
                    araddr_reg      <= S_AXI_ARADDR;
                    reg_read_en_reg <= 1'b1;
                end else begin
                    arready_reg <= 1'b0;
                end
            end
            
            R_WAIT_DATA: begin
                if (reg_read_valid) begin
                    rdata_reg  <= reg_read_data;
                    rvalid_reg <= 1'b1;
                    rresp_reg  <= RESP_OKAY;
                end else begin
                    rvalid_reg <= 1'b0;
                end
            end
            
            R_RESPOND: begin
                if (S_AXI_RREADY) begin
                    rvalid_reg <= 1'b0;
                end else begin
                    rvalid_reg <= 1'b1;
                end
            end
            
            default: begin
                arready_reg <= 1'b0;
                rvalid_reg  <= 1'b0;
            end
        endcase
    end
end

endmodule
