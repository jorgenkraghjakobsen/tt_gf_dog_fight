// game_core_v8.v - Ultra-minimal 1 dog version for synthesis
//`timescale 1ns/1ps

module game_core_v8 #(
    parameter SCREEN_W = 640,
    parameter SCREEN_H = 480,
    parameter BOX_W = 48,   
    parameter BOX_H = 32,   
    parameter N = 2
)(
    input  wire clk,           
    input  wire rst_n,
    input  wire frame_tick,    
    
    // Only 1 active dog, rest unused
    output reg [9:0] posx0, posx1, posx2, posx3,
    output reg [8:0] posy0, posy1, posy2, posy3,
    output reg signed [9:0] velx0, velx1, velx2, velx3,
    output reg signed [9:0] vely0, vely1, vely2, vely3,
    output reg [7:0] hits0, hits1, hits2, hits3,
    output reg [2:0] color_idx0, color_idx1, color_idx2, color_idx3,
    output reg [1:0] power_state0, power_state1, power_state2, power_state3
);

    // Intermediate calculations for bouncing
    reg signed [10:0] next_x;
    reg signed [9:0] next_y;
    reg signed [9:0] dx, dy;  // Velocity divided by 256

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Dog 0 - only active one
            posx0 <= 10'd100;  posy0 <= 9'd100;
            // Simple integer velocity: 1 or 2 pixels per frame
            velx0 <= 10'sd2; vely0 <= 10'sd2;  // Move 2 pixels/frame diagonally
            hits0 <= 8'd0;     color_idx0 <= 3'd1;
            power_state0 <= 2'd0;
            
            // Dogs 1-3 completely unused
            posx1 <= 10'd0; posy1 <= 9'd0; velx1 <= 10'sd0; vely1 <= 10'sd0;
            hits1 <= 8'd0; color_idx1 <= 3'd0; power_state1 <= 2'd0;
            posx2 <= 10'd0; posy2 <= 9'd0; velx2 <= 10'sd0; vely2 <= 10'sd0;
            hits2 <= 8'd0; color_idx2 <= 3'd0; power_state2 <= 2'd0;
            posx3 <= 10'd0; posy3 <= 9'd0; velx3 <= 10'sd0; vely3 <= 10'sd0;
            hits3 <= 8'd0; color_idx3 <= 3'd0; power_state3 <= 2'd0;
        end else begin
            if (frame_tick) begin
                // Simplified: velocity is direct pixels per frame, no division needed
                // Just use velocity directly
                next_x = $signed({1'b0, posx0}) + velx0;
                next_y = $signed({1'b0, posy0}) + vely0;

                // Update position - move first
                posx0 <= next_x[9:0];
                posy0 <= next_y[8:0];

                // Then check boundaries and reverse velocity if needed
                // X axis
                if (next_x <= 0) begin
                    posx0 <= 10'd1;
                    velx0 <= -velx0;
                end else if (next_x >= (SCREEN_W - BOX_W)) begin
                    posx0 <= SCREEN_W - BOX_W - 1;
                    velx0 <= -velx0;
                end

                // Y axis
                if (next_y <= 0) begin
                    posy0 <= 9'd1;
                    vely0 <= -vely0;
                end else if (next_y >= (SCREEN_H - BOX_H)) begin
                    posy0 <= SCREEN_H - BOX_H - 1;
                    vely0 <= -vely0;
                end
            end
        end
    end

endmodule
