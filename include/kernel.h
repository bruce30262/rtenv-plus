#ifndef KERNEL_H
#define KERNEL_H

#include "task.h"
#include "file.h"
#include "event-monitor.h"
#include <stddef.h>


#define MAX_CMDNAME 19
#define MAX_ARGC 19
#define MAX_CMDHELP 1023
#define HISTORY_COUNT 8
#define CMDBUF_SIZE 64
#define MAX_ENVCOUNT 16
#define MAX_ENVNAME 15
#define MAX_ENVVALUE 63

/* Enumeration for command types. */
typedef enum {
	CMD_ECHO = 0,
	CMD_EXPORT,
	CMD_HELP,
	CMD_HISTORY,
	CMD_MAN,
	CMD_PS,
	CMD_XXD,
	CMD_COUNT
} CMD_TYPE;

/* Structure for environment variables. */
typedef struct {
	char name[MAX_ENVNAME + 1];
	char value[MAX_ENVVALUE + 1];
} evar_entry;

#endif
