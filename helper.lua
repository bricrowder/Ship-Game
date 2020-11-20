function bubblesort(a)
	-- make a copy of the array first
	b = {}
	for i=1,#a,1 do
		b[i] = a[i]
	end

    -- init counter
    local c = #b-1
    -- loop through
    while c > 0 do
        for i=1, #b-1 do
            -- is the value greater than the next value?
            if b[i] > b[i+1] then
                -- yes - swap them... 
                local t = b[i]
                b[i] = b[i+1]
                b[i+1] = t
            end
        end
        -- decrease the index counter for the while loop
        c = c - 1
    end
    -- return sorted array
    return b
end

function getXY(a, m)
    local x = math.cos(a) * m
    local y = math.sin(a) * m
    return x, y
end

function getCentre(x, y, x2, y2, a)
    -- get x/y vector difference
    local lx = x2-x
    local ly = y2-y
    -- calc hypotenuse (length)
    local len = math.floor(math.sqrt(lx*lx + ly*ly))
    -- calculate centre point along length
    local cx = x + len/2 * math.cos(a)
    local cy = y + len/2 * math.sin(a)
    -- return
    return cx, cy, len
end

-- checks if line 1 and line 2 intersect, returns if the intersection is actually on the line segment and the intersection point
function LineIntersection(s1, e1, s2, e2)
    -- calculate the intersection point
    local d = (s1.x - e1.x) * (s2.y - e2.y) - (s1.y - e1.y) * (s2.x - e2.x)
    local a = s1.x * e1.y - s1.y * e1.x
    local b = s2.x * e2.y - s2.y * e2.x
    local x = (a * (s2.x - e2.x) - (s1.x - e1.x) * b) / d
    local y = (a * (s2.y - e2.y) - (s1.y - e1.y) * b) / d
    -- check if the result is on the segment
    local onsegment = false
    -- check if it is a horizontal or vertical line
    if math.floor(s2.y) == math.floor(e2.y) then
        -- it is a horizontal line, check if X is between the s2 X's and on y
        if math.floor(x) >= math.floor(s2.x) and math.floor(x) <= math.floor(e2.x) and math.floor(y) == math.floor(s2.y) then
            -- are the two ends of line one on either side of line two?
            if s2.y <= s1.y and s2.y >= e1.y then
                onsegment = true
            end
        end
    else
        -- it is a vertical line, check if Y is between the s2 Y's
        if math.floor(y) >= math.floor(s2.y) and math.floor(y) <= (e2.y) and math.floor(x) == math.floor(s2.x) then
            -- are the two ends of line one on either side of line two?
            if s2.x <= s1.x and s2.x >= e1.x then
                onsegment = true
            end
        end
    end
    return onsegment, x, y
end

function AngleDirection(difference)
	-- figure out which way the bullet should turn
	local direction = 1
	if difference > math.pi then
		difference = math.pi*2 - difference
		direction = -1
	end
	return direction	
end

function HomingAngle(tx, ty, ox, oy, ca, dt)
	-- calc destination angle
	local target = math.atan2(ty-oy, tx-ox)
	-- normalize target angle
	if target < 0 then target = target + math.pi*2 end
	-- get angle differenge
	local difference = target - ca
	-- normalize difference
	if difference < 0 then difference = difference + math.pi*2 end
	-- get direction of adjustment	
	local direction = AngleDirection(difference)
	-- adjust angle if we need to...
	if difference > 0 then
		difference = difference - math.pi/2*dt
		local newangle = ca + math.pi/2*dt * direction
		if difference < 0 then
			newangle = newangle + difference
		end
		if newangle > math.pi*2 then newangle = newangle - math.pi*2 end
		if newangle < 0 then newangle = newangle + math.pi*2 end
		ca = newangle
	end
	return ca
end

function ClampToPlanet(x, y, inner, outer)
    local a = math.atan2(y, x)
    -- calc mag of new position
    local mag = math.sqrt(x*x + y*y)
    -- compare mag to the rings and correct if necessary
    if mag < inner then
        mag = inner
        -- recalc x, y
        x = math.cos(a) * mag 
        y = math.sin(a) * mag
    elseif mag > outer then
        mag = outer
        -- recalc x, y
        x = math.cos(a) * mag 
        y = math.sin(a) * mag 
	end	
	return x, y
end

function LineCircleIntersection(x1, y1, x2, y2, Cx, Cy, Cr)
	local line_length
	local Dx, Dy
	local t
	local Ex, Ey
	local LEC
	local dt
	
	local result = {}

	--the closest point
	result.Ix = 0
	result.Iy = 0
	--first intersection point/tangent point
	result.Ax = 0
	result.Ay = 0
	--second intersection point
	result.Bx = 0
	result.By = 0
	--flags that records if the line SEGMENT intersects with the Cx, Cy
	result.SegMatch = false
	
	--compute the euclidean distance between x1,y1 and x2,y2
	line_length = math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1))

	--compute the direction vector D from x1,y1 and x2,y2
	Dx = (x2-x1)/line_length
	Dy = (y2-y1)/line_length

	--Now the line equation is x = Dx*t + x1, y = Dy*t + y1 with 0 <= t <= 1.

	--compute the value t of the closest point to the circle center (Cx, Cy)
	t = Dx*(Cx-x1) + Dy*(Cy-y1)

	--This is the projection of C on the line from x1,y1 to x2,y2

	--compute the coordinates of the closest point E on line and closest to C
	Ex = t*Dx+x1
	Ey = t*Dy+y1

	result.Ix = Ex
	result.Iy = Ey

	--now check if it is on our line segment by doing a simle bounds check
	--it isn't so simple however in that you have to base it on which is the lowest/highest of the laser at the time
	if x1 < x2 then
		-- laser is shooting to the right
		if Ex >= x1 and Ex <= x2 then result.SegMatch = true end
	elseif x1 > x2 then
		-- laser is shooting to the left
		if Ex <= x1 and Ex >= x2 then result.SegMatch = true end	
	elseif x1 == x2 then
		-- this is if they are the same... shooting directly up/down 
		if Ex == x1 then result.SegMatch = true end
	else
		-- no match
		result.SegMatch = false
	end
	
	-- now we only need to check if the X segment passed
	if result.SegMatch == true then
		if y1 < y2 then
			-- laser is shooting to the down
			if Ey >= y1 and Ey <= y2 then result.SegMatch = true end
		elseif y1 > y2 then
			-- laser is shooting to the up
			if Ey <= y1 and Ey >= y2 then result.SegMatch = true end	
		elseif y1 == y2 then
			-- this is if they are the same... shooting directly left/right 
			if Ey == y1 then result.SegMatch = true end
		else	
            -- no match
            result.SegMatch = false
        end
	end

	--compute the euclidean distance from E to C
	LEC = math.sqrt((Ex-Cx)*(Ex-Cx)+(Ey-Cy)*(Ey-Cy))

	--test if the line intersects the circle
	if LEC < Cr then
    	--compute distance from t to circle intersection point
    	dt = math.sqrt(Cr*Cr - LEC*LEC)

    	--compute first intersection point
    	result.Ax = (t-dt)*Dx + x1
    	result.Ay = (t-dt)*Dy + y1

    	--compute second intersection point
    	result.Bx = (t+dt)*Dx + x1
    	result.By = (t+dt)*Dy + y1
	
	--else test if the line is tangent to circle
	elseif LEC == Cr then
    	--tangent point to circle is E
    	result.Ax = Ex
    	result.Ay = Ey
    	result.Bx = 0
    	result.By = 0
	else
    	result.Ax = -1
    	result.Ay = -1
    	result.Bx = 0
    	result.By = 0
	end

	if result.SegMatch == true then
		return result.Ax, result.Ay
	else
		return nil, nil
	end
end
