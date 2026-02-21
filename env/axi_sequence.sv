class axi_sequence extends uvm_sequence;

   `uvm_object_utils(axi_sequence)

   function new(string name = "axi_sequnce");
      super.new(name);
   endfunction

   virtual task body();

   endtask

endclass
