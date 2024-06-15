`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
////////////////플립플롭
//////nor 래치회로-->> 쓰면안돼

//////D 플립플롭
module D_flip_flop_n( // ck의 negative에서 동작하는 것
    input d,
    input clk,
    input reset_p,
    output reg q
);

    wire d_bar;
    not (d_bar, d);
    
    always @(negedge clk or posedge reset_p) begin // negedge 폴리엣지일떄 한번 실행하라, posedge 라이징엣지일때 한번 실행하라
        if(reset_p) begin q = 0; end 
        else begin q = d; end
    end
    
endmodule


module D_flip_flop_p( // ck의 positive에서 동작하는 것
    input d,
    input clk,
    input reset_p,
    output reg q
);

    wire d_bar;
    not (d_bar, d);
    
    always @(posedge clk or posedge reset_p) begin // 
        if(reset_p) begin q = 0; end //  동시에 클락이 들어오면 if문이 우선이다. 즉, reset 시키겟다.
        else begin q = d; end
    end
    
endmodule

//////JKFF는 쓸일이 없다.
//////T플립플롭
module T_flip_flop_n(
    input clk, reset_p,
    input t,
    output reg q
);
    
    always @(negedge clk or posedge reset_p) begin 
        if(reset_p) begin q = 0; end //
        else begin
        if(t) q = ~q;
        else q = q;
        end
    end
    
endmodule


module T_flip_flop_p(
    input clk, reset_p,
    input t,
    output reg q
);
    
    always @(posedge clk or posedge reset_p) begin 
        if(reset_p) begin q = 0; end //
        else begin
        if(t) q = ~q;
        else q = q;
        end
    end
    
endmodule
///////////////////////////////////
    
module T_flip_flop_n1( /// 이런방법도 있다.
    input clk, reset_p,
    input t,
    output reg q
);
    
    wire qbar;
    reg d;
    assign qbar = ~q;
    
    always @(*)begin // 모든 입력값이 변하면 * 찍어도된다.
        if(t) d = qbar;
        else d = q;
    end
    
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) q = 0;
        else if (t) q = ~q;
        else q = q;
    end

endmodule

////////비동기식 카운터--- negedge에서 변하기때문에 negedge TFF로 만든다.
module up_counter_asyc(
    input clk, reset_p,
    output [3:0] count
);

    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0])); ///T0 : T zero임
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule

//////////비동기식 하향 카운터 --- posedge에서 변하므로 posedge TFF를 이용한다.
module down_counter_asyc(
    input clk, reset_p,
    output [3:0] count
);
    
    T_flip_flop_p T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0])); ///T0 : T zero임
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
    
endmodule

/////////////3비트 동기식 상향 카운터 
module up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else count = count + 1;
    end
    
endmodule

module up_counter_tset_top(  //// .xdc 들어가서 [7,8] clk,  [31~46] count,   [67] reset_p
    input clk, reset_p,
    output [15:0] count
);
    reg [31:0] count_32;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count_32 = 0;
        else count_32 = count_32 + 1;
    end
    
    assign count = count_32[31:16];
    
endmodule



module up_counter_test_top1(  //// .xdc 들어가서 seg 주석풀기
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7);
    
    reg [31:0] count_32;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count_32 = 0;
        else count_32 = count_32 + 1;
    end
    
    assign count = count_32[31:16]; // [15:0]는 눈으로 확인할 수 없을만큼 빠르게 변해서 32bit를 주고 [31:16]를 사용한다. 원래는 없어도 되는문장, 오히려 성능을 낮춘것
    
    decoder_7seg fnd (.hex_value(count_32[28:25]), .seg_7(seg_7)); /// [28:25]를 준 이유는 적당한 속도라서 4bit씩 끊어서 바꾸고 싶은대로 바꿔도됨
    
endmodule


//////////3비트 동기식 하향 카운터
module down_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else count = count - 1;
    end
    
endmodule

//////enable이 포함된 down count
module down_counter_p1(
    input clk, reset_p, enable,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else begin
            if (enable) count = count - 1;
            else count = count;
        end
    end
    
endmodule

////////8비트 count
module down_counter_Nbit_p #(parameter N = 8)(
    input clk, reset_p, enable,
    output reg [N-1:0] count
);

     always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else begin
            if (enable) count = count - 1;
            else count = count;
        end
    end
    
endmodule

//////BCD 10진 up count
module bcd_up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else begin
            count = count + 1;
            if(count == 10) count = 0;
        end
    end
    
endmodule

/////3비트 동기식 상/하향 카운터
module up_down_counter(
    input clk, reset_p,
    input down_up,  /////// 
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count = 0; //// reset_p이 1일때
        else begin ///// reset_p이 1이 아닌 나머지 일때
            if(down_up) count = count - 1;
            else count = count + 1;
        end
    end
endmodule

//////과제 : up_down_counter를 BCD counter로 만들어라.
module bcd_up_down_counter(
    input clk, reset_p,
    input down_up,  /////// 
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count = 0; begin
            if (down_up) begin
                count = count - 1;
                if (count == 15)
                    count = 9;
                end
            else count = count + 1;
                if (count == 10) count = 0;
            end
        end
endmodule

/////////////////과제풀이////////////////
module up_down_bcd_counter(
    input clk, reset_p,
    input down_up, 
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count = 0;
        else begin
            if (down_up)
                if (count == 0) count = 9;
                else count = count - 1;
            else
                if(count == 9) count = 0;
                else count = count + 1;
        end
    end
endmodule

////////링카운터
module ring_counter(
    input clk, reset_p,
    output reg [3:0] q
);

    always @(posedge clk or posedge reset_p)begin
        if (reset_p) q = 4'b0001;
        else begin
            case(q)
                4'b0001 : q = 4'b1000;
                4'b1000 : q = 4'b0100;
                4'b0100 : q = 4'b0010;
                4'b0010 : q = 4'b0001;
                default: q = 4'b0001;
            endcase
        end
    end
endmodule

module ring_counter_1(
    input clk, reset_p,
    output reg [3:0] q
);

    always @(posedge clk or posedge reset_p)begin
        if(reset_p) q = 4'b0001;
        else begin
            if(q == 4'b0001) q = 4'b1000;
            else if(q == 4'b1000) q = 4'b0100;
            else if(q == 4'b0100) q = 4'b0010;
            else if(q == 4'b0010) q = 4'b0001;
            else q = 4'b0001;
        end
    end
endmodule

///출력이 에노드(com)일때
module ring_counter_fnd(
    input clk, reset_p,
    output reg [3:0] com
);
    reg [16:0] clk_div;
    wire clk_div_16;
    
    always @(posedge clk) clk_div = clk_div + 1;
    
    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    always @(posedge clk or posedge reset_p)begin  // [27]에서의 속도만큼 변화한다.
        if (reset_p) com = 4'b1110;
        else if(clk_div_16)begin
            case(com)
                4'b1110 : com = 4'b1101;
                4'b1101 : com = 4'b1011;
                4'b1011 : com = 4'b0111;
                4'b0111 : com = 4'b1110;
                default : com = 4'b1110;
            endcase
        end
    end
endmodule

module three_ring_counter_fnd(
    input clk, reset_p,
    input enable_ring,
    output reg [2:0] com
);
    
    always @(posedge clk or posedge reset_p)begin  // [27]에서의 속도만큼 변화한다.
        if (reset_p) com = 3'b001;
        else if(enable_ring)begin
            case(com)
                3'b001  : com = 3'b010;
                3'b010  : com = 3'b100;
                3'b100  : com = 3'b001;
                default : com = 3'b001;
            endcase
        end
    end
endmodule

module four_ring_counter_fnd(
    input clk, reset_p,
    input enable_ring,
    output reg [3:0] com
);
    
    always @(posedge clk or posedge reset_p)begin  // [27]에서의 속도만큼 변화한다.
        if (reset_p) com = 4'b0001;
        else if(enable_ring)begin
            case(com)
                4'b0001  : com = 4'b0010;
                4'b0010  : com = 4'b0100;
                4'b0100  : com = 4'b1000;
                4'b1000  : com = 4'b0001;
                default : com = 4'b0001;
            endcase
        end
    end
endmodule

module ring_counter_fnd1(
    input clk, reset_p,
    output reg [3:0] com
);
    reg [16:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div - 1;
    
    always @(posedge clk_div[16] or posedge reset_p)begin  // [27]에서의 속도만큼 변화한다.
        if (reset_p) com = 4'b1110;
        else begin
            case(com)
                4'b1110 : com = 4'b1101;
                4'b1101 : com = 4'b1011;
                4'b1011 : com = 4'b0111;
                4'b0111 : com = 4'b1110;
                default: com = 4'b1110;
            endcase
        end
    end
endmodule


////////어렵다 어려워
module up_counter_test_top_2(  //// .xdc 들어가서 seg 주석풀기
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7, 
    output [3:0] com); /// fnd 자리를 지정해주는 변수
          
    reg [31:0] count_32;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count_32 = 0;
        else count_32 = count_32 + 1;
    end
    
    assign count = count_32[31:16]; // [15:0]는 눈으로 확인할 수 없을만큼 빠르게 변해서 32bit를 주고 [31:16]를 사용한다. 원래는 없어도 되는문장, 오히려 성능을 낮춘것
    
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));
    
    reg [3:0] value; /// com에 어떤걸 출력할지 보여주는 변수
    
    always @(posedge clk)begin // posedge 대신에 com으로 줘도되는데 default값도 같이 줘야한다.
        case(com)
            4'b0111: value = count_32[31:28];
            4'b1011: value = count_32[27:24];
            4'b1101: value = count_32[23:20];
            4'b1110: value = count_32[19:16];    
        endcase    
    end
    
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7));
    
endmodule

////////////ring counter LED : 과제
module ring_counter_led(
    input clk, reset_p,
    output reg [15:0] count 
);
    reg [31:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div + 1; // 분주기
    
    always @(posedge clk_div[22] or posedge reset_p)begin
        if (reset_p) count = 16'b0000000000000001;
        else begin
        case(count)
            16'b0000000000000001: count = 16'b0000000000000010;
            16'b0000000000000010: count = 16'b0000000000000100;
            16'b0000000000000100: count = 16'b0000000000001000;
            16'b0000000000001000: count = 16'b0000000000010000;
            16'b0000000000010000: count = 16'b0000000000100000;
            16'b0000000000100000: count = 16'b0000000001000000;
            16'b0000000001000000: count = 16'b0000000010000000;
            16'b0000000010000000: count = 16'b0000000100000000;
            16'b0000000100000000: count = 16'b0000001000000000;
            16'b0000001000000000: count = 16'b0000010000000000;
            16'b0000010000000000: count = 16'b0000100000000000;
            16'b0000100000000000: count = 16'b0001000000000000;
            16'b0001000000000000: count = 16'b0010000000000000;
            16'b0010000000000000: count = 16'b0100000000000000;
            16'b0100000000000000: count = 16'b1000000000000000;
            16'b1000000000000000: count = 16'b0000000000000001;
            default: count = 16'b0000000000000001;                  
        endcase    
        end
    end
endmodule

////////////ring counter LED : 과제 if문
module ring_counter_led_1(
    input clk, reset_p,
    output reg [15:0] count 
);
    reg [20:0] clk_div;
    wire posedge_clk_div_20;
    
    always @(posedge clk, posedge reset_p)begin
        if (reset_p)clk_div = 0;
        else clk_div = clk_div + 1;
    end
    
    always @(posedge clk, posedge reset_p)begin // 서로다른 always문에서 같은 변수를 넣어주면 안된다. 안그럼 short남.
        if (reset_p) begin
            count = 16'b1;
        end
        else begin
            if(posedge_clk_div_20) count = {count[14:0], count[15]}; // 얘가 링카운터 // 15비트가 한자리씩 계속 밀려서 출력값이 나오기 떄문  
//            if(count == 16'b1000_0000_0000_0000) count = 16'b1; // hexa코드 16'b8000 --> hexa보다 binary가 보이게 더 좋다
//            else count = {count[14:0], 1'b0};  //// 주석 두줄은 C언어에서 shift 모듈을 나타낸 것
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[20]), .p_edge(posedge_clk_div_20));
    
endmodule

/////detector
module edge_detector_n(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge
);
    reg ff_cur, ff_old;
    
    always @(negedge clk or posedge reset_p)begin // always문에서 병렬로 동작해야하는지 직렬로 해야하는지 구분해야한다.
        if(reset_p)begin
            ff_cur <= 0; // Non_blocking문은 모듈에 싹다 Non_blocking을 써야함. 
            ff_old <= 0;
        end
        else begin
            ff_cur <= cp; //Non_blocking문(<=): 두개의 회로가 따로 병렬로 동작하는거다. blocking문(=)은 순차적으로 동작하는 것
            ff_old <= ff_cur; // CP에 1이 들어오면 cur=1이 되는데, old는 아직 0이다. 왜냐 순차적이지 않고 동시에 동작하는 두개의 회로이기 떄문
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0; // LUT
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0; // LU도 MUX로 만든다. not gate가 없기 떄문에
    
//    assign p_edge = ff_cur & ~ff_old;
//    assign n_edge = ~ff_cur & ff_old; // 구조적 이어서 쓸일이 없다.
    
endmodule

module edge_detector_p(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge
);
    reg ff_cur, ff_old;
    
    always @(posedge clk or posedge reset_p)begin // always문에서 병렬로 동작해야하는지 직렬로 해야하는지 구분해야한다.
        if(reset_p)begin
            ff_cur <= 0; // Non_blocking문은 모듈에 싹다 Non_blocking을 써야함. 
            ff_old <= 0;
        end
        else begin
            ff_cur <= cp; //Non_blocking문(<=): 두개의 회로가 따로 병렬로 동작하는거다. blocking문(=)은 순차적으로 동작하는 것
            ff_old <= ff_cur; // CP에 1이 들어오면 cur=1이 되는데, old는 아직 0이다. 왜냐 순차적이지 않고 동시에 동작하는 두개의 회로이기 떄문
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0; 
    
//    assign p_edge = ff_cur & ~ff_old;
//    assign n_edge = ~ff_cur & ff_old; // 구조적 이어서 쓸일이 없다.
    
endmodule

//////////ring counter 구조도를 그려서 제출하라.끝

//////////register
module shift_register_SISO_n( // 직렬입력 병렬출력 shift register
    input clk, reset_p,
    input d,
    output q
);

    reg [3:0] siso_reg;

    always @(negedge clk or posedge reset_p)begin
        if(reset_p) siso_reg <= 0;
        else begin
            siso_reg[3] <= d; // nonblocking: 여러문장일 떄 register ??/?/?????
            siso_reg[2] <= siso_reg[3];
            siso_reg[1] <= siso_reg[2];
            siso_reg[0] <= siso_reg[1];            
        end
    end
    assign q = siso_reg[0];

endmodule

//직렬입력 병렬출력 shift register
module shift_register_SIPO_n(
    input clk, reset_p,
    input d,
    input rd_en,
    output [3:0] q
);

    reg [3:0] sipo_reg;
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            sipo_reg = 0;
        end
        else begin
            sipo_reg = {d, sipo_reg[3:1]};
        end
    end

    assign q = rd_en ? sipo_reg : 4'bz; // 4bit 임피던스 Z // 우리는 assign문을 쓸거임, 구조적 코드로 쓰면 더 귀찮음.
    
//    bufif1 (q[0], sipo_reg[0], rd_en); // 1에서 발생하는 현상버퍼 if1 //(출력, 입력, 제어입력) <- 이건 순서가 정해져있는것-
//    bufif1 (q[1], sipo_reg[1], rd_en); // 이런게 있다는 것만 알아둬라
//    bufif1 (q[2], sipo_reg[2], rd_en);
//    bufif1 (q[3], sipo_reg[3], rd_en);
    
endmodule

/////병렬입력 직렬출력 register // 필기참고
module shift_register_PISO(
    input clk, reset_p,
    input [3:0] d, // 외부입력
    input shift_load, // SH/LD
    output q    
);

    reg [3:0] piso_reg;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) piso_reg = 0;
        else begin
            if(shift_load) piso_reg = {1'b0, piso_reg[3:1]};
            else piso_reg = d;
        end
    end
    
    assign q = piso_reg[0]; // 최하위 or 최상위 bit가 하나씩 넘어가면서 저장되기 떄문, 만들기 나름이다.  // 필기 그림 참고 

endmodule

///병렬입력 병렬출력 register -> 얘는 그냥 흔히 아는 레지스터다.
module register_Nbit_p #(parameter N = 8)( 
    input clk, reset_p,
    input [N-1:0] d,
    input wr_en, rd_en,
    output [N-1:0] q
);

    reg [N-1:0] register; // 얘가 register의 실체 
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) register = 0;
        else if(wr_en) register = d; // wr_en 1 줬을때 저장이되는거다. 
    end

    assign q = rd_en ? register : 'bz; // rd-en 1일때만 출력을 내보내는거다. 임피던스 내보낼때는 앞에 몇bit인지 안써도된다. 

endmodule

module sram_8bit_1024( // 필기에 회로도 있음
    input clk, // 메모리는 reset할 필요가 없다. 필요하면 buf 쓰면된다. 
    input wr_en, rd_en,
    input [9:0] addr, // 메모리가 1024개 있으니까 2^10 이어서 10bit 주소
    inout [7:0] data // inout : input도 되고  output도 되는 친구 // 출력하지 않을때는 반드시 임피던스로 끊어줘야한다. 
);

    reg [7:0] mem [0:1023];// mem: memory // 8비트 짜리 메모리 1024개 만들겠다는 뜻 
    
    always @(posedge clk)begin
        if(wr_en) mem[addr] <= data;
    end

    assign data = rd_en ? mem[addr] : 'bz;

endmodule
















//////버튼입력을 받는 FND 카운터///필기에 회로도 있음
module button_test_top(
    input clk, reset_p,
    input btnU,
    output [7:0] seg_7,
    output [3:0] com
);

    reg [15:0] btn_counter;
    reg [3:0] value;
    wire btnU_pedge;
    reg [16:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div + 1;
    wire clk_div_16;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    reg debounced_btn;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btnU;
    end

    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .p_edge(btnU_pedge));

    always @(posedge clk, posedge reset_p)begin // 시스템반도체의 경우: always문 괄호 안에는 clk. reset, enable 밖에 못들어간다. 문법적으로 안되는게 아니라 시스템반도체상 안되는거임.
        if(reset_p)btn_counter = 0;
        else begin
            if(btnU_pedge) btn_counter = btn_counter + 1;
        end
    end
      
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));

    always @(posedge clk)begin 
        case(com)
            4'b0111: value = btn_counter[15:12];
            4'b1011: value = btn_counter[11:8];
            4'b1101: value = btn_counter[7:4];
            4'b1110: value = btn_counter[3:0];    
        endcase    
    end
    
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7));
    
endmodule
///////////////////////////////////////////////////////////////////////////

///////bread board 실습 LED 
//////LED 8bit
module led_bar_top(
    input clk, reset_p,
    output [7:0] led_bar);
    
    reg [28:0] clk_div;
    always @(posedge clk) clk_div = clk_div + 1;
    
    assign led_bar[7:0] = ~clk_div[28:21];
    
endmodule

//////////////////////////////////////////////////
module button_led_bar_top(
    input clk, reset_p,
    input [1:0] btn,
    output [7:0] led_bar
);

    reg [7:0] btn_counter;
    wire [1:0] btnU_pedge;
    reg [16:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div + 1;
    wire clk_div_16; // clk 분주기
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    reg [1:0] debounced_btn;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btn; // 2bit 그대로 받은것
    end

    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btnU_pedge[0])); // 1bit마다 detector를 추가해야한다.
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));
    
    always @(posedge clk, posedge reset_p)begin 
        if(reset_p)btn_counter = 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if (btnU_pedge[1]) btn_counter = btn_counter - 1; /// 여기에 원하는 기능을 추가하면 된다.
        end
    end

    assign led_bar = ~btn_counter; // 출력값이 0으로 나오기 때문에 보기 편하려고 not gate를 써서 출력을 1로 바꿔주는것
    
endmodule
///////////////////////////




///////////btn입력 4FND출력 회로 // 내가 한 것
module button_test_top_(
    input clk, reset_p,
    input [3:0] btnU,
    output [7:0] seg_7,
    output [3:0] com
);

    reg [15:0] btn_counter;
    reg [3:0] value;
    wire [3:0] btnU_pedge;
    reg [16:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div + 1;
    wire clk_div_16;
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    reg [3:0]debounced_btn;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btnU;
    end
    
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btnU_pedge[0]));
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));
    edge_detector_n ed4(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[2]), .p_edge(btnU_pedge[2]));
    edge_detector_n ed5(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[3]), .p_edge(btnU_pedge[3]));

    always @(posedge clk, posedge reset_p)begin // 시스템반도체의 경우: always문 괄호 안에는 clk. reset, enable 밖에 못들어간다. 문법적으로 안되는게 아니라 시스템반도체상 안되는거임.
        if(reset_p)btn_counter = 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if(btnU_pedge[1]) btn_counter = btn_counter - 1;
            else if(btnU_pedge[2]) btn_counter = {btn_counter[14:0], btn_counter[15]};
            else if(btnU_pedge[3]) btn_counter = {btn_counter[0], btn_counter[15:1]};
        end
    end
      
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));

    always @(posedge clk)begin 
        case(com)
            4'b0111: value = btn_counter[15:12];
            4'b1011: value = btn_counter[11:8];
            4'b1101: value = btn_counter[7:4];
            4'b1110: value = btn_counter[3:0];    
        endcase    
    end
    
    wire [7:0] seg_7_bar;
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7_bar));
    assign seg_7 = ~seg_7_bar;
    
endmodule

























