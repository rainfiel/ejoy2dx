
#ifndef __PILI_DEBUG_LOG_H__
#define __PILI_DEBUG_LOG_H__

#ifndef __cplusplus
#include <stdbool.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
	
void debug_log( const char * format, ... );

	
#ifdef __cplusplus
}
#endif
	
#endif
