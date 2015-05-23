local AUTO_UPDATE = false
local version = '3.023'
local UPDATE_HOST = 'raw.github.com'
local UPDATE_PATH = '/SidaBoL/Chaos/master/VPrediction.lua?rand='..math.random(1,10000)
local UPDATE_FILE_PATH = LIB_PATH..'vPrediction.lua'
local UPDATE_URL = 'https://'..UPDATE_HOST..UPDATE_PATH
local function AutoupdaterMsg(msg) print('<font color=\'#6699ff\'><b>VPrediction:</b></font> <font color=\'#FFFFFF\'>'..msg..'.</font>') end

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

require "issuefree/basicUtils"

class 'VPrediction' --{
function VPrediction:__init()
    self.version = tonumber(version)
    self.showdevmode = true
    
    if not _G.VPredictionMenu then
        _G.VPredictionMenu = scriptConfig('VPrediction', 'VPrediction3')
            
            if self.showdevmode then
                _G.VPredictionMenu:addSubMenu('Developers', 'Developers')
                    _G.VPredictionMenu.Developers:addParam('Debug', 'Enable debug', SCRIPT_PARAM_ONOFF, false)
            end
            
            _G.VPredictionMenu:addParam('Version', 'Version', SCRIPT_PARAM_INFO, tostring(self.version))
    end

    self.WaypointsTime = 2
    
    self.TargetsWaypoints = {}
    self.AutoAttacking = {}
    self.CastingSpells = {}
    
    AddNewPathCallback(function(unit, startPos, endPos, isDash ,dashSpeed,dashGravity, dashDistance) self:OnNewPath(unit, startPos, endPos, isDash, dashSpeed, dashGravity, dashDistance) end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    AddTickCallback(function() self:OnTick() end)
    AddDrawCallback(function() self:OnDraw() end)
    self.BlackList = 
    {
        {name = 'aatroxq', duration = 0.75}, -- 4 Dashes, OnDash fails
    }
    
    -- Spells that will cause OnDash to fire, dont shoot and wait to OnDash
    self.dashAboutToHappend =
    {
        {name = 'ahritumble', duration = 0.25},--ahri's r
        {name = 'akalishadowdance', duration = 0.25},--akali r
        {name = 'headbutt', duration = 0.25},--alistar w
        {name = 'caitlynentrapment', duration = 0.25},--caitlyn e
        {name = 'carpetbomb', duration = 0.25},--corki w
        {name = 'dianateleport', duration = 0.25},--diana r
        {name = 'fizzpiercingstrike', duration = 0.25},--fizz q
        {name = 'fizzjump', duration = 0.25},--fizz e
        {name = 'gragasbodyslam', duration = 0.25},--gragas e
        {name = 'gravesmove', duration = 0.25},--graves e
        {name = 'ireliagatotsu', duration = 0.25},--irelia q
        {name = 'jarvanivdragonstrike', duration = 0.25},--jarvan q
        {name = 'jaxleapstrike', duration = 0.25},--jax q
        {name = 'khazixe', duration = 0.25},--khazix e and e evolved
        {name = 'leblancslide', duration = 0.25},--leblanc w
        {name = 'leblancslidem', duration = 0.25},--leblanc w (r)
        {name = 'blindmonkqtwo', duration = 0.25},--lee sin q 
        {name = 'blindmonkwone', duration = 0.25},--lee sin w
        {name = 'luciane', duration = 0.25},--lucian e
        {name = 'maokaiunstablegrowth', duration = 0.25},--maokai w
        {name = 'nocturneparanoia2', duration = 0.25},--nocturne r
        {name = 'pantheon_leapbash', duration = 0.25},--pantheon e?
        {name = 'renektonsliceanddice', duration = 0.25},--renekton e
        {name = 'riventricleave', duration = 0.25},--riven q
        {name = 'rivenfeint', duration = 0.25},--riven e
        {name = 'sejuaniarcticassault', duration = 0.25},--sejuani q
        {name = 'shenshadowdash', duration = 0.25},--shen e
        {name = 'shyvanatransformcast', duration = 0.25},--shyvana r
        {name = 'rocketjump', duration = 0.25},--tristana w
        {name = 'slashcast', duration = 0.25},--tryndamere e
        {name = 'vaynetumble', duration = 0.25},--vayne q
        {name = 'viq', duration = 0.25},--vi q
        {name = 'monkeykingnimbus', duration = 0.25},--wukong q
        {name = 'xenzhaosweep', duration = 0.25},--xin xhao q
        {name = 'yasuodashwrapper', duration = 0.25},--yasuo e

    }
    --[[Spells that don't allow movement (durations approx)]]
    self.spells = {
        {name = 'katarinar', duration = 1}, --Katarinas R
        {name = 'drain', duration = 1}, --Fiddle W
        {name = 'crowstorm', duration = 1}, --Fiddle R
        {name = 'consume', duration = 0.5}, --Nunu Q
        {name = 'absolutezero', duration = 1}, --Nunu R
        {name = 'rocketgrab', duration = 0.5}, --Blitzcrank Q
        {name = 'staticfield', duration = 0.5}, --Blitzcrank R
        {name = 'cassiopeiapetrifyinggaze', duration = 0.5}, --Cassio's R
        {name = 'ezrealtrueshotbarrage', duration = 1}, --Ezreal's R
        {name = 'galioidolofdurand', duration = 1}, --Ezreal's R
        --{name = 'gragasdrunkenrage', duration = 1}, --Gragas W, Rito changed it so that it allows full movement while casting
        {name = 'luxmalicecannon', duration = 1}, --Lux R
        {name = 'reapthewhirlwind', duration = 1}, --Jannas R
        {name = 'jinxw', duration = 0.6}, --jinxW
        {name = 'jinxr', duration = 0.6}, --jinxR
        {name = 'missfortunebullettime', duration = 1}, --MissFortuneR
        {name = 'shenstandunited', duration = 1}, --ShenR
        {name = 'threshe', duration = 0.4}, --ThreshE
        {name = 'threshrpenta', duration = 0.75}, --ThreshR
        {name = 'infiniteduress', duration = 1}, --Warwick R
        {name = 'meditate', duration = 1} --yi W
    }

    self.blinks = {
        {name = 'ezrealarcaneshift', range = 475, delay = 0.25, delay2=0.8},--Ezreals E
        {name = 'deceive', range = 400, delay = 0.25, delay2=0.8}, --Shacos Q
        {name = 'riftwalk', range = 700, delay = 0.25, delay2=0.8},--KassadinR
        {name = 'gate', range = 5500, delay = 1.5, delay2=1.5},--Twisted fate R
        {name = 'katarinae', range = math.huge, delay = 0.25, delay2=0.8},--Katarinas E
        {name = 'elisespideredescent', range = math.huge, delay = 0.25, delay2=0.8},--Elise E
        {name = 'elisespidere', range = math.huge, delay = 0.25, delay2=0.8},--Elise insta E
    }

    return self
end

function VPrediction:GetTime()
    return os.clock()
end

function VPrediction:GetVersion()
    return self.version
end

function VPrediction:OnProcessSpell(unit, spell)
    if unit and unit.type == myHero.type then
        -- not all spells have a movement stop. this is weird.
        -- self.CastingSpells[unit.networkID] = self:GetTime() + 0.25
        
        if string.match(spell.name:lower(), "attack") then
            self.AutoAttacking[unit.networkID] = self:GetTime() + spell.windUpTime
        end
    end
end

function VPrediction:OnNewPath(unit, startPos, endPos, isDash, dashSpeed ,dashGravity, dashDistance)
    local NetworkID = unit.networkID
    if unit and unit.valid and unit.networkID and unit.type == myHero.type then
        if self.TargetsWaypoints[NetworkID] == nil then
            self.TargetsWaypoints[NetworkID] = {}
        end
        local WaypointsToAdd = self:GetCurrentWayPoints(unit)
        if WaypointsToAdd and #WaypointsToAdd >= 1 then
            --[[Save only the last waypoint (where the player clicked)]]
            table.insert(self.TargetsWaypoints[NetworkID], {unitpos = Vector(unit) , waypoint = WaypointsToAdd[#WaypointsToAdd], time = self:GetTime(), n = #WaypointsToAdd})
        end
        return
    end
    
end

function VPrediction:GetWaypoints(NetworkID, from, to)
    local Result = {}
    to = to and to or self:GetTime()
    if self.TargetsWaypoints[NetworkID] then
        for i, waypoint in ipairs(self.TargetsWaypoints[NetworkID]) do
            if from <= waypoint.time  and to >= waypoint.time then
                table.insert(Result, waypoint)
            end
        end
    end
    return Result, #Result
end

function VPrediction:CountWaypoints(NetworkID, from, to)
    local R, N = self:GetWaypoints(NetworkID, from, to)
    return N
end

function VPrediction:GetWaypointsLength(Waypoints)
    local result = 0
    for i = 1, #Waypoints -1 do
        result = result + GetDistance(Waypoints[i], Waypoints[i + 1])
    end
    return result
end

function VPrediction:CutWaypoints(Waypoints, distance)
    local result = {}
    local remaining = distance
    if distance > 0 then
        for i = 1, #Waypoints -1 do
            local A, B = Waypoints[i], Waypoints[i + 1]
            local dist = GetDistance(A, B)
            if dist >= remaining then
                result[1] = Vector(A) + remaining * (Vector(B) - Vector(A)):normalized()

                for j = i + 1, #Waypoints do
                    result[j - i + 1] = Waypoints[j]
                end
                remaining = 0
                break
            else
                remaining = remaining - dist
            end
        end
    else
        local A, B = Waypoints[1], Waypoints[2]
        result = Waypoints
        result[1] = Vector(A) - distance * (Vector(B) - Vector(A)):normalized()
    end

    return result
end

function VPrediction:GetCurrentWayPoints(object)
    local result = {}
    
        if object.hasMovePath then
            table.insert(result, Vector(object))
            for i = object.pathIndex, object.pathCount do
                
                path = object:GetPath(i)
                table.insert(result, Vector(path))
            end
        else
            table.insert(result, Vector(object))
        end
        return result
end

-- Calculate the hero position based on the last waypoints
function VPrediction:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
    local Waypoints = {}
    local Position, CastPosition, Shoot = Vector(unit), Vector(unit), false
    local t

    Waypoints = self:GetCurrentWayPoints(unit)
    local Waypointslength = self:GetWaypointsLength(Waypoints)
    
    if #Waypoints == 1 then
        Position, CastPosition = Vector(Waypoints[1]), Vector(Waypoints[1])
        return Position, CastPosition, true
    elseif unit.type ~= myHero.type then
        CastPosition = Vector(Waypoints[#Waypoints])
        Position = CastPosition
    else
        local tA = 0
        -- Waypoints = self:CutWaypoints(Waypoints, delay * unit.ms - radius)
        local A, B = 0, 0
        if speed ~= math.huge then
            for i = 1, #Waypoints - 1 do
                A, B = Waypoints[i], Waypoints[i+1]
                -- if i == #Waypoints - 1 then
                --     B = Vector(B) + radius * Vector(B - A):normalized()
                -- end
                local t1, p1, t2, p2, D = VectorMovementCollision(A, B, unit.ms, Vector(from), speed)
                local tB = tA + D / unit.ms
                t1, t2 = (t1 and tA <= t1 and t1 <= (tB - tA)) and t1 or nil, (t2 and tA <= t2 and t2 <= (tB - tA)) and t2 or nil
                t = t1 and t2 and math.min(t1, t2) or t1 or t2
                if t then
                    CastPosition = t==t1 and Vector(p1.x, myHero.y, p1.y) or Vector(p2.x, myHero.y, p2.y)
                    break
                end
                tA = tB
            end
        else
            t = 0
            CastPosition = Vector(Waypoints[1])
            Shoot = true
        end

        if not t and not CastPosition then
            pp("here")
        end

        if t then
            Shoot = true
            if (self:GetWaypointsLength(Waypoints) - t * unit.ms - radius) >= 0 then
                Waypoints = self:CutWaypoints(Waypoints, radius + t * unit.ms)
                Position = Vector(Waypoints[1])
            else
                Position = CastPosition
            end
            
            if spelltype == 'line' and unit.type == myHero.type and (Position.x ~= CastPosition.x or Position.z ~= CastPosition.z) and A ~= 0 then
                local angle = Vector(0, 0):angleBetween(Vector(from.x, from.z) - Vector(Position.x, Position.z), Vector(A.x, A.z) - Vector(B.x, B.z))
                if angle >= 40 and angle <= 135 then
                    local angle2 = math.asin((radius - 5) / GetDistance(Position, from))
                    local direction2 = (Vector(Position) - Vector(from))
                    local candi1 = from + direction2:rotated(0, angle2 ,0)
                    local candi2 = from + direction2:rotated(0, -angle2 ,0)
                    CastPosition = GetDistanceSqr(candi1, CastPosition) < GetDistanceSqr(candi2, CastPosition) and candi1 or candi2;
                end
            end
        elseif unit.type ~= myHero.type then
            CastPosition = Vector(Waypoints[#Waypoints])
            Position = CastPosition
        end
    end
    
    return CastPosition, Position, Shoot
end

function VPrediction:MaxAngle(unit, currentwaypoint, from)
    local WPtable, n = self:GetWaypoints(unit.networkID, from)
    local Max = 0
    local CV = (Vector(currentwaypoint.x, 0, currentwaypoint.y) - Vector(unit))
        for i, waypoint in ipairs(WPtable) do
                local angle = Vector(0, 0, 0):angleBetween(CV, Vector(waypoint.waypoint.x, 0, waypoint.waypoint.y) - Vector(waypoint.unitpos.x, 0, waypoint.unitpos.y))
                if angle > Max then
                    Max = angle
                end
        end
    return Max
end

function VPrediction:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype, dmg)
    local Position, CastPosition, HitChance
    -- local SavedWayPoints = self.TargetsWaypoints[unit.networkID] or {}
    local CurrentWayPoints = self:GetCurrentWayPoints(unit)
    
    HitChance = 2
    
    CastPosition, Position, Shoot = self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype, dmg)

    -- I removed this as it doesn't seem to add value. I'm getting "juke" chances when I'm moving in a straight line

    -- -- Detect if the enemy is clicking on a very spreaded way trying to "juke":
    -- -- TODO: finetune the parameters if needed.
    -- if #SavedWayPoints > 6 then
    --     local mean = Vector(0, 0, 0)
    --     for i, waypoint in ipairs(SavedWayPoints) do
    --         mean = mean + Vector(waypoint.waypoint)
    --     end
    --     mean = mean / #SavedWayPoints
        
    --     --In the future this variance could be weighted according to the time passed since the order was issued
    --     local variance = 0
    --     for i, waypoint in ipairs(SavedWayPoints) do
    --         variance = variance + GetDistanceSqr(Vector(waypoint.waypoint), mean)
    --     end
    --     variance = variance / #SavedWayPoints
        
    --     -- As Mr. DienoFail pointed out on PPrediction we could increase the speed instead of decreasing the hit chance but since the path can be on a completely different direction probably that wouldn't be effective at all.
    --     if variance > 600 * 600 then
    --         HitChance = 1.01
    --     end
    -- end
    
    -- Avoid casting spells on random directions 
    local N = 3
    local t1 = 1
    if self:CountWaypoints(unit.networkID, self:GetTime() - 0.75) >= N then
        local angle = self:MaxAngle(unit, CurrentWayPoints[#CurrentWayPoints], self:GetTime() - t1)
        if angle > 110 then
            HitChance = 1.1
        elseif angle < 30 and self:CountWaypoints(unit.networkID, self:GetTime() - 0.1) >= 1 then
            HitChance = 2
        end
    end
    
    if self.CastingSpells[unit.networkID] ~= nil and self.CastingSpells[unit.networkID] > self:GetTime() then
        HitChance = 2.5
    end
    
    if self.AutoAttacking[unit.networkID] ~= nil and self.AutoAttacking[unit.networkID] > self:GetTime() then
        HitChance = 2.5
    end
    
    if Position and CastPosition and ((radius / unit.ms >= delay + GetDistance(from, CastPosition)/speed) or (radius / unit.ms >= delay + GetDistance(from, Position)/speed)) then
        HitChance = 2.8
    end

    if Position and CastPosition and (((radius/2) / unit.ms >= delay + GetDistance(from, CastPosition)/speed) or ((radius/2) / unit.ms >= delay + GetDistance(from, Position)/speed)) then
        HitChance = 3.3
    end

    if not Position or not CastPosition then
        HitChance = 0
        CastPosition = Vector(unit)
        Position = CastPosition
    end

    -- If the target is too close it usually will stop, autoattack, etc. decreasing the delay we compensate that effect
    if GetDistanceSqr(myHero, unit) < 250 * 250 and unit ~= myHero then
        HitChance = HitChance ~= 0 and 2 or 0
        Position, CastPosition = self:CalculateTargetPosition(unit, delay*0.5, radius, speed, from, spelltype,  dmg)
        Position = CastPosition
    end

    if not Shoot then
        HitChance = .9
    end
    
    return CastPosition, HitChance, Position
end

function VPrediction:GetBestCastPosition(unit, delay, radius, range, speed, from, spelltype, dmg)
    assert(radius, 'VPrediction: Radius can\'t be nil')
    range = range and range - 15 or math.huge
    radius = radius == 0 and 1 or (radius + self:GetHitBox(unit)) - 4
    speed = (speed and speed ~= 0) and speed or math.huge
    from = from and from or Vector(myHero)
    if from.networkID and from.networkID == myHero.networkID then
        from = Vector(myHero)
    end
    local IsFromMyHero = GetDistanceSqr(from, myHero) < 50*50 and true or false

    assert(unit, 'VPrediction: Target can\'t be nil')
    assert(range > 0, 'VPrediction: range must be >0')
    assert(speed > 0, 'VPrediction: speed must be >0')
    
    delay = delay + (0.05 + GetLatency() / 2000)

    local Position, CastPosition, HitChance = Vector(unit), Vector(unit), 0

    if unit.type ~= myHero.type then
        Position, CastPosition = self:CalculateTargetPosition(unit, delay, radius, speed, from, spelltype)
        HitChance = 2
    else
        CastPosition, HitChance, Position = self:WayPointAnalysis(unit, delay, radius, range, speed, from, spelltype)
    end

    -- Out of range
    if IsFromMyHero then
        if (spelltype == 'line' and GetDistanceSqr(from, Position) >= range * range) then
            HitChance = 0
        end
        if (spelltype == 'circular' and (GetDistanceSqr(from, Position) >= (range + radius)^2)) then
            HitChance = 0
        end

        if HitChance ~= 0 and spelltype == 'circular' and (GetDistanceSqr(from, CastPosition) > range * range) then
            if GetDistanceSqr(from, Position) <= (range + radius / 1.4) ^ 2 then
                if GetDistanceSqr(from, Position) <= range * range then
                    CastPosition = Position
                else
                    CastPosition = Vector(from) + range * (Vector(Position) - Vector(from)):normalized()
                end
            end
        elseif (GetDistanceSqr(from, CastPosition) > range * range) then
            HitChance = 0
        end
    end

    radius = radius - self:GetHitBox(unit) + 4

    return CastPosition, HitChance, Position
end

function VPrediction:GetCircularCastPosition(unit, delay, radius, range, speed, from)
    -- log("gccp", "prediction")
    return self:GetBestCastPosition(unit, delay, radius, range, speed, from, 'circular')
end
                                                    
function VPrediction:GetLineCastPosition(unit, delay, radius, range, speed, from, dmg)
    return self:GetBestCastPosition(unit, delay, radius, range, speed, from, 'line', dmg)
end

function VPrediction:GetConeAOECastPosition(unit, delay, angle, range, speed, from)
    range = range and range - 4 or 20000
    radius = 1
    from = from and Vector(from) or Vector(myHero)
    angle = (angle < math.pi * 2) and angle or (angle * math.pi / 180)

    local CastPosition, HitChance, Position = self:GetBestCastPosition(unit, delay, radius, range, speed, from, false, 'line')
    local points = {}
    local mainCastPosition, mainHitChance = CastPosition, HitChance

    table.insert(points, Vector(Position) - Vector(from))

    local function CountVectorsBetween(V1, V2, points)
        local result = 0    
        local hitpoints = {} 
        for i, test in ipairs(points) do
            local NVector = Vector(V1):crossP(test)
            local NVector2 = Vector(test):crossP(V2)
            if NVector.y >= 0 and NVector2.y >= 0 then
                result = result + 1
                table.insert(hitpoints, test)
            elseif i == 1 then
                return -1 --doesnt hit the main target
            end
        end
        return result, hitpoints
    end

    local function CheckHit(position, angle, points)
        local direction = Vector(position):normalized()
        local v1 = Vector(position):rotated(0, -angle / 2, 0)
        local v2 = Vector(position):rotated(0, angle / 2, 0)
        return CountVectorsBetween(v1, v2, points)
    end

    for i, target in ipairs(GetEnemyHeroes()) do
        if target.networkID ~= unit.networkID and ValidTarget(target, range * 1.5) then
            CastPosition, HitChance, Position = self:GetBestCastPosition(target, delay, radius, range, speed, from, false, 'line')
            if GetDistanceSqr(from, Position) < range * range then
                table.insert(points, Vector(Position) - Vector(from))
            end
        end
    end

    local MaxHitPos
    local MaxHit = 1
    local MaxHitPoints = {}

    if #points > 1 then
        for i, point in ipairs(points) do
            local pos1 = Vector(point):rotated(0, angle / 2, 0)
            local pos2 = Vector(point):rotated(0, - angle / 2, 0)

            local hits, points1 = CheckHit(pos1, angle, points)
            local hits2, points2 = CheckHit(pos2, angle, points)

            if hits >= MaxHit then
                MaxHitPos = C1
                MaxHit = hits
                MaxHitPoints = points1
            end
            if hits2 >= MaxHit then
                MaxHitPos = C2
                MaxHit = hits2
                MaxHitPoints = points2
            end
        end
    end

    if MaxHit > 1 then
        --Center the cone
        local maxangle = -1
        local p1
        local p2
        for i, hitp in ipairs(MaxHitPoints) do
            for o, hitp2 in ipairs(MaxHitPoints) do
                local cangle = Vector():angleBetween(hitp2, hitp) 
                if cangle > maxangle then
                    maxangle = cangle
                    p1 = hitp
                    p2 = hitp2
                end
            end
        end


        return Vector(from) + range * (((p1 + p2) / 2)):normalized(), mainHitChance, MaxHit
    else
        return mainCastPosition, mainHitChance, 1
    end
end

function VPrediction:GetPredictedPos(unit, delay, speed, from)
    return self:GetBestCastPosition(unit, delay, 1, math.huge, speed, from, 'circular')
end

function VPrediction:OnTick()
    --[[Delete the old saved Waypoints]]
    if self.lastick == nil or self:GetTime() - self.lastick > 0.2 then
        self.lastick = self:GetTime()
        for NID, TargetWaypoints in pairs(self.TargetsWaypoints) do
            local i = 1 
            while i <= #self.TargetsWaypoints[NID] do
                if self.TargetsWaypoints[NID][i]['time'] + self.WaypointsTime < self:GetTime() then
                    table.remove(self.TargetsWaypoints[NID], i)
                else
                    i = i + 1
                end
            end
        end
    end
end

-- Drawing functions for debug: 
function VPrediction:DrawSavedWaypoints(object, time, color, drawPoints)
    colour = color and color or ARGB(255, 0, 255, 0)
    for i = object.pathIndex, object.pathCount do    
        if object:GetPath(i) and object:GetPath(i-1) then
            local pStart = i == object.pathIndex and object.pos or object:GetPath(i-1)
            self:DLine(pStart, object:GetPath(i), colour)
        end
    end
    if drawPoints then
        local Waypoints = self:GetCurrentWayPoints(object)
        for i, waypoint in ipairs(Waypoints) do
            DrawCircle3D(waypoint.x, myHero.y, waypoint.z, 10, 2, ARGB(255, 0,0, 255), 200)
        end
    end
end

function VPrediction:DrawHitBox(object)
    DrawCircle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, ARGB(255, 255, 255, 255))
    if object then
        DrawCircle3D(object.x, object.y, object.z, self:GetHitBox(object), 1, ARGB(255, 0, 255, 0))
    end
end

function VPrediction:DLine(From, To, Color)
    DrawLine3D(From.x, From.y, From.z, To.x, To.y, To.z, 2, Color)
end

function VPrediction:OnDraw()
    if self.showdevmode and _G.VPredictionMenu.Developers.Debug then
        LastGetTarget = LastGetTarget or myHero
        local target = GetTarget() or LastGetTarget
        LastGetTarget = target
        for i, enemy in ipairs(GetEnemyHeroes()) do
            self:DrawHitBox(enemy)
        end
        if target then
            self:DrawHitBox(target) 
            -- local CastPosition,  HitChance,  Position = self:GetCircularCastPosition(target, 0.6, 70, 900, math.huge)
            local CastPosition,  HitChance,  Position = self:GetCircularCastPosition(target, 0.6, 70, 900, 2000)
            if HitChance >= -1 then
                DrawText3D(tostring(HitChance), CastPosition.x, myHero.y, CastPosition.z, 40, ARGB(255, 255, 255, 255), true)
                DrawCircle3D(Position.x, myHero.y, Position.z, 70 + self:GetHitBox(target), 1, ARGB(255, 0, 255, 0))
                DrawCircle3D(CastPosition.x, myHero.y, CastPosition.z, 70 + self:GetHitBox(target), 1, ARGB(255, 255, 0, 0))
            end
local waypoint = self.TargetsWaypoints[target.networkID] and self.TargetsWaypoints[target.networkID] or {}
            -- local waypoint = self:GetCurrentWayPoints(target)
            for i = 1, #waypoint-1 do
                self:DLine(Vector(waypoint[i].waypoint.x, myHero.y, waypoint[i].waypoint.z), Vector(waypoint[i+1].waypoint.x, myHero.y, waypoint[i+1].waypoint.z), ARGB(255,255,255,255))
            end
        end
    end
end

function VPrediction:GetHitBox(object)
    if self.nohitboxmode and object.type and object.type == myHero.type then
        return 0
    end
    return object.boundingRadius or 65
end
