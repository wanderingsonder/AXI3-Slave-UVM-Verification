class axi_reset_dut_sequence extends axi_sequence;
`uvm_object_utils(axi_reset_dut_sequence)
   axi_transaction tr;
 
   function new (string name="axi_reset_dut_sequence");
      super.new(name);
   endfunction

   task body();
      tr=axi_transaction::type_id::create("tr");
      start_item(tr);
       tr.randomize();
       tr.op=rstdut;
       tr.awlen=7;
       tr.awburst=0;
       tr.awsize=2;
      finish_item(tr);
      #50 reset_dut();
      #60 reset_dut();
   endtask
endclass

class axi_reset_dut_test extends axi_base_test;
   `uvm_component_utils(axi_reset_dut_test)

   axi_reset_dut_sequence reset_dut;

   function new (string name="axi_reset_dut_test",uvm_component parent);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      reset_dut=axi_reset_dut_sequence::type_id::create("reset_dut",this);
   endfunction

   virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      `uvm_info(get_type_name(),"START OF TESTCASE",UVM_LOW)
      phase.raise_objection(this);
      reset_dut.start(env.m_agent.m_seqr);
      phase.drop_objection(this);
      `uvm_info(get_type_name(),"END OF TESTCASE",UVM_LOW)
   endtask
   
   function void end_of_elaboration();
      uvm_top.print_topology(uvm_default_table_printer);
      uvm_report_info(get_full_name(),"End of elaboration",UVM_LOW);
   endfunction
endclass

