`timescale 1ns / 1ps
module VGA_top(
    input wire clk, reset, reset_clk,
    input wire [2:0] btn,
    output wire hsync, vsync,
    output wire [11:0] rgb,
    output audioOut,
    output aud_sd
    );

   // signal declaration
   wire [9:0] pixel_x, pixel_y;
   wire video_on, pixel_tick;
   reg [11:0] rgb_reg;
   wire [11:0] rgb_next;
   // body
   // instantiate vga sync circuit
   wire clk_50m;
   wire clk1;
   wire playSound;
   clk_50m_generator myclk(clk, reset_clk, clk_50m);

   clk1_gen clock1 (clk, reset, clk1);

   //audio things
   SongPlayer song (clk, playSound, audioOut, aud_sd);
   
   vga_sync vsync_unit //determine where pixel x and y are at
      (.clk(clk_50m), .reset(reset), .hsync(hsync), .vsync(vsync),
       .video_on(video_on), .p_tick(pixel_tick),
       .pixel_x(pixel_x), .pixel_y(pixel_y));
   // instantiate graphic generator
   pong_graph_animate pong_graph_an_unit //determines where you put the color
      (.clk(clk), .reset(reset), .btn(btn), .video_on(video_on), .pix_x(pixel_x), .pix_y(pixel_y),
       .graph_rgb(rgb_next), .clk1(clk1), .playSound(playSound));
   // rgb buffer
   always @(posedge clk_50m)
      if (pixel_tick)
        begin
         rgb_reg <= rgb_next;
        end
   // output
  assign rgb = rgb_reg;
endmodule
 
module clk_50m_generator(clk, reset_clk, clk_50m);
    input wire clk, reset_clk;
    output wire clk_50m;
    reg [1:0] counter; 
    reg clk_reg;
    wire clk_next;
    
    always @(posedge clk, posedge reset_clk)
          if (reset_clk)
             begin
                clk_reg <= 1'b0;
             end
          else
             begin
                clk_reg <= clk_next;
             end
    
       assign clk_next = ~clk_reg;
       assign clk_50m = clk_reg;
endmodule

module clk1_gen(clk, reset, clk1);
   input wire clk;
   input wire reset;
   output reg clk1;

   reg [26:0] counter1;

   always @(posedge clk) begin
      if (reset) begin
         counter1 <= 0;
         clk1 <= 0;
      end else begin
         if (counter1 == 49999999) begin
            clk1 <= ~clk1;
            counter1 <= 0;
         end else begin
            counter1 <= counter1 + 1;
         end
      end
   end
endmodule

module pong_graph_animate
(
    input clk, reset, clk1,
    input wire video_on,
    input wire [2:0] btn,
    input wire [9:0] pix_x, pix_y,
    output reg [11:0] graph_rgb,
    output reg playSound
);

// X,Y coordinates (0,0) to (639, 479)
localparam MAX_X = 640;
localparam MAX_Y = 480;
wire refr_tick;


//----------------------------------------------------------------
// End Line for Enemy Spaceships
//----------------------------------------------------------------
localparam WALL_Y_T = 428;
localparam WALL_Y_B = 430;


//----------------------------------------------------------------
// Main Space Ship
//----------------------------------------------------------------

localparam space_y_t = 440;
localparam space_y_b = 470;

wire [9:0] space_x_l, space_x_r;
localparam space_x_size = 30;

reg [9:0] space_x_reg, space_x_next;

localparam space_v = 2;



//----------------------------------------------------------------
// Bullet
//----------------------------------------------------------------
localparam BALL_SIZE = 6;

// ball top, bottom boundary
wire [9:0] ball_y_t, ball_y_b;

//ball left, right boundary
wire [9:0] ball_x_l, ball_x_r;

//reg to track left, top position
reg[9:0] ball_y_reg, ball_x_reg;
reg[9:0] ball_y_next, ball_x_next;

//reg to track ball speed
reg [9:0] y_delta_reg, y_delta_next;

reg [1:0] ball_active;



//----------------------------------------------------------------
// Enemy Targets 1
//----------------------------------------------------------------
wire [9:0] e1_t, e2_t, e3_t, e4_t, e5_t, e6_t, e7_t, e8_t, e9_t, e10_t, e11_t, e12_t, e13_t ,e14_t, e15_t,
           e1_b, e2_b, e3_b, e4_b, e5_b, e6_b, e7_b, e8_b, e9_b, e10_b, e11_b, e12_b, e13_b ,e14_b, e15_b;

localparam e1_l = 101;
localparam e2_l = 207;
localparam e3_l = 313;
localparam e4_l = 419;
localparam e5_l = 525;
localparam e6_l = 101;
localparam e7_l = 207;
localparam e8_l = 313;
localparam e9_l = 419;
localparam e10_l = 525;
localparam e11_l = 101;
localparam e12_l = 207;
localparam e13_l = 313;
localparam e14_l = 419;
localparam e15_l = 525;

localparam e1_r = 111;
localparam e2_r = 217;
localparam e3_r = 323;
localparam e4_r = 429;
localparam e5_r = 535;
localparam e6_r = 111;
localparam e7_r = 217;
localparam e8_r = 323;
localparam e9_r = 429;
localparam e10_r = 535;
localparam e11_r = 111;
localparam e12_r = 217;
localparam e13_r = 323;
localparam e14_r = 429;
localparam e15_r = 535;

localparam e_size = 10;

//boundaries for each row as X position is stationary
reg [9:0] e1_y_reg, e1_y_next, 
          e2_y_reg, e2_y_next, 
          e3_y_reg, e3_y_next,
          e4_y_reg, e4_y_next, 
          e5_y_reg, e5_y_next, 
          e6_y_reg, e6_y_next,
          e7_y_reg, e7_y_next, 
          e8_y_reg, e8_y_next, 
          e9_y_reg, e9_y_next,
          e10_y_reg, e10_y_next, 
          e11_y_reg, e11_y_next, 
          e12_y_reg, e12_y_next,
          e13_y_reg, e13_y_next, 
          e14_y_reg, e14_y_next, 
          e15_y_reg, e15_y_next;

localparam e_v = 2;

reg [1:0] e1_destroy,
          e2_destroy,
          e3_destroy,
          e4_destroy,
          e5_destroy,
          e6_destroy,
          e7_destroy,
          e8_destroy,
          e9_destroy,
          e10_destroy,
          e11_destroy,
          e12_destroy,
          e13_destroy,
          e14_destroy,
          e15_destroy;



//----------------------------------------------------------------
// object output signals
//----------------------------------------------------------------
wire wall_on, space_on, sq_ball_on;
wire e1_on, e2_on, e3_on, e4_on, e5_on, e6_on, e7_on, e8_on, e9_on, e10_on, e11_on, e12_on, e13_on ,e14_on, e15_on;
wire [11:0] wall_rgb, space_rgb, ball_rgb, e1_rgb, e2_rgb, e3_rgb;


//----------------------------------------------------------------
// Body
//----------------------------------------------------------------
//register
always @(posedge clk, posedge reset)
        if (reset) begin
            space_x_reg <= 0;
            ball_x_reg <= 10'b1100;
            ball_y_reg <= 10'b0110110010;
            y_delta_reg <= 10'h005;
            ball_active <= 0;
        end
        else
            begin
                space_x_reg <= space_x_next;
                ball_x_reg <= ball_x_next;
                ball_y_reg <= ball_y_next;
                y_delta_reg <= 10'h005;
            end

//register for enemy on different time
always @(posedge clk1, posedge reset)
         if (reset) begin
            e1_y_reg <= 10'b10101010;
            e2_y_reg <= 10'b10101010;
            e3_y_reg <= 10'b10101010;
            e4_y_reg <= 10'b10101010;
            e5_y_reg <= 10'b10101010;
            e6_y_reg <= 10'b1101110;
            e7_y_reg <= 10'b1101110;
            e8_y_reg <= 10'b1101110;
            e9_y_reg <= 10'b1101110;
            e10_y_reg <= 10'b1101110;
            e11_y_reg <= 10'b110010;
            e12_y_reg <= 10'b110010;
            e13_y_reg <= 10'b110010;
            e14_y_reg <= 10'b110010;
            e15_y_reg <= 10'b110010;
            e1_destroy = 0;
            e2_destroy = 0;
            e3_destroy = 0;
            e4_destroy = 0;
            e5_destroy = 0;
            e6_destroy = 0;
            e7_destroy = 0;
            e8_destroy = 0;
            e9_destroy = 0;
            e10_destroy = 0;
            e11_destroy = 0;
            e12_destroy = 0;
            e13_destroy = 0;
            e14_destroy = 0;
            e15_destroy = 0;
         end
         else if (e1_destroy != 1 &&
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )
            begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
            end
            else if (e1_destroy <= 1  &&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b11111;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
             else if (e2_destroy <= 1 &&                 
                  e1_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b11111;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e3_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e1_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b11111;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e4_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e1_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b11111;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
             else if (e5_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e1_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b11111;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e6_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e1_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b11111;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e7_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e1_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b11111;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e8_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e1_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b11111;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
             else if (e9_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e1_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b11111;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e10_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e1_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b11111;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e11_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e1_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b11111;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e12_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e1_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b11111;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e13_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e1_destroy != 1 &&
                  e14_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b11111;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b1;
                end
             else if (e14_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e1_destroy != 1 &&
                  e15_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b11111;
                e15_y_reg <= e15_y_next + 10'b1;
                end
              else if (e15_destroy <= 1&&                 
                  e2_destroy != 1 &&
                  e3_destroy != 1 &&
                  e4_destroy != 1 &&
                  e5_destroy != 1 &&
                  e6_destroy != 1 &&
                  e7_destroy != 1 &&
                  e8_destroy != 1 &&
                  e9_destroy != 1 &&
                  e10_destroy != 1 &&
                  e11_destroy != 1 &&
                  e12_destroy != 1 &&
                  e13_destroy != 1 &&
                  e14_destroy != 1 &&
                  e1_destroy != 1 )begin
                e1_y_reg <= e1_y_next + 10'b1;
                e2_y_reg <= e2_y_next + 10'b1;
                e3_y_reg <= e3_y_next + 10'b1;
                e4_y_reg <= e4_y_next + 10'b1;
                e5_y_reg <= e5_y_next + 10'b1;
                e6_y_reg <= e6_y_next + 10'b1;
                e7_y_reg <= e7_y_next + 10'b1;
                e8_y_reg <= e8_y_next + 10'b1;
                e9_y_reg <= e9_y_next + 10'b1;
                e10_y_reg <= e10_y_next + 10'b1;
                e11_y_reg <= e11_y_next + 10'b1;
                e12_y_reg <= e12_y_next + 10'b1;
                e13_y_reg <= e13_y_next + 10'b1;
                e14_y_reg <= e14_y_next + 10'b1;
                e15_y_reg <= e15_y_next + 10'b11111;
                end

//refr_tick: 1-clock tick asserted at the start of v-sync
//          i.e. when the screen is refreshed (60hz)
    assign refr_tick = (pix_x==481) && (pix_y==0);



//----------------------------------------------------------------
// Wall Finish line for enemy
//----------------------------------------------------------------
// pixel within wall
assign wall_on = (WALL_Y_T <= pix_y) && (pix_y <= WALL_Y_B);

//wall rgb output
assign wall_rgb = 12'b111100000000; // RED





//----------------------------------------------------------------
// space ship
//----------------------------------------------------------------
assign space_x_l = space_x_reg;
assign space_x_r = space_x_l + space_x_size - 1;
// pixel within space ship
assign space_on = (space_y_t <= pix_y) && (pix_y <= space_y_b) &&
                  (space_x_l <= pix_x) && (pix_x <= space_x_r);
// space rgb output
assign space_rgb = 12'b000011110000; //Green
// new spaceship x-position
always @*
begin
    space_x_next = space_x_reg;
    if (refr_tick)
        if(btn[1] & (space_x_r < (MAX_X -1 -space_v)))
            space_x_next = space_x_reg + space_v;   //move to right
        else if (btn[0] & (space_x_l > space_v))
            space_x_next = space_x_reg - space_v;   //move to left
end


//----------------------------------------------------------------
// Enemy 
//----------------------------------------------------------------
assign e1_t = e1_y_reg; assign e2_t = e2_y_reg; assign e3_t = e3_y_reg; assign e4_t = e4_y_reg; assign e5_t = e5_y_reg;
assign e6_t = e6_y_reg; assign e7_t = e7_y_reg; assign e8_t = e8_y_reg; assign e9_t = e9_y_reg; assign e10_t = e10_y_reg;
assign e11_t = e11_y_reg; assign e12_t = e12_y_reg; assign e13_t = e13_y_reg; assign e14_t = e14_y_reg; assign e15_t = e15_y_reg; 
assign e1_b = e1_t + e_size - 1; assign e2_b = e2_t + e_size - 1; assign e3_b = e3_t + e_size - 1; assign e4_b = e4_t + e_size - 1; assign e5_b = e5_t + e_size - 1;
assign e6_b = e6_t + e_size - 1; assign e7_b = e7_t + e_size - 1; assign e8_b = e8_t + e_size - 1; assign e9_b = e9_t + e_size - 1; assign e10_b = e10_t + e_size - 1;
assign e11_b = e11_t + e_size - 1; assign e12_b = e12_t + e_size - 1; assign e13_b = e13_t + e_size - 1; assign e14_b = e14_t + e_size - 1; assign e15_b = e15_t + e_size - 1;
// pixel within enemy
assign e1_on = (e1_t <= pix_y) && (pix_y <= e1_b) && (e1_l <= pix_x) && (pix_x <= e1_r);
assign e2_on = (e2_t <= pix_y) && (pix_y <= e2_b) && (e2_l <= pix_x) && (pix_x <= e2_r);
assign e3_on = (e3_t <= pix_y) && (pix_y <= e3_b) && (e3_l <= pix_x) && (pix_x <= e3_r);
assign e4_on = (e4_t <= pix_y) && (pix_y <= e4_b) && (e4_l <= pix_x) && (pix_x <= e4_r);
assign e5_on = (e5_t <= pix_y) && (pix_y <= e5_b) && (e5_l <= pix_x) && (pix_x <= e5_r);
assign e6_on = (e6_t <= pix_y) && (pix_y <= e6_b) && (e6_l <= pix_x) && (pix_x <= e6_r);
assign e7_on = (e7_t <= pix_y) && (pix_y <= e7_b) && (e7_l <= pix_x) && (pix_x <= e7_r);
assign e8_on = (e8_t <= pix_y) && (pix_y <= e8_b) && (e8_l <= pix_x) && (pix_x <= e8_r);
assign e9_on = (e9_t <= pix_y) && (pix_y <= e9_b) && (e9_l <= pix_x) && (pix_x <= e9_r);
assign e10_on = (e10_t <= pix_y) && (pix_y <= e10_b) && (e10_l <= pix_x) && (pix_x <= e10_r);
assign e11_on = (e11_t <= pix_y) && (pix_y <= e11_b) && (e11_l <= pix_x) && (pix_x <= e11_r);
assign e12_on = (e12_t <= pix_y) && (pix_y <= e12_b) && (e12_l <= pix_x) && (pix_x <= e12_r);
assign e13_on = (e13_t <= pix_y) && (pix_y <= e13_b) && (e13_l <= pix_x) && (pix_x <= e13_r);
assign e14_on = (e14_t <= pix_y) && (pix_y <= e14_b) && (e14_l <= pix_x) && (pix_x <= e14_r);
assign e15_on = (e15_t <= pix_y) && (pix_y <= e15_b) && (e15_l <= pix_x) && (pix_x <= e15_r);

assign e1_rgb = 12'b000000001111; // blue
assign e2_rgb = 12'b000011111111; // light blue
assign e3_rgb = 12'b100110011111; // light purple

// new enemy y-position
always @*
begin
    e1_y_next = e1_y_reg;
    e2_y_next = e2_y_reg;
    e3_y_next = e3_y_reg;
    e4_y_next = e4_y_reg;
    e5_y_next = e5_y_reg;
    e6_y_next = e6_y_reg;
    e7_y_next = e7_y_reg;
    e8_y_next = e8_y_reg;
    e9_y_next = e9_y_reg;
    e10_y_next = e10_y_reg;
    e11_y_next = e11_y_reg;
    e12_y_next = e12_y_reg;
    e13_y_next = e13_y_reg;
    e14_y_next = e14_y_reg;
    e15_y_next = e15_y_reg;
end




//----------------------------------------------------------------
// bullet
//----------------------------------------------------------------
assign ball_x_l = ball_x_reg;
assign ball_x_r = ball_x_l + BALL_SIZE - 1;
assign ball_y_t = ball_y_reg;
assign ball_y_b = ball_y_t + BALL_SIZE -1;
//pixel within bullet
assign sq_ball_on = (ball_y_t<=pix_y) && (pix_y<=ball_y_b) &&
                    (ball_x_l<=pix_x) && (pix_x<=ball_x_r);
// bullet rgb output
assign ball_rgb = 12'b000000000000; //black
// new bullet x-position
always @*
begin 
    ball_x_next = ball_x_reg;
    if (refr_tick)
        if(btn[1] & (space_x_r < (MAX_X -1 -space_v)))
            ball_x_next = ball_x_reg + space_v; //bullet move to right
        else if (btn[0] & (space_x_l > space_v))
            ball_x_next = ball_x_reg - space_v; //bullet move to left
end

// When button is pressed to fire bullet
always @*
begin
   ball_y_next = ball_y_reg;
   if (refr_tick)
      if (btn[2] && (ball_y_t > space_v) && 
      ((ball_y_t != e1_b) && (ball_x_l != e1_r) && (ball_x_r != e1_l)) &&
      ((ball_y_t != e2_b) && (ball_x_l != e2_r) && (ball_x_r != e2_l)) &&
      ((ball_y_t != e3_b) && (ball_x_l != e3_r) && (ball_x_r != e3_l)) &&
      ((ball_y_t != e4_b) && (ball_x_l != e4_r) && (ball_x_r != e4_l)) &&
      ((ball_y_t != e5_b) && (ball_x_l != e5_r) && (ball_x_r != e5_l)) &&
      ((ball_y_t != e6_b) && (ball_x_l != e6_r) && (ball_x_r != e6_l)) &&
      ((ball_y_t != e7_b) && (ball_x_l != e7_r) && (ball_x_r != e7_l)) &&
      ((ball_y_t != e8_b) && (ball_x_l != e8_r) && (ball_x_r != e8_l)) &&
      ((ball_y_t != e9_b) && (ball_x_l != e9_r) && (ball_x_r != e9_l)) &&
      ((ball_y_t != e10_b) && (ball_x_l != e10_r) && (ball_x_r != e10_l)) &&
      ((ball_y_t != e11_b) && (ball_x_l != e11_r) && (ball_x_r != e11_l)) &&
      ((ball_y_t != e12_b) && (ball_x_l != e12_r) && (ball_x_r != e12_l)) &&
      ((ball_y_t != e13_b) && (ball_x_l != e13_r) && (ball_x_r != e13_l)) &&
      ((ball_y_t != e14_b) && (ball_x_l != e14_r) && (ball_x_r != e14_l)) &&
      ((ball_y_t != e15_b) && (ball_x_l != e15_r) && (ball_x_r != e15_l)))
      begin
         ball_y_next = ball_y_reg - BALL_SIZE;
         playSound = 1;
      end
// if bullet is released early then reset to original position
      else if (ball_y_next > space_v) begin
         ball_y_next = space_y_t - BALL_SIZE;
         playSound = 0;
      end
// if bullet reaches the top reset to original location
      else if (ball_y_next <= space_v || 
               ((ball_y_next <= e1_b) && (ball_x_l <= e1_r) && (ball_x_r <= e1_l))|| 
               ((ball_y_next <= e2_b) && (ball_x_l <= e2_r) && (ball_x_r <= e2_l))|| 
               ((ball_y_next <= e3_b) && (ball_x_l <= e3_r) && (ball_x_r <= e3_l))|| 
               ((ball_y_next <= e4_b) && (ball_x_l <= e4_r) && (ball_x_r <= e4_l))||  
               ((ball_y_next <= e5_b) && (ball_x_l <= e5_r) && (ball_x_r <= e5_l))|| 
               ((ball_y_next <= e6_b) && (ball_x_l <= e6_r) && (ball_x_r <= e6_l))|| 
               ((ball_y_next <= e7_b) && (ball_x_l <= e7_r) && (ball_x_r <= e7_l))|| 
               ((ball_y_next <= e8_b) && (ball_x_l <= e8_r) && (ball_x_r <= e8_l))|| 
               ((ball_y_next <= e9_b) && (ball_x_l <= e9_r) && (ball_x_r <= e9_l))|| 
               ((ball_y_next <= e10_b) && (ball_x_l <= e10_r) && (ball_x_r <= e10_l))|| 
               ((ball_y_next <= e11_b) && (ball_x_l <= e11_r) && (ball_x_r <= e11_l))||  
               ((ball_y_next <= e12_b) && (ball_x_l <= e12_r) && (ball_x_r <= e12_l))||  
               ((ball_y_next <= e13_b) && (ball_x_l <= e13_r) && (ball_x_r <= e13_l))|| 
               ((ball_y_next <= e14_b) && (ball_x_l <= e14_r) && (ball_x_r <= e14_l))|| 
               ((ball_y_next <= e15_b) && (ball_x_l <= e15_r) && (ball_x_r <= e15_l))) 
               begin
         ball_y_next = space_y_t - BALL_SIZE;
         playSound = 0;
            if (ball_y_next <= e1_b)
               e1_destroy = 1;
            else if (ball_y_next <= e2_b)
               e2_destroy = 1;
            else if (ball_y_next <= e3_b)
               e3_destroy = 1;
            else if (ball_y_next <= e4_b)
               e4_destroy = 1;
            else if (ball_y_next <= e5_b)
               e5_destroy = 1;
            else if (ball_y_next <= e6_b)
               e6_destroy = 1;
            else if (ball_y_next <= e7_b)
               e7_destroy = 1;
            else if (ball_y_next <= e8_b)
               e8_destroy = 1;
            else if (ball_y_next <= e9_b)
               e9_destroy = 1;
            else if (ball_y_next <= e10_b)
               e10_destroy = 1;
            else if (ball_y_next <= e11_b)
               e11_destroy = 1;
            else if (ball_y_next <= e12_b)
               e12_destroy = 1;
            else if (ball_y_next <= e13_b)
               e13_destroy = 1;
            else if (ball_y_next <= e14_b)
               e14_destroy = 1;
            else if (ball_y_next <= e15_b)
               e15_destroy = 1;
      end
end


   //--------------------------------------------
   // rgb multiplexing circuit
   //--------------------------------------------
   always @*
      if (~video_on)
         graph_rgb = 12'b000000000000; // blank
      else
         if (wall_on)
            graph_rgb = wall_rgb;
         else if (space_on)
            graph_rgb = space_rgb;
         else if (sq_ball_on)
            graph_rgb = ball_rgb;
         else if (e1_on)
            graph_rgb = e1_rgb;
         else if (e2_on)
            graph_rgb = e1_rgb;
         else if (e3_on)
            graph_rgb = e1_rgb;
         else if (e4_on)
            graph_rgb = e1_rgb;
         else if (e5_on)
            graph_rgb = e1_rgb;
         else if (e6_on)
            graph_rgb = e2_rgb;
         else if (e7_on)
            graph_rgb = e2_rgb;
         else if (e8_on)
            graph_rgb = e2_rgb;
         else if (e9_on)
            graph_rgb = e2_rgb;
         else if (e10_on)         
            graph_rgb = e2_rgb;
         else if (e11_on)
            graph_rgb = e3_rgb;
         else if (e12_on)
            graph_rgb = e3_rgb;
         else if (e13_on)         
            graph_rgb = e3_rgb;
         else if (e14_on)
            graph_rgb = e3_rgb;
         else if (e15_on)         
            graph_rgb = e3_rgb;
         else
            graph_rgb = 12'b111111111111; // white background

endmodule

module vga_sync
   (
    input wire clk, reset,
    output wire hsync, vsync, video_on, p_tick,
    output wire [9:0] pixel_x, pixel_y
   );

   // constant declaration
   // VGA 640-by-480 sync parameters
   localparam HD = 640; // horizontal display area
   localparam HF = 48 ; // h. front (left) border
   localparam HB = 16 ; // h. back (right) border
   localparam HR = 96 ; // h. retrace
   localparam VD = 480; // vertical display area
   localparam VF = 10;  // v. front (top) border
   localparam VB = 29;  // v. back (bottom) border
   localparam VR = 2;   // v. retrace

   // mod-2 counter creates the pixel tick
   reg mod2_reg;
   wire mod2_next;
   // sync counters
   reg [9:0] h_count_reg, h_count_next;
   reg [9:0] v_count_reg, v_count_next;
   // output buffer
   reg v_sync_reg, h_sync_reg;
   wire v_sync_next, h_sync_next;
   // status signal
   wire h_end, v_end, pixel_tick;

   // body
   // registers
   always @(posedge clk, posedge reset)
      if (reset)
         begin
            mod2_reg <= 1'b0;
            v_count_reg <= 0;
            h_count_reg <= 0;
            v_sync_reg <= 1'b0;
            h_sync_reg <= 1'b0;
         end
      else
         begin
            mod2_reg <= mod2_next;
            v_count_reg <= v_count_next;
            h_count_reg <= h_count_next;
            v_sync_reg <= v_sync_next;
            h_sync_reg <= h_sync_next;
         end

   // mod-2 circuit to generate 25 MHz enable tick
   assign mod2_next = ~mod2_reg;
   assign pixel_tick = mod2_reg;

   // status signals
   // end of horizontal counter (799)
   assign h_end = (h_count_reg==(HD+HF+HB+HR-1));
   // end of vertical counter (524)
   assign v_end = (v_count_reg==(VD+VF+VB+VR-1));

   // next-state logic of mod-800 horizontal sync counter
   always @*
      if (pixel_tick)  // 25 MHz pulse
         if (h_end)
            h_count_next = 0;
         else
            h_count_next = h_count_reg + 1;
      else
         h_count_next = h_count_reg;

   // next-state logic of mod-525 vertical sync counter
   always @*
      if (pixel_tick & h_end)
         if (v_end)
            v_count_next = 0;
         else
            v_count_next = v_count_reg + 1;
      else
         v_count_next = v_count_reg;

   // horizontal and vertical sync, buffered to avoid glitch
   // h_sync_next asserted between 656 and 751
   assign h_sync_next = (h_count_reg>=(HD+HB) &&
                         h_count_reg<=(HD+HB+HR-1));
   // vh_sync_next asserted between 490 and 491
   assign v_sync_next = (v_count_reg>=(VD+VB) &&
                         v_count_reg<=(VD+VB+VR-1));

   // video on/off
   assign video_on = (h_count_reg<HD) && (v_count_reg<VD);

   // output
   assign hsync = h_sync_reg;
   assign vsync = v_sync_reg;
   assign pixel_x = h_count_reg;
   assign pixel_y = v_count_reg;
   assign p_tick = pixel_tick;
endmodule


// Song Player Module
module SongPlayer(input clk, input playSound, output reg audioOut, output wire aud_sd);
    reg [19:0] counter3;
    reg [31:0] time1, noteTime;
    reg [9:0] msec, number; // millisecond counter, and sequence number of musical note.
    wire [4:0] duration;
    wire [19:0] notePeriod;
    parameter clockFrequency = 100_000_000;

    assign aud_sd = 1'b1;
    bang mysong(number, notePeriod, duration);
    
    always @(posedge clk) begin
        if (~playSound) begin
            counter3 <= 0;
            time1 <= 0;
            number <= 0;
            audioOut <= 1;
        end else begin
            counter3 <= counter3 + 1;
            time1 <= time1 + 1;
            if (counter3 >= notePeriod) begin
                counter3 <= 0;
                audioOut <= ~audioOut; // toggle audio output
            end // toggle audio output
            if (time1 >= noteTime) begin
                time1 <= 0;
                number <= number + 1; // play next note
            end 
            if (number == 1) number <= 0; // Make the number reset at the end of the song
        end
    end

    always @(duration) noteTime = duration * clockFrequency / 8; // number of FPGA clock periods in one note.
endmodule

module bang( input [9:0] number, 
	output reg [19:0] note, 
	output reg [4:0] duration);
parameter   EIGHTH = 5'b00001; // Added in for quicker times
parameter   QUARTER = 5'b00010; 
parameter	HALF = 5'b00100;
parameter	ONE = 2* HALF;
parameter	TWO = 2* ONE;
parameter	FOUR = 2* TWO;
parameter   C3 = 382234,
            D3 = 340530,
            D3S = 321419,
            F3 = 286352,
            G3 = 255102,
            G3S  = 240790,
            A3 = 227273,
            A3S = 214519,
            B3 = 202478,
            
            C4 = 191111,
            C4S = 180388,
            D4 = 170265,
            D4S = 160705,
            E4 = 151685,
            F4 = 143172,
            F4S = 135139,
            G4S  = 120395,
            A4 = 113636,
            A4S = 107259,
            SP = 1;
// All of this was put in for messing with pitch
always @ (number) begin
case(number) //Mario Underground theme
0: begin note = C3; duration = ONE;
end
endcase
end
endmodule