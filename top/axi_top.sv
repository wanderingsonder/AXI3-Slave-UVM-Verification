import uvm_pkg::*;
   `include "uvm_macros.svh"

   import axi_pkg::*;

   module axi_top;

   //reg clk,resetn;
    axi_interface vif();
   AXI_Slave dut(.clk(vif.clk),.resetn(vif.resetn),.awvalid(vif.awvalid),.awready(vif.awready),.awid(vif.awid),.awlen(vif.awlen),.awsize(vif.awsize),.awaddr(vif.awaddr),.awburst(vif.awburst),.wvalid(vif.wvalid),.wready(vif.wready),.wid(vif.wid),.wdata(vif.wdata),.wstrb(vif.wstrb),.wlast(vif.wlast),.bready(vif.bready),.bvalid(vif.bvalid),.bid(vif.bid),.bresp(vif.bresp),.arready(vif.arready),.arid(vif.arid),.araddr(vif.araddr),.arlen(vif.arlen),.arsize(vif.arsize),.arburst(vif.arburst),.arvalid(vif.arvalid),.rid(vif.rid),.rdata(vif.rdata),.rresp(vif.rresp),.rlast(vif.rlast),.rvalid(vif.rvalid),.rready(vif.rready));

   initial begin
      vif.clk = 1'b0;
      vif.resetn=0;
      #40;
      vif.resetn=1;
      #500;
      $finish;
   end

   always #5 vif.clk <= ~vif.clk;

   initial begin
      uvm_config_db#(virtual axi_interface)::set(null,"*","vif",vif);
      run_test();
   end

  initial begin
      $fsdbDumpfile("mywave.fsdb");
      $fsdbDumpvars(0,axi_top);
   end
   
   assign vif.next_addrwr = dut.nextaddr;
   assign vif.next_addrrd = dut.rdnextaddr;

endmodule
