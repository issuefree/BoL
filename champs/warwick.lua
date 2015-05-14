require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Warwick")
pp(" - Howl if near enemies")
pp(" - Strike enemies")
pp(" - AA enemies")

InitAAData({
})

local thirstDam = {3,3.5,4,4.5,5,5.5,6,6.5,7,8,9,10,11,12,13,14,15,16}

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("jungle", {on=true, key=115, label="Jungle", auxLabel="{0}", args={function() return CREEP_ACTIVE or "" end}})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["strike"] = {
   key="Q", 
   range=400, 
   color=violet, 
   base={75,125,175,225,275}, 
   ap=1,
   cost={70,80,90,100,110}
}
spells["howl"] = {
   key="W", 
   cost=35
}
spells["duress"] = {
   key="R", 
   range=700, 
   color=red,
   onHit=true,
   cost={100,125,150}
}

--[[ 
should be easy. Try to AA people. Howl if I can. Q them.
Q minions if I have lots of mana or am low on health.
]]

function Run()
   spells["AA"].bonus = thirstDam[me.level]

   if StartTickActions() then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if CanUse("strike") and Alone() then

      if KillMinion("strike") then
         return true
      end
      
      if GetHPerc(me) < .75 and GetHPerc(me) < GetMPerc(me) then
         if HitMinion("strike", "weak") then
            PrintAction("Strike for health", nil, 1)
            return true
         end
      end
   end

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return
      end
   end

   EndTickActions()
end

function Action()
   if CanUse("howl") and GetWeakestEnemy("AA",100) then
      Cast("howl", me) -- non blocking
      PrintAction("Howl", nil, 1)
   end

   if CastBest("strike") then
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end

local function jungle()
   -- local score = ScoreCreeps(creep)

   if CanUse("strike") then
      if GetMPerc() > GetHPerc() then
         local creep = GetBiggestCreep(GetInRange(me, "strike", CREEPS))
         Cast("strike", creep)
         PrintAction("Strike in the jungle")
         return true
      end
   end

   if GetMPerc() > .75 and CanUse("howl") then
      local creeps = GetInRange(me, 750, CREEPS)
      local score = ScoreCreeps(creeps)
      if score >= 3 then
         Cast("howl", me)
         PrintAction("Howl in the jungle")
         return true
      end
   end

   local creep = GetBiggestCreep(GetInE2ERange(me, GetAARange()+100, CREEPS))
   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end
end   
SetAutoJungle(jungle)

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
