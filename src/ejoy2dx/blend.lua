
-- #define BLEND_GL_ZERO 0
-- #define BLEND_GL_ONE 1
-- #define BLEND_GL_SRC_COLOR 0x0300
-- #define BLEND_GL_ONE_MINUS_SRC_COLOR 0x0301
-- #define BLEND_GL_SRC_ALPHA 0x0302
-- #define BLEND_GL_ONE_MINUS_SRC_ALPHA 0x0303
-- #define BLEND_GL_DST_ALPHA 0x0304
-- #define BLEND_GL_ONE_MINUS_DST_ALPHA 0x0305
-- #define BLEND_GL_DST_COLOR 0x0306
-- #define BLEND_GL_ONE_MINUS_DST_COLOR 0x0307
-- #define BLEND_GL_SRC_ALPHA_SATURATE 0x0308


local shader = require "ejoy2d.shader"

local M = {}

M.blend_cfg = {
	add = {1, 1},
	add_masked = {1, 1},
	multiply_inverse={0x0301, 0x0301},
	multiply={0x0300, 0x0301},
	-- overlay = {0x0302, 0x0303},
	test = {0x0301, 0x0305}
}

function M.begin_blend(mode)
	if not mode or mode == "normal" or mode == "none" then return true end
	if type(mode) == "function" then
		mode()
	else
		local cfg = rawget(M.blend_cfg, mode)
		if not cfg then return false end
		shader.blend(cfg[1], cfg[2])
	end
	return true
end

function M.end_blend()
	shader.blend()
end

return M
