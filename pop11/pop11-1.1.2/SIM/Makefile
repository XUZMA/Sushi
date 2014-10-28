## Makefile of the SFL-Verilog Simulation Environment
## 24-Apr yiida

FILE=top
CPU=pop11
RK=rk
MAIN=main
SIM=pop11.vvp
LOG=pop11.log

CC=nsl2vl
IVL=iverilog
VVP=vvp

all:	ivl sim

ivl: $(FILE).v $(MAIN).v $(CPU).v $(RK).v
	$(IVL) $(FILE).v $(CPU).v $(RK).v $(MAIN).v -o $(SIM)

$(FILE).v: $(FILE).nsl
	$(CC) top.nsl -O2

$(CPU).v: ../SRC/$(CPU).nsl
	$(CC) ../SRC/$(CPU).nsl -O2 -o $(CPU).v

$(RK).v: $(RK).nsl
	$(CC) $(RK).nsl -O2 -o $(RK).v

sim: $(SIM)
	$(VVP) $(SIM)| tee $(LOG)

clean:
	-rm $(SIM) $(LOG) $(FILE).v $(CPU).v $(RK).v
