TARGET      = liteload
TARGET_ADDR	= 0x801D6000

CFILES		= main.c
CFLAGS		= -Xm -Wall -O2

CC			= ccpsx
ASM			= asmpsx

OFILES		= $(CFILES:.c=.obj)

%.obj: %.c
	$(CC) $(CFLAGS) -c $< -o $@
    
all: $(OFILES)
	$(CC) -Xo$(TARGET_ADDR) $(CFLAGS) $(OFILES) -o $(TARGET).cpe
	cpe2x $(TARGET).cpe
    
iso:
	mkpsxiso -q -y iso.xml

clean:
	rm -f $(OFILES) $(TARGET).cpe $(TARGET).exe

cleanall: clean
