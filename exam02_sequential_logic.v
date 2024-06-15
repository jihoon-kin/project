`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
////////////////�ø��÷�
//////nor ��ġȸ��-->> ����ȵ�

//////D �ø��÷�
module D_flip_flop_n( // ck�� negative���� �����ϴ� ��
    input d,
    input clk,
    input reset_p,
    output reg q
);

    wire d_bar;
    not (d_bar, d);
    
    always @(negedge clk or posedge reset_p) begin // negedge ���������ϋ� �ѹ� �����϶�, posedge ����¡�����϶� �ѹ� �����϶�
        if(reset_p) begin q = 0; end 
        else begin q = d; end
    end
    
endmodule


module D_flip_flop_p( // ck�� positive���� �����ϴ� ��
    input d,
    input clk,
    input reset_p,
    output reg q
);

    wire d_bar;
    not (d_bar, d);
    
    always @(posedge clk or posedge reset_p) begin // 
        if(reset_p) begin q = 0; end //  ���ÿ� Ŭ���� ������ if���� �켱�̴�. ��, reset ��Ű�ٴ�.
        else begin q = d; end
    end
    
endmodule

//////JKFF�� ������ ����.
//////T�ø��÷�
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
    
module T_flip_flop_n1( /// �̷������ �ִ�.
    input clk, reset_p,
    input t,
    output reg q
);
    
    wire qbar;
    reg d;
    assign qbar = ~q;
    
    always @(*)begin // ��� �Է°��� ���ϸ� * ���ȴ�.
        if(t) d = qbar;
        else d = q;
    end
    
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) q = 0;
        else if (t) q = ~q;
        else q = q;
    end

endmodule

////////�񵿱�� ī����--- negedge���� ���ϱ⶧���� negedge TFF�� �����.
module up_counter_asyc(
    input clk, reset_p,
    output [3:0] count
);

    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0])); ///T0 : T zero��
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule

//////////�񵿱�� ���� ī���� --- posedge���� ���ϹǷ� posedge TFF�� �̿��Ѵ�.
module down_counter_asyc(
    input clk, reset_p,
    output [3:0] count
);
    
    T_flip_flop_p T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0])); ///T0 : T zero��
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
    
endmodule

/////////////3��Ʈ ����� ���� ī���� 
module up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else count = count + 1;
    end
    
endmodule

module up_counter_tset_top(  //// .xdc ���� [7,8] clk,  [31~46] count,   [67] reset_p
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



module up_counter_test_top1(  //// .xdc ���� seg �ּ�Ǯ��
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7);
    
    reg [31:0] count_32;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count_32 = 0;
        else count_32 = count_32 + 1;
    end
    
    assign count = count_32[31:16]; // [15:0]�� ������ Ȯ���� �� ������ŭ ������ ���ؼ� 32bit�� �ְ� [31:16]�� ����Ѵ�. ������ ��� �Ǵ¹���, ������ ������ �����
    
    decoder_7seg fnd (.hex_value(count_32[28:25]), .seg_7(seg_7)); /// [28:25]�� �� ������ ������ �ӵ��� 4bit�� ��� �ٲٰ� ������� �ٲ㵵��
    
endmodule


//////////3��Ʈ ����� ���� ī����
module down_counter_p(
    input clk, reset_p,
    output reg [3:0] count
);

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count = 0;
        else count = count - 1;
    end
    
endmodule

//////enable�� ���Ե� down count
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

////////8��Ʈ count
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

//////BCD 10�� up count
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

/////3��Ʈ ����� ��/���� ī����
module up_down_counter(
    input clk, reset_p,
    input down_up,  /////// 
    output reg [3:0] count
);
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) count = 0; //// reset_p�� 1�϶�
        else begin ///// reset_p�� 1�� �ƴ� ������ �϶�
            if(down_up) count = count - 1;
            else count = count + 1;
        end
    end
endmodule

//////���� : up_down_counter�� BCD counter�� ������.
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

/////////////////����Ǯ��////////////////
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

////////��ī����
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

///����� �����(com)�϶�
module ring_counter_fnd(
    input clk, reset_p,
    output reg [3:0] com
);
    reg [16:0] clk_div;
    wire clk_div_16;
    
    always @(posedge clk) clk_div = clk_div + 1;
    
    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    always @(posedge clk or posedge reset_p)begin  // [27]������ �ӵ���ŭ ��ȭ�Ѵ�.
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
    
    always @(posedge clk or posedge reset_p)begin  // [27]������ �ӵ���ŭ ��ȭ�Ѵ�.
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
    
    always @(posedge clk or posedge reset_p)begin  // [27]������ �ӵ���ŭ ��ȭ�Ѵ�.
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
    
    always @(posedge clk_div[16] or posedge reset_p)begin  // [27]������ �ӵ���ŭ ��ȭ�Ѵ�.
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


////////��ƴ� �����
module up_counter_test_top_2(  //// .xdc ���� seg �ּ�Ǯ��
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7, 
    output [3:0] com); /// fnd �ڸ��� �������ִ� ����
          
    reg [31:0] count_32;

    always @(posedge clk, posedge reset_p)begin
        if(reset_p) count_32 = 0;
        else count_32 = count_32 + 1;
    end
    
    assign count = count_32[31:16]; // [15:0]�� ������ Ȯ���� �� ������ŭ ������ ���ؼ� 32bit�� �ְ� [31:16]�� ����Ѵ�. ������ ��� �Ǵ¹���, ������ ������ �����
    
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));
    
    reg [3:0] value; /// com�� ��� ������� �����ִ� ����
    
    always @(posedge clk)begin // posedge ��ſ� com���� �൵�Ǵµ� default���� ���� ����Ѵ�.
        case(com)
            4'b0111: value = count_32[31:28];
            4'b1011: value = count_32[27:24];
            4'b1101: value = count_32[23:20];
            4'b1110: value = count_32[19:16];    
        endcase    
    end
    
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7));
    
endmodule

////////////ring counter LED : ����
module ring_counter_led(
    input clk, reset_p,
    output reg [15:0] count 
);
    reg [31:0] clk_div;
    
    always @(posedge clk) clk_div = clk_div + 1; // ���ֱ�
    
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

////////////ring counter LED : ���� if��
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
    
    always @(posedge clk, posedge reset_p)begin // ���δٸ� always������ ���� ������ �־��ָ� �ȵȴ�. �ȱ׷� short��.
        if (reset_p) begin
            count = 16'b1;
        end
        else begin
            if(posedge_clk_div_20) count = {count[14:0], count[15]}; // �갡 ��ī���� // 15��Ʈ�� ���ڸ��� ��� �з��� ��°��� ������ ����  
//            if(count == 16'b1000_0000_0000_0000) count = 16'b1; // hexa�ڵ� 16'b8000 --> hexa���� binary�� ���̰� �� ����
//            else count = {count[14:0], 1'b0};  //// �ּ� ������ C���� shift ����� ��Ÿ�� ��
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
    
    always @(negedge clk or posedge reset_p)begin // always������ ���ķ� �����ؾ��ϴ��� ���ķ� �ؾ��ϴ��� �����ؾ��Ѵ�.
        if(reset_p)begin
            ff_cur <= 0; // Non_blocking���� ��⿡ �ϴ� Non_blocking�� �����. 
            ff_old <= 0;
        end
        else begin
            ff_cur <= cp; //Non_blocking��(<=): �ΰ��� ȸ�ΰ� ���� ���ķ� �����ϴ°Ŵ�. blocking��(=)�� ���������� �����ϴ� ��
            ff_old <= ff_cur; // CP�� 1�� ������ cur=1�� �Ǵµ�, old�� ���� 0�̴�. �ֳ� ���������� �ʰ� ���ÿ� �����ϴ� �ΰ��� ȸ���̱� ����
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0; // LUT
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0; // LU�� MUX�� �����. not gate�� ���� ������
    
//    assign p_edge = ff_cur & ~ff_old;
//    assign n_edge = ~ff_cur & ff_old; // ������ �̾ ������ ����.
    
endmodule

module edge_detector_p(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge
);
    reg ff_cur, ff_old;
    
    always @(posedge clk or posedge reset_p)begin // always������ ���ķ� �����ؾ��ϴ��� ���ķ� �ؾ��ϴ��� �����ؾ��Ѵ�.
        if(reset_p)begin
            ff_cur <= 0; // Non_blocking���� ��⿡ �ϴ� Non_blocking�� �����. 
            ff_old <= 0;
        end
        else begin
            ff_cur <= cp; //Non_blocking��(<=): �ΰ��� ȸ�ΰ� ���� ���ķ� �����ϴ°Ŵ�. blocking��(=)�� ���������� �����ϴ� ��
            ff_old <= ff_cur; // CP�� 1�� ������ cur=1�� �Ǵµ�, old�� ���� 0�̴�. �ֳ� ���������� �ʰ� ���ÿ� �����ϴ� �ΰ��� ȸ���̱� ����
        end
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0; 
    
//    assign p_edge = ff_cur & ~ff_old;
//    assign n_edge = ~ff_cur & ff_old; // ������ �̾ ������ ����.
    
endmodule

//////////ring counter �������� �׷��� �����϶�.��

//////////register
module shift_register_SISO_n( // �����Է� ������� shift register
    input clk, reset_p,
    input d,
    output q
);

    reg [3:0] siso_reg;

    always @(negedge clk or posedge reset_p)begin
        if(reset_p) siso_reg <= 0;
        else begin
            siso_reg[3] <= d; // nonblocking: ���������� �� register ??/?/?????
            siso_reg[2] <= siso_reg[3];
            siso_reg[1] <= siso_reg[2];
            siso_reg[0] <= siso_reg[1];            
        end
    end
    assign q = siso_reg[0];

endmodule

//�����Է� ������� shift register
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

    assign q = rd_en ? sipo_reg : 4'bz; // 4bit ���Ǵ��� Z // �츮�� assign���� ������, ������ �ڵ�� ���� �� ������.
    
//    bufif1 (q[0], sipo_reg[0], rd_en); // 1���� �߻��ϴ� ������� if1 //(���, �Է�, �����Է�) <- �̰� ������ �������ִ°�-
//    bufif1 (q[1], sipo_reg[1], rd_en); // �̷��� �ִٴ� �͸� �˾Ƶֶ�
//    bufif1 (q[2], sipo_reg[2], rd_en);
//    bufif1 (q[3], sipo_reg[3], rd_en);
    
endmodule

/////�����Է� ������� register // �ʱ�����
module shift_register_PISO(
    input clk, reset_p,
    input [3:0] d, // �ܺ��Է�
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
    
    assign q = piso_reg[0]; // ������ or �ֻ��� bit�� �ϳ��� �Ѿ�鼭 ����Ǳ� ����, ����� �����̴�.  // �ʱ� �׸� ���� 

endmodule

///�����Է� ������� register -> ��� �׳� ���� �ƴ� �������ʹ�.
module register_Nbit_p #(parameter N = 8)( 
    input clk, reset_p,
    input [N-1:0] d,
    input wr_en, rd_en,
    output [N-1:0] q
);

    reg [N-1:0] register; // �갡 register�� ��ü 
    always @(posedge clk or posedge reset_p)begin
        if(reset_p) register = 0;
        else if(wr_en) register = d; // wr_en 1 ������ �����̵Ǵ°Ŵ�. 
    end

    assign q = rd_en ? register : 'bz; // rd-en 1�϶��� ����� �������°Ŵ�. ���Ǵ��� ���������� �տ� ��bit���� �Ƚᵵ�ȴ�. 

endmodule

module sram_8bit_1024( // �ʱ⿡ ȸ�ε� ����
    input clk, // �޸𸮴� reset�� �ʿ䰡 ����. �ʿ��ϸ� buf ����ȴ�. 
    input wr_en, rd_en,
    input [9:0] addr, // �޸𸮰� 1024�� �����ϱ� 2^10 �̾ 10bit �ּ�
    inout [7:0] data // inout : input�� �ǰ�  output�� �Ǵ� ģ�� // ������� �������� �ݵ�� ���Ǵ����� ��������Ѵ�. 
);

    reg [7:0] mem [0:1023];// mem: memory // 8��Ʈ ¥�� �޸� 1024�� ����ڴٴ� �� 
    
    always @(posedge clk)begin
        if(wr_en) mem[addr] <= data;
    end

    assign data = rd_en ? mem[addr] : 'bz;

endmodule
















//////��ư�Է��� �޴� FND ī����///�ʱ⿡ ȸ�ε� ����
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

    always @(posedge clk, posedge reset_p)begin // �ý��۹ݵ�ü�� ���: always�� ��ȣ �ȿ��� clk. reset, enable �ۿ� ������. ���������� �ȵǴ°� �ƴ϶� �ý��۹ݵ�ü�� �ȵǴ°���.
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

///////bread board �ǽ� LED 
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
    wire clk_div_16; // clk ���ֱ�
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    reg [1:0] debounced_btn;
    
    always @(posedge clk, posedge reset_p)begin
        if(reset_p) debounced_btn = 0;
        else if(clk_div_16) debounced_btn = btn; // 2bit �״�� ������
    end

    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btnU_pedge[0])); // 1bit���� detector�� �߰��ؾ��Ѵ�.
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));
    
    always @(posedge clk, posedge reset_p)begin 
        if(reset_p)btn_counter = 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if (btnU_pedge[1]) btn_counter = btn_counter - 1; /// ���⿡ ���ϴ� ����� �߰��ϸ� �ȴ�.
        end
    end

    assign led_bar = ~btn_counter; // ��°��� 0���� ������ ������ ���� ���Ϸ��� not gate�� �Ἥ ����� 1�� �ٲ��ִ°�
    
endmodule
///////////////////////////




///////////btn�Է� 4FND��� ȸ�� // ���� �� ��
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

    always @(posedge clk, posedge reset_p)begin // �ý��۹ݵ�ü�� ���: always�� ��ȣ �ȿ��� clk. reset, enable �ۿ� ������. ���������� �ȵǴ°� �ƴ϶� �ý��۹ݵ�ü�� �ȵǴ°���.
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

























