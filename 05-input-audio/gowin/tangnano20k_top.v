`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n, input wire btn_s2,
                      output wire audio_bclk, audio_ws, audio_sd, audio_en);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));

    wire enable;
    debounce #(.COUNT_MAX(270000)) key(.clk(clk), .rst(rst), .noisy(btn_s2), .clean(enable));
    reg [3:0] divider;
    reg [5:0] slot;
    reg bclk_reg;
    reg [15:0] left, right;
    wire sample_tick = divider == 8 && !bclk_reg && slot == 63;
    wire signed [15:0] square0, square1, noise, mixed_l, mixed_r;
    square_channel voice0(.clk(clk), .rst(rst), .sample_tick(sample_tick), .enable(enable),
        .freq_step(32'd40315427), .duty(2'd2), .volume(4'd1), .sample(square0));
    square_channel voice1(.clk(clk), .rst(rst), .sample_tick(sample_tick), .enable(enable),
        .freq_step(32'd60473140), .duty(2'd1), .volume(4'd1), .sample(square1));
    noise_channel percussion(.clk(clk), .rst(rst), .sample_tick(sample_tick),
        .enable(enable), .volume(4'd1), .sample(noise));
    audio_mixer mixer(.square0(square0), .square1(square1), .noise(noise),
        .mixed_l(mixed_l), .mixed_r(mixed_r));
    // Continuous standard I2S: 32-bit slots, 16 data bits and padding.
    // Data changes on BCLK falling edges; WS changes one bit before the MSB.
    always @(posedge clk) begin
        if (rst) begin divider <= 0; slot <= 0; bclk_reg <= 0; left <= 0; right <= 0; end
        else if (divider == 8) begin
            divider <= 0; bclk_reg <= ~bclk_reg;
            if (bclk_reg) slot <= slot + 1'b1;
            if (sample_tick) begin left <= mixed_l; right <= mixed_r; end
        end else divider <= divider + 1'b1;
    end
    assign audio_bclk = bclk_reg;
    assign audio_ws = slot >= 31 && slot < 63;
    assign audio_sd = slot < 16 ? left[15-slot] :
                      slot >= 32 && slot < 48 ? right[47-slot] : 1'b0;
    assign audio_en = enable && !rst;
    assign led_n = {5'b11111, ~enable};
endmodule
`default_nettype wire
