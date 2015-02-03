#ifndef __pili_file_system_h__
#define __pili_file_system_h__

#include "lua.h"
#include "lauxlib.h"

int luaopen_file_system(lua_State* L);

int lexists(lua_State* L);
int lread(lua_State* L);
int lwrite(lua_State* L);
int lclear(lua_State* L);


#include <stddef.h>

struct FileHandle;

struct FileHandle* pf_fileopen(const char *path, const char* format);
struct FileHandle* pf_bundleopen(const char* filename, const char* format);

size_t pf_filesize(struct FileHandle* h);
size_t pf_fread(void *ptr, size_t size, size_t nmemb, struct FileHandle *h);
size_t pf_fwrite(void *ptr, size_t size, size_t nmemb, struct FileHandle *h);
int pf_fremove(const char* filename);
void pf_fileseek_from_cur(struct FileHandle* h, int offset);
void pf_fileseek_from_head(struct FileHandle* h, int offset);
void pf_fileclose(struct FileHandle* h);
int pf_feof(struct FileHandle* h);


#endif
