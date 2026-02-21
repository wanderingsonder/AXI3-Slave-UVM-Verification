package axi_pkg;
import uvm_pkg::*;
   `include "uvm_macros.svh"

   `include "/home/dvft0901/axi_uvm_project_final/env/axi_transaction.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_sequence.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_sequencer.sv"

   `include "/home/dvft0901/axi_uvm_project_final/env/axi_driver.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_monitor.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_agent.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_coverage.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_scoreboard.sv"
   `include "/home/dvft0901/axi_uvm_project_final/env/axi_environment.sv"
   
   `include "/home/dvft0901/axi_uvm_project_final/test/axi_base_test.sv"
   `include "/home/dvft0901/axi_uvm_project_final/test/axi_fixed_wr_rd_test.sv"
   `include "/home/dvft0901/axi_uvm_project_final/test/axi_incr_wr_rd_test.sv"
   `include "/home/dvft0901/axi_uvm_project_final/test/axi_wrap_wr_rd_test.sv"
   `include "/home/dvft0901/axi_uvm_project_final/test/axi_error_wr_rd_test.sv"
   `include "/home/dvft0901/axi_uvm_project_final/test/axi_reset_dut_test.sv"

endpackage
