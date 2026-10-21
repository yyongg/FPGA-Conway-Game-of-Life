module top #(
    parameter int LED_TICK_RATE = 360, // how many ticks before incrementing the LED index

    // how many ticks to wait during reset period after pushing all 64 LEDs (0.175s)
    parameter int RESET_TICK_RATE = 2097151,
    parameter int BITS_PER_COLOR = 24,
    parameter int BIT_INDEX_RATE = 15
)(
    input logic clk,
    output logic _31b
);

    logic [8:0] tick_led = 9'd0;
    logic [3:0] tick_bit = 4'd0;

    logic [23:0] color;
    logic sending = 1'b0;
    logic [20:0] reset_count = 21'd0;

    logic [5:0] led_idx = 6'd0; // which LED are we on
    logic bit_now;
    logic [4:0] bit_idx = 0; // which bit in the sequence are we sending
    assign bit_now = color[23 - bit_idx];   // what is the color bit we are sending

    // color logic
    logic [23:0] rgb;   // what color to push now
    logic [2:0] color_idx = 0;

    // game logic
    logic [63:0] alive = 64'h0000_0000_0007_0402;   // starting state
    // 64'h0000_0000_0007_0402 for glider

    logic [3:0] n;

    function automatic logic [3:0] count_neighbors(input logic [5:0] idx, input logic [63:0] alive);
        logic [2:0] x, y, xm, xp, ym, yp;
        begin
            x = idx[2:0];  // x pos of LED index
            y = idx[5:3];  // y pos of LED index
            xm = x - 3'd1; xp = x + 3'd1;   // 3-bit math -> wraps 0<->7
            ym = y - 3'd1; yp = y + 3'd1;
            count_neighbors = 0;

            // {row, col} concatenation = row*8 + col
            // check top left
            if (alive[{yp, xm}]) begin count_neighbors = count_neighbors + 1; end
            // check top middle
            if (alive[{yp, x}]) begin count_neighbors = count_neighbors + 1; end
            // check top right
            if (alive[{yp, xp}]) begin count_neighbors = count_neighbors + 1; end
            // check left
            if (alive[{y, xm}]) begin count_neighbors = count_neighbors + 1; end
            // check right
            if (alive[{y, xp}]) begin count_neighbors = count_neighbors + 1; end
            // check bottom left
            if (alive[{ym, xm}]) begin count_neighbors = count_neighbors + 1; end
            // check bottom middle
            if (alive[{ym, x}]) begin count_neighbors = count_neighbors + 1; end
            // check bottom right
            if (alive[{ym, xp}]) begin count_neighbors = count_neighbors + 1; end
        end
    endfunction

    // increment LED index every 360 ticks (15 ticks per bit, 24 bits per LED)
    always_ff @(posedge clk) begin
        if (sending) begin
            if (tick_led==LED_TICK_RATE-1) begin
                tick_led <= 0;
                led_idx <= led_idx + 1;
                if (led_idx==63) sending <= 0;
            end

            else tick_led <= tick_led + 1;
        end

        else begin
            if (reset_count == RESET_TICK_RATE-1) begin
                sending <= 1;
                reset_count <= 0;
                for (int i = 0; i < 64; i++) begin
                    n = count_neighbors(i,alive);
                    alive[i] <= (n==3) || (alive[i] && n==2);
                end
                color_idx <= (color_idx==7) ? 0 : color_idx + 1;
            end
            else reset_count <= reset_count + 1;
        end
    end

    // increment bit index every 15 ticks, bit index iterates between 0-23
    always_ff @(posedge clk) begin
        if (sending) begin
            if (tick_bit==BIT_INDEX_RATE-1) begin
                tick_bit <= 0;
                if (bit_idx == BITS_PER_COLOR-1) begin
                    bit_idx <= 0;
                end
                else begin
                    bit_idx <= bit_idx + 1;
                end
            end

            else begin tick_bit <= tick_bit + 1; end
        end
    end

    always_comb begin
        case (color_idx)
            3'd0: rgb = 24'h001F00; // red
            3'd1: rgb = 24'h0F1F00; // yellow
            3'd2: rgb = 24'h1F1F00; // green
            3'd3: rgb = 24'h1F0000; // cyan
            3'd4: rgb = 24'h00001F; // blue
            3'd5: rgb = 24'h000610; // indigo
            3'd6: rgb = 24'h00111F; // violet
            3'd7: rgb = 24'h1F1F1F; // white
            default: rgb = 24'h000000; // if color is outside 0-7, turn off
        endcase
    end

    // if alive is 1 at current LED index assign current color to rgb, otherwise off
    assign color = alive[led_idx] ? rgb : 24'h000000;

    // push the data to LED
    assign _31b = sending & (bit_now ? (tick_bit < 9) : (tick_bit < 4));

endmodule
