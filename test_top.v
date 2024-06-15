`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module keypad_test_top(
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] seg_7,
    output [3:0] com
    );
    //16비트 카운터를 추가하고 
    //key_valid 상승엣지에서 key_value가 1이면 1증가 key_value가 2면 1감소 카운터 값을 fnd에 출력하라
    wire [15:0] key_value;
    
    reg [15:0] key_counter;
    wire key_valid_pe;
    keypad_cntr_FSM key_pad(.clk(clk), .reset_p(reset_p), .row(row), .col(col), .key_value(key_value), .key_valid(key_valid));
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(key_valid), .p_edge(key_valid_pe));
    
   always @(posedge clk, posedge reset_p)begin 
        if(reset_p)key_counter = 0;
        else if(key_valid_pe)begin
            if(key_value == 1) key_counter = key_counter + 1;
            else if(key_value == 2) key_counter = key_counter - 1;
        end
    end
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(key_counter), .seg_7_ca(seg_7), .com(com));
    
endmodule

//////////////////////////////////
module button_test_top_2( // 교수님이 하신것 
    input clk, reset_p,
    input [3:0] btnU,
    output [7:0] seg_7,
    output [3:0] com
);

    reg [15:0] btn_counter;
    wire [3:0] btnU_pedge;
    
//    button_cntr btnU_cntr0(.clk(clk), .reset_p(reset_p), .btn(btnU[0]), .btn_pe(btnU_pedge[0]));
//    button_cntr btnU_cntr1(.clk(clk), .reset_p(reset_p), .btn(btnU[1]), .btn_pe(btnU_pedge[1]));
//    button_cntr btnU_cntr2(.clk(clk), .reset_p(reset_p), .btn(btnU[2]), .btn_pe(btnU_pedge[2]));
//    button_cntr btnU_cntr3(.clk(clk), .reset_p(reset_p), .btn(btnU[3]), .btn_pe(btnU_pedge[3]));
    
    genvar i; // 이 변수는 회로가 만들어지지 않는다. for문에 들어가는 변수로만 쓰임
    generate
        for (i=0;i<4;i=i+1)begin:btn_cntr //for(초기값, 반복을 위한 조건식, 한번 반복하고 다시 수행하는 조건식), 참 인 동안 계속 반복한다.
            button_cntr btn_inst(.clk(clk), .reset_p(reset_p), .btn(btnU[i]), .btn_pe(btnU_pedge[i])); // begin: 뒤에는 잼블럭의 이름을 정해준것
        end
    endgenerate//for = 반복문, 
    
    always @(posedge clk, posedge reset_p)begin 
        if(reset_p)btn_counter = 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if(btnU_pedge[1]) btn_counter = btn_counter - 1;
            else if(btnU_pedge[2]) btn_counter = {btn_counter[14:0], btn_counter[15]};
            else if(btnU_pedge[3]) btn_counter = {btn_counter[0], btn_counter[15:1]};
        end
    end
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(btn_counter), .seg_7_ca(seg_7), .com(com));
    
endmodule


/////////btn입력 FND seg7출력 회로
module button_ledbar_top(
    input clk, reset_p,
    input [3:0] btn,
    output [7:0] seg_7
);
    reg [7:0] btn_counter;
    wire [3:0]btnU_pedge;
    reg [16:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;
    wire clk_div_16;
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p),
        .cp(clk_div[16]), .p_edge(clk_div_16)
        );
    reg [3:0]debounced_btn;
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btn;
    end
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p),
        .cp(debounced_btn[0]), .p_edge(btnU_pedge[0])
        );
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p),
        .cp(debounced_btn[1]), .p_edge(btnU_pedge[1])
        );
     edge_detector_n ed4(.clk(clk), .reset_p(reset_p),
        .cp(debounced_btn[2]), .p_edge(btnU_pedge[2])
        );
     edge_detector_n ed5(.clk(clk), .reset_p(reset_p),
        .cp(debounced_btn[3]), .p_edge(btnU_pedge[3])
        );
    always @(posedge clk, posedge reset_p)begin
        if(reset_p)btn_counter = 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if(btnU_pedge[1]) btn_counter = btn_counter - 1;
            else if(btnU_pedge[2]) btn_counter = {btn_counter[6:0], btn_counter[7]};
            else if(btnU_pedge[3]) btn_counter = {btn_counter[0], btn_counter[7:1]};
        end
    end
    
    wire [7:0] seg_7_bar;
    decoder_7seg(.hex_value(btn_counter[3:0]), .seg_7(seg_7_bar));
    assign seg_7 = ~seg_7_bar;
    
endmodule

module watch_top( // 시간을 정확히 맞출 수 있는 시계
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7
);
    wire clk_usec, clk_msec, clk_sec, clk_min;
    reg sec, min;

//    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
    clock_usec usec_clk(clk, reset_p, clk_usec); //위에 있는거랑 같은거다 대신 모듈 입출력의 순서를 알아야한다.  
    
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    
    clock_min min_clk(clk, reset_p, sec, clk_min);
    
    // usec -> msec -> sec -> min 이렇게 순차적으로 세어서 한클락씩 만들어지는거다. 
    
    wire [3:0] sec1, sec10, min1, min10;
    
    wire [2:0]btn_pedge;
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    reg q;
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) begin q=0; end
        else begin
            if(btn_pedge[0]) q=~q;
            else q=q;
        end
    end    
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) begin sec=0; min=0; end
        else begin
            if (q) begin
                sec=btn_pedge[1];
                min=btn_pedge[2];
            end
            else begin
                sec=clk_sec;
                min=clk_min;
            end
        end
    end
    
    counter_dec_60 counter_sec(clk, reset_p,sec, sec1, sec10);
    counter_dec_60 counter_min(clk, reset_p,min, min1, min10);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({min10,min1,sec10,sec1}),
    .seg_7_an(seg_7), .com(com));
    
endmodule // edge detector에서 PDT가 발생하여 40ns 정도 오차가 발생한다. 우리가 잘모르기 때문에 상관 없다. 

// Clk을 갖다 쓸수있게 만든 모듈 하지만 시계를 만들때 Clk모듈을 한꺼번에 모아놓으면, 
// 내가 시간을 맞추고 싶을때 다시 분해하는 작업을 해야하기 때문에 시계만들때는 굳이 이렇게 하지마라.
// 지금은 시간이 조금남아서 하는거니 걍 해봐라.
module clk_top(
    input clk, reset_p,
    output clk_sec, clk_min
    );
    
    wire clk_usec, clk_msec;
    
    clock_usec usec_clk(clk, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, clk_sec, clk_min);
    
endmodule

////csec Clk 모듈
module csec_clk_top(
    input clk, reset_p,
    output clk_10msec, clk_sec
    );
    
    wire clk_usec, clk_msec;
    
    clock_usec usec_clk(clk, reset_p, clk_usec); 
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_10 _msec_clk(clk, reset_p, clk_msec, clk_10msec);
    clock_div_100 sec_clk(clk, reset_p, clk_10msec, clk_sec);
    
endmodule

//sec clk 모듈
module sec_clk_top(
    input clk, reset_p,
    output clk_sec
    );
    
    wire clk_usec, clk_msec;
    
    clock_usec usec_clk(clk, reset_p, clk_usec); 
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    
endmodule

///교수님이 하신것
module watch_top1( // 시간을 정확히 맞출 수 있는 시계
    input clk, reset_p,
    input [2:0] btn,
    input enable_w,
    output [3:0] com,
    output [7:0] seg_7
);
    wire clk_usec, clk_msec;
    wire clk_sec, clk_min;
    wire sec_edge, min_edge;
    wire [3:0] sec1, sec10, min1, min10;
    wire set_mode;
    wire [2:0] btn_pedge;
////    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
//    clock_usec usec_clk(clk, reset_p, clk_usec); //위에 있는거랑 같은거다 대신 모듈 입출력의 순서를 알아야한다.  
    
//    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    
//    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    
//    clock_min min_clk(clk, reset_p, sec_edge, clk_min);

    clk_top clk_top(clk, reset_p, sec_edge, clk_min);
    
    // usec -> msec -> sec -> min 이렇게 순차적으로 세어서 한클락씩 만들어지는거다. 
    
    counter_dec_60 counter_sec(clk, reset_p, sec_edge, sec1, sec10);
    counter_dec_60 counter_min(clk, reset_p, min_edge, min1, min10);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({min10, min1, sec10, sec1}), .seg_7_an(seg_7), .com(com));
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    
    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(set_mode));
    
    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    assign min_edge = set_mode ? btn_pedge[2] : clk_min;

endmodule // edge detector에서 PDT가 발생하여 40ns 정도 오차가 발생한다. 우리가 잘모르기 때문에 상관 없다. 

//우리가 다기능 시계를 만들었는데 watch, stop_watch, cook_timer 얘네가 fnd, btn_cntr 등이 다 들어가있어서 밖으로 빼서 하나만 쓰기위해 하는 것.
module loadable_watch(
    input clk, reset_p,
    input [2:0] btn_pedge,
    output [15:0] value
);
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire sec_edge, min_edge;
    wire set_mode;
    wire cur_time_load_en, set_time_load_en;
    wire [3:0] cur_sec1, cur_sec10, set_sec1, set_sec10;
    wire [3:0] cur_min1, cur_min10, set_min1, set_min10;
    wire [15:0] cur_time, set_time;
   
    clk_top clk_top(clk, reset_p, clk_sec, clk_min);
//    clock_usec usec_clk(clk, reset_p, clk_usec); //위에 있는거랑 같은거다 대신 모듈 입출력의 순서를 알아야한다.  
//    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
//    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
//    clock_min min_clk(clk, reset_p, sec_edge, clk_min);// 여기만 sec_edge를 넣는 이유 시간이 밀리기 떄문?
//        // usec -> msec -> sec -> min 이렇게 순차적으로 세어서 한클락씩 만들어지는거다. 
        
    loadable_counter_dec_60 cur_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(cur_time_load_en), .set_value1(set_sec1), .set_value10(set_sec10), 
    .dec1(cur_sec1), .dec10(cur_sec10)); // 현재시간 초카운터
    loadable_counter_dec_60 cur_time_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(cur_time_load_en), .set_value1(set_min1), .set_value10(set_min10), 
    .dec1(cur_min1), .dec10(cur_min10)); // 현재시간 분카운터
    loadable_counter_dec_60 set_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[1]), .load_enable(set_time_load_en), .set_value1(cur_sec1), .set_value10(cur_sec10), 
    .dec1(set_sec1), .dec10(set_sec10)); // 세팅시간 초카운터
    loadable_counter_dec_60 set_time_min(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[2]), .load_enable(set_time_load_en), .set_value1(cur_min1), .set_value10(cur_min10), 
    .dec1(set_min1), .dec10(set_min10));
    
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    
    assign value = set_mode ? set_time : cur_time;
    
    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(set_mode));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(set_mode), .n_edge(cur_time_load_en), .p_edge(set_time_load_en));
    // cp가 set_mode이니까 상승엣지일떄 set_time_load_en이 1이 되는거고, 하강엣지일떄 cur_time_load_endl 1이 되는거다.
/*  wire w1, w2;
    mux_2_1b mux1(.d0(btnU_pedge[0]), .d1(clk_sec), .s(set_mode), .f(w1));
    mux_2_1b mux2(.d0(btnU_pedge[1]), .d1(clk_min), .s(set_mode), .f(w2));*/
    
    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    // set_mode일때 버튼으로 인해 바뀐 초가 분에 반영이 안되어서 만든 코드?
    // 만약 40분 59초이고 1번 버튼을 3번 눌렀으면, 41분 02초가 되어야 하는데 40분 02초가 된다.
    // 문제 :  초는 system clk에 의해서 올라가지만, 분은 올라가지 않는다.
    // 해결 : clock_min min_clk의 입력에 sec_edge를 넣어줌으로써, clock_min min_clk도 system clk에 반영될 수 있게 하였다.

    assign min_edge = set_mode ? btn_pedge[2] : clk_min;
    // 초, 분 말고 시간까지 6개의 fnd를 썼다면 있어야하는 코드
    
endmodule

////////////////////////////////////////////////////////////////////////////////////////////
module loadable_watch_top( // 카운터 값이 덮어써지는 시계
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7
);
    wire [15:0] value;
    wire [2:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    loadable_watch watch(clk, reset_p, btn_pedge, value);
       
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));

endmodule


// STOP WATCH 만들기//////////
module stop_watch_top(
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7
);
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire [3:0] btn_pedge;
    wire start_stop;
    wire clk_start;
    wire [3:0] sec1, sec10, min1, min10;
    
//    clock_usec usec_clk(clk_start, reset_p, clk_usec); 
//    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
//    clock_div_1000 sec_clk(clk_start, reset_p, clk_msec, clk_sec);
//    clock_min min_clk(clk_start, reset_p, clk_sec, clk_min); 
    
    clk_top clk_top(clk, reset_p, clk_sec, clk_min);
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));

    T_flip_flop_p tff_start(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(start_stop));

    assign clk_start = start_stop ? clk : 0;
    
    counter_dec_60 counter_sec(clk, reset_p, clk_sec, sec1, sec10);    
    counter_dec_60 counter_min(clk, reset_p, clk_min, min1, min10);
    
    

    wire lap_swatch, lap_load;
    T_flip_flop_p tff_lap(.clk(clk), .reset_p(reset_p), .t(btn_pedge[1]), .q(lap_swatch));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(lap_swatch), .p_edge(lap_load));
    
    reg [15:0] lap_time;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)lap_time = 0;
        else if(lap_load) lap_time = {min10, min1, sec10, sec1};
    end
    
    wire [15:0] value, cur_time;
    assign cur_time = {min10, min1, sec10, sec1};
    assign value = lap_swatch ? lap_time : {min10, min1, sec10, sec1};
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));
    
endmodule

/////////////////////////
module stop_watch_csec(
    input clk, reset_p,
    input [2:0] btn_pedge,
    output [15:0] value
);
    wire clk_10msec, clk_sec;
    wire start_stop;
    wire clk_start;
    wire lap_swatch, lap_load;
    wire [3:0] sec1, sec10, msec1, msec10;
    reg [15:0] lap_time;
    wire [15:0] cur_time;
    
//    clock_usec usec_clk(clk_start, reset_p, clk_usec); 
//    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
//    clock_div_10 _msec_clk(clk_start, reset_p, clk_msec, clk_10msec);
//    clock_div_100 sec_clk(clk_start, reset_p, clk_10msec, clk_sec);

    csec_clk_top csec_clk(clk_start, reset_p, clk_10msec, clk_sec);

    T_flip_flop_p tff_start(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(start_stop));

    assign clk_start = start_stop ? clk : 0;

    counter_dec_60 counter_sec(clk, reset_p, clk_sec, sec1, sec10);    
    counter_dec_100 counter_msec(clk, reset_p, clk_10msec, msec1, msec10);

    T_flip_flop_p tff_lap(.clk(clk), .reset_p(reset_p), .t(btn_pedge[1]), .q(lap_swatch));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(lap_swatch), .p_edge(lap_load));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)lap_time = 0;
        else if(lap_load) lap_time = {sec10, sec1, msec10, msec1};
    end

    assign cur_time = {sec10, sec1, msec10, msec1};
    assign value = lap_swatch ? lap_time : cur_time;
    
endmodule


//////////////////////////////////////초 : 10ms 단위 출력 스위치
module stop_watch_top_1(
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7
);

    wire [3:0] btn_pedge;
    wire [15:0] value;

    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));

    stop_watch_csec stop_watch(clk, reset_p, btn_pedge, value);

    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));

endmodule
/////////////////////////////////////////////////////
module cook_timer(
    input clk, reset_p,
    input [3:0] btn_pedge,
    output [15:0] value,
    output [5:0] led
//    output buzz_clk
    );
    
    wire btn_start, inc_sec, inc_min, alarm_off;
    wire [3:0] set_sec1, set_sec10, set_min1, set_min10;    
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10;
    wire load_enable, dec_clk, clk_start;
    reg start_stop;
    wire [15:0] cur_time, set_time;
    reg time_out;
    wire timeout_pedge;
    reg alarm;
    wire clk_msec, clk_sec;
    
    clock_usec usec_clk(clk_start, reset_p, clk_usec); 
    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk_start, reset_p, clk_msec, clk_sec);
//    sec_clk_top sec_clk(clk_start, reset_p, clk_sec);
    
    assign {alarm_off, inc_min, inc_sec, btn_start} = btn_pedge;
    // 뒤에 입력이 앞으로 넘어가는 구조이기 때문에 바꿔서하면 안된다.
    
    assign led[5] = start_stop;
    assign led[4] = time_out;
    
    assign clk_start = start_stop ? clk : 0;

    counter_dec_60 set_sec(clk, reset_p, inc_sec, set_sec1, set_sec10);
    counter_dec_60 set_min(clk, reset_p, inc_min, set_min1, set_min10);
    
    
    loadable_downcounter_dec_60 cur_sec(clk, reset_p, clk_sec, load_enable, set_sec1, set_sec10, cur_sec1, cur_sec10, dec_clk);
    // 초 카운터에서 설정한 클락을 분카운터에 넣어주면 주는것이었다. 
    loadable_downcounter_dec_60 cur_min(clk, reset_p, dec_clk, load_enable, set_min1, set_min10, cur_min1, cur_min10); // 여기서는 dec_clk을 지워야한다.?
    
  // cur_time이 0이될때 start_stop을 0으로 맞추기 위해 time_out의 엣지를 잡아준 것.
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) time_out = 0;
        else begin
            if(start_stop && clk_msec && cur_time == 0) time_out = 1;
            else time_out = 0; // start_stop == 0 && clk_msech
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(start_stop), .p_edge(load_enable));
    
//    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_start), .q(start_stop));
// 밑에 always문은 TFF인데 TFF의 내용을 수정해서 시간을 cur_time 이 0이 되면 멈추는걸 보여주는 코드
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) start_stop = 0;
        else begin
            if(btn_start) start_stop = ~start_stop;
            else if(timeout_pedge) start_stop = 0; // 1msec하고 한클락 후에 0이 된다. ?
        end
    end
    
    edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(time_out), .p_edge(timeout_pedge));
    
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            alarm = 0;
        end
        else begin
            if(timeout_pedge) alarm = 1;
            else if(alarm && alarm_off) alarm = 0;
        end
    end
    
    assign led[0] = alarm;
    
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    assign value = start_stop ? cur_time : set_time;
    
    
//    reg [16:0] clk_div = 0;
//    always @(posedge clk) clk_div = clk_div + 1;
    
//    assign buzz_clk = alarm ? clk_div[12] : 0; // 13번 bit가 8000~9000hz 정도 된다. 
    
endmodule

/////////////////교수님이 하신 주방 타이머///// 버튼 4개 사용 스타트, 분, 초. 알람off.
module cook_timer_top(
    input clk, reset_p,
    input [3:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output [5:0] led
//    output buzz_clk
    );
    
    wire [15:0] value;
    wire [3:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));

    cook_timer cook(clk, reset_p, btn_pedge, value, led);

    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));
    
endmodule


////////////////////////////////////////개인과제////////////////////////////////////////
// 시계 스톱워치 주방타이머 // 버튼을 누를때마다 출력이 바뀜 ///이걸 내가 하다니 디먹스는 교수님이 도와주심
module smart_watch(
    input clk, reset_p,
    input [4:0] btn,
    output [3:0] com,
    output [7:0] seg_7
);
    
    wire [3:0] out_w, out_s, out_c;
    wire btn4_edge;
    wire [2:0] ring_out;
    wire [9:0] f;
    wire [7:0] seg_7_out_w, seg_7_out_s, seg_7_out_c;
    
    watch_top1 watch(.clk(clk), .reset_p(reset_p), .btn(f[2:0]), .com(out_w), .seg_7(seg_7_out_w));
    stop_watch_top stop_watch(.clk(clk), .reset_p(reset_p), .btn(f[5:3]), .com(out_s), .seg_7(seg_7_out_s));
    cook_timer cook_timer(.clk(clk), .reset_p(reset_p), .btn(f[9:6]), .com(out_c), .seg_7(seg_7_out_c), .led(led));

    button_cntr btn_cntr4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pe(btn4_edge));
    
    three_ring_counter_fnd ring(.clk(clk), .reset_p(reset_p), .enable_ring(btn4_edge), .com(ring_out));
      
    assign f = (ring_out[0]) ? {7'b0, btn[2:0]} :      
               (ring_out[1]) ? {4'b0, btn[2:0], 3'b0} :     
               (ring_out[2]) ? {btn[3:0], 6'b0} : 0;

    assign com = (ring_out[0]) ? out_w :     
                 (ring_out[1]) ? out_s :  
                 (ring_out[2]) ? out_c : 0; 
  
    assign seg_7 = (ring_out[0]) ? seg_7_out_w :     
                   (ring_out[1]) ? seg_7_out_s :  
                   (ring_out[2]) ? seg_7_out_c : 0; 
endmodule

///////////////////////////////////Smart Watch 교수님이 하신 것
module multy_purpose_watch(
    input clk, reset_p,
    input [4:0] btn,
    output [3:0] com,
    output [7:0] seg_7,
    output [5:0] led
);

    parameter watch_mode        = 3'b001;
    parameter stop_watch_mode   = 3'b010;
    parameter cook_timer_mode   = 3'b100;
    
    wire [2:0] watch_btn, stopw_btn;
    wire [3:0] cook_btn;
    wire [15:0] watch_value, stop_watch_value, cook_timer_value;
    reg [2:0] mode;
    wire btn_mode;
    wire [3:0] btn_pedge;
    wire [15:0] value;
    
    loadable_watch watch(clk, reset_p, btn_pedge, watch_value);
    stop_watch_csec stop_watch(clk, reset_p, btn_pedge, stop_watch_value);
    cook_timer cook(clk, reset_p, btn_pedge, cook_timer_value, led);
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));
    button_cntr btn_cntr4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pe(btn_mode));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)mode = watch_mode;
        else if(btn_mode)begin
            case(mode)
                watch_mode      : mode = stop_watch_mode;
                stop_watch_mode : mode = cook_timer_mode;
                cook_timer_mode : mode = watch_mode;
                default         : mode = watch_mode;
            endcase
        end
    end
    
    assign {cook_btn, stopw_btn, watch_btn} = (mode == watch_mode) ? {7'b0, btn_pedge[2:0]} : // 이게바로 DeMux 쓰는 방법이다.
                                              (mode == stop_watch_mode) ? {4'b0, btn_pedge[2:0], 3'b0} : 
                                              {btn_pedge[3:0], 6'b0}; 
    
    assign value = (mode == cook_timer_mode) ? cook_timer_value :
                   (mode == stop_watch_mode) ? stop_watch_value :
                   watch_value;
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));
    
    //    assign com = (mode == cook_timer_mode) ? cook_com : // 이게 바로 Mux 쓰는 방법이다.
    //                 (mode == stop_watch_mode) ? stopw_com : 
    //                 watch_com;
    //    assign seg_7 = (mode == cook_timer_mode) ? cook_seg_7 : 
    //                   (mode == stop_watch_mode) ? stopw_seg7 : 
    //                   watch_seg7;
endmodule

////////////////////DHT11 온습도센서
module dht11_top(
    input clk, reset_p,
    inout dht11_data,
    output [3:0] com,
    output [7:0] seg_7,
    output [7:0] led_bar
);
    
    wire [7:0] humidity, temperature;
    
    dht11 dht(clk, reset_p, dht11_data, humidity, temperature, led_bar);
    
    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000, humidity}), .bcd(bcd_humi));
    bin_to_dec tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr)); 
    
    wire [15:0] value;
    assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));

endmodule

module ultrasonic_top(
    input clk, reset_p,
    input echo,
    output trigger,
    output [3:0] com,
    output [7:0] seg_7,
    output [3:0] led_bar
);
    wire [11:0] distance;
    ultra_sonic_prof ult(clk, reset_p, echo, trigger, distance, led_bar);
    
    wire [15:0] bcd_dist;
    bin_to_dec dist(.bin(distance), .bcd(bcd_dist));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_dist), .seg_7_an(seg_7), .com(com));
    
endmodule

////////////////////////////////PWM_LED 밝기 제어하는 top module 
module led_pwm_top(
    input clk, reset_p,
    output [3:0] led_pwm
);
    reg [27:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    // duty에 0%에서 63%까지 주는것 clk_div[27:22] 
    pwm_128pc pwm_led_r(.clk(clk), .reset_p(reset_p), .duty(clk_div[27:21]), .pwm_freq(10_000), .pwm_128(led_pwm[0]));
    
    pwm_128pc pwm_led_g(.clk(clk), .reset_p(reset_p), .duty(clk_div[26:20]), .pwm_freq(10_000), .pwm_128(led_pwm[1]));
    
    pwm_128pc pwm_led_b(.clk(clk), .reset_p(reset_p), .duty(32), .pwm_freq(10_000), .pwm_128(led_pwm[2]));
    
    pwm_128pc pwm_led_c(.clk(clk), .reset_p(reset_p), .duty(25), .pwm_freq(10_000), .pwm_128(led_pwm[3]));

endmodule

//////////////////Motor 손풍기
module dc_motor_pwm_top(
    input clk, reset_p,
    output motor_pwm
);
    reg [29:0] clk_div;
    initial clk_div = 0;
    always @(posedge clk)clk_div = clk_div + 1;
    
    pwm_128pc pwm_motor(.clk(clk), .reset_p(reset_p), .duty(clk_div[29:23]), .pwm_freq(100), .pwm_128(motor_pwm));
    
endmodule

/////////////////SG90 servo motor 내가 한 것
module servo_motor_pwm_top(
    input clk, reset_p,
    input [2:0] btn,
    output servo_motor_pwm
);
    wire [2:0] btn_pedge;
    reg [7:0] duty_clk;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) duty_clk = 0;
        else if(btn_pedge[0])
            duty_clk = 7;
        else if(btn_pedge[1])
            duty_clk = 20;
        else if(btn_pedge[2])
            duty_clk = 32;
    end
    
    pwm_256step servo0(.clk(clk), .reset_p(reset_p), .duty(duty_clk), .pwm_freq(50), .pwm_servo(servo_motor_pwm));
    
endmodule

/////////////////교수님이 하신 것 
module servo_sg90(
    input clk, reset_p,
    input [2:0] btn,
    output sg90,
    output [3:0] com,
    output [7:0] seg_7
);
    wire [2:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    wire clk_div_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[25]), .p_edge(clk_div_pedge));
    
    reg [8:0] duty;
    reg up_down;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            duty = 14;
            up_down = 1;
        end
        else if(btn_pedge[0])begin // 얘가 우선순위가 우위에 있다. 사용자를 위주로 코드를 짜야 보기가 편하기 때문
            if(up_down)up_down = 0;
            else up_down = 1;
        end
        else if(btn_pedge[1])begin 
            duty = 14;
        end
        else if(btn_pedge[2])begin
            duty = 64;
        end
        else if(clk_div_pedge)begin 
            if(duty >= 64)up_down = 0;
            else if(duty <= 14)up_down = 1;
            
            if(up_down)duty = duty + 1;
            else duty = duty - 1;
        end
    end
    
    // 7,8,9,10 네단계만 움직이게 한것 .duty(clk_div[29:28] + 7)    
    pwm_512step servo0(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm_freq(50), .pwm_servo(sg90));
    
    wire [15:0] bcd_duty;
    bin_to_dec dist(.bin({3'b0, duty}), .bcd(bcd_duty));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_duty), .seg_7_an(seg_7), .com(com));
    
endmodule


//////승범이형이 한것
module servo_sg90_1(
    input clk, reset_p,
    input [2:0] btn,
    output sg90,
    output [3:0] com,
    output [7:0] seg_7
);
    wire [2:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    reg [31:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    wire clk_div_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[8]), .p_edge(clk_div_pedge));
    
    reg [20:0] duty;
    reg up_down;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            duty = 51_800;
            up_down = 1;
        end
        else if(btn_pedge[0])begin 
            if(up_down)up_down = 0;
            else up_down = 1;
        end
        else if(btn_pedge[1])begin 
            duty = 51_800;
        end
        else if(btn_pedge[2])begin 
            duty = 256_000;
        end
        else if(clk_div_pedge)begin 
            if(duty >= 256_000)up_down = 0;
            else if(duty <= 51_800)up_down = 1;
            
            if(up_down)duty = duty + 1;
            else duty = duty - 1;
        end
    end
    
    pwm_512_period servo0(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm_period(2_000_000), .pwm_512(sg90));
    
    wire [15:0] bcd_duty;
    bin_to_dec dist(.bin(duty[20:9]), .bcd(bcd_duty));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_duty), .seg_7_an(seg_7), .com(com));
    
endmodule

// 가변저항을 이용하여  analog에서 digital로 변환하는 회로를 만들어보자
module adc_top(
    input clk, reset_p,
    input vauxp6, vauxn6,
    output [3:0] com,
    output [7:0] seg_7
);
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
          (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
//          di_in,               // Input data bus for the dynamic reconfiguration port
//          dwe_in,              // Write Enable for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
//          busy_out,            // ADC Busy signal
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
//          drdy_out,            // Data ready signal for the dynamic reconfiguration port
          .eoc_out(eoc_out)             // End of Conversion Signal // analog를 digital로 변환하고 1로 변하는,,
//          eos_out,             // End of Sequence Signal
//          alarm_out,           // OR'ed output of all the Alarms    
//          vp_in,               // Dedicated Analog Input Pair
//          vn_in
          );
    
    wire eoc_out_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    reg [11:0] adc_value;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)adc_value = 0;
        else if(eoc_out_pedge)adc_value = {2'b0, do_out[15:6]};
    end
    
    wire [15:0] bcd_value;
    bin_to_dec adc_bcd(.bin(adc_value), .bcd(bcd_value));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_value), .seg_7_an(seg_7), .com(com));
endmodule

//////////////8bit 짜리 
module adc_top1(
    input clk, reset_p,
    input vauxp6, vauxn6,
    output [3:0] com,
    output [7:0] seg_7,
    output led_pwm
);
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
          (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
//          di_in,               // Input data bus for the dynamic reconfiguration port
//          dwe_in,              // Write Enable for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
//          busy_out,            // ADC Busy signal
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
//          drdy_out,            // Data ready signal for the dynamic reconfiguration port
          .eoc_out(eoc_out)             // End of Conversion Signal // analog를 digital로 변환하고 1로 변하는,,
//          eos_out,             // End of Sequence Signal
//          alarm_out,           // OR'ed output of all the Alarms    
//          vp_in,               // Dedicated Analog Input Pair
//          vn_in
          );
    
    wire eoc_out_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    reg [11:0] adc_value;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)adc_value = 0;
        else if(eoc_out_pedge)adc_value = {4'b0, do_out[15:8]}; // 8bit 짜리 정밀도
    end
    
    wire [15:0] bcd_value;
    bin_to_dec adc_bcd(.bin(adc_value), .bcd(bcd_value));
    
    pwm_128pc pwm_led(.clk(clk), .reset_p(reset_p), .duty(do_out[15:9]), .pwm_freq(10_000), .pwm_128(led_pwm));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_value), .seg_7_an(seg_7), .com(com));
endmodule


module adc_sequence2_top(
    input clk, reset_p,
    input vauxp6, vauxn6,
    input vauxp15, vauxn15,
    output led_r, led_g,
    output led_r_b, led_g_b,
    output [3:0] com,
    output [7:0] seg_7
);
    wire [4:0] channel_out;
    wire [15:0] do_out;
    wire eoc_out, eos_out;
    
    adc_ch6_ch15 adc_seq2
          (
              .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
              .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
              .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
              .reset_in(reset_p),            // Reset signal for the System Monitor control logic
              .vauxp6(vauxp6),              // Auxiliary channel 6
              .vauxn6(vauxn6),
              .vauxp15(vauxp15),             // Auxiliary channel 15
              .vauxn15(vauxn15),
              .channel_out(channel_out),         // Channel Selection Outputs
              .do_out(do_out),              // Output data bus for dynamic reconfiguration port
              .eoc_out(eoc_out),             // End of Conversion Signal
              .eos_out(eos_out)             // End of Sequence Signal
          );
          
    wire eoc_out_pedge;
    edge_detector_n ed_eoc(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge));
    
    reg [11:0] adc_value_x, adc_value_y; // adc_value가 두개 필요하다 x축, y축
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            adc_value_x = 0;
            adc_value_y = 0;
        end
        else if(eoc_out_pedge)begin // channel_out 에 따라 x인지 y인지 판별할 수 있다.
            case(channel_out[3:0]) // 최상위 비트를 하나 빼고 4비트만 줘야한다. 왜?
                6 : adc_value_x = {4'b0, do_out[15:10]}; // fnd에 각각 두자리씩 쓰려고 6비트로 한거임. 7비트면 128까지 나오니까
                15: adc_value_y = {4'b0, do_out[15:10]};
            endcase
        end
    end
    
    wire [15:0] bcd_value_x, bcd_value_y;
    bin_to_dec adc_x_bcd(.bin(adc_value_x), .bcd(bcd_value_x));
    bin_to_dec adc_y_bcd(.bin(adc_value_y), .bcd(bcd_value_y));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({bcd_value_x[7:0], bcd_value_y[7:0]}), .seg_7_an(seg_7), .com(com));
    
    wire eos_out_pedge; 
    edge_detector_n ed_eos(.clk(clk), .reset_p(reset_p), .cp(eos_out), .p_edge(eos_out_pedge));
    
    reg [6:0] duty_x, duty_y; // 미세하게 타이밍을 맞추기 위해서 eos 를 이용한 것. 육안으로는 달라진걸 판별하기 어렵다.
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            duty_x = 0;
            duty_y = 0;
        end
        else if(eos_out_pedge)begin
            duty_x = bcd_value_x[6:0];
            duty_y = bcd_value_y[6:0];
        end
    end
    
    pwm_128pc pwm_led_r(.clk(clk), .reset_p(reset_p), .duty(duty_x), .pwm_freq(10_000), .pwm_128(led_r));
    pwm_128pc pwm_led_g(.clk(clk), .reset_p(reset_p), .duty(duty_y), .pwm_freq(10_000), .pwm_128(led_g));
    
    wire led_r_b, led_g_b;
    assign led_r_b = led_r;
    assign led_g_b = led_g;
    
endmodule

///I2C 통신모듈 TOP
// 0번 누르면 data에 0 8개 보내고 back light 켜지고, 1번 누르면 data에 1 8개 보내고 back light 꺼진다. 
module I2C_master_top(
    input clk, reset_p,
    input [1:0] btn,
    output sda, scl
);  
    // 우리는 write만 쓸건데, read가 1, write가 0 이어서 rd_wr에 0을 준거다.
    // addr 주소값은 datasheet에 0x27로 정해져있는 값이다.
    
    reg [7:0] data;
    reg valid;
    
    I2C_master master(.clk(clk), .reset_p(reset_p), .rd_wr(0), .addr(7'h27), .data(data), .valid(valid), .sda(sda), .scl(scl));
    
    wire [1:0] btn_pedge, btn_nedge;
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]), .btn_ne(btn_nedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]), .btn_ne(btn_nedge[1]));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            data = 0;
            valid = 0;
        end
        else begin
            if(btn_pedge[0])begin
                data = 8'b0000_0000;
                valid = 1;
            end
            else if(btn_nedge[0]) valid = 0;
            else if(btn_pedge[1])begin
                data = 8'b0000_1000; // data pin 중에 3번 bit가 back light에 연결되있어서 3번에만 1 줘도 되는 것이다.
                valid = 1;
            end
            else if(btn_nedge[1]) valid = 0;
        end
    end
endmodule

module I2C_txtlcd_top(
    input clk, reset_p,
    input [2:0] btn,
    output scl, sda
);
    parameter IDLE          = 6'b00_0001;
    parameter INIT          = 6'b00_0010;
    parameter SEND          = 6'b00_0100;
    parameter MOVE_CURSOR   = 6'b00_1000;
    parameter SHIFT_DISPLAY = 6'b01_0000;
    
    parameter SAMPLE_DATA = "A"; // 이렇게 하면 A의 아스키 코드값이 저장된다.
    
    wire [2:0] btn_pedge;
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
        
    reg [7:0] send_buffer;
    reg send_e, rs;
    wire busy;
    
    I2C_lcd_send_byte send_byte(.clk(clk), .reset_p(reset_p), .addr(7'h27), .send_buffer(send_buffer), 
                                .send(send_e), .rs(rs), .scl(scl), .sda(sda), .busy(busy));
    
    reg [21:0] count_usec;
    reg count_usec_e;
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec = 0;
        end
        else begin
            if(clk_usec && count_usec_e)count_usec = count_usec + 1;
            else if(!count_usec_e)count_usec = 0;
        end
    end
    
    reg [5:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg init_flag; // 초기화가 안됐을때 초기화시켜주는 변수
    reg [3:0] cnt_data;
    
    always @(posedge clk or posedge reset_p)begin // text lcd를 다루는 always문
        if(reset_p)begin
            next_state = IDLE;
            send_buffer = 0;
            rs = 0;
            send_e = 0;
            init_flag = 0;
            cnt_data = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(init_flag)begin
                        if(btn_pedge[0])next_state = SEND;
                        else if(btn_pedge[1])next_state = MOVE_CURSOR;
                        else if(btn_pedge[2])next_state = SHIFT_DISPLAY;
                    end
                    else begin // datasheet에 초기화하는 방법 그대로 해야해서 40ms 기다리는 거다. 
                        if(count_usec <= 22'd80_000)begin
                            count_usec_e = 1;
                        end
                        else begin
                            next_state = INIT;
                            count_usec_e = 0;
                        end
                    end
                end
                INIT:begin // datasheet 대로 4bit씩 보내주는것 시간은 왜 이렇게 하는지 모르겟음
                    if(count_usec <= 22'd1000)begin
                        send_buffer = 8'h33;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd1010)send_e = 0;
                    else if(count_usec <= 22'd2010)begin
                        send_buffer = 8'h32;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd2020)send_e = 0;
                    else if(count_usec <= 22'd3020)begin
                        send_buffer = 8'h28;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd3030)send_e = 0;
                    else if(count_usec <= 22'd4030)begin
                        send_buffer = 8'h0e; // datasheet에 0000_1100으로 해줘야 display ON이라고 명시되어있다.
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd4040)send_e = 0;
                    else if(count_usec <= 22'd5040)begin
                        send_buffer = 8'h01;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd5050)send_e = 0;
                    else if(count_usec <= 22'd6050)begin
                        send_buffer = 8'h06;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd6060)send_e = 0;
                    else begin
                        next_state = IDLE;
                        init_flag = 1;
                        count_usec_e = 0;
                    end
                end
                SEND:begin // data send를 할거다. 우리는 대문자 A를 찍히게 할거다.
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                        cnt_data = cnt_data + 1;
                    end
                    else begin
                        send_buffer = SAMPLE_DATA + cnt_data;
                        rs = 1;
                        send_e = 1;
                    end
                end
                    MOVE_CURSOR:begin
                        if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = 8'hc0;
                        rs = 0;
                        send_e = 1;
                    end
                end
                SHIFT_DISPLAY:begin
                    if(busy)begin
                        next_state = IDLE;
                        send_e = 0;
                    end
                    else begin
                        send_buffer = 8'h1c;
                        rs = 0;
                        send_e = 1;
                    end
                end
            endcase
        end
    end

endmodule

///////////////////////////선풍기 팀프로젝트 완성/////////////////////////////////////////////////////////////////////////
module fan_top(
    input clk, reset_p,
    input [3:0]btn, // LED 밝기, 바람 세기, 타이머 버튼으로 3개
    input echo,
    output led_pwm_o, motor_pwm_o,//LED 밝기, 모터의 output
    output [3:0]com,
    output [7:0]seg_7,
    output [2:0]motor_led,timer_led,
    output trigger,
    output sg90
    );
    wire [11:0] distance;
    wire motor_off, motor_sw;
    
    led_brightness(.clk(clk), //LED밝기 모듈
                   .reset_p(reset_p),
                   .btn(btn[0]),
                   .led_pwm_o(led_pwm_o)); //JA1
               
    dc_motor_speed(.clk(clk), //모터 스피드 모듈
                   .reset_p(reset_p),
                   .motor_off(motor_off),
                   .distance(distance),
                   .btn(btn[1]),
                   .motor_pwm_o(motor_pwm_o),
                   .motor_led(motor_led),
                   .motor_sw(motor_sw)); //JA2
    
    fan_timer( .clk(clk), 
               .reset_p(reset_p),
               .motor_sw(motor_sw), 
               .btn_str(btn[2]), 
               .motor_off(motor_off),
               .timer_led(timer_led),
               .com(com),
               .seg_7(seg_7)); 
    
    ultra_sonic_prof ult(clk, reset_p, echo, trigger, distance);
    
    servomotor servo(.clk(clk), .reset_p(reset_p), .btn_str(btn[3]), .motor_sw(motor_sw), .sg90(sg90));
           
endmodule










