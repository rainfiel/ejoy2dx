
#include "lua.h"
#include "filesystem.h"
#include <stdlib.h>
#include <sys/stat.h>

static int
_read_file(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);

	struct FileHandle *handle = pf_fileopen(filename, "rb");
	if (handle == NULL){
		return luaL_error(L, "Can't open file %s", filename);
	}
	
	int buff_size = pf_filesize(handle);
	if (buff_size == 0){
		pf_fileclose(handle);
		return luaL_error(L, "file size is zero %s", filename);
	}
	char* buffer = (char*)malloc(buff_size);
	pf_fread(buffer, sizeof(char), buff_size, handle);
	pf_fileclose(handle);

  lua_pushlstring(L, buffer, buff_size);
  return 1;
}

static int
_write_file(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
	size_t size;
	const char* data = luaL_checklstring(L, 2, &size);

	struct FileHandle * handle = pf_fileopen(filename, "w");
	if (handle == NULL){
		return luaL_error(L, "Can't open file for write %s", filename);
	}

	pf_fwrite((void*)data, sizeof(char), size, handle);
	pf_fileclose(handle);

  return 0;
}

static int
_delete_file(lua_State* L) {
	const char* filename = luaL_checkstring(L, 1);
	int ok = pf_fremove(filename);
	lua_pushinteger(L, ok);
  return 1;
}

static int
_exists(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
	struct stat st;
  int result = stat(filename, &st);
	if (result != 0)
		return 0;
	lua_pushboolean(L, 1);
	return 1;
}

int 
luaopen_osutil(lua_State* L) {
	luaL_checkversion(L);

	luaL_Reg l[] = {
		// filesystem
		{"exists", _exists},
		{"read_file", _read_file},
		{"write_file", _write_file},
		{"delete_file", _delete_file},
		
		{NULL, NULL}
	};

	luaL_newlib(L, l);
	return 1;
}
