
#include "lualibs.h"
#include <lauxlib.h>

static void
_register(lua_State *L, lua_CFunction func, const char * libname) {
  luaL_requiref(L, libname, func, 0);
  lua_pop(L, 1);
}

int luaopen_image(lua_State *L);
int luaopen_serialize(lua_State *L);
int luaopen_osutil(lua_State *L);
int luaopen_monitor(lua_State *L);
int luaopen_easing(lua_State *L);
int luaopen_lsocket(lua_State *L);
int luaopen_crypt(lua_State *L);
int luaopen_timesync(lua_State *L);
int luaopen_sproto_core(lua_State *L);
int luaopen_lpeg (lua_State *L);
int luaopen_liekkas(lua_State *L);
int luaopen_liekkas_bgm(lua_State* L);
int luaopen_liekkas_decode(lua_State *L);
int luaopen_lzma(lua_State *L);
int luaopen_yaml(lua_State *L);

void
init_lua_libs(lua_State* L) {
	_register(L, luaopen_image, "ejoy2dx.image.c");
	_register(L, luaopen_osutil, "ejoy2dx.osutil.c");
	_register(L, luaopen_serialize, "ejoy2dx.serialize.c");
	_register(L, luaopen_easing, "ejoy2dx.easing.c");
	_register(L, luaopen_lsocket, "ejoy2dx.socket.c");
	_register(L, luaopen_crypt, "ejoy2dx.crypt.c");
	_register(L, luaopen_timesync, "ejoy2dx.timesync.c");
	_register(L, luaopen_sproto_core, "ejoy2dx.sproto.c");
	_register(L, luaopen_lpeg, "ejoy2dx.lpeg.c");
	_register(L, luaopen_liekkas, "liekkas");
	_register(L, luaopen_liekkas_bgm, "liekkas.bgm");
	_register(L, luaopen_liekkas_decode, "liekkas.decode");
	_register(L, luaopen_lzma, "ejoy2dx.lzma.c");
	_register(L, luaopen_yaml, "ejoy2dx.yaml.c");
  
#ifdef DEBUG
  _register(L, luaopen_monitor, "ejoy2dx.lmonitor.c");
#endif

}
