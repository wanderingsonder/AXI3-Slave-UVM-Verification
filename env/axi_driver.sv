class axi_driver extends uvm_driver #(axi_transaction);

   `uvm_component_utils(axi_driver) 
   virtual axi_interface vif;
   axi_transaction tr;
   
     function new(string name = "axi_driver", uvm_component parent);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);  
      tr = axi_transaction::type_id::create("tr");
    /* if(!uvm_config_db#(virtual axi_interface)::get(this,"","vif",vif)) begin
      `uvm_fatal("DRV",{"vif not found"});  end*/
   endfunction
   
virtual task run_phase(uvm_phase phase);
      //forever begin
      seq_item_port.get_next_item(tr);
       `uvm_info("DRV",$sformatf("awaddr=%0h",tr.awaddr),UVM_NONE); 
      run();
      seq_item_port.item_done();
      //end
   endtask
   
   task run();
   if(tr.op == rstdut)
      reset_dut();
   else if(tr.op == wrrdfixed)begin
   `uvm_info("DRV",$sformatf("Fixed Mode Write -> read wlen=%0d wsize=%0d",tr.awlen+1,tr.awsize),UVM_MEDIUM);
      fixed_wr();
      fixed_rd();
      end
   else if(tr.op == wrrdincr)begin
   `uvm_info("DRV",$sformatf("increament Mode Write -> read wlen=%0d wsize=%0d",tr.awlen+1,tr.awsize),UVM_MEDIUM);
      incr_wr();
      incr_rd();
      end
   else if(tr.op == wrrdwrap)begin
   `uvm_info("DRV",$sformatf("Wrap Mode Write -> read wlen=%0d wsize=%0d",tr.awlen+1,tr.awsize),UVM_MEDIUM);
      wrap_wr();
      wrap_rd();
      end
   else if(tr.op == wrrderror)begin
   `uvm_info("DRV",$sformatf("Error Mode Write -> read wlen=%0d wsize=%0d",tr.awlen+1,tr.awsize),UVM_MEDIUM);
      error_wr();
      error_rd();
      end
   endtask
   
task reset_dut();
    vif.resetn <= 1'b0;
   vif.awid    <= 1'b0;
   vif.awlen   <= 1'b0;
   vif.awsize  <= 1'b0;
   vif.awaddr  <= 1'b0;
   vif.awburst <= 1'b0;
    
   vif.wid    <= 1'b0;
   vif.wdata  <= 1'b0;
   vif.wstrb  <= 1'b0;
   vif.wlast  <= 1'b0;

   vif.bid    <= 1'b0;
   vif.bresp  <= 1'b0;
   
   vif.arid    <= 1'b0;
   vif.araddr  <= 1'b0;
   vif.arlen   <= 1'b0;
   vif.arsize  <= 1'b0;
   vif.arburst <= 1'b0;
             
   vif.rid	  <= 1'b0;  
   vif.rdata  <= 1'b0;
   vif.rresp  <= 1'b0;
   vif.rstrb  <= 1'b0;
   vif.rlast  <= 1'b0;
   
   @(posedge vif.clk);
    vif.resetn <= 1'b1;

endtask
   
    task fixed_wr();
      `uvm_info("[DRV]","Fixed_mode write transaction is started",UVM_LOW);

      @(posedge vif.clk);
      vif.resetn  <= 1'b1;
      vif.awid    <= tr.id;
      vif.awlen   <= 7;
      vif.awsize  <= 3'b010;
      vif.awaddr  <= tr.awaddr;//32'h0005;
      vif.awburst <= 0;
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",tr.awaddr,tr.wdata),UVM_LOW);

      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b0;
      vif.arvalid <= 1'b0;
      //vif.rready<= 1'b0;
         
      vif.awvalid <= 1'b1;
      wait(vif.awready == 1'b1);
      @(posedge vif.clk);

      vif.awvalid <= 1'b0;
      vif.wvalid  <= 1'b1;
      vif.wid     <= tr.id;
      vif.wlast   <= 1'b0;

      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      for(int i=0; i<(vif.awlen+1); i++) begin
      vif.wdata <= $urandom_range(0,100);
      vif.wstrb <= 4'b1111;
      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      //`uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",tr.awaddr,tr.wdata),UVM_LOW);
      end

      vif.wlast   <= 1'b1; 
      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b1;
      vif.bid     <= tr.id;
      wait(vif.bvalid == 1'b1);
      @(posedge vif.clk);
       vif.bready <= 0;
      `uvm_info("[DRV]","Fixed_mode write transaction is completed",UVM_LOW);
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",vif.awaddr,vif.wdata),UVM_LOW);

   endtask

   task fixed_rd();
         `uvm_info("[DRV]", "fixed_mode read transaction is started",UVM_LOW);

         @(posedge vif.clk);
         vif.resetn  <= 1'b1;
         vif.arvalid <= 1'b1;
         vif.arid    <= tr.id;
         vif.arlen   <= 7;
         vif.arsize  <= 3'b010;
         vif.araddr  <= tr.awaddr;//32'h0005;
         vif.arburst <= 0;

         wait(vif.arready == 1);
         @(posedge vif.clk);
         vif.rready <= 1'b1;
            
         wait(vif.rlast == 1'b1);
         @(posedge vif.clk);
         vif.rready <= 1'b0;
         vif.arvalid<= 1'b0;

         `uvm_info("[DRV]", "FIXED_MODE read complete",UVM_LOW)
   endtask
   
   task incr_wr();
      `uvm_info("[DRV]","INCR_mode write transaction is started",UVM_LOW);

      @(posedge vif.clk);
      vif.resetn  <= 1'b1;
      vif.awid    <= tr.id;
      vif.awlen   <= 7;
      vif.awsize  <= 3'b010;
      vif.awaddr  <= 5;
      vif.awburst <= 1;

      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b0;
      vif.arvalid <= 1'b0;
      //vif.rready<= 1'b0;
         
      vif.awvalid <= 1'b1;
      wait(vif.awready == 1'b1);
      @(posedge vif.clk);

      vif.awvalid <= 1'b0;
      vif.wvalid  <= 1'b1;
      vif.wid     <= tr.id;
      vif.wlast   <= 1'b0;

      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      for(int i=0; i<(vif.awlen+1); i++) begin
      vif.wdata <= $urandom_range(0,100);
      vif.wstrb <= 4'b1111;
      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      end

      vif.wlast   <= 1'b1; 
      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b1;
      vif.bid     <= tr.id;
      wait(vif.bvalid == 1'b1);
      @(posedge vif.clk);
       vif.bready <= 0;
      `uvm_info("[DRV]","INCR_mode write transaction is completed",UVM_LOW);
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",vif.awaddr,vif.wdata),UVM_LOW);

   endtask

   task incr_rd();
      tr = axi_transaction::type_id::create("tr");
         `uvm_info("[DRV]", "INCR_mode read transaction is started",UVM_LOW);

         @(posedge vif.clk);
         vif.resetn  <= 1'b1;
         vif.arvalid <= 1'b1;
         vif.arid    <= tr.id;
         vif.arlen   <= 7;
         vif.arsize  <= 3'b010;
         vif.araddr  <= 5;
         vif.arburst <= 1;

         wait(vif.arready == 1);
         @(posedge vif.clk);
         vif.rready <= 1'b1;
            
         wait(vif.rlast == 1'b1);
         @(posedge vif.clk);
         vif.rready  <= 1'b0;
         vif.arvalid <= 1'b0;

         `uvm_info("[DRV]", "INCR_MODE read complete",UVM_LOW)
   endtask

   task wrap_wr();
      `uvm_info("[DRV]","WRAP_mode write transaction is started",UVM_LOW);

      @(posedge vif.clk);
      vif.resetn  <= 1'b1;
      vif.awid    <= tr.id;
      vif.awlen   <= 7;
      vif.awsize  <= 3'b010;
      vif.awaddr  <= 5;
      vif.awburst <= 2;
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",tr.awaddr,tr.wdata),UVM_LOW);

      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b0;
      vif.arvalid <= 1'b0;
      //vif.rready<= 1'b0;
         
      vif.awvalid <= 1'b1;
      wait(vif.awready == 1'b1);
      @(posedge vif.clk);

      vif.awvalid <= 1'b0;
      vif.wvalid  <= 1'b1;
      vif.wid     <= tr.id;
      vif.wlast   <= 1'b0;

      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      for(int i=0; i<(vif.awlen+1); i++) begin
      vif.wdata <= $urandom_range(0,100);
      vif.wstrb <= 4'b1111;
      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      end

      vif.wlast   <= 1'b1; 
      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b1;
      vif.bid     <= tr.id;
      wait(vif.bvalid == 1'b1);
      @(posedge vif.clk);
       vif.bready <= 0;
      `uvm_info("[DRV]","WRAP_mode write transaction is completed",UVM_LOW);
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",vif.awaddr,vif.wdata),UVM_LOW);

   endtask

   task wrap_rd();
         `uvm_info("[DRV]", "WRAP_mode read transaction is started",UVM_LOW);

         @(posedge vif.clk);
         vif.resetn  <= 1'b1;
         vif.arvalid <= 1'b1;
         vif.arid    <= tr.id;
         vif.arlen   <= 7;
         vif.arsize  <= 3'b010;
         vif.araddr  <= 32'h0005;
         vif.arburst <= 2;

         wait(vif.arready == 1);
         @(posedge vif.clk);
         vif.rready <= 1'b1;
            
         wait(vif.rlast == 1'b1);
         @(posedge vif.clk);
         vif.rready <= 1'b0;
         vif.arvalid<= 1'b0;

         `uvm_info("[DRV]", "WRAP_MODE read complete",UVM_LOW)
   endtask

   task error_wr();
      `uvm_info("[DRV]","ERROR_mode write transaction is started",UVM_LOW);

      @(posedge vif.clk);
      vif.resetn  <= 1'b1;
      vif.awid    <= tr.id;
      vif.awlen   <= 7;
      vif.awsize  <= 3'b010;
      vif.awaddr  <= 129;
      vif.awburst <= 2;
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",tr.awaddr,tr.wdata),UVM_LOW);

      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b0;
      vif.arvalid <= 1'b0;
      //vif.rready<= 1'b0;
         
      vif.awvalid <= 1'b1;
      wait(vif.awready == 1'b1);
      @(posedge vif.clk);

      vif.awvalid <= 1'b0;
      vif.wvalid  <= 1'b1;
      vif.wid     <= tr.id;
      vif.wlast   <= 1'b0;

      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      for(int i=0; i<(vif.awlen+1); i++) begin
      vif.wdata <= $urandom_range(0,100);
      vif.wstrb <= 4'b1111;
      wait(vif.wready == 1'b1);
      @(posedge vif.clk);
      end

      vif.wlast   <= 1'b1; 
      vif.wvalid  <= 1'b0;
      vif.bready  <= 1'b1;
      vif.bid     <= tr.id;
      wait(vif.bvalid == 1'b1);
      @(posedge vif.clk);
       vif.bready <= 0;
      `uvm_info("[DRV]","ERROR_mode write transaction is completed",UVM_LOW);
      `uvm_info("[DRV]",$sformatf("awaddr=%0d wdata=%0d",vif.awaddr,vif.wdata),UVM_LOW);

   endtask

   task error_rd();
         `uvm_info("[DRV]", "ERROR_mode read transaction is started",UVM_LOW);

         @(posedge vif.clk);
         vif.resetn  <= 1'b1;
         vif.arvalid <= 1'b1;
         vif.arid    <= tr.id;
         vif.arlen   <= 7;
         vif.arsize  <= 3'b010;
         vif.araddr  <= 129;
         vif.arburst <= 2;

         wait(vif.arready == 1);
         @(posedge vif.clk);
         vif.rready <= 1'b1;
            
         wait(vif.rlast == 1'b1);
         @(posedge vif.clk);
         vif.rready <= 1'b0;
         vif.arvalid<= 1'b0;

         `uvm_info("[DRV]", "ERROR_MODE read complete",UVM_LOW)
   endtask
endclass

