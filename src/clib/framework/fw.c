
#include <stdbool.h>

#include "opengl.h"
#include "ejoy2dgame.h"
#include "fault.h"
#include "screen.h"
#include "array.h"
#include "fw.h"
#include "lualibs.h"
#include "filesystem.h"
#include "platform_init.h"

#include <lauxlib.h>

#include <stdlib.h>
#include <stdio.h>

#ifndef LOGIC_FRAME
#define LOGIC_FRAME 30
#endif

struct WINDOWGAME {
	struct game *game;
};

static struct WINDOWGAME *G = NULL;
static struct WINDOWGAME *G2 = NULL; //TODO container
static struct STARTUP_INFO *STARTUP = NULL;

#define IOS 1
#define WINDOWS 2

#if EJOY2D_OS == IOS || EJOY2D_OS == ANDROID
static const char * startscript =
"local path, lua_root, lua_main, startup = ...\n"

"lua_main = lua_main or [[main]]\n"
//"lua_root = lua_root or [[script]]\n"
"if not path then print('PLEASE SPECIFY THE WORK DIRECTORY') end\n"
"local fw=require(\"ejoy2d.framework\")\n"
"fw.WorkDir = path\n"
"fw.GameInfo = startup\n"

"local script_root = path .. [[/?.lua;]] .. path .. [[/?/init.lua;./?.lua;./?/init.lua]]\n"
"local script_project = path .. [[/script/?.lua;]].. path .. [[/script]] .. [[/?/init.lua;./?.lua;./?/init.lua]]\n"
"package.path = script_root..[[;]]..script_project\n"

"require([[script]])\n"
//"local f = assert(loadfile(path..[[/script/]]..lua_main))\n"
"local f = require(lua_main)\n"
// "f()\n"
;
#else
static const char * startscript =
"local path, lua_root, lua_main, startup = ...\n"

"lua_main = lua_main or [[main.lua]]\n"
"lua_root = lua_root or [[script]]\n"
"if not path then print('PLEASE SPECIFY THE WORK DIRECTORY') end\n"
"path = string.match(path,[[(.*)\\[^\\]*$]])\n"
"local fw=require(\"ejoy2d.framework\")\n"
"fw.WorkDir = path\n"
"fw.GameInfo = startup\n"

//ejoy2dx path
"local ej2dx = path .. [[\\..\\..\\src]] .. [[\\?.lua;]] .. path .. [[\\..\\..\\src]] .. [[\\?\\init.lua;.\\?.lua;.\\?\\init.lua]]\n"
//ejoy2d path
"local ej2d  = path .. [[\\..\\..\\ejoy2d]] .. [[\\?.lua;]] .. path .. [[\\..\\..\\ejoy2d]] .. [[\\?\\init.lua;.\\?.lua;.\\?\\init.lua]]\n"
//user path
"local usr = path .. [[\\]]..lua_root..[[\\?.lua;]].. path .. [[\\]]..lua_root.. [[\\?\\init.lua;.\\?.lua;.\\?\\init.lua]]\n"
"package.path = ej2dx..[[;]]..ej2d..[[;]]..usr\n"

"require(lua_root)\n"
"local f = assert(loadfile(path..[[\\]]..lua_root..[[\\]]..lua_main))\n"
"f()\n"
;
#endif

static struct WINDOWGAME *
create_game() {
	struct WINDOWGAME * g = (struct WINDOWGAME *)malloc(sizeof(*g));
	g->game = ejoy2d_game();
	return g;
}

static int
traceback(lua_State *L) {
	const char *msg = lua_tostring(L, 1);
	if (msg == NULL) {
	if (luaL_callmeta(L, 1, "__tostring") &&
		lua_type(L, -1) == LUA_TSTRING)
		return 1; 
	else
		msg = lua_pushfstring(L, "(error object is a %s value)",
								luaL_typename(L, 1));
	}
	luaL_traceback(L, L, msg, 1); 
	return 1;
}

static void
push_startup_info(lua_State* L, struct STARTUP_INFO* start) {
	lua_newtable(L);
	lua_pushnumber(L, start->orix);
	lua_setfield(L, -2, "orix");
	lua_pushnumber(L, start->oriy);
	lua_setfield(L, -2, "oriy");

	lua_pushnumber(L, start->width);
	lua_setfield(L, -2, "width");
	lua_pushnumber(L, start->height);
	lua_setfield(L, -2, "height");

	lua_pushnumber(L, start->scale);
	lua_setfield(L, -2, "scale");
	lua_pushinteger(L, start->reload_count);
	lua_setfield(L, -2, "reload_count");

	lua_pushboolean(L, start->auto_rotate);
	lua_setfield(L, -2, "auto_rotate");
    
    lua_pushboolean(L, true);
    lua_setfield(L, -2, "simul_gesture");

	if (start->serialized)	
		lua_pushlightuserdata(L, start->serialized);
	else
		lua_pushnil(L);
	lua_setfield(L, -2, "serialized");

	if (start->user_data)
		lua_pushstring(L, start->user_data);
	else
		lua_pushnil(L);
	lua_setfield(L, -2, "user_data");

	lua_pushinteger(L, LOGIC_FRAME);
	lua_setfield(L, -2, "logic_frame");
    
#if defined(_DEBUG) || defined(DEBUG)
    lua_pushboolean(L, false);
#else
    lua_pushboolean(L, true);
#endif
    lua_setfield(L, -2, "is_release");
}

static int
force_sync_frame(lua_State* L) {
	G->game->logic_time = G->game->real_time;
	return 0;
}

#if EJOY2D_OS==ANDROID
static int
android_loader(lua_State *L) {
	size_t name_sz = 0;
	const char * libname = luaL_checklstring(L, 1, &name_sz);
	
	ARRAY(char, tmp, 1+name_sz+20);
	char *name = tmp+1;
	tmp[0]='@';
	int i;
	for (i=0;i<name_sz;i++) {
		if (libname[i] == '.') {
			name[i] = '/';
		} else {
			name[i] = libname[i];
		}
	}

	strcpy(name+name_sz,".lua");
	struct FileHandle* h = pf_fileopen(name, "rb");
	if (!h)	{
		strcpy(name+name_sz,"/init.lua");
		h = pf_fileopen(name, "rb");
		if (!h) {	
			char name2[name_sz+20];
			strcpy(name+name_sz,".lua");
			snprintf(name2, name_sz+20, "script/%s", name);
			h = pf_fileopen(name2, "rb");
			if (!h) {
				strcpy(name+name_sz,"/init.lua");
				snprintf(name2, name_sz+20, "script/%s", name);
				h = pf_fileopen(name2, "rb");
				if (!h) {
					return luaL_error(L, "Can't open %s", name);
				}
			}
		}
	}

	size_t sz = pf_filesize(h);
	char buf[sz];
	if(sz > 0 && !pf_fread(buf, sizeof(char), sz, h)){
		pf_fileclose(h);
		return luaL_error(L,"Can't read %s", name);
	}
	pf_fileclose(h);

	int r = luaL_loadbuffer(L, buf, sz, tmp);	
	if (r!=LUA_OK) {
		return luaL_error(L, "error loading module %s :\n\t%s",
											name, lua_tostring(L, -1));
	}
	lua_pushstring(L, name);
	return 2;
}
#else
static int
android_loader(lua_State *L) {
	return 0;
}
#endif

static void
set_android_loader(lua_State* L) {
	lua_getglobal(L, "package");
	luaL_checktype(L,-1,LUA_TTABLE);
	lua_getfield(L,-1, "searchers");
	luaL_checktype(L,-1,LUA_TTABLE);
	int len = lua_rawlen(L, -1);
	lua_pushcfunction(L, android_loader);
	lua_rawseti(L, -2, len+1);
	lua_pop(L,2);
}

struct WINDOWGAME*
new_game(const char* lua_root, const char* script) {
	struct WINDOWGAME* wg = create_game();
	lua_State* L = ejoy2d_game_lua(wg->game);
	platform_init(L);
	init_lua_libs(L);
	init_user_lua_libs(L);

#if EJOY2D_OS==ANDROID
	set_android_loader(L);
#endif

	lua_pushcfunction(L, traceback);
	int tb = lua_gettop(L);
	int err = luaL_loadstring(L, startscript);
	if (err) {
		const char *msg = lua_tostring(L,-1);
		fault("load: %s", msg);
	}


	lua_pushstring(L, STARTUP->folder);
	lua_pushstring(L, lua_root); 
	lua_pushstring(L, script);

	push_startup_info(L, STARTUP);
	err = lua_pcall(L, 4, 0, tb);
	if (err) {
		const char *msg = lua_tostring(L,-1);
		fault("run: %s", msg);
	}
	lua_pop(L,1);

	return wg;
}

static int
lnew_game(lua_State* L) {
	if (!G2) {
		const char *root = luaL_checkstring(L, 1);
		const char *script = luaL_checkstring(L, 2);
		G2 = new_game(root, script);
		ejoy2d_game_start(G2->game);
	}
	return 0;
}

static int
lclose_game(lua_State* L) {
	if (G2) {
		if (G2->game && G2->game->L) {
			lua_close(G2->game->L);
			G2->game->L = NULL;
		}
		free(G2->game);
		G2=NULL;
	}
	return 0;
}

#define FLUOR_FUNC(X) \
static int _fluor##X(lua_State *L) { \
    int nargs = (int)luaL_checkinteger(L, 1);           \
    int nresults = (int)luaL_checkinteger(L,2);         \
    lua_call(L, nargs, nresults);                       \
    return nresults;                                    \
}                                                   \
	
FLUOR_FUNC(1)
FLUOR_FUNC(2)

static int
lgame_fps(lua_State *L) {
	lua_pushnumber(L, G->game->frame_count / G->game->real_time);
	return 1;
}

void
ejoy2d_fw_init(struct STARTUP_INFO* startup) {
	screen_init(startup->width,startup->height,startup->scale);

	//free it
	STARTUP = startup;
	G = new_game(STARTUP->lua_root, STARTUP->script);

	lua_State *L = ejoy2d_game_lua(G->game);
	lua_register(L, "ejoy2dx_sync_frame", force_sync_frame);
	lua_register(L, "ejoy2dx_new_lvm", lnew_game);
	lua_register(L, "ejoy2dx_close_lvm", lclose_game);
	lua_register(L, "ejoy2dx_fps", lgame_fps);
	lua_register(L, "fluor1", _fluor1);
	lua_register(L, "fluor2", _fluor2);

	ejoy2d_game_logicframe(LOGIC_FRAME);
	ejoy2d_game_start(G->game);
}	

bool
ejoy2d_fw_auto_rotate() {
    if (!G || !STARTUP) return false;
    lua_State *L = ejoy2d_game_lua(G->game);
    luaL_requiref(L, "ejoy2d.framework", NULL, 0);
    lua_getfield(L, -1, "GameInfo");
    lua_getfield(L, -1, "auto_rotate");
    bool auto_rotate = lua_toboolean(L, -1);
    lua_pop(L, 3);
    return auto_rotate;
}

bool
ejoy2d_fw_simul_gesture() {
    if (!G || !STARTUP) return false;
    lua_State *L = ejoy2d_game_lua(G->game);
    luaL_requiref(L, "ejoy2d.framework", NULL, 0);
    lua_getfield(L, -1, "GameInfo");
    lua_getfield(L, -1, "simul_gesture");
    bool simul = lua_toboolean(L, -1);
    lua_pop(L, 3);
    return simul;
}

static void
ejoy2d_check_reload() {
	if (!G || !STARTUP) return;

	lua_State *L = ejoy2d_game_lua(G->game);
	lua_getfield(L, LUA_REGISTRYINDEX, "ejoy_reload");
	int reload_flag = lua_toboolean(L, -1);
	lua_pop(L, 1);

	if (reload_flag) {
		STARTUP->reload_count = STARTUP->reload_count + 1;

		lua_getfield(L, LUA_REGISTRYINDEX, "seraized_texture");
		STARTUP->serialized = lua_touserdata(L, -1);
		lua_pop(L, 1);

		ejoy2d_game_reload(G->game);

		free(G);
		ejoy2d_fw_init(STARTUP);
	}

}

void
ejoy2d_fw_message(int ID,const char* msg,const char* data, lua_Number n){
	ejoy2d_game_message(G->game, ID, msg, data, n);
}

void
ejoy2d_fw_update(float delta) {
	if (G2) {
		ejoy2d_game_update(G2->game, delta);
	}
	ejoy2d_game_update(G->game, delta);
	ejoy2d_check_reload();
}

void
ejoy2d_fw_frame() {
	ejoy2d_game_drawframe(G->game);
}

int
ejoy2d_fw_touch(int x, int y,int touch, int id) {
	return ejoy2d_game_touch(G->game, id, x,y,touch);
}

void
ejoy2d_fw_gesture(int type, float x1, float y1, float x2, float y2, int state) {
	ejoy2d_game_gesture(G->game, type, x1, y1, x2, y2, state);
}

void
ejoy2d_fw_view_layout(int stat, float x, float y, float width, float height) {
	ejoy2d_game_view_layout(G->game, stat, x, y, width, height);
}

void
ejoy2d_fw_pause() {
    ejoy2d_game_pause(G->game);
}

void
ejoy2d_fw_resume() {
    ejoy2d_game_resume(G->game);
}

void
ejoy2d_fw_close() {
	ejoy2d_game_close(G->game);
}
