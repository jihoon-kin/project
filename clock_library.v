`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module clock_usec( // 마이크로세크 클럭 만들기
    input clk, reset_p,
    output clk_usec // 1usec가 주기인 clk
    );
    
    reg [7:0] cnt_sysclk; // 10ns
    wire cp_usec;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)cnt_sysclk = 0;
        else if(cnt_sysclk >= 99) cnt_sysclk = 0; // basys 기본 주기가 10ns이기 떄문에 100 곱해서 100usec로 만들어 주는 것
        else cnt_sysclk = cnt_sysclk + 1;
    end
    
    assign cp_usec = (cnt_sysclk < 50) ? 0 : 1; // 0.5usec일떄 상승엣지 이고 1usec일떄 하강엣지기 떄문에 n_edge를 쓰는게 낫다.
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_usec), .n_edge(clk_usec));  
    
endmodule

module clock_div_1000( // 1000 분주기 //1000 분주기 만들려면 인스턴스 두개 붙여서 만들면됨.
    input clk, reset_p,
    input clk_source,
    output clk_div_1000
    );
    
    reg [8:0] cnt_clk_source;
    reg cp_div_1000;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_clk_source = 0;
            cp_div_1000 = 0;
        end
        else if(clk_source) begin
            if(cnt_clk_source >= 499) begin // 한주기를 1000으로 만드려고 1 ~ 499까지 0인 상태고, 500 ~999까지 1인상태를 만들기 위함이다. , 
                cnt_clk_source = 0;
                cp_div_1000 = ~cp_div_1000;
            end
            else cnt_clk_source = cnt_clk_source +1;
        end
    end

    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_div_1000), .n_edge(clk_div_1000));  // usec 1000개 심어서 한클락을 만듯
    
endmodule

// 10ms 에서 1sec로 만드는 100분주기///////////
module clock_div_100( 
    input clk, reset_p,
    input clk_source,
    output clk_div_100
    );
    
    reg [8:0] cnt_clk_source;
    reg cp_div_100;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_clk_source = 0;
            cp_div_100 = 0;
        end
        else if(clk_source) begin
            if(cnt_clk_source >= 49) begin // 한주기를 1000으로 만드려고 1 ~ 499까지 0인 상태고, 500 ~999까지 1인상태를 만들기 위함이다. , 
                cnt_clk_source = 0;
                cp_div_100 = ~cp_div_100;
            end
            else cnt_clk_source = cnt_clk_source +1;
        end
    end

    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_div_100), .n_edge(clk_div_100));  
    
endmodule


// 1ms 에서 10ms로 만드는 10분주기///////////
module clock_div_10( 
    input clk, reset_p,
    input clk_source,
    output clk_div_10
    );
    
    reg [2:0] cnt_clk_source;
    reg cp_div_10;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_clk_source = 0;
            cp_div_10 = 0;
        end
        else if(clk_source) begin
            if(cnt_clk_source >= 4) begin
                cnt_clk_source = 0;
                cp_div_10 = ~cp_div_10;
            end
            else cnt_clk_source = cnt_clk_source +1;
        end
    end

    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_div_10), .n_edge(clk_div_10));  
    
endmodule

/////////1분에 한 클락씩 나오는거
module clock_min( 
    input clk, reset_p,
    input clk_sec,
    output clk_min
    );
    
    reg [4:0] cnt_sec; // 초를 세는 카운트
    reg cp_min;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt_sec = 0;
            cp_min = 0;
        end
        else if(clk_sec) begin
            if(cnt_sec >= 29) begin
                cnt_sec = 0;
                cp_min = ~cp_min;
            end
            else cnt_sec = cnt_sec +1;
        end
    end

    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(cp_min), .n_edge(clk_min));  
    
endmodule

module counter_dec_60( // 10진수 데시몰로 60까지 세는 카운트
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(clk_time)begin
                if(dec1 >= 9)begin
                    dec1 = 0;
                    if(dec10 >= 5)dec10 = 0;
                    else dec10 = dec10 + 1;
                end
                else dec1 = dec1 +1; 
            end
        end
     end
endmodule

module downcounter_dec_60( // 10진수 데시몰로 60까지 세는 카운트
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(clk_time)begin
                if(dec1 <= 9)begin
                    dec1 = 0;
                    if(dec10 <= 5)dec10 = 0;
                    else dec10 = dec10 - 1;
                end
                else dec1 = dec1 - 1; 
            end
        end
    end 

endmodule

////////덮어쓰기하려고 만드는 모듈 // 시계 만드는 다른방법
module loadable_counter_dec_60( // 10진수 데시몰로 60까지 세는 카운트
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = set_value10;
             end
             else if(clk_time)begin
                if(dec1 >= 9)begin
                    dec1 = 0;
                    if(dec10 >= 5)dec10 = 0;
                    else dec10 = dec10 + 1;
                end
                else dec1 = dec1 +1; 
            end
        end
    end 

endmodule

module loadable_downcounter_dec_60( // 10진수 데시몰로 60까지 세는 카운트
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10,
    output reg dec_clk
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = set_value10;
             end
             else if(clk_time)begin
                if(dec1 == 0)begin
                    dec1 = 9;
                    if(dec10 == 0)begin
                        dec10 = 5;
                        dec_clk = 1; // 분이 0에서 5로 바뀌면서 초도 0에서 9로 내려갈때 클럭을 줘서 분 카운트 동기를 맞추게하였음.
                    end
                    else dec10 = dec10 - 1;
                end
                else dec1 = dec1 - 1; 
            end
            else dec_clk = 0; // 한클락짜리라서 edge를 잡을 필요도 없다.
        end
    end 

endmodule

module loadable_downcounter_dec_3( // 10진수 데시몰로 60까지 세는 카운트
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10,
    output reg dec_clk
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = set_value10;
             end
             else if(clk_time)begin
                if(dec1 == 3)begin
                    dec1 = dec1 - 1; 
                    dec_clk = 1;
                end
                else if(dec1 == 2)begin
                    dec1 = dec1 - 1; 
                    dec_clk = 1;
                end
                else if(dec1 == 1)begin
                    dec1 = dec1 - 1; 
                    dec_clk = 1;
                end
            end
            else dec_clk = 0; // 한클락짜리라서 edge를 잡을 필요도 없다.
        end
    end 
endmodule

module counter_dec_100( // 10진수 데시몰로 100까지 세는 카운트
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            dec1 = 0;
            dec10 = 0;
        end
        else begin
            if(clk_time)begin
                if(dec1 >= 9)begin
                    dec1 = 0;
                    if(dec10 >= 9)dec10 = 0;
                    else dec10 = dec10 + 1;
                end
                else dec1 = dec1 +1; 
            end
        end
    end 

endmodule

/////////58분주기 - Ultrasonic에서 네거티브 슬랙이 나와서 만들어준 것
module sr04_div58(
    input clk, reset_p,
    input clk_usec, cnt_e,
    output reg [11:0] cm
);
    integer cnt;

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            cm = 0;
            cnt = 0;
        end
        else begin
            if(cnt_e)begin
                if(clk_usec)begin
                    cnt = cnt + 1;
                    if(cnt >= 58)begin
                        cnt = 0;
                        cm = cm + 1;
                    end
                end
            end
            else begin
                cnt = 0;
                cm = 0;
            end
        end
    end 

endmodule










