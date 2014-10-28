/******************** MODULE INFO  ****************************/
/*
*  File name   :  main.v
*
*  AUTHOR      :  Yoshihiro Iida (3aepm001@keyaki.cc.u-tokai.ac.jp)
*  VERSION     :  1.0
*  DATE        :  Oct 16, 2003
*
*   Compiler    :  Icarus Verilog
*   Project     :  POP-11: PDP-11 compatible On Programmable chip
*   Functions   :  UNIX simulation environment for POP-11
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
*    Naohiko Shimizu (nshimizu@ip-arch.jp) Sep 15, 2009:
*        Module terminals are changed to named bind.
*
*/


module main;
  parameter  STEP = 2;
  integer    disp, fp;
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
  wire[15:0] ramtmp;

  reg [15:0] hdd [0:2097151];
  reg [15:0] dsk_in;
  wire[15:0] dsk_out;
  wire[20:0] dsk_adr;
  wire       dsk_rd, dsk_wt;
  integer    t0;

  // Declare submodule

  div4 div4(.p_reset(p_reset), .m_clock(m_clock) , .we_enable(we_enable) , .clk(clk) );
  //top top(p_reset, m_clock , D0 , D1 , A , WE , OE , CS1 , CS0 , BE3 , BE2 , BE1 , BE0 , IN , OUT , WEH , WEL , txd , rts , rxd , cts , 1 , dsk_wt , dsk_rd , dsk_in , dsk_out , dsk_adr );
  top top ( .p_reset(p_reset) , .m_clock(m_clock) , .D0(D0) , .D1(D1) , .A(A) , .WE(WE) , .OE(OE) , .CS1(CS1) , .CS0(CS0) , .BE3(BE3) , .BE2(BE2) , .BE1(BE1) , .BE0(BE0) , .IN(IN) , .OUT(OUT) , .WEH(WEH) , .WEL(WEL) , .txd(txd) , .rts(rts) , .rxd(rxd) , .cts(cts) , .we_enable(1) , .dsk_wt(dsk_wt) , .dsk_rd(dsk_rd) , .dsk_in(dsk_in) , .dsk_out(dsk_out) , .dsk_adr(dsk_adr) );

  // Generate master clock
  initial begin
    m_clock = 1'b1;
    forever #(STEP/2) m_clock = ~m_clock;
  end

  // Generate reset
  initial begin
    p_reset = 1'b1;
    #(STEP*4) p_reset = 1'b0;
  end

  // Monitor
  always @(negedge top.cpu.m_clock & disp) begin 
    t0 = top.cpu.cpu.rs232.sender.send_buf&8'h7f;
    if(t0 == 8'h0d) t0 = 8'h0a;
    $display("pc:%x %x %x %x %x %x %x %x %x %b%b*%b opc:%b%o ram:%b%b b:%x a:%x dsk:%b%b i:%x o:%x a:%x va:%x vi:%x vo:%x T%b:%x R%b:%x",
      top.cpu.cpu.cpu.dp.PC, 
      top.cpu.cpu.cpu.dp.R0, top.cpu.cpu.cpu.dp.R1, top.cpu.cpu.cpu.dp.R2, top.cpu.cpu.cpu.dp.R3,
      top.cpu.cpu.cpu.dp.R4, top.cpu.cpu.cpu.dp.R5, top.cpu.cpu.cpu.dp.kSP, top.cpu.cpu.cpu.dp.uSP,
      top.cpu.cpu.cpu.pswout[15:14], top.cpu.cpu.cpu.pswout[13:12], top.cpu.cpu.cpu.pswout[7:0], 
      top.cpu.cpu.cpu.dp.OPC_BYTE, top.cpu.cpu.cpu.dp.OPC,
      //top.cpu.rd_lo, WEL, IN, OUT,
      OE, WE, D0, A, dsk_rd, dsk_wt, dsk_in, dsk_out, dsk_adr,
      top.cpu.cpu.cpu.adrs, top.cpu.cpu.cpu.dati, top.cpu.cpu.cpu.dato,
      top.cpu.cpu.rs232.sender.put,
      //top.cpu.cpu.rs232.sender.valid,
      top.cpu.cpu.rs232.sender.send_buf,
      top.cpu.cpu.rs232.reciever.get,
      //top.cpu.cpu.rs232.reciever.valid,
      top.cpu.cpu.rs232.reciever.recv_buf);
      if(top.cpu.cpu.rs232.sender.put) begin
        fp = $fopen("tty.log", "a");
        $fwrite(fp, "%c", top.cpu.cpu.rs232.sender.send_buf&8'h7f);
        $fclose(fp);
      end
      if(top.cpu.cpu.cpu._id_dhalt) $finish;
  end

  assign eabtmp = eab[A];
  assign ramtmp = ram[A];

  always @(negedge m_clock) begin
    if(top.cpu.rd_lo) IN <= eab[A];

    if( WEH & WEL ) eab[A] <= OUT;
    if( WEH &~WEL ) eab[A] <= { OUT[15:8], eabtmp[7:0] };
    if(~WEH & WEL ) eab[A] <= { eabtmp[15:8], OUT[7:0] };

    if(~WE &~BE1 &~BE0 ) ram[A] <= D0;
    if(~WE & BE1 &~BE0 ) ram[A] <= { ramtmp[15:8], D0[7:0] };
    if(~WE &~BE1 & BE0 ) ram[A] <= { D0[15:8], ramtmp[7:0] };
  end

  assign D0 = ~OE ? ram[A]: 16'bz;

  // HDD
  always @(negedge m_clock) begin
    if( dsk_rd ) dsk_in <= hdd[ dsk_adr ];
    if( dsk_wt ) hdd[ dsk_adr ] <= dsk_out;
  end

  // Waveform logging
  initial begin
//    $dumpfile("main.vcd");
//    $dumpvars(5, main);
  end

  // Memory
  initial begin
    $readmemh("boot.hex", eab);
    $readmemh("unix.hex", hdd);
  end

  // main simulation
  initial begin
    $write("POP-11: PDP-11 On Programmable chip\n");
    $write("(c)2002-2004 Yoshihiro Iida, Shimizu Lab., Tokai University, Japan\n");

    fp = $fopen("tty.log");
    $fwrite(fp, "POP-11: PDP-11 On Programmable chip\n");
    $fwrite(fp, "(c)2002-2004 Yoshihiro Iida, Shimizu Lab., Tokai University, Japan\n");
    $fclose(fp);

    disp = 1;
    rts = 1; txd = 1;
    // rkunix.40
    //#(STEP*1000) $finish;
    #(STEP*500000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h72; //r
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h6b; //k
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000)
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h75; //u
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h6e; //n
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h69; //i
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h78; //x
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h2e; //.
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h34; //4
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h30; //0
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h0d; //\r
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    // root
    #(STEP*20000000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h72; //r
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h6f; //o
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h6f; //o
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h74; //t
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h0d; //\r
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    // ls (ret)
    #(STEP*4000000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h6c; //l
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h73; //s
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h20; // 
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h2d; //-
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h6c; //l
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    #(STEP*10000) 
		top.cpu.cpu.rs232.reciever.recv_buf = 8'h0d; //\r
		top.cpu.cpu.rs232.reciever.valid = 1'b0;
    disp = 1;
    #(STEP*30000000) $finish;
  end


endmodule
	
