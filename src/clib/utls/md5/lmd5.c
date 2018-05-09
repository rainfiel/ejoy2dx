#include "lua.h"
#include "lauxlib.h"

void md5_signature(const char * text, size_t sz, char sig[32]);
int md5_file(const char* filename, char sig[32]);

static int
lmd5(lua_State* L) {
  char buf[32];
  size_t sz;
  const char* data = luaL_checklstring(L, 1, &sz);
  md5_signature(data, sz, buf);
  lua_pushlstring(L, buf, 32);
  return 1;
}

static int
lget_file_md5(lua_State* L) {
  char md5[32];
  const char* filename = luaL_checkstring(L, 1);
  int err = md5_file(filename, md5);
  if(err) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushlstring(L, md5, 32);
  return 1;
}

int
luaopen_md5(lua_State* L) {
  luaL_Reg reg[] = {
    { "md5" , lmd5 },
    { "file_md5", lget_file_md5 },
    { NULL, NULL },
  };

  luaL_checkversion(L);
  luaL_newlib(L, reg);

  return 1;
}
