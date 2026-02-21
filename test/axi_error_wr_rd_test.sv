class axi_wr_rd_error_sequence extends axi_sequence;
   `uvm_object_utils(axi_wr_rd_error_sequence)
   axi_transaction tr;

   function new(string name="axi_wr_rd_error_sequence");
      super.new(name);
   endfunction
   
   task pre_body();
      //reset_dut;
   endtask

   virtual task body();
   tr = axi_transaction::type_id::create("tr");
   `uvm_info("SEQ","sending error mode transaction to driver",UVM_NONE);
      start_item(tr);
      //tr.randomize() with {tr.awsize == 3'b010; tr.awburst==1;};
     assert(tr.randomize());
      tr.op    = wrrderror;
      tr.awlen = 7;
      tr.awburst = 1;
      tr.awsize = 2;
      finish_item(tr);
   //`uvm_info("SEQ",$sformatf("awaddr=%0h",tr.awaddr),UVM_NONE);

   endtask
endclass

class axi_error_wr_rd_test extends axi_base_test;
 `uvm_component_utils(axi_error_wr_rd_test)
   axi_wr_rd_error_sequence wrrderror;

   function new(string name="axi_error_wr_rd_test",uvm_component parent=null);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      wrrderror = axi_wr_rd_error_sequence::type_id::create("wrrderror");
   endfunction

   virtual task run_phase(uvm_phase phase);
      `uvm_info("axi_error_wr_rd_test",$sformatf("This is a axi_error_wr_rd_test in RUN PHASE"),UVM_HIGH);
      phase.raise_objection(this);
      wrrderror.start(env.m_agent.m_seqr);
      phase.drop_objection(this);
   endtask

   function void end_of_elaboration();
      uvm_top.print_topology(uvm_default_table_printer);
      uvm_report_info(get_full_name(),"End of elaboration",UVM_LOW);
   endfunction
endclass

