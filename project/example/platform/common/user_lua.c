
#include <lauxlib.h>

//int luaopen_xxx(lua_State* L);

static void
_register(lua_State *L, lua_CFunction func, const char * libname) {
  luaL_requiref(L, libname, func, 0);
  lua_pop(L, 1);
}

void init_user_lua_libs(lua_State *L) {
//	_register(L, luaopen_xxx, "your.name.c");
}
