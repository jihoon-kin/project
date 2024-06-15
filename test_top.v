`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module keypad_test_top(
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] seg_7,
    output [3:0] com
    );
    //16��Ʈ ī���͸� �߰��ϰ� 
    //key_valid ��¿������� key_value�� 1�̸� 1���� key_value�� 2�� 1���� ī���� ���� fnd�� ����϶�
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
module button_test_top_2( // �������� �ϽŰ� 
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
    
    genvar i; // �� ������ ȸ�ΰ� ��������� �ʴ´�. for���� ���� �����θ� ����
    generate
        for (i=0;i<4;i=i+1)begin:btn_cntr //for(�ʱⰪ, �ݺ��� ���� ���ǽ�, �ѹ� �ݺ��ϰ� �ٽ� �����ϴ� ���ǽ�), �� �� ���� ��� �ݺ��Ѵ�.
            button_cntr btn_inst(.clk(clk), .reset_p(reset_p), .btn(btnU[i]), .btn_pe(btnU_pedge[i])); // begin: �ڿ��� ����� �̸��� �����ذ�
        end
    endgenerate//for = �ݺ���, 
    
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


/////////btn�Է� FND seg7��� ȸ��
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

module watch_top( // �ð��� ��Ȯ�� ���� �� �ִ� �ð�
    input clk, reset_p,
    input [2:0] btn,
    output [3:0] com,
    output [7:0] seg_7
);
    wire clk_usec, clk_msec, clk_sec, clk_min;
    reg sec, min;

//    clock_usec usec_clk(.clk(clk), .reset_p(reset_p), .clk_usec(clk_usec));
    clock_usec usec_clk(clk, reset_p, clk_usec); //���� �ִ°Ŷ� �����Ŵ� ��� ��� ������� ������ �˾ƾ��Ѵ�.  
    
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    
    clock_min min_clk(clk, reset_p, sec, clk_min);
    
    // usec -> msec -> sec -> min �̷��� ���������� ��� ��Ŭ���� ��������°Ŵ�. 
    
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
    
endmodule // edge detector���� PDT�� �߻��Ͽ� 40ns ���� ������ �߻��Ѵ�. �츮�� �߸𸣱� ������ ��� ����. 

// Clk�� ���� �����ְ� ���� ��� ������ �ð踦 ���鶧 Clk����� �Ѳ����� ��Ƴ�����, 
// ���� �ð��� ���߰� ������ �ٽ� �����ϴ� �۾��� �ؾ��ϱ� ������ �ð踸�鶧�� ���� �̷��� ��������.
// ������ �ð��� ���ݳ��Ƽ� �ϴ°Ŵ� �� �غ���.
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

////csec Clk ���
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

//sec clk ���
module sec_clk_top(
    input clk, reset_p,
    output clk_sec
    );
    
    wire clk_usec, clk_msec;
    
    clock_usec usec_clk(clk, reset_p, clk_usec); 
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    
endmodule

///�������� �ϽŰ�
module watch_top1( // �ð��� ��Ȯ�� ���� �� �ִ� �ð�
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
//    clock_usec usec_clk(clk, reset_p, clk_usec); //���� �ִ°Ŷ� �����Ŵ� ��� ��� ������� ������ �˾ƾ��Ѵ�.  
    
//    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    
//    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    
//    clock_min min_clk(clk, reset_p, sec_edge, clk_min);

    clk_top clk_top(clk, reset_p, sec_edge, clk_min);
    
    // usec -> msec -> sec -> min �̷��� ���������� ��� ��Ŭ���� ��������°Ŵ�. 
    
    counter_dec_60 counter_sec(clk, reset_p, sec_edge, sec1, sec10);
    counter_dec_60 counter_min(clk, reset_p, min_edge, min1, min10);
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({min10, min1, sec10, sec1}), .seg_7_an(seg_7), .com(com));
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    
    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(set_mode));
    
    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    assign min_edge = set_mode ? btn_pedge[2] : clk_min;

endmodule // edge detector���� PDT�� �߻��Ͽ� 40ns ���� ������ �߻��Ѵ�. �츮�� �߸𸣱� ������ ��� ����. 

//�츮�� �ٱ�� �ð踦 ������µ� watch, stop_watch, cook_timer ��װ� fnd, btn_cntr ���� �� ���־ ������ ���� �ϳ��� �������� �ϴ� ��.
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
//    clock_usec usec_clk(clk, reset_p, clk_usec); //���� �ִ°Ŷ� �����Ŵ� ��� ��� ������� ������ �˾ƾ��Ѵ�.  
//    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
//    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
//    clock_min min_clk(clk, reset_p, sec_edge, clk_min);// ���⸸ sec_edge�� �ִ� ���� �ð��� �и��� ����?
//        // usec -> msec -> sec -> min �̷��� ���������� ��� ��Ŭ���� ��������°Ŵ�. 
        
    loadable_counter_dec_60 cur_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(cur_time_load_en), .set_value1(set_sec1), .set_value10(set_sec10), 
    .dec1(cur_sec1), .dec10(cur_sec10)); // ����ð� ��ī����
    loadable_counter_dec_60 cur_time_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(cur_time_load_en), .set_value1(set_min1), .set_value10(set_min10), 
    .dec1(cur_min1), .dec10(cur_min10)); // ����ð� ��ī����
    loadable_counter_dec_60 set_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[1]), .load_enable(set_time_load_en), .set_value1(cur_sec1), .set_value10(cur_sec10), 
    .dec1(set_sec1), .dec10(set_sec10)); // ���ýð� ��ī����
    loadable_counter_dec_60 set_time_min(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[2]), .load_enable(set_time_load_en), .set_value1(cur_min1), .set_value10(cur_min10), 
    .dec1(set_min1), .dec10(set_min10));
    
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    
    assign value = set_mode ? set_time : cur_time;
    
    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(set_mode));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(set_mode), .n_edge(cur_time_load_en), .p_edge(set_time_load_en));
    // cp�� set_mode�̴ϱ� ��¿����ϋ� set_time_load_en�� 1�� �Ǵ°Ű�, �ϰ������ϋ� cur_time_load_endl 1�� �Ǵ°Ŵ�.
/*  wire w1, w2;
    mux_2_1b mux1(.d0(btnU_pedge[0]), .d1(clk_sec), .s(set_mode), .f(w1));
    mux_2_1b mux2(.d0(btnU_pedge[1]), .d1(clk_min), .s(set_mode), .f(w2));*/
    
    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    // set_mode�϶� ��ư���� ���� �ٲ� �ʰ� �п� �ݿ��� �ȵǾ ���� �ڵ�?
    // ���� 40�� 59���̰� 1�� ��ư�� 3�� ��������, 41�� 02�ʰ� �Ǿ�� �ϴµ� 40�� 02�ʰ� �ȴ�.
    // ���� :  �ʴ� system clk�� ���ؼ� �ö�����, ���� �ö��� �ʴ´�.
    // �ذ� : clock_min min_clk�� �Է¿� sec_edge�� �־������ν�, clock_min min_clk�� system clk�� �ݿ��� �� �ְ� �Ͽ���.

    assign min_edge = set_mode ? btn_pedge[2] : clk_min;
    // ��, �� ���� �ð����� 6���� fnd�� ��ٸ� �־���ϴ� �ڵ�
    
endmodule

////////////////////////////////////////////////////////////////////////////////////////////
module loadable_watch_top( // ī���� ���� ��������� �ð�
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


// STOP WATCH �����//////////
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


//////////////////////////////////////�� : 10ms ���� ��� ����ġ
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
    // �ڿ� �Է��� ������ �Ѿ�� �����̱� ������ �ٲ㼭�ϸ� �ȵȴ�.
    
    assign led[5] = start_stop;
    assign led[4] = time_out;
    
    assign clk_start = start_stop ? clk : 0;

    counter_dec_60 set_sec(clk, reset_p, inc_sec, set_sec1, set_sec10);
    counter_dec_60 set_min(clk, reset_p, inc_min, set_min1, set_min10);
    
    
    loadable_downcounter_dec_60 cur_sec(clk, reset_p, clk_sec, load_enable, set_sec1, set_sec10, cur_sec1, cur_sec10, dec_clk);
    // �� ī���Ϳ��� ������ Ŭ���� ��ī���Ϳ� �־��ָ� �ִ°��̾���. 
    loadable_downcounter_dec_60 cur_min(clk, reset_p, dec_clk, load_enable, set_min1, set_min10, cur_min1, cur_min10); // ���⼭�� dec_clk�� �������Ѵ�.?
    
  // cur_time�� 0�̵ɶ� start_stop�� 0���� ���߱� ���� time_out�� ������ ����� ��.
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) time_out = 0;
        else begin
            if(start_stop && clk_msec && cur_time == 0) time_out = 1;
            else time_out = 0; // start_stop == 0 && clk_msech
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(start_stop), .p_edge(load_enable));
    
//    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_start), .q(start_stop));
// �ؿ� always���� TFF�ε� TFF�� ������ �����ؼ� �ð��� cur_time �� 0�� �Ǹ� ���ߴ°� �����ִ� �ڵ�
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) start_stop = 0;
        else begin
            if(btn_start) start_stop = ~start_stop;
            else if(timeout_pedge) start_stop = 0; // 1msec�ϰ� ��Ŭ�� �Ŀ� 0�� �ȴ�. ?
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
    
//    assign buzz_clk = alarm ? clk_div[12] : 0; // 13�� bit�� 8000~9000hz ���� �ȴ�. 
    
endmodule

/////////////////�������� �Ͻ� �ֹ� Ÿ�̸�///// ��ư 4�� ��� ��ŸƮ, ��, ��. �˶�off.
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


////////////////////////////////////////���ΰ���////////////////////////////////////////
// �ð� �����ġ �ֹ�Ÿ�̸� // ��ư�� ���������� ����� �ٲ� ///�̰� ���� �ϴٴ� ��Խ��� �������� �����ֽ�
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

///////////////////////////////////Smart Watch �������� �Ͻ� ��
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
    
    assign {cook_btn, stopw_btn, watch_btn} = (mode == watch_mode) ? {7'b0, btn_pedge[2:0]} : // �̰Թٷ� DeMux ���� ����̴�.
                                              (mode == stop_watch_mode) ? {4'b0, btn_pedge[2:0], 3'b0} : 
                                              {btn_pedge[3:0], 6'b0}; 
    
    assign value = (mode == cook_timer_mode) ? cook_timer_value :
                   (mode == stop_watch_mode) ? stop_watch_value :
                   watch_value;
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_an(seg_7), .com(com));
    
    //    assign com = (mode == cook_timer_mode) ? cook_com : // �̰� �ٷ� Mux ���� ����̴�.
    //                 (mode == stop_watch_mode) ? stopw_com : 
    //                 watch_com;
    //    assign seg_7 = (mode == cook_timer_mode) ? cook_seg_7 : 
    //                   (mode == stop_watch_mode) ? stopw_seg7 : 
    //                   watch_seg7;
endmodule

////////////////////DHT11 �½�������
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

////////////////////////////////PWM_LED ��� �����ϴ� top module 
module led_pwm_top(
    input clk, reset_p,
    output [3:0] led_pwm
);
    reg [27:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    
    // duty�� 0%���� 63%���� �ִ°� clk_div[27:22] 
    pwm_128pc pwm_led_r(.clk(clk), .reset_p(reset_p), .duty(clk_div[27:21]), .pwm_freq(10_000), .pwm_128(led_pwm[0]));
    
    pwm_128pc pwm_led_g(.clk(clk), .reset_p(reset_p), .duty(clk_div[26:20]), .pwm_freq(10_000), .pwm_128(led_pwm[1]));
    
    pwm_128pc pwm_led_b(.clk(clk), .reset_p(reset_p), .duty(32), .pwm_freq(10_000), .pwm_128(led_pwm[2]));
    
    pwm_128pc pwm_led_c(.clk(clk), .reset_p(reset_p), .duty(25), .pwm_freq(10_000), .pwm_128(led_pwm[3]));

endmodule

//////////////////Motor ��ǳ��
module dc_motor_pwm_top(
    input clk, reset_p,
    output motor_pwm
);
    reg [29:0] clk_div;
    initial clk_div = 0;
    always @(posedge clk)clk_div = clk_div + 1;
    
    pwm_128pc pwm_motor(.clk(clk), .reset_p(reset_p), .duty(clk_div[29:23]), .pwm_freq(100), .pwm_128(motor_pwm));
    
endmodule

/////////////////SG90 servo motor ���� �� ��
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

/////////////////�������� �Ͻ� �� 
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
        else if(btn_pedge[0])begin // �갡 �켱������ ������ �ִ�. ����ڸ� ���ַ� �ڵ带 ¥�� ���Ⱑ ���ϱ� ����
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
    
    // 7,8,9,10 �״ܰ踸 �����̰� �Ѱ� .duty(clk_div[29:28] + 7)    
    pwm_512step servo0(.clk(clk), .reset_p(reset_p), .duty(duty), .pwm_freq(50), .pwm_servo(sg90));
    
    wire [15:0] bcd_duty;
    bin_to_dec dist(.bin({3'b0, duty}), .bcd(bcd_duty));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_duty), .seg_7_an(seg_7), .com(com));
    
endmodule


//////�¹������� �Ѱ�
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

// ���������� �̿��Ͽ�  analog���� digital�� ��ȯ�ϴ� ȸ�θ� ������
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
          .eoc_out(eoc_out)             // End of Conversion Signal // analog�� digital�� ��ȯ�ϰ� 1�� ���ϴ�,,
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

//////////////8bit ¥�� 
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
          .eoc_out(eoc_out)             // End of Conversion Signal // analog�� digital�� ��ȯ�ϰ� 1�� ���ϴ�,,
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
        else if(eoc_out_pedge)adc_value = {4'b0, do_out[15:8]}; // 8bit ¥�� ���е�
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
    
    reg [11:0] adc_value_x, adc_value_y; // adc_value�� �ΰ� �ʿ��ϴ� x��, y��
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            adc_value_x = 0;
            adc_value_y = 0;
        end
        else if(eoc_out_pedge)begin // channel_out �� ���� x���� y���� �Ǻ��� �� �ִ�.
            case(channel_out[3:0]) // �ֻ��� ��Ʈ�� �ϳ� ���� 4��Ʈ�� ����Ѵ�. ��?
                6 : adc_value_x = {4'b0, do_out[15:10]}; // fnd�� ���� ���ڸ��� ������ 6��Ʈ�� �Ѱ���. 7��Ʈ�� 128���� �����ϱ�
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
    
    reg [6:0] duty_x, duty_y; // �̼��ϰ� Ÿ�̹��� ���߱� ���ؼ� eos �� �̿��� ��. �������δ� �޶����� �Ǻ��ϱ� ��ƴ�.
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

///I2C ��Ÿ�� TOP
// 0�� ������ data�� 0 8�� ������ back light ������, 1�� ������ data�� 1 8�� ������ back light ������. 
module I2C_master_top(
    input clk, reset_p,
    input [1:0] btn,
    output sda, scl
);  
    // �츮�� write�� ���ǵ�, read�� 1, write�� 0 �̾ rd_wr�� 0�� �ذŴ�.
    // addr �ּҰ��� datasheet�� 0x27�� �������ִ� ���̴�.
    
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
                data = 8'b0000_1000; // data pin �߿� 3�� bit�� back light�� ������־ 3������ 1 �൵ �Ǵ� ���̴�.
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
    
    parameter SAMPLE_DATA = "A"; // �̷��� �ϸ� A�� �ƽ�Ű �ڵ尪�� ����ȴ�.
    
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
    
    reg init_flag; // �ʱ�ȭ�� �ȵ����� �ʱ�ȭ�����ִ� ����
    reg [3:0] cnt_data;
    
    always @(posedge clk or posedge reset_p)begin // text lcd�� �ٷ�� always��
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
                    else begin // datasheet�� �ʱ�ȭ�ϴ� ��� �״�� �ؾ��ؼ� 40ms ��ٸ��� �Ŵ�. 
                        if(count_usec <= 22'd80_000)begin
                            count_usec_e = 1;
                        end
                        else begin
                            next_state = INIT;
                            count_usec_e = 0;
                        end
                    end
                end
                INIT:begin // datasheet ��� 4bit�� �����ִ°� �ð��� �� �̷��� �ϴ��� �𸣰���
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
                        send_buffer = 8'h0e; // datasheet�� 0000_1100���� ����� display ON�̶�� ��õǾ��ִ�.
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
                SEND:begin // data send�� �ҰŴ�. �츮�� �빮�� A�� ������ �ҰŴ�.
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

///////////////////////////��ǳ�� ��������Ʈ �ϼ�/////////////////////////////////////////////////////////////////////////
module fan_top(
    input clk, reset_p,
    input [3:0]btn, // LED ���, �ٶ� ����, Ÿ�̸� ��ư���� 3��
    input echo,
    output led_pwm_o, motor_pwm_o,//LED ���, ������ output
    output [3:0]com,
    output [7:0]seg_7,
    output [2:0]motor_led,timer_led,
    output trigger,
    output sg90
    );
    wire [11:0] distance;
    wire motor_off, motor_sw;
    
    led_brightness(.clk(clk), //LED��� ���
                   .reset_p(reset_p),
                   .btn(btn[0]),
                   .led_pwm_o(led_pwm_o)); //JA1
               
    dc_motor_speed(.clk(clk), //���� ���ǵ� ���
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










