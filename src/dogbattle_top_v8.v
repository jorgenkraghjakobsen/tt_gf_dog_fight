// dogbattle_top_v8.v
// Top-level for 8-dog battle with VGA output
// Divides 50MHz -> 25MHz for VGA timing
//`timescale 1ns/1ps

module dogbattle_top_v8 (
    input  wire clk50,    // external 50 MHz clock
    input  wire rst_n,
    output wire vga_hs,
    output wire vga_vs,
    output wire [2:0] vga_r,
    output wire [2:0] vga_g,
    output wire [1:0] vga_b,
    output wire pix_clk_out  // expose pixel clock for FPGA testing
);

    // divide-by-2 to get ~25MHz pixel clock
    reg pix_clk;
    always @(posedge clk50 or negedge rst_n) begin
        if (!rst_n) pix_clk <= 0;
        else pix_clk <= ~pix_clk;
    end

    // VGA timing
    wire active;
    wire [9:0] px;
    wire [8:0] py;
    wire frame_tick;
    vga_timing vt (
        .clk(pix_clk),
        .rst_n(rst_n),
        .hsync(vga_hs),
        .vsync(vga_vs),
        .active(active),
        .x(px),
        .y(py),
        .frame_tick(frame_tick)
    );

    // game core parameters
    localparam BOX_W = 48;
    localparam BOX_H = 32;
    localparam N = 4;  // Simplified to 4 dogs

    // Flattened nets for 4 dogs:
    wire [9:0] posx0, posx1, posx2, posx3;
    wire [8:0] posy0, posy1, posy2, posy3;
    wire signed [9:0] velx0, velx1, velx2, velx3;
    wire signed [9:0] vely0, vely1, vely2, vely3;
    wire [7:0] hits0, hits1, hits2, hits3;
    wire [2:0] col0, col1, col2, col3;
    wire [1:0] pwr0, pwr1, pwr2, pwr3;

    // Instantiate game_core_v8 with flat individual ports
    game_core_v8 #(.SCREEN_W(640), .SCREEN_H(480), .BOX_W(BOX_W), .BOX_H(BOX_H), .N(4)) gc (
        .clk(pix_clk),
        .rst_n(rst_n),
        .frame_tick(frame_tick),
        .posx0(posx0), .posx1(posx1), .posx2(posx2), .posx3(posx3),
        .posy0(posy0), .posy1(posy1), .posy2(posy2), .posy3(posy3),
        .velx0(velx0), .velx1(velx1), .velx2(velx2), .velx3(velx3),
        .vely0(vely0), .vely1(vely1), .vely2(vely2), .vely3(vely3),
        .hits0(hits0), .hits1(hits1), .hits2(hits2), .hits3(hits3),
        .color_idx0(col0), .color_idx1(col1), .color_idx2(col2), .color_idx3(col3),
        .power_state0(pwr0), .power_state1(pwr1), .power_state2(pwr2), .power_state3(pwr3)
    );

    // Pixel generation
    reg [2:0] out_r;
    reg [2:0] out_g;
    reg [1:0] out_b;

    // Dog rendering results
    wire [2:0] dog0_render, dog1_render, dog2_render, dog3_render;
    assign dog0_render = render_dog(px, py, posx0, posy0);
    assign dog1_render = render_dog(px, py, posx1, posy1);
    assign dog2_render = render_dog(px, py, posx2, posy2);
    assign dog3_render = render_dog(px, py, posx3, posy3);

    // Helper function: check if pixel inside box i (bounding box)
    function inside_box;
        input [9:0] pxi;
        input [8:0] pyi;
        input [9:0] bx;
        input [8:0] by;
        begin
            inside_box = (pxi >= bx) && (pxi < bx + BOX_W) && (pyi >= by) && (pyi < by + BOX_H);
        end
    endfunction

    // Procedural dog rendering function
    // Returns: {is_dog_pixel, is_outline, is_eye}
    function [2:0] render_dog;
        input [9:0] pxi;     // pixel x
        input [8:0] pyi;     // pixel y
        input [9:0] bx;      // box x position
        input [8:0] by;      // box y position
        reg [5:0] rel_x;     // relative x within box (0-47)
        reg [4:0] rel_y;     // relative y within box (0-31)
        reg is_body, is_head, is_leg, is_ear, is_eye, is_tail, is_outline;
        reg [5:0] dx;
        reg [4:0] dy;
        begin
            // Safety check - should only be called when inside bounding box
            if (pxi < bx || pyi < by || pxi >= (bx + BOX_W) || pyi >= (by + BOX_H)) begin
                render_dog = 3'b000;  // Not in dog
            end else begin
                // Calculate relative position within box
                rel_x = pxi - bx;
                rel_y = pyi - by;

                // Initialize
                is_body = 0;
                is_head = 0;
                is_leg = 0;
                is_ear = 0;
                is_eye = 0;
                is_tail = 0;
                is_outline = 0;

                // Body (main rectangle) - center of sprite
                // From x: 12-40, y: 8-24
                if (rel_x >= 12 && rel_x < 40 && rel_y >= 8 && rel_y < 24) begin
                    is_body = 1;
                end

                // Head (circle at front) - right side
                // Center at (40, 16), radius ~8
                dx = (rel_x > 40) ? (rel_x - 40) : (40 - rel_x);
                dy = (rel_y > 16) ? (rel_y - 16) : (16 - rel_y);
                if ((dx * dx + dy * dy) < 64) begin  // radius^2 = 64
                    is_head = 1;
                end

                // Ears (triangular shapes on top of head)
                // Left ear
                if (rel_x >= 36 && rel_x < 40 && rel_y >= 8 && rel_y < 14) begin
                    if ((rel_y - 8) < (40 - rel_x)) begin
                        is_ear = 1;
                    end
                end
                // Right ear
                if (rel_x >= 40 && rel_x < 44 && rel_y >= 8 && rel_y < 14) begin
                    if ((rel_y - 8) < (rel_x - 40)) begin
                        is_ear = 1;
                    end
                end

                // Eyes (two small dots)
                // Left eye at (42, 14)
                if (rel_x >= 41 && rel_x < 43 && rel_y >= 13 && rel_y < 15) begin
                    is_eye = 1;
                end

                // Legs (4 small rectangles at bottom)
                // Front left leg
                if (rel_x >= 32 && rel_x < 36 && rel_y >= 24 && rel_y < 30) begin
                    is_leg = 1;
                end
                // Front right leg
                if (rel_x >= 38 && rel_x < 42 && rel_y >= 24 && rel_y < 30) begin
                    is_leg = 1;
                end
                // Back left leg
                if (rel_x >= 14 && rel_x < 18 && rel_y >= 24 && rel_y < 30) begin
                    is_leg = 1;
                end
                // Back right leg
                if (rel_x >= 20 && rel_x < 24 && rel_y >= 24 && rel_y < 30) begin
                    is_leg = 1;
                end

                // Tail (curved shape at back/left)
                // Simple tail: starts at back of body, curves up
                if (rel_x >= 4 && rel_x < 12 && rel_y >= 6 && rel_y < 14) begin
                    // Curved check: make it taper
                    if ((rel_x - 4) + (rel_y - 6) < 10) begin
                        is_tail = 1;
                    end
                end

                // Outline detection - check edges of dog shapes
                // Body outline
                if (is_body && (rel_x == 12 || rel_x == 39 || rel_y == 8 || rel_y == 23)) begin
                    is_outline = 1;
                end
                // Head outline - check perimeter of circle
                if (is_head && (dx * dx + dy * dy) >= 49 && (dx * dx + dy * dy) < 64) begin
                    is_outline = 1;
                end
                // Leg outlines
                if (is_leg && ((rel_x == 32 || rel_x == 35 || rel_x == 38 || rel_x == 41 ||
                               rel_x == 14 || rel_x == 17 || rel_x == 20 || rel_x == 23) ||
                               (rel_y == 24 || rel_y == 29))) begin
                    is_outline = 1;
                end

                // Return flags
                render_dog = {(is_body || is_head || is_leg || is_ear || is_tail), is_outline, is_eye};
            end
        end
    endfunction

    // Map hits to bar height
    function [5:0] hits_to_height;
        input [7:0] h;
        begin
            // scale 0..255 -> 0..BOX_H
            hits_to_height = (h * BOX_H) / 255;
        end
    endfunction

    always @(posedge pix_clk or negedge rst_n) begin
        if (!rst_n) begin
            out_r <= 3'b000;
            out_g <= 3'b000;
            out_b <= 2'b00;
        end else begin
            if (!active) begin
                out_r <= 3'b000; 
                out_g <= 3'b000; 
                out_b <= 2'b00;
            end else begin
                // Background gradient
                out_r <= px[9:7];
                out_g <= py[8:6];
                out_b <= {px[6]^py[6], px[5]^py[5]};

                // Draw all dogs with procedural rendering
                // Dog 0
                if (inside_box(px, py, posx0, posy0)) begin
                    if (dog0_render[2]) begin  // is_dog_pixel
                        if (dog0_render[0]) begin  // is_eye
                            // Eyes are always black
                            out_r <= 3'b000;
                            out_g <= 3'b000;
                            out_b <= 2'b00;
                        end else if (dog0_render[1]) begin  // is_outline
                            // Outline is darker version of main color
                            out_r <= {1'b0, col0[2], col0[1]};
                            out_g <= {1'b0, col0[1], col0[0]};
                            out_b <= {1'b0, col0[0]};
                        end else begin
                            // Main dog color
                            out_r <= {col0[2], col0[2], col0[1]};
                            out_g <= {col0[1], col0[1], col0[0]};
                            out_b <= {col0[0], col0[1]};
                        end
                    end
                end

                // Dog 1
                if (inside_box(px, py, posx1, posy1)) begin
                    if (dog1_render[2]) begin
                        if (dog1_render[0]) begin
                            out_r <= 3'b000;
                            out_g <= 3'b000;
                            out_b <= 2'b00;
                        end else if (dog1_render[1]) begin
                            out_r <= {1'b0, col1[2], col1[1]};
                            out_g <= {1'b0, col1[1], col1[0]};
                            out_b <= {1'b0, col1[0]};
                        end else begin
                            out_r <= {col1[2], col1[2], col1[1]};
                            out_g <= {col1[1], col1[1], col1[0]};
                            out_b <= {col1[0], col1[1]};
                        end
                    end
                end

                // Dog 2
                if (inside_box(px, py, posx2, posy2)) begin
                    if (dog2_render[2]) begin
                        if (dog2_render[0]) begin
                            out_r <= 3'b000;
                            out_g <= 3'b000;
                            out_b <= 2'b00;
                        end else if (dog2_render[1]) begin
                            out_r <= {1'b0, col2[2], col2[1]};
                            out_g <= {1'b0, col2[1], col2[0]};
                            out_b <= {1'b0, col2[0]};
                        end else begin
                            out_r <= {col2[2], col2[2], col2[1]};
                            out_g <= {col2[1], col2[1], col2[0]};
                            out_b <= {col2[0], col2[1]};
                        end
                    end
                end

                // Dog 3
                if (inside_box(px, py, posx3, posy3)) begin
                    if (dog3_render[2]) begin
                        if (dog3_render[0]) begin
                            out_r <= 3'b000;
                            out_g <= 3'b000;
                            out_b <= 2'b00;
                        end else if (dog3_render[1]) begin
                            out_r <= {1'b0, col3[2], col3[1]};
                            out_g <= {1'b0, col3[1], col3[0]};
                            out_b <= {1'b0, col3[0]};
                        end else begin
                            out_r <= {col3[2], col3[2], col3[1]};
                            out_g <= {col3[1], col3[1], col3[0]};
                            out_b <= {col3[0], col3[1]};
                        end
                    end
                end

                // Draw hit bars above each dog (red bars)
                if ((px >= posx0) && (px < posx0 + 6)) begin
                    if (py >= posy0 - hits_to_height(hits0) && py < posy0) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx1) && (px < posx1 + 6)) begin
                    if (py >= posy1 - hits_to_height(hits1) && py < posy1) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx2) && (px < posx2 + 6)) begin
                    if (py >= posy2 - hits_to_height(hits2) && py < posy2) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
                if ((px >= posx3) && (px < posx3 + 6)) begin
                    if (py >= posy3 - hits_to_height(hits3) && py < posy3) begin
                        out_r <= 3'b111; out_g <= 3'b000; out_b <= 2'b00;
                    end
                end
            end
        end
    end

    assign vga_r = out_r;
    assign vga_g = out_g;
    assign vga_b = out_b;
    assign pix_clk_out = pix_clk;  // expose internal pixel clock

endmodule
