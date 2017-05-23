#include "platform_init.h"

#include <android/log.h>

static void
debug_log( const char * format, ... )
{
  va_list arglist;
  va_start( arglist, format );
  __android_log_vprint(ANDROID_LOG_INFO,"EJOY2DX",(format),(arglist)); 
  va_end( arglist );
}

static int
my_print (lua_State *L) {
  int n = lua_gettop(L);  /* number of arguments */
  int i;
  luaL_Buffer b;
  luaL_buffinit(L, &b);

  lua_getglobal(L, "tostring");
  for (i=1; i<=n; i++) {
    const char *s;
    size_t l;
    lua_pushvalue(L, -1);  /* function to be called */
    lua_pushvalue(L, i);   /* value to print */
    lua_call(L, 1, 1);
    s = lua_tostring(L, -1);  /* get result */
    if (s == NULL)
      return luaL_error(L,"must return a string to print");
    luaL_addstring(&b, s);
    luaL_addstring(&b, "\t");
    lua_pop(L, 1);  /* pop result */
  }
  luaL_pushresult(&b);
  char* s = (char*)lua_tostring(L, -1);
  debug_log(s);
  return 0;
}

void platform_init(struct lua_State* L)
{
    lua_register(L, "print", my_print);	
}