#include <lua.h>
#include <lauxlib.h>
#include "easing.h"

AHEasingFunction easing_funcs [] = 
{
	LinearInterpolation,

	// Quadratic easing; p^2
	QuadraticEaseIn,
	QuadraticEaseOut,
	QuadraticEaseInOut,

	// Cubic easing; p^3
	CubicEaseIn,
	CubicEaseOut,
	CubicEaseInOut,

	// Quartic easing; p^4
	QuarticEaseIn,
	QuarticEaseOut,
	QuarticEaseInOut,

	// Quintic easing; p^5
	QuinticEaseIn,
	QuinticEaseOut,
	QuinticEaseInOut,

	// Sine wave easing; sin(p * PI/2)
	SineEaseIn,
	SineEaseOut,
	SineEaseInOut,

	// Circular easing; sqrt(1 - p^2)
	CircularEaseIn,
	CircularEaseOut,
	CircularEaseInOut,

	// Exponential easing, base 2
	ExponentialEaseIn,
	ExponentialEaseOut,
	ExponentialEaseInOut,

	// Exponentially-damped sine wave easing
	ElasticEaseIn,
	ElasticEaseOut,
	ElasticEaseInOut,

	// Exponentially-decaying bounce easing
	BounceEaseIn,
	BounceEaseOut,
	BounceEaseInOut,
	
	// Overshooting cubic easing; 
	BackEaseIn,
	BackEaseOut,
	BackEaseInOut,
};

static int
_easing(lua_State* L) {
	luaL_checktype(L, 1, LUA_TTABLE);
	int type = (int)luaL_checkinteger(L, 2);
	float start = (float)luaL_checknumber(L, 3);
	float end = (float)luaL_checknumber(L, 4);
	float times = (float)luaL_checkinteger(L, 5);

	if (type >= sizeof(easing_funcs)/sizeof(easing_funcs[0])) {
		luaL_error(L, "invalid easing function:%d", type);
	}

	float delta = end - start;
	int counter;

	AHEasingFunction func = easing_funcs[type];

	for (counter=1; counter <= times; counter++) {
		float rate = counter / times;
		float val = start + delta * func(rate);
		lua_pushnumber(L, val);
		lua_rawseti(L, 1, counter);
	}

	return 0;
}

int
luaopen_easing(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "easing", _easing },
		{ NULL, NULL },
	};
	luaL_newlib(L,l);

	return 1;
}
