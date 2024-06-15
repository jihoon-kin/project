`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/15 15:22:10
// Design Name: 
// Module Name: multi_fan_cntr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

///////////////////////선풍기 팀프로젝트 완성/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module led_brightness( //pull-up 저항으로 하자
    input clk, reset_p,
    input btn,
    output reg led_pwm_o
);

    wire [1:0]led_pwm;
    reg [27:0] clk_div = 0;
    always@(posedge clk) clk_div =clk_div+1;
    
    pwm_100pc_sf led0(.clk(clk), //1단
              .reset_p(reset_p),
              .duty(50),
              .pwm_freq(1_000_000),
              .pwm_100pc(led_pwm[0])
              );
              
    pwm_100pc_sf led1(.clk(clk), //2단
              .reset_p(reset_p),
              .duty(90),
              .pwm_freq(1_000_000),
              .pwm_100pc(led_pwm[1])
              );
    
    wire btn_pedge;        
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge));         
            
    reg [1:0]cnt_btn; //0,1,2,3 -> 꺼짐, 1,2,3단계 밝기        
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_btn =0;
        end
        else if(btn_pedge) begin
            cnt_btn= cnt_btn+1;    
        end        
    end        
              
    always@(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            led_pwm_o =0;
        end
        else begin
            case(cnt_btn)
                2'b00: begin led_pwm_o = 0; end
                2'b01: begin led_pwm_o = led_pwm[0]; end
                2'b10: begin led_pwm_o = led_pwm[1]; end
                2'b11: begin led_pwm_o = 1; end
            endcase
        end    
    end
    
endmodule

module dc_motor_speed( 
    input clk, reset_p,
    input btn,
    input motor_off,
    input [11:0]distance,
    output reg motor_pwm_o,
    output reg [2:0]motor_led,
    output reg motor_sw
);
    wire [1:0]motor_pwm;
    reg [27:0] clk_div = 0;
    always@(posedge clk) clk_div =clk_div+1;
    
    pwm_100pc_sf led0(.clk(clk), //1단
              .reset_p(reset_p),
              .duty(25),
              .pwm_freq(1_00),
              .pwm_100pc(motor_pwm[0])
              );
              
    pwm_100pc_sf led1(.clk(clk), //2단
              .reset_p(reset_p),
              .duty(45),
              .pwm_freq(1_00),
              .pwm_100pc(motor_pwm[1])
              );
    wire btn_pedge;        
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge));         
            
    reg [1:0]cnt_btn; //0,1,2,3 -> 꺼짐, 1,2,3단계 밝기        
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_btn =0;
        end
        else if(btn_pedge) begin cnt_btn= cnt_btn+1; end
        else if(motor_off) begin cnt_btn=0; end 
        else if(distance>=11'h20) begin cnt_btn = 0; end
    end        
              
    always@(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            motor_pwm_o =0;
            motor_sw = 0;
        end
        else begin
            case(cnt_btn)
                2'b00: begin motor_pwm_o = 0;               motor_sw =0;      motor_led=3'b000; end
                2'b01: begin motor_pwm_o = motor_pwm[0];    motor_sw =1;      motor_led=3'b001; end
                2'b10: begin motor_pwm_o = motor_pwm[1];    motor_sw =1;      motor_led=3'b010; end
                2'b11: begin motor_pwm_o = 1;               motor_sw =1;      motor_led=3'b100; end
            endcase
        end    
    end
   
endmodule


module fan_timer(   //타이머
    input clk, reset_p,
    input btn_str,
    input motor_sw,
    output reg motor_off,
    output [3:0]com,
    output [7:0]seg_7,
    output reg [2:0]timer_led
    );
    wire btn_str_pedge, btn_str_nedge, btn_sw;
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn_sw), .btn_pe(btn_str_pedge), .btn_ne(btn_str_nedge));
    
    assign btn_sw = motor_sw ? btn_str : 0;
    
    wire btn_start, inc_sec, inc_min, alarm_off; //버튼 0번 1번 2번 3번
    wire [3:0] set_sec1, set_sec10, set_min1, set_min10;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10;
    wire load_enable, dec_clk, clk_start; //clk_start : start했을 때만 클럭이 나오도록 함
    reg start_stop;
    wire [16:0]cur_time,cur_time_1;
    wire [15:0]set_time;
    wire timeout_pedge;
    reg time_out;
    reg motor_e;
    
    assign clk_start = start_stop ?  clk : 0;
    
    clock_usec usec_clk(clk_start, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk_start,reset_p,clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk_start,reset_p,clk_msec, clk_sec);
    
    reg [1:0]setting_state;
    reg [2:0]setting_time;
    
    always@(posedge clk or posedge reset_p) begin //1->3->5분->타이머 해제
        if(reset_p) begin
            setting_time=0;
            timer_led =0;
        end
        else begin
            case(setting_state)
                2'b00: begin setting_time=0; timer_led = 3'b000; motor_e = 1; end
                2'b01: begin setting_time=1; timer_led = 3'b001; motor_e = 0; end
                2'b10: begin setting_time=3; timer_led = 3'b010; motor_e = 0; end
                2'b11: begin setting_time=5; timer_led = 3'b100; motor_e = 0; end
            endcase
         end
    end
    
    always@(posedge clk or posedge reset_p) begin
        if(reset_p) setting_state=0;
        else if(btn_str_pedge) setting_state = setting_state + 1;
        else if(timeout_pedge) setting_state = 2'b00;
    end
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) time_out =0;
        else begin
            if(start_stop &&clk_msec && cur_time ==0) time_out = 1;
            else  time_out = 0;
        end
    end
    
    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(time_out), .p_edge(timeout_pedge));
    
    always @ (posedge clk or posedge reset_p)begin
         if(reset_p) begin
             start_stop = 0;
             motor_off = 0 ;
         end
         else begin
         if(btn_str_pedge) start_stop = 0;
         else if (btn_str_nedge) start_stop = 1; //start or stop
         else if(timeout_pedge) begin
             start_stop = 0;
             motor_off = 1;
         end
         else motor_off = 0;
         end
     end
     
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(start_stop), .p_edge(load_enable));
    loadable_downcounter_dec_60_fan cur_sec(.clk(clk),
                                            .reset_p(reset_p),
                                            .clk_time(clk_sec),
                                            .load_enable(load_enable),
                                            .dec1(cur_sec1),
                                            .dec10(cur_sec10),
                                            .dec_clk(dec_clk));
                                            
    loadable_downcounter_dec_60_fan cur_min(.clk(clk),
                                            .reset_p(reset_p),
                                            .clk_time(dec_clk),
                                            .load_enable(load_enable),
                                            .set_value1(setting_time),
                                            .dec1(cur_min1),
                                            .dec10(0));
    wire [16:0]value;
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1, motor_e};
    assign cur_time_1 = setting_time ? cur_time : 0;
    assign value = start_stop ? cur_time_1 : 0;
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value[16:1]), .seg_7_an(seg_7), .com(com));
    
endmodule

/////////////////UltraSonic 초음파센서
module ultra_sonic_prof(
    input clk, reset_p,
    input echo, 
    output reg trigger,
    output reg [11:0] distance
);
    
    parameter S_IDLE    = 3'b001;
    parameter TRI_10US  = 3'b010;
    parameter ECHO_STATE= 3'b100;
    
    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;
    
    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end
    wire echo_pedge, echo_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(echo), .p_edge(echo_pedge), .n_edge(echo_nedge));
    
    reg [11:0] echo_time;
    reg [3:0] state, next_state;
    reg [1:0] read_state;
    
       reg cnt_e;
       wire [11:0] cm;
       sr04_div58 div58(clk, reset_p, clk_usec, cnt_e, cm);

    always @(negedge clk or posedge reset_p)begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
    always @(posedge clk or posedge reset_p)begin  
        if(reset_p)begin
            count_usec_e = 0;
            next_state = S_IDLE;
            trigger = 0;
            read_state = S_WAIT_PEDGE;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd100_000)begin 
                        count_usec_e = 1; 
                    end
                    else begin 
                        next_state = TRI_10US;
                        count_usec_e = 0; 
                    end
                end
                TRI_10US:begin 
                    if(count_usec <= 22'd10)begin 
                        count_usec_e = 1;
                        trigger = 1;
                    end
                    else begin
                        count_usec_e = 0;
                        trigger = 0;
                        next_state = ECHO_STATE;
                    end
                end
                ECHO_STATE:begin 
                    case(read_state)
                        S_WAIT_PEDGE:begin
                            count_usec_e = 0;
                            if(echo_pedge)begin
                                read_state = S_WAIT_NEDGE;
                                cnt_e = 1;  //추가
                            end
                        end
                        S_WAIT_NEDGE:begin
                            if(echo_nedge)begin       
                                read_state = S_WAIT_PEDGE;
                                count_usec_e = 0;                    
                                distance = cm;  //추가
                                    
                                cnt_e =0;       //추가
                                next_state = S_IDLE;
                            end
                            else begin
                                count_usec_e = 1;
                            end
                        end
                    endcase
                end
                default:next_state = S_IDLE;
            endcase
        end
    end
endmodule

module servomotor(
    input clk, reset_p,
    input btn_str,
    input motor_sw,
    output sg90
);
    wire btn_pedge;
    
    button_cntr btn_cntr(.clk(clk), .reset_p(reset_p), .btn(btn_str), .btn_pe(btn_pedge));
    
    reg turn_on;

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)turn_on = 0;
        else if(btn_pedge)     begin turn_on = turn_on + 1; end
        else if(motor_sw == 0) begin turn_on = 0; end
    end
    
    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    wire clk_div_pedge;
    edge_detector_n ed0(.clk(clk), .reset_p(reset_p), .cp(clk_div[22]), .p_edge(clk_div_pedge));
    
    reg [8:0] duty;
    reg up_down;
   
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            duty = 14;
            up_down = 1;
        end
        else if(motor_sw)begin 
            if(turn_on)begin
                if(clk_div_pedge)begin
                    if(duty >= 70)up_down = 0;
                    else if(duty <= 8)up_down = 1;
                        
                    if(up_down)duty = duty + 1;
                    else duty = duty - 1;
                end
            end
        end
    end

    pwm_512step servo0(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm_freq(50), .pwm_servo(sg90));

endmodule
