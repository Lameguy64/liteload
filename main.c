#include <sys/types.h>
#include <string.h>
#include <libetc.h>
#include <libgte.h>
#include <libgpu.h>
#include <libapi.h>
#include <libsio.h>

#define VERSION "1.1"

#define set_bpc( r0 ) __asm__ volatile (	\
	"mtc0	%0, $3;"						\
	:										\
	: "r"( r0 ) )
	
// Color look-up for the colored bars background
CVECTOR colortable[] = {
	{ 255, 255, 255 },
	{ 255, 255, 0 },
	{ 0, 255, 255 },
	{ 0, 255, 0 },
	{ 192, 0, 192 },
	{ 255, 0, 0 },
	{ 0, 0, 192 },
};

typedef struct {
    struct EXEC exe_param;
    unsigned int exe_crc32;
	unsigned int exe_flags;
} EXPARAM;

typedef struct {
    int size;
    unsigned int addr;
    unsigned int crc32;
} BINPARAM;

TILE box;
char command[8];
EXPARAM params;
int y_center;

// Serial routines

char* sio_addr = NULL;
int sio_len,sio_read;

#define PATCH_ENTRY	0xC000

void (*patch_jump)(void) = (void*)0x80010000;

void _sioCallback() {
    
    if ( ( sio_read < sio_len ) && ( sio_addr ) ) {
		
        sio_addr[sio_read] = _sio_control(0, 4, 0);
		sio_read++;
        
	} else {
        
		_sio_control(0, 4, 0);
        
	}
	
	_sio_control(2, 1, 0);
    
}

void setread(char* addr, int len) {
    
    sio_addr = addr;
    sio_read = 0;
    sio_len = len;
    
}

// CRC32

#define CRC32_REMAINDER		0xFFFFFFFF

void initTable32(unsigned int* table) {

	int i,j;
	unsigned int crcVal;

	for(i=0; i<256; i++) {

		crcVal = i;

		for(j=0; j<8; j++) {

			if (crcVal&0x00000001L)
				crcVal = (crcVal>>1)^0xEDB88320L;
			else
				crcVal = crcVal>>1;

		}

		table[i] = crcVal;

	}

}

unsigned int crc32(void* buff, int bytes, unsigned int crc) {

	int	i;
	unsigned char*	byteBuff = (unsigned char*)buff;
	unsigned int	byte;
	unsigned int	crcTable[256];

    initTable32(crcTable);

	for(i=0; i<bytes; i++) {

		byte = 0x000000ffL&(unsigned int)byteBuff[i];
		crc = (crc>>8)^crcTable[(crc^byte)&0xff];

	}

	return(crc^0xFFFFFFFF);

}

// Main

void serialInit() {
	
	// Init serial
	_sio_control(1, 2, MR_SB_01|MR_CHLEN_8|0x02);
	_sio_control(1, 3, 115200);
	_sio_control(1, 1, CR_RXEN|CR_RXIEN|CR_TXEN);
    
    // Set a callback
    Sio1Callback(_sioCallback);
	
}

void init() {
    
	DISPENV disp;
	DRAWENV draw;
    
    // Init display
	
	ResetGraph(0);
    
    if ( *((char *)0xbfc7ff52) == 'E' ) {
        
		// For PAL systems
		SetVideoMode(MODE_PAL);
		SetDefDispEnv(&disp, 0, 0, 320, 256);
        SetDefDrawEnv(&draw, 0, 0, 320, 256);
        disp.screen.y = 24;
        y_center = 128;
        
    } else {
        
		// For NTSC systems
		SetVideoMode(MODE_NTSC);
		SetDefDispEnv(&disp, 0, 0, 320, 240);
        SetDefDrawEnv(&draw, 0, 0, 320, 240);
        y_center = 120;
        
    }
	
	draw.dfe = 1;
	draw.isbg = 1;
	setRGB0(&draw, 0, 0, 0);
	
	PutDispEnv(&disp);
	PutDrawEnv(&draw);
    
    FntLoad(960, 0);
    FntOpen(0, 0, 320, disp.disp.h, 0, 110);
    
	serialInit();
	
}

// Display stuff

void drawbars() {
    
    int i;
    
    setTile(&box);
    setWH(&box, 40, 256);
    
    for(i=0; i<7; i++) {
        
        setXY0(&box, 40*i, 0);
        setRGB0(&box, colortable[i].r, colortable[i].g, colortable[i].b);
        
        DrawPrim(&box);
    }
    
}

void drawmainscreen() {
    
    drawbars();
	
    setWH(&box, 209, 27);
    setXY0(&box, 16, 14);
    setRGB0(&box, 0, 0, 0);
    DrawPrim(&box);
    
    setXY0(&box, 16, 46);
    setWH(&box, 87, 11);
    DrawPrim(&box);    
    
	FntPrint("\n\n  LITELOAD V" VERSION " BY LAMEGUY64\n");
    FntPrint("  2018 MEIDO-TEK PRODUCTIONS\n");
    FntPrint("  BUILT " __DATE__ " " __TIME__ "\n");
    FntPrint("\n  STAND BY...\n");
    FntFlush(-1);

}

void drawmessage(char* msg) {
    
    setWH(&box, 233, 11);
    setXY0(&box, 16, 14);
    setRGB0(&box, 0, 0, 0);
    DrawPrim(&box);
    
    FntPrint("\n\n  ");
    FntPrint(msg);
    FntFlush(-1);
    
}

// Load routines

void loadEXE() {
    
    int i;
    int* paddr = (int*)PATCH_ENTRY;
	
    drawbars();
    drawmessage("RECEIVING PARAMETERS...");
    
	params.exe_crc32 = 0;
	
    while((_sio_control(0, 0, 0) & (SR_TXU|SR_TXRDY)) != (SR_TXU|SR_TXRDY));
	_sio_control(1, 4, 'K');
    
    setread((char*)&params, sizeof(EXPARAM));
    while(sio_read < sio_len) {
		VSync(0);
	}
	
	setread((char*)params.exe_param.t_addr, params.exe_param.t_size);
	
	drawmessage("DOWNLOADING...");
    
    setWH(&box, 200, 32);
    setXY0(&box, 50, y_center-16);
    setRGB0(&box, 0, 0, 0);
    DrawPrim(&box);
	
    while(sio_read < sio_len) {
        
        VSync(0);
        
        if ( sio_read <= sio_len ) {
            
            setWH(&box, (196*((ONE*(sio_read>>2))/(sio_len>>2)))/ONE, 28);
            setXY0(&box, 52, y_center-14);
            setRGB0(&box, 255, 255, 0);
            DrawPrim(&box);
            
        }
        
    }
	
    if ( crc32((void*)params.exe_param.t_addr, 
        params.exe_param.t_size, CRC32_REMAINDER) != params.exe_crc32 ) {
		
        drawmessage("CHECKSUM ERROR.");
        
        for(i=0; i<120; i++) {
            VSync(0);
        }
        
        return;
        
    }
    
    drawmessage("EXECUTE!");
	
    StopCallback();
	EnterCriticalSection();
	
	paddr[1] = 0x0;		// Enable a loaded debug stub by patching
	paddr[0] = 0x0;		// the first 2 instructions with nop
	
	if( params.exe_flags & 0x1 ) {	// Set BPC if first bit is set
		set_bpc( params.exe_param.pc0 );
	}
	
	Exec(&params.exe_param, 0, 0);
	
}

void loadBIN(int mode) {
    
    BINPARAM param;
    int i;
    
	drawbars();
	drawmessage("RECEIVING PARAMETERS...");
	
	while((_sio_control(0, 0, 0) & (SR_TXU|SR_TXRDY)) != (SR_TXU|SR_TXRDY));
	_sio_control(1, 4, 'K');
	
	setread((char*)&param, sizeof(BINPARAM));
	while(sio_read < sio_len)  {
		VSync(0);
	}
    
	if( mode ) {
		param.addr = (unsigned int)patch_jump;
	}
	
	setread((char*)param.addr, param.size);
	
    drawmessage("DOWNLOADING...");
    
    setWH(&box, 200, 32);
    setXY0(&box, 50, y_center-16);
    setRGB0(&box, 0, 0, 0);
    DrawPrim(&box);
	
    while( sio_read < sio_len ) {
        
        VSync(0);
        
        if( sio_read <= sio_len ) {
            
            setWH(&box, (196*((ONE*(sio_read>>2))/(sio_len>>2)))/ONE, 28);
            setXY0(&box, 52, y_center-14);
            setRGB0(&box, 255, 255, 0);
            DrawPrim(&box);
            
        }
        
    }
    
    if( crc32((void*)param.addr, param.size, CRC32_REMAINDER) != param.crc32 ) {
        
        drawmessage("CHECKSUM ERROR.");
        
        for(i=0; i<120; i++) {
            VSync(0);
        }
        
        return;
        
    }
	
	if( mode ) {
		
		patch_jump();
		
	}
    
}

int main() {
	
	int timeout = 0;
	
    init();
	
    drawmainscreen();
    SetDispMask(1);
	
    while(1) {
    
		timeout = 0;
		memset(command, 0x0, 8);
        setread(command, 4);
		while(sio_read < sio_len) {
			
			VSync(0);
			
			if( timeout > 60 ) {	// timeout routine in case of garbage in serial
				memset(command, 0x0, 8);
				setread(command, 4);
				timeout = 0;
			}
			
			if( sio_read ) {
				timeout++;
			}
			
		}
        
        // Load EXE
        if( strncmp(command, "MEXE", 4) == 0 ) {
            
            loadEXE();
            drawmainscreen();
        
        // Load BIN
        } else if( strncmp(command, "MBIN", 4) == 0 ) {
            
            loadBIN( 0 );
            drawmainscreen();
        
		// Load patch installer
        } else if( strncmp(command, "MPAT", 4) == 0 ) {
            
            loadBIN( 1 );
            drawmainscreen();
            
        }
        
    }
    
	return 0;
    
}