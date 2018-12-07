#include <stdio.h>
#include <malloc.h>
#include <string.h>

typedef struct {
	unsigned int pc0;
	unsigned int gp0;
	unsigned int t_addr;
	unsigned int t_size;
	unsigned int d_addr;
	unsigned int d_size;
	unsigned int b_addr;
	unsigned int b_size;
	unsigned int sp_addr;
	unsigned int sp_size;
	unsigned int sp;
	unsigned int fp;
	unsigned int gp;
	unsigned int ret;
	unsigned int base;
} EXEC;

typedef struct {
	char header[8];
	char pad[8];
	EXEC params;
	char license[64];
	char pad2[1908];
} PSEXE;

int main(int argc, const char* argv[]) {
	
	PSEXE exe_head;
	char *exe_data;
	char out_name[MAX_PATH];
	
	printf( "PS-EXE to BIN for ROM loaders\n" );
	
	if( argc == 1 ) {
		printf( "  exe2bin <infile>\n" );
		return 0;
	}
	
	FILE* fp = fopen( argv[1], "rb" );
	if( !fp ) {
		printf( "I cannot open file.\n") ;
		return EXIT_FAILURE;
	}
	
	fread( &exe_head, 1, sizeof( PSEXE ), fp );
	
	printf( "pc0:%08x t_addr:%08x t_size:%08x\n", 
		exe_head.params.pc0,
		exe_head.params.t_addr,
		exe_head.params.t_size );
	
	exe_data = (char*)malloc( exe_head.params.t_size );
	fseek( fp, 2048, SEEK_SET );
	fread( exe_data, 1, exe_head.params.t_size, fp );
	
	fclose( fp );
	
	strcpy( out_name, argv[1] );
	{
		char *pos = strrchr( out_name, '.' );
		
		if( !pos ) {
			
			strcat( out_name, ".bin" );
			
		} else {
			
			strcpy( pos, ".bin" );
			
		}
	}
	
	printf( "Output: %s\n", out_name );
	
	fp = fopen( out_name, "wb" );
	if( !fp ) {
		printf( "I cannot write a file.\n" );
		free( exe_data );
		return EXIT_FAILURE;
	}
	
	fwrite( &exe_head.params, 1, sizeof( EXEC ), fp );
	fwrite( exe_data, 1, exe_head.params.t_size, fp );
	
	free( exe_data );
	
	return 0;
	
}