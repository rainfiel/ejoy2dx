
#include "lua.h"
#include <lauxlib.h>
#include "filesystem.h"
#include <stdlib.h>
#include <sys/stat.h>
#include <windows.h>
#include <direct.h> 

static int
_read_file(lua_State* L) {
  const char* filename = luaL_checkstring(L, 1);
	const char* mode = luaL_optstring(L, 2, "rb");

	struct FileHandle *handle = pf_fileopen(filename, mode);
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
	const char* mode = luaL_optstring(L, 3, "w");

	struct FileHandle * handle = pf_fileopen(filename, mode);
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

// modes:
//   "d" for Documents
//   "l" for Library
//   "c" for Caches
static int
_get_path(lua_State* L) {
	const char* filename = luaL_checkstring(L, 1);
	const char* mode = luaL_checkstring(L, 2);

	luaL_requiref(L, "ejoy2d.framework", NULL, 0);
	lua_getfield(L, -1, "WorkDir");
	const char* root = luaL_checkstring(L, -1);
	lua_pop(L, 2);
	
	const char* mode_name;
	switch (mode[0])
	{
	case 'd':
		mode_name = "Documents/";
		break;
	case 'l':
		mode_name = "Library/";
		break;
	case 'c':
		mode_name = "Library/Caches";
		break;
	default:
		luaL_error(L, "unsupport path mode:%s", mode);
		return 0;
	}
	luaL_Buffer buffer;
	luaL_buffinit(L, &buffer);
	luaL_addstring(&buffer, root);
	luaL_addstring(&buffer, "/data/");
	luaL_addstring(&buffer, mode_name);
	luaL_addstring(&buffer, filename);
	luaL_pushresult(&buffer);

	return 1;
}

static char*
to_unicode(const char* str)  
{  
    int dwUnicodeLen = MultiByteToWideChar(CP_ACP,0,str,-1,NULL,0);  
    if(!dwUnicodeLen)  
    {  
        return strdup(str);  
    }  
    size_t num = dwUnicodeLen*sizeof(wchar_t);  
    wchar_t *pwText = (wchar_t*)malloc(num);  
    memset(pwText,0,num);  
    MultiByteToWideChar(CP_ACP,0,str,-1,pwText,dwUnicodeLen);  
    return (char*)pwText;  
}  
  
static int
_to_utf8(lua_State* L) {
	const char* text = luaL_checkstring(L, 1);

	char* unicode = to_unicode(text);
	
  int len;  
  len = WideCharToMultiByte(CP_UTF8, 0, (const wchar_t*)unicode, -1, NULL, 0, NULL, NULL);  

  char *szUtf8 = (char*)malloc(len + 1);  
  memset(szUtf8, 0, len + 1);  
  WideCharToMultiByte(CP_UTF8, 0, (const wchar_t*)unicode, -1, szUtf8, len, NULL,NULL);  

	lua_pushlstring(L, szUtf8, len);

	free(unicode);

	return 1;
}

static int
_input(lua_State* L) {
	return 0;
}

static int
_is_key_down(lua_State *L) {
	int vk = (int)luaL_checkinteger(L, 1);
	short stat = GetKeyState(vk);

	if (stat & 0x8000)
		lua_pushboolean(L, true);
	else
		lua_pushboolean(L, false);
	return 1;
}

static int
_create_directory(lua_State *L) {
	const char *path = luaL_checkstring (L, 1);
	
	BOOL bRet = CreateDirectory(path, NULL);
	if (bRet || GetLastError() == ERROR_ALREADY_EXISTS) {
		lua_pushboolean(L, 1);
		return 1;
	}

	return 0;
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
		{"to_utf8", _to_utf8},
		{"get_path", _get_path},
		{"create_directory", _create_directory},
		//{"input", _input},
		{"is_key_down", _is_key_down},
		
		{NULL, NULL}
	};

	luaL_newlib(L, l);
	return 1;
}
