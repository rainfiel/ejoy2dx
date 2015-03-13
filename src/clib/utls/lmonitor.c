//
//  lmonitor.c
//  pili
//
//  Created by rainfiel on 14-10-19.
//  Copyright (c) 2014年 ejoy2d. All rights reserved.
//
#include <lua.h>
#include <lauxlib.h>
#include <string.h>
#include <stdlib.h>

#define REPORT_MAX (1024*1024)
#define FNAME_MAX 1024

struct status {
	int max_depth;
	int depth;
	int calls;
	int ptr;
	int from;
	int count;
	char buffer[REPORT_MAX];
};

static struct status * G = NULL;

static void
monitor_init(struct status * st) {
	st->max_depth = 0;
	st->depth = 0;
	st->calls = 0;
	st->ptr = 0;
	st->count = 0;
	st->from = 0;
}

static void
monitor_cat(struct status * st, const char * str, size_t sz) {
	if (sz + st->ptr > REPORT_MAX) {
		sz = REPORT_MAX - st->ptr;
	}
	memcpy(st->buffer + st->ptr, str, sz);
	st->ptr += sz;
}

static void
recordcall(struct status *s, int event) {
	switch (event) {
		case LUA_HOOKCALL:
		case LUA_HOOKTAILCALL:
			if (++s->depth > s->max_depth) {
				s->max_depth = s->depth;
			}
			break;
		case LUA_HOOKRET:
			--s->depth;
			++s->calls;
			break;
		case LUA_HOOKLINE:
			s->count ++;
			break;
	}
}

static void
monitor_depth(lua_State *L, lua_Debug *ar) {
	recordcall(G, ar->event);
}

static void
monitor_detailreport(lua_State *L, lua_Debug *ar) {
	char info[FNAME_MAX];
	struct status * s = G;
	int n;
	lua_getinfo(L, "nS", ar);
	switch (ar->event) {
		case LUA_HOOKCALL:
		case LUA_HOOKTAILCALL:
			if (ar->name != NULL) {
				n = snprintf(info, FNAME_MAX, "%d\n%*s%s ", s->count, s->depth, "", ar->name);
			} else if (ar->linedefined < 0) {
				n = snprintf(info, FNAME_MAX, "%d\n%*s= ", s->count, s->depth, "");
			} else {
				n = snprintf(info, FNAME_MAX, "%d\n%*s%s:%d ", s->count, s->depth, "", ar->short_src, ar->linedefined);
			}
			monitor_cat(s, info, n);
			s->count = 0;
			break;
		case LUA_HOOKRET:
			if (s->count > 0) {
				n = snprintf(info, FNAME_MAX, "%d\n%*s", s->count, s->depth,"");
				monitor_cat(s, info, n);
				s->count = 0;
			}
			break;
	}
	recordcall(s, ar->event);
}

static void
monitor_depthfrom(lua_State *L, lua_Debug *ar) {
	struct status * s = G;
	switch (ar->event) {
		case LUA_HOOKRET:
			if (s->calls > s->from) {
				lua_sethook(L, monitor_detailreport, LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE, 0);
			}
			break;
	}
	recordcall(s, ar->event);
}

static void
monitor_report(lua_State *L, lua_Debug *ar) {
	char info[FNAME_MAX];
	struct status * s = G;
	int n;
	lua_getinfo(L, "nS", ar);
	switch (ar->event) {
		case LUA_HOOKCALL:
		case LUA_HOOKTAILCALL:
			if (ar->name != NULL) {
				n = snprintf(info, FNAME_MAX, "%*s%s\n", s->depth, "", ar->name);
			} else if (ar->linedefined < 0) {
				n = snprintf(info, FNAME_MAX, "%*s=\n", s->depth, "");
			} else {
				n = snprintf(info, FNAME_MAX, "%*s%s:%d\n", s->depth, "", ar->short_src, ar->linedefined);
			}
			monitor_cat(s, info, n);
			break;
	}
	recordcall(s, ar->event);
}

static int
lreport(lua_State *L) {
	monitor_init(G);
	luaL_checktype(L, 1, LUA_TFUNCTION);
	lua_sethook(L, monitor_report, LUA_MASKCALL | LUA_MASKRET, 0);
	int args = lua_gettop(L) - 1;
	lua_call(L, args, 0);
	lua_sethook(L, NULL, 0 , 0);
	lua_pushinteger(L, G->max_depth);
	lua_pushinteger(L, G->calls);
	lua_pushlstring(L, G->buffer, G->ptr);
	return 3;
}

static int
ldepth(lua_State *L) {
	monitor_init(G);
	int args = lua_gettop(L) - 1;
	if (!lua_isfunction(L, 1)) {
		int n = luaL_checkinteger(L, 1);
		G->from = n;
		--args;
		lua_sethook(L, monitor_depthfrom, LUA_MASKCALL | LUA_MASKRET, 0);
	} else {
		lua_sethook(L, monitor_depth, LUA_MASKCALL | LUA_MASKRET, 0);
	}
	lua_call(L, args, 0);
	lua_sethook(L, NULL, 0 , 0);
	lua_pushinteger(L, G->max_depth);
	lua_pushinteger(L, G->calls);
	lua_pushlstring(L, G->buffer, G->ptr);
	return 3;
}

static int
ldetailreport(lua_State *L) {
	monitor_init(G);
	luaL_checktype(L, 1, LUA_TFUNCTION);
	lua_sethook(L, monitor_detailreport, LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE, 0);
	int args = lua_gettop(L) - 1;
	lua_call(L, args, 0);
	lua_sethook(L, NULL, 0 , 0);
	lua_pushinteger(L, G->max_depth);
	lua_pushinteger(L, G->calls);
	lua_pushlstring(L, G->buffer, G->ptr);
	return 3;
}

int
luaopen_monitor(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "depth", ldepth },
		{ "report", lreport },
		{ "detailreport", ldetailreport },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);
	struct status * s = malloc(sizeof(*G));
	G = s;
	return 1;
}