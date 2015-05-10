require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Zilean")

InitAAData({
   speed = 1250,
   particles = {"ChronoBasicAttack_mis"}
})

AddToggle("autoChrono", {on=true, key=112, label="Auto Chrono Shift"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "bomb"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bomb"] = {
   key="Q", 
   range=900-25, 
   color=violet, 
   base={75,115,165,230,300}, 
   ap=.9,
   delay=.25,
   speed=2200,   -- tss
   radius=325,
   noblock=true,
   cost={60,65,70,75,80},
}
spells["rewind"] = {
   key="W", 
   cost=35,
}
spells["warp"] = {
   key="E", 
   range=550, 
   color=yellow, 
   cost=50,
}
spells["chrono"] = {
   key="R", 
   range=900, 
   color=green, 
   cost={125,150,175},
} 

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("autoChrono") and CanUse("chrono") then
      for _,ally in ipairs(SortByHealth(GetInRange(me, "chrono", ALLIES))) do
         if GetHPerc(ally) < .2 and #GetInRange(ally, 500, ENEMIES) >= 2 then
            Cast("chrono", ally)
            PrintAction("Chrono low health", ally)
            return true
         end         
      end
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() then
      if CanUse("bomb") then
         local targets = GetInRange(me, "bomb", MINIONS)
         local bestT
         local bestK = 2
         for _,target in ipairs(targets) do
            local kills = #GetKills("bomb", GetInRange(target, spells["bomb"].radius, MINIONS))
            if kills > bestK then
               bestT = target
               bestK = kills
            end
         end
         if bestT then
            Cast("bomb", bestT)
            PrintAction("Bomb for lasthit")
            return true
         end
      end
   end

   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("bomb", nil, {"warning", "explo", "k", "Unrevealed"})

   if GetWeakestEnemy("bomb") then
      if GetCD("bomb") > 3 and CanUse("rewind") then
         Cast("rewind", me)
         PrintAction("Rewind")
         return true
      end
   end

   if CastBest("bomb") then
      return true
   end
   return false
end

function FollowUp()
   if not CanUse("bomb") then
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
   end
   return false
end

local function onObject(object)
end

local function onSpell(unit, spell)
   if IsOn("autoChrono") and CanUse("chrono") then
      local target = CheckShield("chrono", unit, spell, "CHECK")
      if target and GetHPerc(target) < .2 then
         Cast("chrono", target)
         PrintAction("CHRONO to save from "..spell.name, bestT)
      end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
