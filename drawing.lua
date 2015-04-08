require "issuefree/telemetry"

-- circle colors
yellow = 0xFFFFFF00
green  = 0xFF00FF00
red    = 0xFFFF0000
blue   = 0xFF0000FF
cyan   = 0xFF00FFFF
violet = 0xFFFF00FF
darkViolet = 0x00220022

-- text colors
yellowT = 0xFFFFFF00
greenT  = 0xFF00FF00
redT    = 0xFFFF0000
blueT   = 0xFF00FFFF

function LineBetween(object1, object2, thickness)	
   if not thickness then
      thickness = 1
   end

   local p1 = WorldToScreen(D3DXVECTOR3(object1.x, object1.y, object1.z))
   local p2 = WorldToScreen(D3DXVECTOR3(object2.x, object2.y, object2.z))

   table.insert(DRAWS, {DrawLine, {p1.x, p1.y, p2.x, p2.y, thickness, cyan}})
end

function DrawBB(t, color)
   if not color then color = yellow end
   DrawCircle(t.x, t.y, t.z, GetWidth(t), color)
end

DRAWS = {}
function Text(text, x, z, color)
	table.insert(DRAWS, {DrawText, {text, 14, x, z, color}})
end

function TextObject(text, object, color)
	table.insert(DRAWS, {DrawText3D, {tostring(text), object.x, object.y, object.z, 14, color, true}})
end

function Circle(target, radius, color, thickness)	
	if not target or target.x == 0 then 
		return 
	end

	thickness = thickness or 1
	color = color or yellow
	radius = radius or GetWidth(target)

	if type(target) == "userdata" then
		for i = 1, thickness, 1 do
			table.insert(DRAWS, {DrawCircle, {target.x, target.y, target.z, radius+i-1, color}})
			-- DrawCircle(target.x, target.y, target.z, radius+i-1, color)
		end		
	else
		local p = Point(target)
		if not p.x or not p.y or not p.z then
			return 
		end
		for i = 1, thickness, 1 do
			table.insert(DRAWS, {DrawCircle, {p.x, p.y, p.z, radius+i-1, color}})
			-- DrawCircle(p.x, p.y, p.z, radius+i-1, color)
		end
	end
end

function DoDraws()
	while #DRAWS > 0 do
		-- a = DRAWS[1][2]
		-- DRAWS[1][1](a[1], a[2], a[3], a[4], a[5])
		DRAWS[1][1](table.unpack(DRAWS[1][2]))
		table.remove(DRAWS, 1)
	end
end

-- from sxorbwalk
function DrawRectangleAL(x, y, w, h, color)
   local Points = {}
   Points[1] = D3DXVECTOR2(math.floor(x), math.floor(y))
   Points[2] = D3DXVECTOR2(math.floor(x + w), math.floor(y))
   table.insert(DRAWS, {DrawLines2, {Points, math.floor(h), color}})
end