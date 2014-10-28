BOOT:
	clr r3
	mov #177412,r1
	mov r3,(r1)
	clr -(r1)
	mov #177000,-(r1)
	mov #5,-(r1)
BOOT_L0:
	tstb (r1)
	bpl BOOT_L0
	clr pc
