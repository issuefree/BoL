require "issuefree/timCommon"
require "issuefree/modules"


-- Try to stick to one "action" per loop.
-- Action function should return 
--   true if they perform an action that takes time (most spells attacks)
--   false if no action or the spell takes no time

pp("\nTim's Xin Zhao")

InitAAData({
   particles={"xen_ziou_intimidate"},
   resets={GetSpellInfo("Q").name}
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} ({1})", args={GetAADamage, "talon"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["talon"] = {
   key="Q", 
   base={15,30,45,60,75}, 
   ad=.2,
   type="P",
   modAA="talon",
   object="xenZiou_ChainAttack_indicator",
   range=GetAARange,
   rangeType="e2e",
   cost=30
} 
spells["cry"] = {
   key="W", 
   base={30,35,40,45,50}, 
   ap=.7,
   type="H",
   cost=40,
} 
spells["charge"] = {
   key="E", 
   range=600, 
   color=yellow,
   base={70,110,150,190,230}, 
   ap=.6,
   type="M",
   -- radius=function() return GetWidth(me) + 112.5 end,  --TODO test
   cost=60,
} 
spells["sweep"] = {
   key="R", 
   range=375,  --TODO test
   rangeType="e2e",
   color=red, 
   base={75,175,275},
   adBonus=1,
   targetHealth=.15,
   cost=100
} 

function Run()
   if StartTickActions() then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") then
      if Alone() then
         if ModAAFarm("talon") then
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

   if CanUse("cry") and GetWeakestEnemy("AA") then
      Cast("cry", me)
      PrintAction("Cry", nil, 1)
   end


   if CanUse("charge") then
      local target = GetMarkedTarget() or GetWeakestEnemy("charge")
      if target and 
         not UnderTower(target) and 
         IsInRange("charge", target) and 
         not IsInRange("AA", target) 
      then
         Cast("charge", target)
         PrintAction("Charge", target)
         return true
      end
   end

   if CanUse("sweep") then
      local target = GetMarkedTarget() or GetWeakestEnemy("sweep")
      if target and HasBuff("challenge", target) then
         if #GetInRange(target, "sweep", ENEMIES) >= 2 then
            Cast("sweep", target)
            PrintAction("Sweep", target)
            return true
         end
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target, "talon") then
      return true
   end

   return false
end
function FollowUp()
   if IsOn("lasthit") then
      if Alone() then
         if GetHPerc(me) < .75 then
            if HitMinion("AA", "strong") then
               PrintAction("..for heal", nil, .5)
               return true
            end
         end
      end
   end

   return false
end

local function onCreate(object)
   PersistOnTargets("challenge", object, "xen_ziou_intimidate", ENEMIES)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

