declare rk {
  func_in  rkda_rd;

  func_in  rkba_rd;

  func_in  rkwc_rd;

  func_in  rkcs_rd;

  input    rk_in[16];
  output   rk_out[16];

  func_in  disk_ack;
  output   disk_adr[21];
  output   disk_out[16];
  input    disk_in[16];

  func_in  mem_ack;
  output   mem_adr[18];
  output   mem_out[16];
  input    mem_in[16];

  func_out irq;
  func_out active;
  func_in rkda_wt(rk_in);
  func_in rkba_wt(rk_in);
  func_in rkwc_wt(rk_in);
  func_in rkcs_wt(rk_in);
  func_out disk_read(disk_adr);
  func_out disk_write(disk_adr,disk_out);
  func_out mem_read(mem_adr);
  func_out mem_write(mem_adr,mem_out);

}

