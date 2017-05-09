#include <jni.h>
#include <string>

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

int luaopen_fog(lua_State* L){return 0;}
static void
_register(lua_State *L, lua_CFunction func, const char * libname) {
  luaL_requiref(L, libname, func, 0);
  lua_pop(L, 1);
}

JNIEXPORT jstring JNICALL
Java_com_ejoy2dx_example_MainActivity_stringFromJNI(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++xxx";

	lua_State *L = luaL_newstate();
	luaL_openlibs(L);

	lua_pushstring(L, "came from lua");

	return env->NewStringUTF(lua_tostring(L, -1));

   // return env->NewStringUTF(hello.c_str());
}
}