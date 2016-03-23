
#include <stdbool.h>

#include "opengl.h"
#include "ejoy2dgame.h"
#include "fault.h"
#include "screen.h"
#include "fw.h"
#include "lualibs.h"

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
static struct STARTUP_INFO *STARTUP = NULL;

#define IOS 1
#define WINDOWS 2

#if EJOY2D_OS == IOS
static const char * startscript =
"local path, lua_root, lua_main, startup = ...\n"

"lua_main = lua_main or [[main.lua]]\n"
//"lua_root = lua_root or [[script]]\n"
"if not path then print('PLEASE SPECIFY THE WORK DIRECTORY') end\n"
"local fw=require(\"ejoy2d.framework\")\n"
"fw.WorkDir = path\n"
"fw.GameInfo = startup\n"

"local script_root = path .. [[/?.lua;]] .. path .. [[/?/init.lua;./?.lua;./?/init.lua]]\n"
"local script_project = path .. [[/script/?.lua;]].. path .. [[/script]] .. [[/?/init.lua;./?.lua;./?/init.lua]]\n"
"package.path = script_root..[[;]]..script_project\n"

"require([[script]])\n"
"local f = assert(loadfile(path..[[/script/]]..lua_main))\n"
"f()\n"
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
	if (msg)
		luaL_traceback(L, L, msg, 1);
	else if (!lua_isnoneornil(L, 1)) {
	if (!luaL_callmeta(L, 1, "__tostring"))
		lua_pushliteral(L, "(no error message)");
	}
	return 1;
}

static int
force_sync_frame(lua_State* L) {
	G->game->logic_time = G->game->real_time;
	return 0;
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
}

void
ejoy2d_fw_init(struct STARTUP_INFO* startup) {
	//free it
	STARTUP = startup;
	G = create_game();

	screen_init(startup->width,startup->height,startup->scale);
	lua_State *L = ejoy2d_game_lua(G->game);
	
	init_lua_libs(L);
	init_user_lua_libs(L);
	lua_register(L, "ejoy2dx_sync_frame", force_sync_frame);

	lua_pushcfunction(L, traceback);
	int tb = lua_gettop(L);
	int err = luaL_loadstring(L, startscript);
	if (err) {
		const char *msg = lua_tostring(L,-1);
		fault("%s", msg);
	}

	lua_pushstring(L, startup->folder);
	lua_pushstring(L, startup->lua_root); 
	lua_pushstring(L, startup->script);

	push_startup_info(L, startup);
	err = lua_pcall(L, 4, 0, tb);
	if (err) {
		const char *msg = lua_tostring(L,-1);
		fault("%s", msg);
	}
	lua_pop(L,1);

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
