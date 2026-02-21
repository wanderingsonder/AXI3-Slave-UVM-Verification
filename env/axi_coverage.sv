class axi_coverage extends uvm_component;
   `uvm_component_utils(axi_coverage)
  
   function new(string name="axi_coverage",uvm_component parent=null);
      super.new(name,parent);
      axi_covergroup = new();
   endfunction

   covergroup axi_covergroup with function sample(
         bit [31:0] awaddr,
         bit [31:0] wdata,
         bit [31:0] araddr,
         bit [31:0] rdata,
         bit awvalid,
         bit wvalid,
         bit rvalid,
         bit rready);

         cp1: coverpoint awaddr  {bins   b1=  {[0:127]}; bins b2={[128:$]};}
         cp2: coverpoint wdata   {bins   b3=  {[0:255]};}
         cp3: coverpoint araddr  {bins   b4=  {[0:127]}; bins b5={[128:$]};}
         cp4: coverpoint rdata   {bins   b6=  {[0:255]};}
         cp5: coverpoint awvalid {bins   b7=  {0}; bins b8={1};}
         cp6: coverpoint wvalid  {bins   b9=  {0}; bins b10={1};}
         cp7: coverpoint rvalid  {bins   b11= {0}; bins b12={1};}
         cp8: coverpoint rready  {bins   b13= {0}; bins b14={1};}
   endgroup
endclass
