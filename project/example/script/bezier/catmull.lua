
local pow_table={}

local function catmull(points, steps)
	local amount = #points
	if amount < 6 then		return points	end
	local steps = steps or 5
	local spline = {}
	local count = amount/2 - 1
	local p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y
	-- local p0, p1, p2, p3, x, y
	local x, y
	for i = 1, count do
		if i == 1 then					-- if first point
			p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = points[1], points[2],
																							 points[1], points[2],
																							 points[3], points[4],
																							 points[5], points[6]
			-- p0, p1, p2, p3 = points[i], points[i], points[i + 1], points[i + 2]
		elseif	i == count then		-- if last point
			p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = points[amount-5], points[amount-4],
																							 points[amount-3], points[amount-2],
																							 points[amount-1], points[amount],
																							 points[amount-1], points[amount]
			-- p0, p1, p2, p3 = points[#points - 2], points[#points - 1], points[#points], points[#points]
		else
			p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y = points[2*(i-1)-1], points[2*(i-1)],
																							 points[2*(i-1)+1], points[2*(i-1)+2],
																							 points[2*(i-1)+3], points[2*(i-1)+4],
																							 points[2*(i-1)+5], points[2*(i-1)+6]
			-- p0, p1, p2, p3 = points[i - 1], points[i], points[i + 1], points[i + 2]
		end
		for t = 0, 1, 1 / steps do
			local t2, t3
			local pow = pow_table[t]
			if not pow then
				t2 = t*t 
				t3 = t2*t
				pow_table[t] = {t2, t3}
			else
				t2 = pow[1]
				t3 = pow[2]
			end
			x = 0.5 * ( ( 2 * p1x ) + ( p2x - p0x ) * t + ( 2 * p0x - 5 * p1x + 4 * p2x - p3x ) * t2 + ( 3 * p1x - p0x - 3 * p2x + p3x ) * t3 )
			y = 0.5 * ( ( 2 * p1y ) + ( p2y - p0y ) * t + ( 2 * p0y - 5 * p1y + 4 * p2y - p3y ) * t2 + ( 3 * p1y - p0y - 3 * p2y + p3y ) * t3 )
			--prevent duplicate entries
			if not(#spline > 0 and spline[#spline-1] == x and spline[#spline] == y) then
				table.insert( spline, x )	-- table of points
				table.insert( spline, y )
			end
		end
	end
	return spline
end

return catmull