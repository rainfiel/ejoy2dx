
local math = require "math"

local M = {}

function M.same_sign_angle(angle, closest)
	if closest > angle + 180 then
		return closest - 360
	elseif closest < angle - 180 then
		return closest + 360
	else
		return closest
	end
end

function M.decay(src, dst, half_life, dtime)
	dst = M.same_sign_angle(src, dst)

	if half_life <= 0 then
		return dst
	else
		return dst + (0.5^(dtime/half_life)) * (src - dst)
	end
end

function M.normalise(angle)
	if angle > 180 then
		return angle <= 540 and angle - 360 or
					M.normalise(angle % 360)
	elseif angle <= -180 then
		return angle >= -540 and angle + 360 or
					M.normalise(angle % 360)
	else
		return angle
	end
end

function M.atan(x, y)
	local deg = math.deg(math.atan(y/x))
	if deg < 0 then
		return (x < 0 and y > 0) and deg + 180 or deg
	elseif deg > 0 then
		return (x < 0 and y < 0) and deg + 180 or deg
	else
		return x < 0 and 180 or deg
	end
end

function M.add(left, right)
	return M.normalise(left+right)
end

function M.sub(left, right)
	return M.normalise(left-right)
end

return M
