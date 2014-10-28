declare pop11 {
  input     dati[16];
  output    dato[16];
  output    adrs[16];
  func_in   irq_in, rdy, error, fault;
  func_out  rd, wt;
  output    byte;
  func_out  int_ack;
  output    pswout[16];
  input     psi[16];
  func_out  inst;
  func_in pswt(psi);
}

