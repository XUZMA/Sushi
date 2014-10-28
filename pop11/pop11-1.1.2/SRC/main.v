/******************** MODULE INFO  ****************************/
/*
*  File name   :  main.v
*
*  AUTHOR      :  Yoshihiro Iida (3aepm001@keyaki.cc.u-tokai.ac.jp)
*  VERSION     :  1.0
*  DATE        :  Oct 16, 2003
*
*   Compiler    :  iverilog
*   Project     :  POP-11: PDP-11 compatible On Programmable chip
*   Functions   :  Simulation script of POP-11 for Icarus Verilog 
*
*
Copyright (c) Yoshihiro Iida, Tokai University, Shimizu Lab., Japan.
(http://shimizu-lab.dt.u-tokai.ac.jp)
This software is the property of Tokai University, Shimizu Lab., Japan.

The POP-11 is free set of files; you can use it, redistribute it
and/or modify it under the following terms:

1. You are not allowed to remove or modify this copyright notice
   and License paragraphs, even if parts of the software is used.
2. The improvements and/or extentions you make SHALL be available
   for the community under THIS license, source code included.
   Improvements or extentions, including adaptions to new architectures/languages,
   SHALL be reported and transmitted to Tokai University, Shimizu Lab., Japan.
3. You must cause the modified files to carry prominent notices stating
   that you changed the files, what you did and the date of changes.
4. You may NOT distribute this set of files under another license without
   explisit permission from Tokai University, Shimizu Lab., Japan.
5. This set of files is free, and distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY; without even the implied warranty
   of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   You SHALL NOT use this software unless you accept to carry all
   risk and cost of defects or limitations.

*
*    ------------  CHANGE RECORD  ----------------
*    Yoshihiro Iida (3aepm001@keyaki.cc.u-tokai.ac.jp) Sep 21, 2004:
*        First free version of this software published.
*
*/

module main;
  parameter  clk = 2;
  reg        p_reset, m_clock;
  reg        rts, txd;
  wire       cts, rxd;
  wire       clk, we_enable;
  wire       WE, OE, CS0, CS1, BE0, BE1, BE2, BE3;
  wire       WEL, WEH;
  wire[15:0] D0, D1;
  wire[15:0] A;
  reg [15:0] IN;
  wire[15:0] OUT;
  reg [15:0] eab [0:2047];
  reg [15:0] ram [0:65535];
  wire[15:0] eabtmp;

  wire[15:0] ATA_DD;
  wire[2:0]  ATA_DA;
  wire[1:0]  ATA_CS;
  wire       ATA_RST, ATA_DIOR, ATA_DIOW;

  // Declare submodule

  div4 div4(.p_reset(p_reset), .m_clock (m_clock) , .we_enable (we_enable) , .clk (clk) );
  top top(.p_reset(p_reset), .m_clock(div4.clk) , .D0 (D0) , .D1 (D1) , .A (A) , .WE (WE) , .OE (OE) , .CS1 (CS1) , .CS0 (CS0) , .BE3 (BE3) , .BE2 (BE2) , .BE1 (BE1) , .BE0 (BE0) , .IN (IN) , .OUT (OUT) , .WEH (WEH) , .WEL (WEL) , 
    .txd (txd) , .rts (rts) , .rxd (rxd) , .cts (cts) , .ATA_RST (ATA_RST) , .ATA_CS (ATA_CS) , .ATA_DA (ATA_DA) , .ATA_DD (ATA_DD) , .ATA_DIOR (ATA_DIOR) , .ATA_DIOW (ATA_DIOW) , .ATA_DMACK (ATA_DMACK) , .WE_enable (we_enable) );
    //txd , rts , rxd , cts , ATA_RST , ATA_CS , ATA_DA , ATA_DD , ATA_DIOR , ATA_DIOW , ATA_DMACK , div4.we_enable );

  // Generate master clock
  initial begin
    m_clock = 1'b1;
    forever #(clk/2) m_clock = ~m_clock;
  end

  // Generate reset
  initial begin
    p_reset = 1'b1;
    #(clk*2) p_reset = 1'b0;
  end

  // Monitor
  always @(negedge top.cpu.m_clock) begin 
  //always @(posedge top.cpu.cpu.cpu.inst) begin 
    $strobe("pc:%x %x %x %x %x %x %x %x %x %b opc:%b%o rom:%b%b i/o:%x:%x ram:%b%b b:%x a:%x src:%x dst:%x adr:%x alu:%x",
      top.cpu.cpu.cpu.dp.PC, 
      top.cpu.cpu.cpu.dp.R0, top.cpu.cpu.cpu.dp.R1, top.cpu.cpu.cpu.dp.R2, top.cpu.cpu.cpu.dp.R3,
      top.cpu.cpu.cpu.dp.R4, top.cpu.cpu.cpu.dp.R5, top.cpu.cpu.cpu.dp.kSP, top.cpu.cpu.cpu.dp.uSP,
      top.cpu.cpu.cpu.pswout, top.cpu.cpu.cpu.dp.OPC_BYTE, top.cpu.cpu.cpu.dp.OPC,
      top.cpu.rd_lo, WEL, IN, OUT,
      OE, WE, D0, A, 
      //top.cpu.cpu.cpu.adrs, top.cpu.cpu.cpu.dati, top.cpu.cpu.cpu.dato,
      top.cpu.cpu.cpu.dp.SRC, top.cpu.cpu.cpu.dp.DST, top.cpu.cpu.cpu.dp.ADR, top.cpu.cpu.cpu.dp.alu.out
      );
    if(top.cpu.cpu.cpu._id_dhalt) begin
      $display("system halt");
      $finish;
    end
  end

  assign eabtmp = eab[A];

  always @(negedge m_clock) begin
    if(top.cpu.rd_lo)
      IN <= eab[A];

    if( WEH & WEL )
      eab[A] <= OUT;
    if( WEH &~WEL )
      eab[A] <= { OUT[15:8], eabtmp[7:0]};
    if(~WEH & WEL )
      eab[A] <= { eabtmp[15:8], OUT[7:0]};
  end

  always @(posedge m_clock)
    if(~WE) ram[A] <= D0;

  assign D0 = ~OE ? ram[A]: 16'bz;

  // Waveform logging
  initial begin
    $dumpfile("main.vcd");
    $dumpvars(1, main);
  end

  // Memory
  initial begin
    $readmemh("bmem", eab);
  end

  assign ATA_DD = ~ATA_DIOR ? 16'b0: 16'bz;

  // main simulation
  initial begin
    rts = 1; txd = 1;
    #(clk*100) $finish;
  end


endmodule
	
