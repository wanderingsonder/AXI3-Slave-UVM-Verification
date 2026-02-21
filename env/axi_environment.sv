class axi_environment extends uvm_env;

   virtual axi_interface vif; 
   axi_agent m_agent;
   axi_scoreboard sco;

   `uvm_component_utils(axi_environment)

   function new (string name = "axi_environment", uvm_component parent);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      m_agent= axi_agent::type_id::create("m_agent", this);
      sco    = axi_scoreboard::type_id::create("sco",this);

      if(!uvm_config_db#(virtual axi_interface)::get(this,"","vif",vif)) begin
      `uvm_fatal(get_full_name(),{"NOVIF","virtual interface not declared"});
    end
   endfunction

   function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      m_agent.mon.mon_port.connect(sco.mon_sco.analysis_export);
   endfunction
endclass
