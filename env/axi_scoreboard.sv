class axi_scoreboard extends uvm_scoreboard;

   `uvm_component_utils(axi_scoreboard)
   axi_transaction tr;
   axi_coverage m_cov;
   virtual axi_interface vif;
   uvm_tlm_analysis_fifo#(axi_transaction) mon_sco;

   //bit expected_memory [127:0];
   //bit actual_memory [127:0];

   int total_transaction = 0;
   int pass_transaction  = 0;
   int fail_transaction  = 0;
   int write_transaction = 0;
   int error_transaction = 0;
   int reset_transaction = 0;
   
   bit [31:0]read_data;
   bit [31:0]w_data;
   bit [7:0] mem [128];
   //axi_transaction expected_memory[$];
   //axi_transaction actual_memory[$];

   
   function new(string name="axi_scoreboard", uvm_component parent=null);
      super.new(name,parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      tr = axi_transaction::type_id::create("tr");
      mon_sco = new("mon_sco",this);
      m_cov = axi_coverage::type_id::create("m_cov",this);
      if(!uvm_config_db#(virtual axi_interface)::get(this,"","vif",vif)) begin 
     `uvm_fatal("NOVIF","virtual interface not found")
      end
     /*foreach(expected_memory[i]) begin
      expected_memory[i] = 32'h0;
      end
      foreach(actual_memory[i]) begin
      actual_memory[i]   = 32'h0;
      end*/
   endfunction

   virtual task run_phase(uvm_phase phase);
      super.run_phase(phase);
      forever begin
      //@(posedge vif.clk);
         run();
      end
   endtask

   task run();
      mon_sco.get(tr);
      m_cov.axi_covergroup.sample(tr.awaddr,tr.wdata,tr.araddr,tr.rdata,tr.awvalid,tr.wvalid,tr.rvalid,tr.rready);
      pass_fail();
      total_transaction++;
    //`uvm_info("SCO",$sformatf("Received transaction - ID=%0d OP=%0s",tr.id,tr.op.name()),UVM_MEDIUM);
     /* case(tr.op)
      wrrdfixed   : fixed_mode(tr);
      wrrdincr    : incr_mode(tr);
      wrrdwrap    : wrap_mode(tr);
      wrrderror   : errr_mode(tr);
      //wrrdresetdut : reset_mode(tr);
      default   : `uvm_error("sco",$sformatf("unknown operation mode: %s",tr.op.name()))
      endcase*/
      //print_transaction_result(tr);

    endtask
      
      task pass_fail();
    if(vif.resetn==1'b0) begin
         `uvm_info("[SCO]",$sformatf("Reset =%0d",vif.resetn),UVM_LOW);
         foreach(mem[i]) mem[i]=i;
         end

          if((tr.rvalid==1'b0) && (tr.wvalid==1'b1)) begin
            `uvm_info("[SCO]","Data write",UVM_LOW);

            mem[tr.awaddr]=tr.wdata[7:0];
            mem[tr.awaddr+1]=tr.wdata[15:8];
            mem[tr.awaddr+2]=tr.wdata[23:16];
            mem[tr.awaddr+3]=tr.wdata[31:24];
            
            w_data={mem[tr.awaddr+3],mem[tr.awaddr+2],mem[tr.awaddr+1],mem[tr.awaddr]};
            end

         else if(tr.rvalid==1'b1) begin

            read_data={mem[tr.araddr+3],mem[tr.araddr+2],mem[tr.araddr+1],mem[tr.araddr]};
            if(tr.rdata==32'h0000_0000) begin
            `uvm_info("[SCO]","--EMPTY LOCATION--",UVM_LOW);
            `uvm_info("[SCO]",$sformatf("rdata=%0d <==> sco.rdata=%0d",tr.rdata,read_data),UVM_LOW);
         end

         else if(tr.rdata==read_data) begin
            `uvm_info("[SCO]",$sformatf("--PASS-- rdata=%0d <==> sco.rdata=%0d",tr.rdata,read_data),UVM_LOW);
         end
         else begin
            `uvm_info("[SCO]",$sformatf("--FAIL-- rdata=%0d <==> sco.rdata=%0d",tr.rdata,read_data),UVM_LOW);
      end
      $display("---------------------------------");
    end

  endtask

        virtual function void report_phase(uvm_phase phase);
            super.report_phase(phase);
      `uvm_info(get_type_name(),$sformatf("-----AXI3 REPORT-----"),UVM_LOW);
      `uvm_info(get_type_name(),$sformatf("----total_transaction = %0d-------",total_transaction),UVM_LOW);     `uvm_info(get_type_name(),$sformatf("----pass_transaction   = %0d-------",pass_transaction ),UVM_LOW);
      `uvm_info(get_type_name(),$sformatf("----fail_transaction  = %0d-------",fail_transaction ),UVM_LOW);
      `uvm_info(get_type_name(),$sformatf("----write_transaction = %0d-------",write_transaction),UVM_LOW);
      `uvm_info(get_type_name(),$sformatf("----error_transaction = %0d-------",error_transaction),UVM_LOW)       `uvm_info(get_type_name(),$sformatf("----reset_transaction = %0d-------",reset_transaction),UVM_LOW);
      endfunction
endclass

