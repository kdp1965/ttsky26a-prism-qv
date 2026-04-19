/*
 * Copyright (c) 2025 Michael Bell
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Wrapper for all TinyQV peripherals
//
// Address space:
// 0x800_0000 - 03f: Reserved by project wrapper (time, debug, etc)
// 0x800_0040 - 07f: GPIO configuration
// 0x800_0080 - 0bf: UART TX
// 0x800_00c0 - 0ff: UART RX
// 0x800_0100 - 2ff: 12 user peripherals (64 bytes each, word and halfword access supported, each has an interrupt)
// 0x800_0400 - 7ff: PRISM Peripheral
module tinyQV_peripherals (
    input         clk,
    input         rst_n,

    input  [7:0]  ui_in,        // The input PMOD, always available
    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected

    input [10:0]  addr_in,
    input [31:0]  data_in,      // Data in to the peripheral, bottom 8, 16 or all 32 bits are valid on write.

    // Data read and write requests from the TinyQV core.
    input [1:0]   data_write_n, // 11 = no write, 00 = 8-bits, 01 = 16-bits, 10 = 32-bits
    input [1:0]   data_read_n,  // 11 = no read,  00 = 8-bits, 01 = 16-bits, 10 = 32-bits

    output [31:0] data_out,     // Data out from the peripheral, bottom 8, 16 or all 32 bits are valid on read when data_ready is high.
    output        data_ready,

    input         data_read_complete,  // Set by TinyQV when a read is complete

    output [15:2] user_interrupts  // User peripherals get interrupts 2-15
);

    // Registered data out to TinyQV
    reg  [31:0] data_out_r;
    reg         data_out_hold;
    reg         data_ready_r;

    wire        read_req = data_read_n != 2'b11;

    // Muxed data out direct from selected peripheral
    reg [31:0] data_from_peri;
    reg        data_ready_from_peri;
    reg        data_ready_from_prism;

    // Must mask the data_read_n to avoid extra read while
    // buffering the result
    wire [1:0] data_read_n_peri;
    assign data_read_n_peri = data_read_n | {2{data_ready_r}};

    wire [31:0] data_from_user_peri   [0:3];
    wire [31:0] data_from_prism;
    wire        data_ready_from_user_peri   [0:3];

    wire [7:0]  uo_out_from_user_peri   [0:15];
    wire [7:0]  uo_out_from_prism;
    reg [7:0] uo_out_comb;
    assign uo_out = uo_out_comb;

    // Register the data output from the peripheral.  This improves timing and
    // also simplifies the peripheral interface (no need for the peripheral to care
    // about holding data_out until data_read_complete - it looks like it is read
    // synchronously).
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out_hold <= 0;
        end else begin
            if (data_read_complete) data_out_hold <= 0;

            if (!data_out_hold && data_ready_from_peri && data_read_n != 2'b11) begin
                data_out_hold <= 1;
                data_out_r <= data_from_peri;
            end

            // Data ready must be registered because data_out is.
            data_ready_r <= read_req && data_ready_from_peri;
        end
    end

    assign data_out = data_out_r;
    assign data_ready = data_ready_r || data_write_n != 2'b11;

    // --------------------------------------------------------------------- //
    // Decode the address to select the active peripheral

    localparam PERI_GPIO = 1;
    localparam PERI_UART = 2;

    reg [3:0] peri_user;
    reg       peri_prism;

    always @(*) begin
        peri_user  = 0;
        peri_prism = 0;

        if (addr_in[9]) begin
            data_from_peri = data_from_prism;
            data_ready_from_peri = data_ready_from_prism;
            peri_prism = 1;
        end else begin
            peri_user[addr_in[7:6]] = 1;
            data_from_peri = data_from_user_peri[addr_in[7:6]];
            data_ready_from_peri = data_ready_from_user_peri[addr_in[7:6]];
        end
    end

    assign data_from_user_peri[0] = 32'h0;
    assign data_ready_from_user_peri[0] = 0;
    assign uo_out_from_user_peri[0] = 8'h0;

    // --------------------------------------------------------------------- //
    // GPIO

    reg  [3:0] gpio_out_func_sel [0:7];
    reg  [7:0] gpio_out;

    assign uo_out_from_user_peri[4] = 8'h0;
    assign uo_out_from_user_peri[5] = 8'h0;
    assign uo_out_from_user_peri[6] = 8'h0;
    assign uo_out_from_user_peri[7] = 8'h0;
    assign uo_out_from_user_peri[9] = 8'h0;
    assign uo_out_from_user_peri[10] = 8'h0;
    assign uo_out_from_user_peri[11] = 8'h0;
    assign uo_out_from_user_peri[12] = 8'h0;
    assign uo_out_from_user_peri[13] = 8'h0;
    assign uo_out_from_user_peri[14] = 8'h0;
    assign uo_out_from_user_peri[15] = 8'h0;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            gpio_out <= 0;
        end else if (peri_user[PERI_GPIO]) begin
            if (addr_in[5:0] == 6'h0) begin
                if (data_write_n != 2'b11) gpio_out <= data_in[7:0];
            end
        end
    end

    assign data_from_user_peri[PERI_GPIO] = (addr_in[5:0] == 6'h0) ? {24'h0, gpio_out} :
                                            (addr_in[5:0] == 6'h4) ? {24'h0, ui_in}    :
                                            ({addr_in[5], addr_in[1:0]} == 3'b100) ? {27'h0, gpio_out_func_sel[addr_in[4:2]]} :
                                            32'h0;
    assign data_ready_from_user_peri[PERI_GPIO] = 1;
    assign uo_out_from_user_peri[PERI_GPIO] = gpio_out;

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            always @(posedge clk) begin
                if (!rst_n) begin
                    gpio_out_func_sel[i] <= (i == 0 || i == 1) ? PERI_UART : PERI_GPIO;
                end else if (peri_user[PERI_GPIO]) begin
                    if ({addr_in[5], addr_in[1:0]} == 3'b100 && addr_in[4:2] == i) begin
                        if (data_write_n != 2'b11) gpio_out_func_sel[i] <= data_in[3:0];
                    end
                end
            end

            always @(*) begin
                uo_out_comb[i] = 0;

                uo_out_comb[i] = uo_out_from_user_peri[gpio_out_func_sel[i][3:0]][i];
            end
        end
    endgenerate

    // --------------------------------------------------------------------- //
    // UART

    tqvp_uart_wrapper i_uart (
        .clk(clk),
        .rst_n(rst_n),

        .ui_in(ui_in),
        .uo_out(uo_out_from_user_peri[PERI_UART]),

        .address(addr_in[5:0]),
        .data_in(data_in),

        .data_write_n(data_write_n    | {2{~peri_user[PERI_UART]}}),
        .data_read_n(data_read_n_peri | {2{~peri_user[PERI_UART]}}),

        .data_out(data_from_user_peri[PERI_UART]),
        .data_ready(data_ready_from_user_peri[PERI_UART]),

        .user_interrupt(user_interrupts[PERI_UART+1:PERI_UART])
    );

    // There is no peripheral 3, UART uses its interrupt.
    assign uo_out_from_user_peri[3] = 8'h0;
    assign data_from_user_peri[3] = 32'h0;
    assign data_ready_from_user_peri[3] = 1;

    // --------------------------------------------------------------------- //
    // Full interface peripherals

    tqvp_prism i_prism (
        .clk(clk),
        .rst_n(rst_n),

        .ui_in(ui_in),
        .uo_out(uo_out_from_user_peri[8]),

        .address(addr_in[5:0]),
        .data_in(data_in),

        .data_write_n(data_write_n    | {2{~peri_prism}}),
        .data_read_n(data_read_n_peri | {2{~peri_prism}}),

        .data_out(data_from_prism),
        .data_ready(data_ready_from_prism),

        .user_interrupt(user_interrupts[8])
    );

    assign user_interrupts[7:4]  = 4'h0;
    assign user_interrupts[15:9] = 7'h0;

endmodule
