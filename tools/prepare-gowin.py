"""Generate portable Tang Nano 20K Gowin projects from the series RTL.

Run from any directory: python tools/prepare-gowin.py
Generated files are committed so opening a project needs no Python installation.
"""
from pathlib import Path
import json
import runpy
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BOARD = ROOT / 'boards/tangnano20k'


def write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + '\n', encoding='utf-8', newline='\n')


COMMON = '''
`default_nettype none
module board_reset(input wire clk, input wire button, output wire rst);
    reg [15:0] startup = 0;
    reg [1:0] sync = 0;
    always @(posedge clk) begin
        sync <= {sync[0], button};
        if (!(&startup)) startup <= startup + 1'b1;
    end
    assign rst = !(&startup) | sync[1];
endmodule
`default_nettype wire
'''

VIDEO = '''
`default_nettype none
// 27 MHz -> 371.25 MHz serial -> 74.25 MHz pixel (720p60).
module video_clock(input wire clk, input wire rst,
                   output wire serial_clk, output wire pix_clk, output wire locked);
    rPLL #(.FCLKIN("27"), .IDIV_SEL(3), .FBDIV_SEL(54), .ODIV_SEL(2),
           .DYN_IDIV_SEL("false"), .DYN_FBDIV_SEL("false"), .DYN_ODIV_SEL("false"),
           .CLKFB_SEL("internal"), .DEVICE("GW2AR-18C")) pll (
        .CLKIN(clk), .CLKOUT(serial_clk), .LOCK(locked), .RESET(rst), .RESET_P(1'b0),
        .CLKFB(1'b0), .FBDSEL(6'd0), .IDSEL(6'd0), .ODSEL(6'd0),
        .PSDA(4'd0), .DUTYDA(4'd0), .FDLY(4'd0));
    CLKDIV #(.DIV_MODE("5"), .GSREN("false")) divider (
        .HCLKIN(serial_clk), .RESETN(locked), .CALIB(1'b0), .CLKOUT(pix_clk));
endmodule

module tmds_lane(input wire pix_clk, input wire serial_clk, input wire rst,
                 input wire [9:0] symbol, output wire p, output wire n);
    wire serial;
    OSER10 serializer(.PCLK(pix_clk), .FCLK(serial_clk), .RESET(rst),
        .D0(symbol[0]), .D1(symbol[1]), .D2(symbol[2]), .D3(symbol[3]),
        .D4(symbol[4]), .D5(symbol[5]), .D6(symbol[6]), .D7(symbol[7]),
        .D8(symbol[8]), .D9(symbol[9]), .Q(serial));
    TLVDS_OBUF output_buffer(.I(serial), .O(p), .OB(n));
endmodule
`default_nettype wire
'''

UART = '''
`default_nettype none
// Buffer the short firmware greeting because the SoC has no UART backpressure.
// 256 bytes; overflow is latched and exposed on an LED.
module board_uart(input wire clk, input wire rst, input wire wr,
                  input wire [7:0] data, output wire tx, output reg overflow);
    reg [7:0] fifo [0:255];
    reg [8:0] wp, rp;
    reg [9:0] shift;
    reg [3:0] bits_left;
    reg [7:0] divider;
    wire full = (wp[8] != rp[8]) && (wp[7:0] == rp[7:0]);
    assign tx = bits_left == 0 ? 1'b1 : shift[0];
    always @(posedge clk) begin
        if (rst) begin
            wp <= 0; rp <= 0; shift <= 10'h3ff;
            bits_left <= 0; divider <= 0; overflow <= 0;
        end else begin
            if (wr) begin
                if (full) overflow <= 1;
                else begin fifo[wp[7:0]] <= data; wp <= wp + 1'b1; end
            end
            if (bits_left == 0) begin
                if (wp != rp) begin
                    shift <= {1'b1, fifo[rp[7:0]], 1'b0};
                    rp <= rp + 1'b1; bits_left <= 10; divider <= 0;
                end
            end else if (divider == 233) begin
                divider <= 0; shift <= {1'b1, shift[9:1]}; bits_left <= bits_left - 1'b1;
            end else divider <= divider + 1'b1;
        end
    end
endmodule
`default_nettype wire
'''


def top(body, extra=''):
    return '''`default_nettype none
module tangnano20k_top(input wire clk, input wire btn_s1,
                      output wire [5:0] led_n%s);
    wire rst;
    board_reset reset_control(.clk(clk), .button(btn_s1), .rst(rst));
%s
endmodule
`default_nettype wire
''' % (extra, body)


def main():
    import os
    write(BOARD / 'rtl/board_reset.v', COMMON)
    write(BOARD / 'rtl/video_io.v', VIDEO)
    write(BOARD / 'rtl/board_uart.v', UART)
    runpy.run_path(str(ROOT / '06-riscv-soc/firmware/build_firmware.py'))
    firmware = (ROOT / '06-riscv-soc/firmware/firmware.hex').read_text()
    models = ['02-golden-models/rtl/' + n + '.v' for n in ['popcount', 'popand', 'hamming', 'dot8']]
    soc = ['06-riscv-soc/rtl/simple_soc.v', '06-riscv-soc/third_party/picorv32.v',
           '07-semnpu/rtl/semnpu_regs.v', 'boards/tangnano20k/rtl/board_uart.v'] + models
    projects = []
    projects.append(('01-hdl-basics', ['01-hdl-basics/rtl/blinky.v', '01-hdl-basics/rtl/counter.v'], top('''
    wire blink;
    wire [31:0] count;
    blinky blink_core(.clk(clk), .rst(rst), .led_n(blink));
    counter #(.WIDTH(32)) counter_core(.clk(clk), .rst(rst), .en(1'b1), .count(count));
    assign led_n = {~count[28:24], blink};'''), {}))
    projects.append(('02-golden-models', models, top('''
    reg [31:0] count;
    always @(posedge clk) if (rst) count <= 0; else count <= count + 1'b1;
    wire [127:0] a = {4{count}}, b = {4{32'h55555555}};
    wire [7:0] score, distance;
    wire signed [31:0] acc;
    popand pa(.a(a), .b(b), .score(score));
    hamming hm(.a(a), .b(b), .distance(distance));
    dot8 dot(.clk(clk), .rst(rst), .clear(count[19:0] == 0),
             .in_valid(count[19:0] == 1), .a(count[27:20]), .b(8'sd3), .acc(acc));
    assign led_n = ~{acc[2:0], distance[1:0], score[0]};'''), {}))
    for stage in ['03-hdmi', '04-tilemap-sprites']:
        sources = ['boards/tangnano20k/rtl/video_io.v', '03-hdmi/rtl/video_timing.v',
                   '03-hdmi/rtl/tmds_encoder.v']
        body = '''
    wire serial_clk, pix_clk, locked;
    video_clock clocks(.clk(clk), .rst(rst), .serial_clk(serial_clk),
                       .pix_clk(pix_clk), .locked(locked));
    reg [2:0] reset_pipe = 3'b111;
    always @(posedge pix_clk or negedge locked)
        if (!locked) reset_pipe <= 3'b111;
        else reset_pipe <= {reset_pipe[1:0], 1'b0};
    wire video_rst = reset_pipe[2];
    wire [11:0] x, y;
    wire de, hs, vs;
    wire [9:0] red, green, blue;
'''
        if stage == '03-hdmi':
            sources += ['03-hdmi/rtl/hdmi_colorbars.v', '03-hdmi/rtl/colorbars.v']
            body += '''
    hdmi_colorbars video(.pix_clk(pix_clk), .rst(video_rst), .x(x), .y(y),
        .de(de), .hsync(hs), .vsync(vs), .tmds_r(red), .tmds_g(green), .tmds_b(blue));
'''
        else:
            sources += ['04-tilemap-sprites/rtl/tile_sprite_ppu.v']
            body += '''
    video_timing timing(.clk(pix_clk), .rst(video_rst), .x(x), .y(y),
                        .de(de), .hsync(hs), .vsync(vs));
    wire [7:0] r, g, b;
    wire ppu_de;
    reg hs_delay, vs_delay;
    always @(posedge pix_clk) begin hs_delay <= hs; vs_delay <= vs; end
    tile_sprite_ppu ppu(.clk(pix_clk), .rst(video_rst), .de(de),
        .x(x[10:2]), .y(y[9:2]), .scroll_x(9'd0), .scroll_y(8'd0),
        .out_de(ppu_de), .r(r), .g(g), .b(b));
    tmds_encoder er(.clk(pix_clk), .rst(video_rst), .data(r),
        .c0(1'b0), .c1(1'b0), .de(ppu_de), .symbol(red));
    tmds_encoder eg(.clk(pix_clk), .rst(video_rst), .data(g),
        .c0(1'b0), .c1(1'b0), .de(ppu_de), .symbol(green));
    tmds_encoder eb(.clk(pix_clk), .rst(video_rst), .data(b),
        .c0(hs_delay), .c1(vs_delay), .de(ppu_de), .symbol(blue));
'''
        body += '''
    tmds_lane lane0(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(blue), .p(tmds_d_p[0]), .n(tmds_d_n[0]));
    tmds_lane lane1(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(green), .p(tmds_d_p[1]), .n(tmds_d_n[1]));
    tmds_lane lane2(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(red), .p(tmds_d_p[2]), .n(tmds_d_n[2]));
    tmds_lane laneclk(.pix_clk(pix_clk), .serial_clk(serial_clk), .rst(video_rst),
        .symbol(10'b1111100000), .p(tmds_clk_p), .n(tmds_clk_n));
    assign led_n = {5'b11111, ~locked};
'''
        projects.append((stage, sources, top(body, ', output wire tmds_clk_p, tmds_clk_n,\n                      output wire [2:0] tmds_d_p, tmds_d_n'), {'hdmi': True}))
    projects.append(('05-input-audio', ['05-input-audio/rtl/' + n + '.v' for n in
        ['debounce', 'square_channel', 'noise_channel', 'audio_mixer', 'i2s_tx']], top('''
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
    assign led_n = {5'b11111, ~enable};''', ', input wire btn_s2,\n                      output wire audio_bclk, audio_ws, audio_sd, audio_en'), {'audio': True}))
    soc_top = top('''
    wire trap, uart_wr, report_wr, done, overflow;
    wire [7:0] uart_char;
    wire [1:0] report_idx;
    wire [31:0] report_val;
    reg [2:0] seen;
    reg [2:0] passed;
    simple_soc #(.FIRMWARE("firmware.hex")) soc(.clk(clk), .rst_n(!rst), .trap(trap),
        .uart_wr(uart_wr), .uart_char(uart_char), .report_wr(report_wr),
        .report_idx(report_idx), .report_val(report_val), .done(done));
    board_uart uart(.clk(clk), .rst(rst), .wr(uart_wr), .data(uart_char),
                    .tx(uart_tx), .overflow(overflow));
    always @(posedge clk) begin
        if (rst) begin seen <= 0; passed <= 0; end
        else if (report_wr && report_idx < 3) begin
            seen[report_idx] <= 1;
            case (report_idx)
                0: passed[0] <= report_val == EXPECT0;
                1: passed[1] <= report_val == EXPECT1;
                2: passed[2] <= report_val == EXPECT2;
            endcase
        end
    end
    assign led_n = ~{overflow, trap, done, seen & passed};''', ', output wire uart_tx')
    expected = (ROOT / '06-riscv-soc/firmware/expected.hex').read_text().splitlines()
    for i, value in enumerate(expected):
        soc_top = soc_top.replace('EXPECT' + str(i), "32'h" + value)
    for stage in ['06-riscv-soc', '07-semnpu']:
        projects.append((stage, soc, soc_top, {'uart': True}))
    projects.append(('09-retro-cpu-cores', ['09-retro-cpu-cores/rtl/cpu_bus_socket.v'], top('''
    reg [2:0] state;
    wire ready, valid;
    wire [7:0] data;
    wire [31:0] addr, wdata;
    wire [3:0] wstrb;
    reg passed;
    cpu_bus_socket socket(.clk(clk), .rst(rst), .cpu_valid(state == 0), .cpu_we(1'b0),
        .cpu_addr(16'h1002), .cpu_wdata(8'd0), .cpu_ready(ready), .cpu_rdata(data),
        .mem_valid(valid), .mem_addr(addr), .mem_wdata(wdata), .mem_wstrb(wstrb),
        .mem_ready(valid), .mem_rdata(32'h11223344));
    always @(posedge clk) begin
        if (rst) begin state <= 0; passed <= 0; end
        else case (state)
            0: state <= 1;
            1: if (ready) begin passed <= data == 8'h22 && addr == 32'h80001000; state <= 2; end
            default: state <= state;
        endcase
    end
    assign led_n = {4'b1111, ~(state == 2), ~passed};'''), {}))
    lcd_variants = runpy.run_path(str(ROOT / 'tools/gowin-lcd.py'))
    projects += lcd_variants['projects'](top)
    for stage, sources, rtl, opts in projects:
        directory = ROOT / stage / opts.get('folder', 'gowin')
        write(directory / 'tangnano20k_top.v', rtl)
        pins = [('clk', '4'), ('btn_s1', '88')] + [('led_n[%d]' % i, str(15+i)) for i in range(6)]
        if opts.get('uart'): pins.append(('uart_tx', '69'))
        if opts.get('audio'):
            pins += [('btn_s2', '87'), ('audio_en', '51'), ('audio_sd', '54'), ('audio_ws', '55'), ('audio_bclk', '56')]
        if opts.get('lcd'):
            pins += [('lcd_dclk', '77'), ('lcd_de', '48'), ('lcd_hsync', '25'), ('lcd_vsync', '26')]
            pins += [(f'lcd_r[{i}]', str(42-i)) for i in range(5)]
            pins += [(f'lcd_g[{i}]', str(37-i)) for i in range(6)]
            pins += [(f'lcd_b[{i}]', str(31-i)) for i in range(5)]
        cst = []
        for signal, pin in pins:
            pull = 'DOWN' if signal.startswith('btn_') else 'UP'
            cst += [f'IO_LOC "{signal}" {pin};', f'IO_PORT "{signal}" IO_TYPE=LVCMOS33 PULL_MODE={pull};']
            if signal.startswith('lcd_'):
                cst[-1] = f'IO_PORT "{signal}" IO_TYPE=LVCMOS33 PULL_MODE=UP DRIVE=24;'
        if opts.get('hdmi'):
            for signal, pair in [('tmds_clk_p', '33,34'), ('tmds_d_p[0]', '35,36'),
                                 ('tmds_d_p[1]', '37,38'), ('tmds_d_p[2]', '39,40')]:
                cst += [f'IO_LOC "{signal}" {pair};', f'IO_PORT "{signal}" IO_TYPE=LVDS25 PULL_MODE=NONE DRIVE=3.5 BANK_VCCIO=3.3;']
        write(directory / 'tangnano20k.cst', '\n'.join(cst))
        sdc = 'create_clock -name clk27 -period 37.037 [get_ports {clk}]\n'
        if opts.get('hdmi'):
            sdc += '''create_generated_clock -name serial371 -source [get_ports {clk}] -multiply_by 55 -divide_by 4 [get_pins {clocks/pll/CLKOUT}]
create_generated_clock -name pixel74 -source [get_pins {clocks/pll/CLKOUT}] -divide_by 5 [get_pins {clocks/divider/CLKOUT}]
'''
        # Asynchronous buttons are synchronized by board_reset/debounce.
        if opts.get('lcd'):
            sdc += '''create_generated_clock -name pixel9 -source [get_ports {clk}] -divide_by 3 [get_pins {clocks/pll/CLKOUT}]
create_generated_clock -name lcd_dclk -source [get_pins {clocks/pll/CLKOUT}] -divide_by 1 [get_ports {lcd_dclk}]
set_output_delay -clock lcd_dclk -max 12.000 [get_ports {lcd_de lcd_hsync lcd_vsync lcd_r[*] lcd_g[*] lcd_b[*]}]
set_output_delay -clock lcd_dclk -min -12.000 [get_ports {lcd_de lcd_hsync lcd_vsync lcd_r[*] lcd_g[*] lcd_b[*]}]
'''
        sdc += 'set_false_path -from [get_ports {btn_s1}]\n'
        if opts.get('audio'): sdc += 'set_false_path -from [get_ports {btn_s2}]\n'
        write(directory / 'tangnano20k.sdc', sdc)
        sources = ['boards/tangnano20k/rtl/board_reset.v'] + sources
        files = [(os.path.relpath(ROOT / s, directory).replace('\\', '/'), 'verilog') for s in sources]
        files += [('tangnano20k_top.v', 'verilog'), ('tangnano20k.cst', 'cst'), ('tangnano20k.sdc', 'sdc')]
        project = ET.Element('Project')
        ET.SubElement(project, 'Template').text = 'FPGA'
        ET.SubElement(project, 'Version').text = '5'
        ET.SubElement(project, 'Device', name='GW2AR-18C', pn='GW2AR-LV18QN88C8/I7').text = 'gw2ar18c-000'
        filelist = ET.SubElement(project, 'FileList')
        for path, kind in files:
            ET.SubElement(filelist, 'File', path=path, type='file.'+kind, enable='1')
        ET.indent(project)
        write(directory / 'tangnano20k.gprj', '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE gowin-fpga-project>\n' + ET.tostring(project, encoding='unicode'))
        write(directory / 'impl/project_process_config.json', json.dumps({
            'Process_Configuration_Verion': '1.0',
            'Synthesize_tool': 'GowinSyn', 'TopModule': 'tangnano20k_top',
            'Verilog_Standard': 'Vlg_Std_Sysv2017',
            'OUTPUT_BASE_NAME': 'tangnano20k', 'IncludePath': [],
            'Implicit_Initial_Value_Support': True,
            'Promote_Physical_Constraint_Warning_to_Error': True,
            'Run_Timing_Driven': True,
        }, indent=2))
        # Explicit top/settings for the batch flow; IDE can also infer the sole root.
        write(directory / 'build.tcl', '\n'.join([
            'set project_dir [file dirname [file normalize [info script]]]', 'cd $project_dir',
            'set_device -name GW2AR-18C GW2AR-LV18QN88C8/I7'] +
            ['add_file {'+path+'}' for path, _ in files] +
            ['set_option -top_module tangnano20k_top', 'set_option -verilog_std sysv2017',
             'set_option -output_base_name tangnano20k', 'run all']))
        if opts.get('uart'):
            write(directory / 'firmware.hex', firmware)
        print('Prepared', directory.relative_to(ROOT))


if __name__ == '__main__':
    main()
