`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
/////////////////btn �Է¹޴� ���
module button_cntr(
    input clk, reset_p,
    input btn,
    output btn_pe, btn_ne
);
    reg [16:0] clk_div;
    wire clk_div_16;
    reg [3:0]debounced_btn;
    
    always @(posedge clk) clk_div = clk_div + 1;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16)); // /2^17
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btn;
    end
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .p_edge(btn_pe), .n_edge(btn_ne));
    
endmodule

///////fnd ��� �������
module fnd_4digit_cntr(
    input clk, reset_p,
    input [15:0] value,
    output [7:0] seg_7_an, seg_7_ca, // ����� Ÿ���ϋ� 1�϶� ������, ĳ�ҵ� Ÿ���ϋ� 0�ϋ� ����
    output [3:0] com,
    output led_bar
);
    reg [3:0] hex_value;
    
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));

    always @(posedge clk)begin 
        case(com)
            4'b0111: hex_value = value[15:12];
            4'b1011: hex_value = value[11:8];
            4'b1101: hex_value = value[7:4];
            4'b1110: hex_value = value[3:0];    
        endcase    
    end
    
    decoder_7seg fnd (.hex_value(hex_value), .seg_7(seg_7_an));
    assign seg_7_ca = ~seg_7_an;
endmodule
///////������� �������� �ϽŰ�

/// 16 keypad
module key_pad_cntr(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value, // Ű�� 16�� �־ 4bit�ؾ���
    output reg key_valid // �ƹ��͵� �� ���������� ���� �ʿ��� ����
    );
    
    reg [19:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    wire clk_8msec;
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .p_edge(clk_8msec_p), .n_edge(clk_8msec_n));
    
    always @(posedge clk_div or posedge reset_p)begin  
        if (reset_p) col = 4'b0001;
        else if(clk_8msec_p && !key_valid)begin
            case(col)
                4'b0001 : col = 4'b0010;
                4'b0010 : col = 4'b0100;
                4'b0100 : col = 4'b1000;
                4'b1000 : col = 4'b0001;
                default : col = 4'b0001;
            endcase
        end
    end
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) begin
            key_value = 0;
            key_valid = 0; 
        end
        else begin
            if(clk_8msec_n)begin
                if(row)begin // 
                    key_valid = 1;
                    case({col, row})
                        8'b0001_0001: key_value = 4'h7; //0
                        8'b0001_0010: key_value = 4'h4; //1
                        8'b0001_0100: key_value = 4'h1; //2
                        8'b0001_1000: key_value = 4'hC; //3 // CUV
                        
                        8'b0010_0001: key_value = 4'h8; //4
                        8'b0010_0010: key_value = 4'h5; //5
                        8'b0010_0100: key_value = 4'h2; //6
                        8'b0010_1000: key_value = 4'h0; //7
                        
                        8'b0100_0001: key_value = 4'h9; //8
                        8'b0100_0010: key_value = 4'h6; //9
                        8'b0100_0100: key_value = 4'h3; //A
                        8'b0100_1000: key_value = 4'hF; //b //equal
                        
                        8'b1000_0001: key_value = 4'hA; //C // +
                        8'b1000_0010: key_value = 4'hb; //d // -
                        8'b1000_0100: key_value = 4'hE; //E // *
                        8'b1000_1000: key_value = 4'hd; //F // /
                    endcase
                end
                else begin  
                    key_valid = 0;
                    key_value = 0;
                end
            end
        end
    end
endmodule


//���� : key_valid �� edge�� ��� pos or neg�� �޾Ƽ�, 1 ������ ī��Ʈ�� ���� 2��  ����
//16bit keyī���� ����� �� keyī���� ���� fnd�� ����϶�
//���� ��� ��

//03.18. �̰� �����ڴ� �ʱ� ����
module keypad_cntr_FSM( // ������ȸ���̴�.
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg [3:0] key_value,
    output reg key_valid
);
//parameter�� ���� ���ٲٴ� ��� �����ҋ� ����.
    parameter SCAN_0 =      1; //5'b00001;
    parameter SCAN_1 =      2; //5'b00010;
    parameter SCAN_2 =      3; //5'b00100;
    parameter SCAN_3 =      4; //5'b01000;
    parameter KEY_PROCESS = 5; //5'b10000; �̷��� �൵�ȴ�.
    
    reg [4:0] state, next_state;
    
    always @* begin
        case(state)
            SCAN_0: begin
                if(row == 0)next_state = SCAN_1;
                else next_state = KEY_PROCESS;
            end
            SCAN_1: begin
                if(row == 0)next_state = SCAN_2;
                else next_state = KEY_PROCESS;
            end
            SCAN_2: begin
                if(row == 0)next_state = SCAN_3;
                else next_state = KEY_PROCESS;
            end
            SCAN_3: begin
                if(row == 0)next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
            KEY_PROCESS: begin
                if(row != 0)next_state = KEY_PROCESS;
                else next_state = SCAN_0;
            end
        endcase
    end
    
    reg [19:0] clk_div;
    always @(posedge clk)clk_div = clk_div + 1;
    wire clk_8msec;
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .p_edge(clk_8msec));
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)state = SCAN_0;
        else if(clk_8msec) state = next_state;
    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            key_value = 0;
            key_valid = 0;
            col = 4'b0001;
        end
        else begin
            case(state)
                SCAN_0: begin col = 4'b0001; key_valid = 0; end
                SCAN_1: begin col = 4'b0010; key_valid = 0; end
                SCAN_2: begin col = 4'b0100; key_valid = 0; end
                SCAN_3: begin col = 4'b1000; key_valid = 0; end
                KEY_PROCESS: begin
                    key_valid = 1;
                    case({col, row})
                        8'b0001_0001: key_value = 4'h7; //0
                        8'b0001_0010: key_value = 4'h4; //1
                        8'b0001_0100: key_value = 4'h1; //2
                        8'b0001_1000: key_value = 4'hC; //3 // CUV
                        
                        8'b0010_0001: key_value = 4'h8; //4
                        8'b0010_0010: key_value = 4'h5; //5
                        8'b0010_0100: key_value = 4'h2; //6
                        8'b0010_1000: key_value = 4'h0; //7
                        
                        8'b0100_0001: key_value = 4'h9; //8
                        8'b0100_0010: key_value = 4'h6; //9
                        8'b0100_0100: key_value = 4'h3; //A
                        8'b0100_1000: key_value = 4'hF; //b //equal
                        
                        8'b1000_0001: key_value = 4'hA; //C // +
                        8'b1000_0010: key_value = 4'hb; //d // -
                        8'b1000_0100: key_value = 4'hE; //E // *
                        8'b1000_1000: key_value = 4'hd; //F // /
                    endcase
                end
            endcase
        end
    end
    
endmodule

/////////////////////////FSM �½�������
module dht11(
    input clk, reset_p,
    inout dht11_data, // inout �� �ϳ��� input output �Ѵ� ������ // input�� �ֱ� ������ reg�� ��������.
    output reg [7:0] humidity, temperature,
    output [7:0] led_bar
);
    parameter S_IDLE        = 6'b000001;
    parameter S_LOW_18MS    = 6'b000010;
    parameter S_HIGH_20US   = 6'b000100;
    parameter S_LOW_80US    = 6'b001000;
    parameter S_HIGH_80US   = 6'b010000;
    parameter S_READ_DATA   = 6'b100000;
    
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
    
    wire dht_pedge, dht_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));
    
    reg [5:0] state, next_state;
    reg [1:0] read_state;
        
    assign led_bar[5:0] = state;
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
    reg [39:0] temp_data;
    reg [5:0] data_count;
    
    reg dht11_buffer; // dht11_data�� reg�� ������� ������ ���� reg
    assign dht11_data = dht11_buffer;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec_e = 0;
            next_state = S_IDLE;
            dht11_buffer = 1'bz; // ���Ǵ��� : ���⼭ ���ڴ�. // inout�� ������ �ݵ�� �̷� ������ ���Ǵ����� ����Ѵ�.
            read_state = S_WAIT_PEDGE;
            data_count = 0;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd3_000_000)begin // 3�ʰ� ���������� // ���� 3��(3_000_000)�� �־����
                        count_usec_e = 1; 
                        dht11_buffer = 1'bz; 
                    end
                    else begin // 3�ʰ� �����ų� ������ 
                        next_state = S_LOW_18MS;
                        count_usec_e = 0; // clear�س��� ���� S_LOW_18MS ���� ���� �ؾ��Ѵ�.
                    end
                end
                S_LOW_18MS:begin // dht11�� 0���� ����Ʈ�����Ѵ�. 18MS���� 0 �ָ�ȴ�. // "�ּ�" 18ms���� �� �� �൵�ȴ�.
                    if(count_usec < 22'd20_000)begin // �ð��� ���°ſ��� d (decimal)
                        count_usec_e = 1; // enable �� 1�� �༭ ī���͸� �����ϰ� �Ѱ�
                        dht11_buffer = 0; 
                    end
                    else begin
                        count_usec_e = 0;
                        next_state = S_HIGH_20US;
                        dht11_buffer = 1'bz;
                    end
                end
                S_HIGH_20US:begin // high (Ǯ��)�� ���ٰ� ��ٷ���.nedge�� ���ö�����
                    count_usec_e = 1;
                    if(dht_nedge)begin
                        next_state = S_LOW_80US;
                        count_usec_e = 0;
                    end
                    if(count_usec > 22'd20_000)begin // ���࿡ ���� error�� ���� ���
                        next_state =S_IDLE; // 20us���� ������ ��� ������ ���Ұ�� IDLE ���·� ���ư��� ����� �ڵ�
                        count_usec_e = 0;
                    end
                end
                S_LOW_80US:begin
                    count_usec_e = 1;
                    if(dht_pedge)begin
                        next_state = S_HIGH_80US;
                        count_usec_e = 0;
                    end
                    if(count_usec > 22'd20_000)begin // ���࿡ ���� error�� ���� ���
                        next_state =S_IDLE; // 20us���� ������ ��� ������ ���Ұ�� IDLE ���·� ���ư��� ����� �ڵ�
                        count_usec_e = 0;
                    end
                end
                S_HIGH_80US:begin
                    count_usec_e = 1;
                    if(dht_nedge)begin // nedge�� �߸� read data ��
                        next_state = S_READ_DATA;
                        count_usec_e = 0;
                    end
                    if(count_usec > 22'd20_000)begin // ���࿡ ���� error�� ���� ���
                        next_state =S_IDLE; // 20us���� ������ ��� ������ ���Ұ�� IDLE ���·� ���ư��� ����� �ڵ�
                        count_usec_e = 0;
                    end
                end
                S_READ_DATA:begin // data count�� 40���� �Ǹ� �ٽ� IDLE�� ����ȴ�.
                    case(read_state)
                        S_WAIT_PEDGE:begin
                            if(dht_pedge)begin
                                read_state = S_WAIT_NEDGE;
                            end
                            count_usec_e = 0;
                        end
                        S_WAIT_NEDGE:begin
                            if(dht_nedge)begin // count usec ���� �����Ѵ�. 30�̵� 50�̵� ���� ������ 0�� ���� ũ�� 1�� ����?
                                if(count_usec < 50)begin
                                    temp_data = {temp_data[38:0], 1'b0};
                                end
                                else begin
                                    temp_data = {temp_data[38:0], 1'b1};
                                end
                                data_count = data_count + 1;
                                read_state = S_WAIT_PEDGE;
                            end
                            else begin
                                count_usec_e = 1;
                            end
                        end
                    endcase
                    if(data_count >= 40)begin
                        data_count = 0;
                        next_state = S_IDLE;
                        humidity = temp_data[39:32];
                        temperature = temp_data[23:16];
                        // ���� �߿��Ѱ� ���� if���� ī��Ʈ 40���� ���Դٴ� �Ŵϱ� �½��� ��¸� �ϸ�ȴ�. 
                    end
                    if(count_usec > 22'd50_000)begin // ���࿡ ���� error�� ���� ���
                        data_count = 0;
                        next_state =S_IDLE; // 20us���� ������ ��� ������ ���Ұ�� IDLE ���·� ���ư��� ����� �ڵ�
                        count_usec_e = 0;
                    end
                end
                default:next_state = S_IDLE;
            endcase
        end
    end
endmodule



////////////////////PWM ��ǳ�� motor
module pwm_128pc(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0] pwm_freq,
    output reg pwm_128
);
    parameter sys_clk_freq = 100_000_000; // cora 125_000_000
    
    integer cnt;
    reg pwm_freqx128; // �� Ŭ���� ���� �ֱⰡ �޶�����.
    
    wire [26:0] temp; // �ý��� Ŭ���� 100_000_000 �̾ 27��Ʈ�� �ʿ�
    assign temp = sys_clk_freq / pwm_freq;
    // �ԷµǴ� �ð����� �����⸦ �ؼ� ����� ���°Ŷ� �䱸�ð��� ���� ������ negtive slack�� ���°Ŵ�.
    // �׸��� assign�� �̱⶧��
    
//    integer cnt_sysclk;
//    always @(posedge clk or posedge reset_p)begin
//        if(reset_p)cnt_sysclk = 0;
//        else if(cnt_sysclk >= pwm_freq - 1)begin
//            cnt_sysclk = 0; // basys �⺻ �ֱⰡ 10ns�̱� ������ 100 ���ؼ� 100usec�� ����� �ִ� ��
//            temp = temp + 1;
//        end
//        else cnt_sysclk = cnt_sysclk + 1;
//    end
    
    // sys_clk�� pwm_freq�� ������ �� 2�� ������ �� 100���� ������ , pwm_freqx100�� toggle �����ش�.
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            pwm_freqx128 = 0;
            cnt = 0;
        end
        else begin // ������ ��ſ� 2���� shift�� �ϸ�ȴ�.
            if(cnt >= temp[26:7] - 1) cnt = 0; // 10000hz ���鶧 (cnt >= sys_clk_freq/pwm_freq/100-1)
            else cnt = cnt + 1;
                
            if(cnt < temp[26:8]) pwm_freqx128 = 0; // 10000hz ���� �� (cnt >= sys_clk_freq/pwm_freq/100/2)
            else pwm_freqx128 = 1;
        end
    end
    
    wire pwm_freqx128_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqx128), .n_edge(pwm_freqx128_nedge));
    
    reg [6:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty  = 0;
            pwm_128 = 0;
        end
        else begin // 127 �ܰ�� ��� �����ѰŴ�. 7��Ʈ�� ������
            if(pwm_freqx128_nedge)begin
                cnt_duty = cnt_duty + 1;
//                if(cnt_duty >= 99) cnt_duty = 0;
//                else cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty)pwm_128 = 1;
                else pwm_128 = 0;
            end
        end
    end
endmodule

////////////////���� SG90 ��� ������ ������ �� �ְ� ������
module pwm_256step(
    input clk, reset_p,
    input [7:0] duty,
    input [13:0] pwm_freq,
    output reg pwm_servo
);

    parameter sys_clk_freq = 100_000_000;
    
    integer cnt;
    reg pwm_freqx256;
    
    wire [26:0] temp;
    assign temp = sys_clk_freq / pwm_freq;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            pwm_freqx256 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:8] - 1) cnt = 0;
            else cnt = cnt + 1;
            
            if(cnt >= temp[26:9]) pwm_freqx256 = 0;
            else pwm_freqx256 = 1;
        end
    end
    
    wire pwm_freqx256_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqx256), .n_edge(pwm_freqx256_nedge));
    
    reg [7:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_servo = 0;
        end
        else begin
            if(pwm_freqx256_nedge)begin
                cnt_duty = cnt_duty + 1;
                if(cnt_duty < duty)pwm_servo = 1;
                else pwm_servo = 0;
            end
        end
    end
endmodule

module pwm_512step(
    input clk, reset_p,
    input [8:0] duty,
    input [13:0] pwm_freq,
    output reg pwm_servo
);

    parameter sys_clk_freq = 100_000_000;
    
    integer cnt;
    reg pwm_freqx512;
    
    wire [26:0] temp;
    assign temp = sys_clk_freq / pwm_freq;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            pwm_freqx512 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:9] - 1) cnt = 0;
            else cnt = cnt + 1;
            
            if(cnt >= temp[26:10]) pwm_freqx512 = 0;
            else pwm_freqx512 = 1;
        end
    end
    
    wire pwm_freqx512_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqx512), .n_edge(pwm_freqx512_nedge));
    
    reg [8:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_servo = 0;
        end
        else begin
            if(pwm_freqx512_nedge)begin
                cnt_duty = cnt_duty + 1;
                if(cnt_duty < duty)pwm_servo = 1;
                else pwm_servo = 0;
            end
        end
    end
endmodule

module pwm_100pc_sf(
    input clk, reset_p,
    input [6:0] duty, //���� ������ ��Ƽ ��
    input [13:0] pwm_freq,//���� ������ ���ļ�
    output reg pwm_100pc //100���� �����ϹǷ� 100��
);
    parameter sys_clk_freq = 100_000_000;    //cora �� 125_000_000
    
    integer cnt=0;
    reg pwm_freqX100=0;
    reg [6:0] cnt_duty=0;
    wire pwm_freq_nedge;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX100), .n_edge(pwm_freq_nedge));
    
    always @(posedge clk or posedge reset_p) begin  //�Էµ� ���ļ��� ������ ���� clk pulse ����
        if(reset_p)begin
            pwm_freqX100 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= sys_clk_freq / pwm_freq / 100 -1) cnt =0;
            else cnt = cnt +1;
            
            if (cnt<sys_clk_freq / pwm_freq/ 100/ 2) pwm_freqX100=0;
            else pwm_freqX100 = 1;
        end
    end
    
    always @(posedge clk or posedge reset_p)begin //��Ƽ �� ����
        if(reset_p)begin
            cnt_duty = 0;
            pwm_100pc = 0;
        end
        else begin
                if(pwm_freq_nedge)begin
                    if(cnt_duty >= 99) cnt_duty = 0;
                    else cnt_duty = cnt_duty + 1;
                    if(cnt_duty < duty)pwm_100pc = 1;
                    else pwm_100pc = 0;
                end
        end
    end
endmodule


// servo �ֱⰡ 20ms = ���ļ� 50hz
// 100,000,000hz / 50hz / 512  = 3906.25 ( (1/10ns) / (1/20ns) / 512 )// 20ms�� ������� 50���� �����Ű�, 512���� ī��Ʈ �ҷ��� 512�� ��������. �׷��� 1 count�� 3906
// 39us * 512 �ϸ� 20ms �� ���´�.
//////�¹������� �Ѱ� �غ���
module pwm_512_period( // ���ļ� ���� �ֱ�� ������.
    input clk, reset_p,
    input [20:0] duty,
    input [20:0] pwm_period, // temp[26:9]�� 18bit���� 18bit �� ��
    output reg pwm_512
);    
    reg [20:0] cnt_duty;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_duty = 0;
            pwm_512 = 0;
        end
        else begin
            if(cnt_duty >= pwm_period - 1)cnt_duty = 0;
            else cnt_duty = cnt_duty + 1;
            
            if(cnt_duty < duty)pwm_512 = 1;
            else pwm_512 = 0;
        end
    end
endmodule

//////////I2C ��Ÿ��
module I2C_master(
    input clk, reset_p,
    input rd_wr,
    input [6:0] addr,
    input [7:0] data,
    input valid,
    output reg sda, // �츮�� �����⸸ �ҰŶ� output�� sda�� �����Ŵ�. ������ in out �Ѵ� �� �� �־ inout�� �� ���� �ִ�.
    output reg scl 
);
    parameter IDLE          = 7'b000_0001;
    parameter COMM_START    = 7'b000_0010; 
    parameter SND_ADDR      = 7'b000_0100;
    parameter RD_ACK        = 7'b000_1000; // ACK Analog?
    parameter SND_DATA      = 7'b001_0000;
    parameter SCL_STOP      = 7'b010_0000;
    parameter COMM_STOP     = 7'b100_0000; // comunication ��� STOP
    
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};
    
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    reg [2:0] count_usec5;
    reg scl_toggle_e;
    
    // I2C ����� ���� ������ ������ ������� // 1us�� 10us�� �ٲ۰�, ��, 1MHz�� 100KHz�� �ٲ۰�
    always @(posedge clk or posedge reset_p)begin // 10���ֱ� ����� // 
        if(reset_p)begin
            count_usec5 = 0;
            scl = 1; // IDLE ���¿����� 1�� ���� �Ǿ���ؼ� 1�̴�.
        end
        else if(scl_toggle_e)begin
            if(clk_usec)begin
                if(count_usec5 >= 4)begin
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;
            end
        end
        else if(scl_toggle_e == 0) count_usec5 = 0;
    end
    
    wire scl_nedge, scl_pedge;
    edge_detector_n ed_scl(.clk(clk), .reset_p(reset_p), .cp(scl), .n_edge(scl_nedge), .p_edge(scl_pedge));
    
    wire valid_pedge;
    edge_detector_n ed_valid(.clk(clk), .reset_p(reset_p), .cp(valid), .p_edge(valid_pedge));
    
    reg [6:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg [2:0] cnt_bit; // down_count�� �ʿ���.
    reg stop_data;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            sda = 1;
            next_state = IDLE;
            scl_toggle_e = 0;
            cnt_bit = 7;
            stop_data = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(valid_pedge) next_state = COMM_START;
                end
                COMM_START:begin
                    sda = 0;
                    scl_toggle_e = 1;
                    next_state = SND_ADDR;
                end
                SND_ADDR:begin
                    if(scl_nedge) sda = addr_rw[cnt_bit];
                    else if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                RD_ACK:begin
                    if(scl_nedge) sda = 'bz; // ���Ʈ�� ���� �� z�� ����
                    else if(scl_pedge)begin
                        if(stop_data)begin
                            stop_data = 0;
                            next_state = SCL_STOP;
                        end
                        else begin
                            next_state = SND_DATA;
                        end
                    end
                end
                SND_DATA:begin
                    if(scl_nedge) sda = data[cnt_bit];
                    else if(scl_pedge)begin
                        if(cnt_bit == 0)begin
                            cnt_bit = 7;
                            next_state = RD_ACK;
                            stop_data = 1;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                SCL_STOP:begin
                    if(scl_nedge)begin
                        sda = 0;
                    end
                    else if(scl_pedge)begin
                        next_state = COMM_STOP;
                    end
                end
                COMM_STOP:begin
                    if(count_usec5 >= 3)begin
                        sda = 1;
                        scl_toggle_e = 0;
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end
endmodule

// 1byte ������(text) ������ ���
module I2C_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr,
    input [127:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy
);
    parameter IDLE                      = 6'b00_0001;
    parameter SEND_HIGH_NIBBLE_DISABLE  = 6'b00_0010;
    parameter SEND_HIGH_NIBBLE_ENABLE   = 6'b00_0100;
    parameter SEND_LOW_NIBBLE_DISABLE   = 6'b00_1000;
    parameter SEND_LOW_NIBBLE_ENABLE    = 6'b01_0000;
    parameter SEND_DISABLE              = 6'b10_0000;
    
    reg [7:0] data;
    reg valid;
    
    reg [21:0] count_usec;
    reg count_usec_e;
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    wire send_pedge;
    edge_detector_n ed_send(.clk(clk), .reset_p(reset_p), .cp(send), .p_edge(send_pedge));
    
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
        if(reset_p) state = IDLE;
        else state = next_state;
    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            busy = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(send_pedge)begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                        busy = 1;
                    end
                end
                SEND_HIGH_NIBBLE_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[7:4], 3'b100, rs}; // {[d7 d6 d5 d4] [BL EN RW] RS} 
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin 
                        next_state = SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[7:4], 3'b110, rs}; // {[d7 d6 d5 d4] [BL EN RW] RS} 
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin 
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_LOW_NIBBLE_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[3:0], 3'b100, rs}; // {[d7 d6 d5 d4] [BL EN RW] RS} 
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin 
                        next_state = SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_LOW_NIBBLE_ENABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[3:0], 3'b110, rs}; // {[d7 d6 d5 d4] [BL EN RW] RS} 
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin 
                        next_state = SEND_DISABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end
                end
                SEND_DISABLE:begin
                    if(count_usec <= 22'd200)begin
                        data = {send_buffer[3:0], 3'b100, rs}; // {[d7 d6 d5 d4] [BL EN RW] RS} 
                        valid = 1;
                        count_usec_e = 1;
                    end
                    else begin 
                        next_state = IDLE;
                        count_usec_e = 0;
                        valid = 0;
                        busy = 0;
                    end
                end
            endcase
        end
    end
    
    I2C_master master(.clk(clk), .reset_p(reset_p), .rd_wr(0), .addr(7'h27), .data(data), .valid(valid), .sda(sda), .scl(scl));
    
endmodule


module counter_pwm(         //�Ŀ�, ���� �ܰ� ����
    input clk, reset_p,
    input btn_pedge,
    output reg [7:0] power,
    output reg[2:0] led
    );
    reg [1:0] cnt;
    
     always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt = 0;
            power = 0;
            led =0;
        end
        else if (btn_pedge) begin                       
            cnt = cnt + 1;
            case(cnt)
                2'b00 : begin
                    power = 7'd0;
                    led = 0;                    
                end       
                2'b01 : begin
                   led =0;
                    power = 7'd42;
                    led[0] = 1;
                end                                
                2'b10 : begin
                    led = 0;
                    power = 7'd84;
                    led[1] = 1;
                end 
                2'b11 : begin
                    led =0;
                    power = 7'd127;
                    led[2] = 1;
                end             
                default  power = 7'd0 ;
            endcase               
        end           
    end
endmodule
/////////////////////////////////////////////////////////////////////////////////////
module pwm_128step_fan(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0]pwm_freq,
    output reg pwm_128
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  
    
    reg[26:0] cnt;
    reg pwm_freqX128;
    
    wire [26:0]temp; //100_000_000 ������   
   
    integer cnt_sysclk;
    assign temp = sys_clk_freq/pwm_freq;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX128 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:7] - 1) cnt = 0;//�߶� ������ == shift����,,, �ݴ�� 0 �߰�
            else cnt = cnt + 1;
                
            if(cnt <temp[26:8]) pwm_freqX128 = 0;
            else pwm_freqX128 = 1;
        end               
    end
   
    wire pwm_freqX100_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX128),.n_edge(pwm_freqX100_nedge));
    
    reg [6:0] cnt_duty;
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_128 = 0;            
        end
        else begin
            if(pwm_freqX100_nedge) begin
                                                   
                cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty) pwm_128 = 1;
                else pwm_128 = 0;
            end
              
        end
    end   
endmodule   
/////////////////////////////////////////////////////////////////////////////
module loadable_downcounter_dec_60_fan( //Ÿ�̸� ���� �δ���ī����
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1,
    output reg [3:0] dec1, dec10,
    output reg dec_clk
    );
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = 0;
            end
            else if(clk_time) begin
                if(dec1 == 0) begin  //0���� �۾��� �� ����
                     dec1 = 9;
                     if (dec10 == 0) begin
                        dec10 =5;
                        dec_clk = 1; // cooktimer����� �� 00����  59�� ���� �� 1�б��̰� ����ȭ
                     end
                     else dec10 = dec10 - 1;
                end
                else dec1 = dec1 -1;
            end
            else dec_clk =0; // ���⼭ 0 �ؼ� ���� ���� �ʿ� ���� (one cycle pulse��)
        end
    end
endmodule
//////////////////////////////////////////////////
module cook_timer_fan(   //Ÿ�̸�
    input clk, reset_p,
    input btn_nedge,
    input btn_pedge,
    output [15:0] value,
    output reg [2:0]led_timer
    );
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10;
    wire load_enable;
    wire dec_clk, clk_start;
    wire [15:0]  cur_time;
   
    clock_usec usec_clk(clk_start, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk_start, reset_p, clk_msec, clk_sec);
    
    reg timer_e;
    reg [1:0] cnt;
    reg [5:0] timer135;
    wire timeout_e_pedge;
    reg timeout_e;
    
     assign clk_start = timer_e ? clk : 0;
    
     always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt = 0;
            timer135 = 0;
            timer_e = 0;
        end
        else if (btn_nedge) timer_e = 1;
        else if (btn_pedge) begin
            timer_e= 0;
            cnt = cnt + 1;
            case(cnt)
                2'b00 : begin
                    timer135 = 0;
                    led_timer = 0;
               end
                2'b01 : begin
                    led_timer = 0;
                    timer135 = 1;
                    led_timer[0] = 1;
                end
                2'b10 : begin
                    led_timer = 0;
                    timer135 = 3;
                    led_timer[1] = 1;
                end
                2'b11 : begin
                    led_timer = 0;
                    timer135 = 5;
                    led_timer[2] = 1;
                end
                default  timer135 = 0 ;
             endcase
            end
        else if (timeout_e_pedge) timer_e = 0;
    end
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(timer_e), .p_edge(load_enable));
    
    loadable_downcounter_dec_60_fan cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(load_enable),
                .dec1(cur_sec1), .dec10(cur_sec10), .dec_clk(dec_clk));
    loadable_downcounter_dec_60_fan cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(load_enable),
                 .set_value1(timer135), .dec1(cur_min1), .dec10(0));
    
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            timeout_e = 0;
        end
        else begin
            if (timer_e && clk_msec && cur_time == 0) begin
                timeout_e = 1;
            end
            else begin
                timeout_e =0;
            end
        end
    end
    
    edge_detector_n ed_timeout_e(.clk(clk), .reset_p(reset_p), .cp(timeout_e),  .p_edge(timeout_e_pedge));
   
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign value = timer_e ? cur_time : 0;
    reg [16:0] clk_div =0;
    always @(posedge clk) clk_div = clk_div +1;
endmodule


module LCD_DHT11(
    input clk, reset_p,
    inout dht11_data,
    output scl, sda
);
    
    wire [7:0] humidity, temperature;
    
    dht11 dht(clk, reset_p, dht11_data, humidity, temperature);
    
    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000, humidity}), .bcd(bcd_humi));
    bin_to_dec tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr)); 
    
    
endmodule


///////////////////////��ǳ�� ��������Ʈ �ϼ�/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module led_brightness( //pull-up �������� ����
    input clk, reset_p,
    input btn,
    output reg led_pwm_o
);

    wire [1:0]led_pwm;
    reg [27:0] clk_div = 0;
    always@(posedge clk) clk_div =clk_div+1;
    
    pwm_100pc_sf led0(.clk(clk), //1��
              .reset_p(reset_p),
              .duty(50),
              .pwm_freq(1_000_000),
              .pwm_100pc(led_pwm[0])
              );
              
    pwm_100pc_sf led1(.clk(clk), //2��
              .reset_p(reset_p),
              .duty(90),
              .pwm_freq(1_000_000),
              .pwm_100pc(led_pwm[1])
              );
    
    wire btn_pedge;        
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge));         
            
    reg [1:0]cnt_btn; //0,1,2,3 -> ����, 1,2,3�ܰ� ���        
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
    
    pwm_100pc_sf led0(.clk(clk), //1��
              .reset_p(reset_p),
              .duty(25),
              .pwm_freq(1_00),
              .pwm_100pc(motor_pwm[0])
              );
              
    pwm_100pc_sf led1(.clk(clk), //2��
              .reset_p(reset_p),
              .duty(45),
              .pwm_freq(1_00),
              .pwm_100pc(motor_pwm[1])
              );
    wire btn_pedge;        
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn), .btn_pe(btn_pedge));         
            
    reg [1:0]cnt_btn; //0,1,2,3 -> ����, 1,2,3�ܰ� ���        
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


module fan_timer(   //Ÿ�̸�
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
    
    wire btn_start, inc_sec, inc_min, alarm_off; //��ư 0�� 1�� 2�� 3��
    wire [3:0] set_sec1, set_sec10, set_min1, set_min10;
    wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10;
    wire load_enable, dec_clk, clk_start; //clk_start : start���� ���� Ŭ���� �������� ��
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
    
    always@(posedge clk or posedge reset_p) begin //1->3->5��->Ÿ�̸� ����
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

/////////////////UltraSonic �����ļ���
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
                                cnt_e = 1;  //�߰�
                            end
                        end
                        S_WAIT_NEDGE:begin
                            if(echo_nedge)begin       
                                read_state = S_WAIT_PEDGE;
                                count_usec_e = 0;                    
                                distance = cm;  //�߰�
                                    
                                cnt_e =0;       //�߰�
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