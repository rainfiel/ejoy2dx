
#ifndef __os_utils_h__
#define __os_utils_h__

#include "lua.h"
#include "lauxlib.h"
#include "ejoy2d.h"

int luaopen_osutil(lua_State* L);
EJOY_API void set_view_controller(void*);

#endif
