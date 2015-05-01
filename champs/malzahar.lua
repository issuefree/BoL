require "issuefree/timCommon"
require "issuefree/modules"


pp("\nTim's Malzahar")
pp(" -- Lasthit with visions chains")
pp(" -- Lasthit with void bars")
pp(" -- Disrupt with void")
pp(" -- Hit cc'd with zone and void")
pp(" -- AoE with void")
pp(" -- zone and grasp likely kills")
pp("")


InitAAData({ 
   speed=2000,
   extraWindup=.3,
   particles={"Malzahar_Base_BA_mis"}
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "visions", "void"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["void"] = {
   key="Q", 
   range=900, 
   color=cyan, 
   base={80,135,190,245,300}, 
   ap=.8,
   delay=.8-.3, -- testskillshot
   speed=0,
   radius=75, -- this is just a circle in the center. slightly large
   noblock=true,
   cost={80,85,90,95,100},
} 
spells["zone"] = {
   key="W", 
   range=800, 
   color=yellow, 
   base={0},   
   targetMaxHealth={.2,.25,.3,.35,.4},
   targetMaxHealthAP=.0005,
   delay=.1,
   speed=0,
   radius=250, -- reticle
   noblock=true,
   cost={90,95,100,105,110},
} 
spells["visions"] = {
   key="E",
   range=650, 
   color=violet, 
   base={80,140,200,260,320}, 
   ap=.8,
   radius=450,
   cost={60,75,90,105,120},
} 
spells["grasp"] = {
   key="R", 
   range=700, 
   color=red, 
   base={250,400,550}, 
   ap=1.3,
   channel=true,
   name="AlzaharNetherGrasp",
   object="AlZaharNetherGrasp_tar.troy",
   channelTime=2.5,
   cost=100,
} 

function getVoidHits(target, targets)
   local hits = {}
   table.insert(hits, target)
   hits = concat(hits, GetInLine(target, "void", ProjectionA(target, 90, 200), targets))
   hits = concat(hits, GetInLine(target, "void", ProjectionA(target, -90, 200), targets))
   return uniques(hits)
end

function getNumVoidHits(target, targets)
   return #getVoidHits(target, targets)
end

local lastVisionsLoc = nil

function Run()
   if P.visions then
      if lastVisionsLoc then
         local jump = GetDistance(P.visions, lastVisionsLoc)
         if jump > spells["visions"].radius then
            pp("New visions jump record "..jump)
            spells["visions"].radius = jump
         end
      end
      lastVisionsLoc = Point(P.visions)
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("void") then
      return true
   end

   if CastAtCC("zone") or
      CastAtCC("void")
   then
      return true
   end   

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then

      -- Don't LH with visions if I have an active visions
      if not P.visions then
         local target = KillMinion("visions", {"strong", "lowMana"}, nil, true)
         if target then
            -- there's something to bounce to
            if #GetInRange(target, spells["visions"].radius, MINIONS, ENEMIES) > 1 then
               Cast("visions", target)
               PrintAction("Visions minion for LH")
               return true
            end
         end
      end

      if CanUse("void") then
         -- get all minions in void range plus some fudge factor to look at width and radius
         local bestT = nil
         local bestS = 0
         local bestH = {}
         local minions = GetInRange(me, GetSpellRange("void")+200, MINIONS)
         for _,minion in ipairs(minions) do
            local hits = {}
            if IsInRange("void", minion, me, spells["void"].radius) then
               hits = getVoidHits(minion, minions)
               score = scoreHits("void", hits, .05, .95)

               if not bestT or score > bestS then
                  bestT = minion
                  bestS = score
                  bestH = hits
               end
            end
         end
         if bestS > GetThreshMP("void", .1, 1.5) then
            CastXYZ("void", GetCastPoint(bestT, "void"))
            PrintAction("Void for LH", bestS)
            return true
         end
      end

   end
   
   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("void", "AlzaharCall")
   -- TestSkillShot("zone", "AlzaharNullZone")

   if CastBest("visions") then
      return true
   end

   -- void for aoe want 2 hits
   if CanUse("void") then
      local targets = GetGoodFireaheads("void", 1, ENEMIES)
      local target, score = SelectFromList(targets, getNumVoidHits, targets)
      if score >= 2 then
         CastXYZ("void", GetCastPoint(target, "void"))
         PrintAction("Void for AoE", score)
         return true
      end
   end

   if SkillShot("void") then
      return true
   end

   local targets = SortByHealth(GetInRange(me, "grasp", ENEMIES))
   for _,target in ipairs(targets) do
      if WillKill("visions", "zone", "grasp", target) then
         MarkTarget(target)
         Cast("zone", target)
         PrintAction("Zone for execute")
         break
      end
   end

   if CanUse("grasp") then
      local target = GetMarkedTarget()
      if target then
         Cast("grasp", target)
         PrintAction("Grasp marked", target)
         return true
      end
   end


   if not CanUse("visions") then -- I seem to recall seeing it prefer AA to visions.
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
   end

   return false
end
function FollowUp()
   return false
end

local function onCreate(object)
   Persist("visions", object, "Malzahar_Base_E_buf.troy")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

