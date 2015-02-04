local vector = require "bezier.vector"

local Bezier = {}
Bezier.__index = Bezier
function Bezier.new(controlPoints)
	local b = {degree = math.floor(#controlPoints / 2)-1, controlPoints = {}}
	for i = 1,b.degree+1 do
		b.controlPoints[i] = vector.new(controlPoints[2*i-1], controlPoints[2*i])
	end
	setmetatable(b, Bezier)
	return b
end

function Bezier:controlPolygon(min, max)
	local min = min or 1
	local max = max or #self.controlPoints

	local ret = {}
	for i=min,max do
		ret[#ret+1] = self.controlPoints[i].x
		ret[#ret+1] = self.controlPoints[i].y
	end
	return ret
end

function Bezier:clone()
	return Bezier.new(self:controlPolygon())
end

function Bezier:translate(x, y)
	local t = vector.new(x,y)
	for i,p in ipairs(self.controlPoints) do
		self.controlPoints[i] = p + t
	end
end

function Bezier:eval(t)
	if t < 0 or t > 1 then error("t must be in the range [0:1]") end
	local points, last = {}

	points = self.controlPoints
	for k = 1,self.degree do
		last = points
		points = {}
		for i = 1,self.degree - (k-1) do
			points[i] = (1-t) * last[i] + t * last[i+1]
		end
	end
	return points[1].x, points[1].y
end

function Bezier:degreeUp()
	local newpoints, oldpoints = {}, self.controlPoints
	local newdeg = self.degree + 1
	newpoints[1] = oldpoints[1]
	newpoints[newdeg+1] = oldpoints[newdeg]
	for i = 2,newdeg do
		newpoints[i] = (i-1) / newdeg * oldpoints[i-1] + (newdeg-i+1) / newdeg * oldpoints[i]
	end
	self.controlPoints = newpoints
	self.degree = newdeg
end

function Bezier:subdivide(t)
	local t = t or .5
	if t < 0 or t > 1 then error("t must be in the range [0:1]") end

	local points, last = self.controlPoints, {}
	local left, right
	left = {points[1].x, points[1].y}
	right = {points[#points].y, points[#points].x}

	-- new control points are on the edges of the de casteljau scheme
	points = self.controlPoints
	for k = 1,self.degree do
		last = points
		points = {}
		for i = 1,self.degree - (k-1) do
			points[i] = (1-t) * last[i] + t * last[i+1]
		end
		left[#left+1]   = points[1].x
		left[#left+1]   = points[1].y
		right[#right+1] = points[#points].y -- y and x are switched because
		right[#right+1] = points[#points].x -- join is in reversed order
	end

	-- join left and right
	for i = #right,1,-1 do
		left[#left+1] = right[i]
	end
	self.controlPoints = {}
	for i = 1,#left/2 do
		self.controlPoints[i] = vector.new(left[2*i-1], left[2*i])
	end
	self.degree = #left/2 - 1
	return self
end

function Bezier:derivation()
	local points = {}
	for i = 1,#self.controlPoints-1 do
		local diff = self.degree * (self.controlPoints[i+1] - self.controlPoints[i])
		points[#points+1] = diff.x
		points[#points+1] = diff.y
	end
	return Bezier.new(points)
end

function Bezier:polygon(k)
	local k = k or 3
	local temp = self:clone()
	while k > 0 do
		temp:subdivide()
		k = k - 1
	end
	return temp:controlPolygon()
end

return Bezier