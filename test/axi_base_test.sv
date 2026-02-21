class axi_base_test extends uvm_test;
`uvm_component_utils(axi_base_test)

   axi_environment env; 
   axi_sequence m_seq;
   
   function new(string name= "axi_base_test", uvm_component parent = null);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);      
      m_seq = axi_sequence::type_id::create("m_seq",this);
      env   = axi_environment::type_id::create("env",this);
   endfunction

   function void end_of_elaboration();
      uvm_top.print_topology;
      uvm_report_info(get_full_name(),"End_of_elaboration",UVM_LOW);
   endfunction

   virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      m_seq.start(env.m_agent.m_seqr);
   endtask
endclass

task reset_dut();
   virtual axi_interface vif;
   $display("ENTERED RESET TASK ------------- %0t",$time);
   if(!uvm_config_db#(virtual axi_interface)::get(null,"","vif",vif))
      `uvm_fatal("TEST FATAL","NO INTERFACE ACCESS");
   `uvm_info("START RESET",$sformatf("------RESET APPLIED------"),UVM_LOW);
   @(posedge vif.clk)
   vif.resetn <= 1'b0;
   vif.awvalid <= 1'b0;
   vif.awready <= 1'b0;
   vif.awid    <= 1'b0;
   vif.awlen   <= 1'b0;
   vif.awsize  <= 1'b0;
   vif.awaddr  <= 1'b0;
   vif.awburst <= 1'b0;
    
   vif.wvalid <= 1'b0; 
   vif.wready <= 1'b0;
   vif.wid    <= 1'b0;
   vif.wdata  <= 1'b0;
   vif.wstrb  <= 1'b0;
   vif.wlast  <= 1'b0;

   vif.bready <= 1'b0; 
   vif.bvalid <= 1'b0;
   vif.bid    <= 1'b0;
   vif.bresp  <= 1'b0;
   
   vif.arready <= 1'b0; 
   vif.arid    <= 1'b0;
   vif.araddr  <= 1'b0;
   vif.arlen   <= 1'b0;
   vif.arsize  <= 1'b0;
   vif.arburst <= 1'b0;
   vif.arvalid <= 1'b0;
             
   vif.rid	  <= 1'b0;  
   vif.rdata  <= 1'b0;
   vif.rresp  <= 1'b0;
   vif.rstrb  <= 1'b0;
   vif.rlast  <= 1'b0;
   vif.rvalid <= 1'b0;
   vif.rready <= 1'b0;
   
    @(posedge vif.clk);
    vif.resetn<=1'b1;
   `uvm_info("START RESET",$sformatf("------RESET REMOVED------"),UVM_LOW);
    $display("COMING OUT FROM RESET TASK ---------------- %0t",$time);
endtask

