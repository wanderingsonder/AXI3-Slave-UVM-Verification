//======================================================
// AXI Slave  (Final Clean Version, Option 2 Boundaries)
//======================================================
module AXI_Slave (
  input  logic        clk,
  input  logic        resetn,

  // Write Address Channel
  input  logic [3:0]  awid,
  input  logic [31:0] awaddr,
  input  logic [3:0]  awlen,
  input  logic [2:0]  awsize,
  input  logic [1:0]  awburst,
  input  logic        awvalid,
  output logic        awready,

  // Write Data Channel
  input  logic [3:0]  wid,
  input  logic [31:0] wdata,
  input  logic [3:0]  wstrb,
  input  logic        wlast,
  input  logic        wvalid,
  output logic        wready,

  // Write Response Channel
  output logic [3:0]  bid,
  output logic [1:0]  bresp,
  output logic        bvalid,
  input  logic        bready,

  // Read Address Channel
  input  logic [3:0]  arid,
  input  logic [31:0] araddr,
  input  logic [3:0]  arlen,
  input  logic [2:0]  arsize,
  input  logic [1:0]  arburst,
  input  logic        arvalid,
  output logic        arready,

  // Read Data Channel
  output logic [3:0]  rid,
  output logic [31:0] rdata,
  output logic [1:0]  rresp,
  output logic        rvalid,
  output logic        rlast,
  input  logic        rready
);

  //--------------------------------------------------
  // Local Memory
  //--------------------------------------------------
  logic [7:0] memory [128];

  //--------------------------------------------------
  // Helper functions
  //--------------------------------------------------

  //--- Write helpers
  function automatic [31:0] data_wr_fixed(input [3:0] wstrb, input [31:0] addr, input [31:0] wdata_i);
    integer i;
    begin
      for(i=0; i<4; i++) if(wstrb[i]) memory[addr+i] = wdata_i[8*i +: 8];
      return addr;
    end
  endfunction

  function automatic [31:0] data_wr_incr(input [3:0] wstrb, input [31:0] addr, input [31:0] wdata_i, input [2:0] awsize);
    integer i;
    begin
      for(i=0; i<4; i++) if(wstrb[i]) memory[addr+i] = wdata_i[8*i +: 8];
      return addr + (1 << awsize);
    end
  endfunction

  function automatic [31:0] data_wr_wrap(input [3:0] wstrb, input [31:0] addr, input [31:0] wdata_i,
                                         input [7:0] boundary, input [2:0] awsize);
    logic [31:0] next_addr;
    integer i;
    begin
      for(i=0; i<4; i++) if(wstrb[i]) memory[addr+i] = wdata_i[8*i +: 8];
      next_addr = addr + (1 << awsize);
      if((next_addr & (boundary-1)) == 0)
        next_addr = addr - boundary + (1 << awsize);
      return next_addr;
    end
  endfunction

  //--- Read helpers
  function automatic [31:0] data_rd_fixed(input [31:0] addr);
    begin
      rdata = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
      return addr;
    end
  endfunction

  function automatic [31:0] data_rd_incr(input [31:0] addr, input [2:0] arsize);
    begin
      rdata = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
      return addr + (1 << arsize);
    end
  endfunction

  function automatic [31:0] data_rd_wrap(input [31:0] addr, input [7:0] boundary, input [2:0] arsize);
    logic [31:0] next_addr;
    begin
      rdata = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};
      next_addr = addr + (1 << arsize);
      if((next_addr & (boundary-1)) == 0)
        next_addr = addr - boundary + (1 << arsize);
      return next_addr;
    end
  endfunction

  //--- Wrap boundary calc
  function automatic [7:0] wrap_boundary(input [3:0] len, input [2:0] size);
    case(len)
      4'd1:   wrap_boundary = 2  * (1 << size);
      4'd3:   wrap_boundary = 4  * (1 << size);
      4'd7:   wrap_boundary = 8  * (1 << size);
      4'd15:  wrap_boundary = 16 * (1 << size);
      default:wrap_boundary = (len + 1) * (1 << size);
    endcase
  endfunction

  //--------------------------------------------------
  // FSM State Declarations
  //--------------------------------------------------
  typedef enum logic [2:0] {widle, waddr_dec, wstart, wreadys, wlast_st} wstate_t;
  typedef enum logic [1:0] {bidle, bvalids, bwait} bstate_t;
  typedef enum logic [2:0] {ridle, raddr_dec, rvalids, rlast_st} rstate_t;

  //--------------------------------------------------
  // Internal registers
  //--------------------------------------------------
  wstate_t wstate, wnext_state;
  bstate_t bstate, bnext_state;
  rstate_t rstate, rnext_state;

  logic [31:0] nextaddr, nextaddr_next;
  logic [31:0] retaddr, retaddr_next;
  logic [3:0]  wlen_count, wlen_count_next;
  logic        first, first_next;
  logic [7:0]  boundary_wr, boundary_wr_next;

  logic [31:0] rdnextaddr, rdnextaddr_next;
  logic [31:0] rdretaddr, rdretaddr_next;
  logic [3:0]  rdlen_count, rdlen_count_next;
  logic [7:0]  boundary_rd, boundary_rd_next;

  //--------------------------------------------------
  // WRITE DATA FSM
  //--------------------------------------------------
  always_ff @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      wstate      <= widle;
      nextaddr    <= 0;
      retaddr     <= 0;
      wlen_count  <= 0;
      first       <= 0;
      boundary_wr <= 0;
    end else begin
      wstate      <= wnext_state;
      nextaddr    <= nextaddr_next;
      retaddr     <= retaddr_next;
      wlen_count  <= wlen_count_next;
      first       <= first_next;
      boundary_wr <= boundary_wr_next;
    end
  end

  always_comb begin
    // defaults
    wnext_state      = wstate;
    wready           = 0;
    nextaddr_next    = nextaddr;
    retaddr_next     = retaddr;
    wlen_count_next  = wlen_count;
    first_next       = first;
    boundary_wr_next = boundary_wr;

    case(wstate)
      widle: if(awvalid) begin
        first_next       = 0;
        wlen_count_next  = 0;
        wnext_state      = waddr_dec;
      end

      waddr_dec: begin
        if(!first) begin
          nextaddr_next = awaddr;
          first_next    = 1;
        end
        wready = 1;
        if(wvalid) wnext_state = wstart;
      end

      wstart: if(wvalid) begin
        case(awburst)
          2'b00: retaddr_next = data_wr_fixed(wstrb, nextaddr, wdata);
          2'b01: retaddr_next = data_wr_incr(wstrb, nextaddr, wdata, awsize);
          2'b10: begin
            boundary_wr_next = wrap_boundary(awlen, awsize);
            retaddr_next     = data_wr_wrap(wstrb, nextaddr, wdata, boundary_wr_next, awsize);
          end
        endcase
        nextaddr_next   = retaddr_next;
        wlen_count_next = wlen_count + 1;
        wready          = 1;
        wnext_state     = (wlast || (wlen_count_next == awlen)) ? wlast_st : wreadys;
      end

      wreadys: if(wvalid) begin
        wready = 1;
        case(awburst)
          2'b00: retaddr_next = data_wr_fixed(wstrb, nextaddr, wdata);
          2'b01: retaddr_next = data_wr_incr(wstrb, nextaddr, wdata, awsize);
          2'b10: begin
            boundary_wr_next = wrap_boundary(awlen, awsize);
            retaddr_next     = data_wr_wrap(wstrb, nextaddr, wdata, boundary_wr_next, awsize);
          end
        endcase
        nextaddr_next   = retaddr_next;
        wlen_count_next = wlen_count + 1;
        if(wlast|| (wlen_count_next == awlen)) wnext_state = wlast_st;
      end

      wlast_st: begin
        wready          = 0;
        wlen_count_next = 0;
        first_next      = 0;
        wnext_state     = widle;
      end
    endcase
  end

 //---------------------------------------------------
 //Write ADDRESS READY  HANDSHAKE
 //---------------------------------------------------
 always_comb begin
   awready = 1'b0;

   if(wstate == widle && awvalid) begin
     awready = 1'b1;
      end
   else if(wstate != widle)
   awready = 1'b0;
   end

  //--------------------------------------------------
  // WRITE RESPONSE FSM
  //--------------------------------------------------
  always_ff @(posedge clk or negedge resetn) begin
    if(!resetn)
      bstate <= bidle;
    else begin
      bstate <= bnext_state;
     end
  end

  always_comb begin
    bnext_state = bstate;
    bvalid = 0;
    bid    = wid;
    bresp  = 2'b00;
    case(bstate)
      bidle: if(wstate == wlast_st) bnext_state = bvalids;
      bvalids: begin
        bvalid = 1;
        bresp  = (awsize > 3'b010) ? 2'b10 : 2'b00;
        if(bready) bnext_state = bidle;
        else bnext_state = bvalids;
      end
      bwait: if(!bready) bnext_state = bidle;
    endcase
  end

  //--------------------------------------------------
  // READ DATA FSM
  //--------------------------------------------------
  always_ff @(posedge clk or negedge resetn) begin
    if(!resetn) begin
      rstate       <= ridle;
      rdnextaddr   <= 0;
      rdretaddr    <= 0;
      rdlen_count  <= 0;
      boundary_rd  <= 0;
    end else begin
      rstate       <= rnext_state;
      rdnextaddr   <= rdnextaddr_next;
      rdretaddr    <= rdretaddr_next;
      rdlen_count  <= rdlen_count_next;
      boundary_rd  <= boundary_rd_next;
    end
  end

  always_comb begin
    // defaults
    rnext_state       = rstate;
    rvalid           = 0;
    rlast            = 0;
    arready           = (rstate == ridle);
    rid               = arid;
    //rresp             = 2'b00;
    rdnextaddr_next   = rdnextaddr;
    rdretaddr_next    = rdretaddr;
    rdlen_count_next  = rdlen_count;
    boundary_rd_next  = boundary_rd;

    case(rstate)
      ridle: if(arvalid) begin
        rdnextaddr_next  = araddr;
        rdlen_count_next = 0;
        rnext_state      = raddr_dec;
      end

      raddr_dec: if(rready) begin
        rvalid = 1;
        case(arburst)
          2'b00: rdretaddr_next = data_rd_fixed(rdnextaddr);
          2'b01: rdretaddr_next = data_rd_incr(rdnextaddr, arsize);
          2'b10: begin
            boundary_rd_next = wrap_boundary(arlen, arsize);
            rdretaddr_next   = data_rd_wrap(rdnextaddr, boundary_rd_next, arsize);
          end
        endcase
        rdnextaddr_next   = rdretaddr_next;
        rdlen_count_next  = rdlen_count + 1;
        rresp = (rdnextaddr_next > 128)? 2'b10 : 2'b00;
        rnext_state       = (rdlen_count == arlen) ? rlast_st : rvalids;
        // $display("rresp= %0d",rresp);

      end

      rvalids: if(rready) begin
        rvalid = 1;
        case(arburst)
          2'b00: rdretaddr_next = data_rd_fixed(rdnextaddr);
          2'b01: rdretaddr_next = data_rd_incr(rdnextaddr, arsize);
          2'b10: begin
            boundary_rd_next = wrap_boundary(arlen, arsize);
            rdretaddr_next   = data_rd_wrap(rdnextaddr, boundary_rd_next, arsize);
          end
        endcase
        rdnextaddr_next   = rdretaddr_next;
        rdlen_count_next  = rdlen_count + 1;
        //$display("next_addr= %0d",rdnextaddr_next);
        rresp = (rdnextaddr_next > 128)? 2'b10 : 2'b00;
       // $display("rresp= %0d",rresp);
        if(rdlen_count_next == arlen-1) rnext_state = rlast_st;
      end

      rlast_st: begin
        rvalid = 1;
        rlast  = 1;
      //  $display("rresp= %0d",rresp);
        if(rready) begin
          rdlen_count_next = 0;
          rnext_state      = ridle;
        end
      end
    endcase
  end

endmodule



