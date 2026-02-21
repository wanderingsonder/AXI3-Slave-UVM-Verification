class axi_agent extends uvm_agent; 

 `uvm_component_utils(axi_agent)
  virtual axi_interface vif;
   axi_driver drv;
   axi_sequencer m_seqr;
   axi_monitor mon;

   function new (string name = "axi_agent", uvm_component  parent=null);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if(!uvm_config_db#(virtual axi_interface)::get(this,"","vif",vif)) begin
      `uvm_fatal(get_full_name(),{"vif not found"});  end

      mon=axi_monitor::type_id::create("mon",this);
      drv=axi_driver::type_id::create("drv",this);
      m_seqr=axi_sequencer::type_id::create("m_seqr",this);
   endfunction

  virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      drv.seq_item_port.connect(m_seqr.seq_item_export);
      drv.vif=vif;
      mon.vif=vif;
   endfunction
endclass

