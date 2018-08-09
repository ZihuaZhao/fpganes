//
//register
//

module ppu_ri(
    //system signal
    input wire          clk_in,
    input wire          rst_in,
    //about register
    input wire  [2:0]   sel_in,         //which register;
    input wire          ncs_in,         //whether enable register;
    input wire          r_nw_in,        //read or write;
    input wire  [7:0]   cpu_d_in,       //cpu data(address) input to $2006/$2007;
    output wire [7:0]   cpu_d_out,      //ppu data output to cpu;
    //about vram($2006 , $2007)
    input wire  [13:0]  vram_a_in,      //vram address input to $2006;
    input wire  [7:0]   vram_d_in,      //vram data input to $2007;
    input wire  [7:0]   pram_d_in,      //pram data input;
    output reg  [7:0]   vram_d_out,     //ppu data output to $2007;
    output reg          vram_wr_out,    //vram read/write;
    output reg          pram_wr_out,    //pram read/write;
    output wire [2:0]   fv_out,         //fv out;
    output wire [4:0]   vt_out,         //vt out;
    output wire [2:0]   fh_out,         //fh out;
    output wire [4:0]   ht_out,         //ht out;
    output wire         hv_out,         //hv out;
    output wire         s_out,          //s_out;
    //about vblank
    input wire          vblank_in,      //vblank status;
    output wire         vblank_out,     //vblank(union) status out; 
    output wire         nvbl_en_out,    //nmi on vblank;
    //about spr
    input wire  [7:0]   spr_ram_d_in,   //sprite ram data;
    input wire          spr_overflow_in,//sprite overflow 8;
    input wire          spr_0_hit,      //sprite 0 hit;
    output wire         spr_en_out,     //whether show sprite;
    output wire         spr_ls_out,     //whether show sprites on left screen;
    output wire         spr_h_out,      //8/16 type of sprites;
    output wire         spr_pt_sel_out, //pattern table for sprites;
    output wire         spr_ram_a_out,  //sprite ram address;
    output reg          spr_d_out,      //sprite ram data;
    output reg         spr_ram_wr_out, //whether write sprite ram;
    //about increment
    output reg          inc_addr_out,   //vram address increment;
    output wire         inc_addr_amt_out, //vram address increment amount;
    //about background 
    output wire         bg_en_out,      //whether show background;
    output wire         bg_ls_out,       //whether show background on left screem;
    output wire         upd_cntrs_out
);

//$2000(PPUCTRL)
reg [1:0]   q_hv , d_hv;                    //nametable address;[0 - 1]
reg         q_nt_wr , d_nt_wr;              //nametable read/write;[2]
reg         q_spr_pt_addr , d_spr_pt_addr;  //sprite pattern table address;[3]
reg         q_bg_pt_addr , d_bg_pt_addr;    //background pattern table address;[4](q_s , d_s)
reg         q_spr_sz , d_spr_sz;            //sprite size selection;[5]
reg         q_nmi , d_nmi;                  //nmi signal;[7]

//$2001(PPUMASK)
reg         q_ls_bg , d_ls_bg;              //whether show background on left screen;[1]
reg         q_ls_spr , d_ls_spr;            //whether show sprites on left screen;[2]
reg         q_bg , d_bg;                    //whether show background;[3]
reg         q_spr , d_spr;                  //whether show sprite;[4]
reg [2:0]   q_bg_color , d_bg_color;        //background color[5 - 7];

//$2002(PPUSTATUS)
reg         q_vblank , d_vblank;            //vblank status;[7]
reg         q_vblank_in , d_vblank_in;      //last vblank signal;
reg         q_ncs_in;

//$2003(OAMADDR)
reg [7:0]   q_spr_addr , d_spr_addr;        //sprite oam address;

//$2004(OAMDATA)
//reg [7:0]   q_spr_data , d_spr_data;        //sprite oam data;

//$2005(PPUSCROLL)
reg [2:0]   q_fv , d_fv;                    //fine vertical;
reg [4:0]   q_vt , d_vt;                    //high 5 vertical;
reg [2:0]   q_fh , d_fh;                    //fine horizontal;
reg [4:0]   q_ht , d_ht;                    //high 5 horizontal;
reg         q_hv_sel , d_hv_sel;            //high/low selection for $2005/$2006;

//$2006(PPUADDR)

//$2007(PPUDATA)
reg [7:0]   q_cpu_d_out , d_cpu_d_out;      //output to cpu;

//
reg         q_rd_buf , d_rd_buf;
reg         q_rd_rdy , d_rd_rdy;
reg q_upd_cntrs_out, d_upd_cntrs_out;
//
always @(posedge clk_in)
    begin 
        if(rst_in)
            begin
                q_hv <= 2'h0;
                q_nt_wr <= 1'b0;
                q_spr_pt_addr <= 1'b0;
                q_bg_pt_addr <= 1'b0;
                q_spr_sz <= 1'b0;
                q_nmi <= 1'b0;
                q_ls_bg <= 1'b0;
                q_ls_spr <= 1'b0;
                q_bg <= 1'b0;
                q_spr <= 1'b0;
                q_bg_color <= 3'h0;
                q_vblank <= 1'b0;
                q_vblank_in <= 1'b0;
                q_fv <= 3'h0;
                q_vt <= 5'h00;
                q_fh <= 3'h0;
                q_ht <= 5'h0;
                q_hv_sel <= 1'b0;
                q_cpu_d_out <= 8'h00;
            end
        else begin
            q_hv <= d_hv;
            q_nt_wr <= d_nt_wr;
            q_spr_pt_addr <= d_spr_pt_addr;
            q_bg_pt_addr <= d_bg_pt_addr;
            q_spr_sz <= d_spr_sz;
            q_nmi <= d_nmi;
            q_ls_bg <= d_ls_bg;
            q_ls_spr <= d_ls_spr;
            q_bg <= d_bg;
            q_spr <= d_spr;
            q_bg_color <= d_bg_color;
            q_vblank <= d_vblank;
            q_vblank_in <= d_vblank_in;
            q_fv <= d_fv;
            q_vt <= d_vt;
            q_fh <= d_fh;
            q_ht <= d_ht;
            q_hv_sel <= d_hv_sel;
            q_cpu_d_out <= d_cpu_d_out;
        end
    end

always @*
    begin
        //default
        d_hv = q_hv;
        d_nt_wr = d_nt_wr;
        d_spr_pt_addr = q_spr_pt_addr;
        d_bg_pt_addr = q_bg_pt_addr;
        d_spr_sz = q_spr_sz;
        d_nmi = q_nmi;
        d_ls_bg = q_ls_bg;
        d_ls_spr = q_ls_spr;
        d_bg = q_bg;
        d_spr = q_spr;
        d_vblank = q_vblank;
        d_fv = q_fv;
        d_vt = q_vt;
        d_fh = q_fh;
        d_ht = q_ht;
        d_hv_sel = q_hv_sel;
        d_cpu_d_out = q_cpu_d_out;

        //
        d_rd_buf = (q_rd_rdy) ? vram_d_in : q_rd_buf;
        d_rd_rdy = 1'b0;

        //
        d_upd_cntrs_out = 1'b0;

        //vblank reset
        d_vblank = (~q_vblank_in & vblank_in) ? 1'b1 : 
                   (~vblank_in)               ? 1'b0 : q_vblank;

        //vram reset
        vram_d_out = 8'h00;
        vram_wr_out = 1'b0;
        pram_wr_out = 1'b0;
        inc_addr_out = 1'b0;

        spr_d_out = 8'h00;
        spr_ram_wr_out = 1'b0;

        if(q_ncs_in & ~ncs_in)
            begin
                if(r_nw_in)
                    begin
                        case(sel_in)//read
                            3'h2://$2002
                                begin
                                    d_cpu_d_out = {q_vblank , spr_0_hit , spr_overflow_in , 5'h00};
                                    d_hv_sel = 1'b0;
                                    d_vblank = 1'b0;
                                end
                            3'h4://$2004
                                begin
                                    d_cpu_d_out = spr_ram_d_in;
                                end
                            3'h7://$2007
                                begin
                                    d_cpu_d_out = (vram_a_in[13:8] == 6'h3F) ? pram_d_in : q_rd_buf;
                                    d_rd_rdy = 1'b1;
                                    inc_addr_out = 1'b1;
                                end
                        endcase
                    end
                else
                    begin
                        case(sel_in)//write
                            3'h0://$2000
                                begin
                                    d_hv = cpu_d_in[1:0];
                                    d_nt_wr = cpu_d_in[2];
                                    d_spr_pt_addr = cpu_d_in[3];
                                    d_bg_pt_addr = cpu_d_in[4];
                                    d_spr_sz = cpu_d_in[5];
                                    d_nmi = cpu_d_in[7];
                                end
                            3'h1://$2001
                                begin
                                    d_ls_bg = cpu_d_in[1];
                                    d_ls_spr = cpu_d_in[2];
                                    d_bg = cpu_d_in[3];
                                    d_spr = cpu_d_in[4];
                                    d_bg_color = cpu_d_in[7:5];
                                end
                            3'h3://$2003
                                begin
                                    d_spr_addr = cpu_d_in;
                                end
                            3'h4://$2004
                                begin
                                    spr_d_out = cpu_d_in;
                                    d_spr_addr = q_spr_addr + 8'h01;
                                    spr_ram_wr_out = 1'h1;
                                end
                            3'h5://$2005
                                begin
                                    d_hv_sel = ~q_hv_sel;
                                    if(q_hv_sel)
                                        begin
                                            d_fv = cpu_d_in[2:0];
                                            d_vt = cpu_d_in[7:3];
                                        end
                                    else
                                        begin
                                            d_fh = cpu_d_in[2:0];
                                            d_vt = cpu_d_in[7:3];
                                        end
                                end
                            3'h6://$2006
                                begin
                                    d_hv_sel = ~q_hv_sel;
                                    if(q_hv_sel)
                                        begin
                                            d_vt[4:3] = cpu_d_in[1:0];
                                            d_hv = cpu_d_in[3:2];
                                            d_fv[1:0] = cpu_d_in[5:4];
                                            d_fv[2] = 1'b0;
                                        end
                                    else
                                        begin
                                            d_ht = cpu_d_in[4:0];
                                            d_vt[2:0] = cpu_d_in[7:5];
                                        end
                                end
                            3'h7://$2007
                                begin
                                    if(vram_a_in[13:8] == 6'h3F)
                                        pram_wr_out = 1'b1;
                                        
                                    else
                                        vram_wr_out = 1'b1;
                                        vram_d_out = cpu_d_in;
                                        inc_addr_out = 1'b1;
                                end
                        endcase
                    end
            end
    end

    assign cpu_d_out = (~ncs_in & r_nw_in) ? q_cpu_d_out : 8'h00;
    assign fv_out = q_fv;
    assign vt_out = q_vt;
    assign fh_out = q_fh;
    assign ht_out = q_ht;
    assign hv_out = q_hv;
    assign s_out = q_bg_pt_addr;
    assign vblank_out = q_vblank;
    assign nvbl_en_out = q_nmi;
    assign spr_en_out = q_spr;
    assign spr_ls_out = q_ls_spr;
    assign spr_h_out = q_spr_sz;
    assign spr_pt_sel_out = q_spr_pt_addr;
    assign spr_ram_a_out = q_spr_addr;
    assign bg_en_out = 1;
    assign bg_ls_out = q_ls_bg;
    assign inc_addr_amt_out = q_nt_wr;

endmodule

        


