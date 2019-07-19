TARGET		= liteload.elf

CFILES		= $(notdir $(wildcard *.c))
CPPFILES 	= $(notdir $(wildcard *.cpp))
AFILES		= $(notdir $(wildcard *.s))

OFILES		= $(addprefix build/,$(CFILES:.c=.o) $(CPPFILES:.cpp=.o) $(AFILES:.s=.o))

PREFIX		= mipsel-unknown-elf-
LIBDIRS		= -L../psn00bsdk/libpsn00b
INCLUDE	 	= -I../psn00bsdk/libpsn00b/include

INCLUDE	 	+=
LIBDIRS		+=

LIBS		= -lpsxetc -lpsxgpu -lpsxgte -lpsxspu -lpsxsio -lpsxapi -lc

CFLAGS		= -g -O2 -fno-builtin -fdata-sections -ffunction-sections
CPPFLAGS	= -g $(CFLAGS) -fno-exceptions
AFLAGS		= -g -msoft-float
LDFLAGS		= -g -Ttext=0x801FAFF0 -gc-sections -T /c/mipsel-unknown-elf/mipsel-unknown-elf/lib/ldscripts/elf32elmip.x

CC			= $(PREFIX)gcc
CXX			= $(PREFIX)g++
AS			= $(PREFIX)as
LD			= $(PREFIX)ld

all: $(OFILES)
	$(LD) $(LDFLAGS) $(LIBDIRS) $(OFILES) $(LIBS) -o $(TARGET)
	elf2x -q $(TARGET)
	
build/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@
	
build/%.o: %.s
	@mkdir -p $(dir $@)
	$(CC) $(AFLAGS) $(INCLUDE) -c $< -o $@
	
iso:
	mkpsxiso -y -q -o $(TARGET:.elf=.iso) iso.xml

clean:
	rm -rf build $(TARGET) $(TARGET:.elf=.exe) $(TARGET:.elf=.iso)
