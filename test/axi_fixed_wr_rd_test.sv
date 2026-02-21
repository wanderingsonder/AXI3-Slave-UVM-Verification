class axi_wr_rd_fixed_sequence extends axi_sequence;
   `uvm_object_utils(axi_wr_rd_fixed_sequence)
   axi_transaction tr;

   function new(string name="axi_wr_rd_fixed_sequence");
      super.new(name);
   endfunction
   
   task pre_body();
      //reset_dut;
   endtask

   virtual task body();
   //#40;
   tr = axi_transaction::type_id::create("tr");
   `uvm_info("SEQ","sending fixed mode transaction to driver",UVM_NONE);
      start_item(tr);
      //tr.randomize() with {tr.awsize == 3'b010;tr.awburst==2'b00;};
    assert(tr.randomize());
      tr.op    = wrrdfixed;
      tr.awlen = 7;
      tr.awburst = 0;
      tr.awsize = 2;
      finish_item(tr);
   `uvm_info("SEQ",$sformatf("awaddr=%0h",tr.awaddr),UVM_NONE);

   endtask
endclass

class axi_fixed_wr_rd_test extends axi_base_test;
 `uvm_component_utils(axi_fixed_wr_rd_test)
   axi_wr_rd_fixed_sequence wrrdfixed;

   function new(string name="axi_fixed_wr_rd_test",uvm_component parent=null);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      wrrdfixed = axi_wr_rd_fixed_sequence::type_id::create("wrrdfixed");
   endfunction

   virtual task run_phase(uvm_phase phase);
      `uvm_info("axi_fixed_wr_rd_test",$sformatf("This is a axi_fixed_wr_rd_test in RUN PHASE"),UVM_HIGH);
      phase.raise_objection(this);
      wrrdfixed.start(env.m_agent.m_seqr);
      phase.drop_objection(this);
   endtask

   function void end_of_elaboration();
      uvm_top.print_topology(uvm_default_table_printer);
      uvm_report_info(get_full_name(),"End of elaboration",UVM_LOW);
   endfunction
endclass

