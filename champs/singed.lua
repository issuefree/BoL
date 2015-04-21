require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Singed")

AddToggle("move", {on=true, key=112, label="Move to Mouse"})
AddToggle("tear", {on=true, key=113, label="Tear"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})

spells["poison"] = {
   key="Q", 
   base={66,102,138,174,210}, 
   ap=.9
} 
spells["goo"] = {
   key="W", 
   range=1000, 
   color=yellow, 
   delay=.3,
   speed=0,
   radius=175,
   cost={70,80,90,100,110}
} 
spells["fling"] = {
   key="E", 
   range=125, 
   color=violet, 
   base={50,65,80,95,110}, 
   targetMaxHealth={.06,.065,.07,.075,.08},
   cost={100,110,120,130,140}
} 
spells["potion"] = {
   key="R", 
   cost=150
} 

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() then
		if Action() then
			return true
		end
	end

   if IsOn("tear") then
      if CanChargeTear() and GetMPerc(me) > .25 and Alone() then
         CastBuff("poison")
      end
      if not CanChargeTear() and VeryAlone() and #GetInRange(me, 500, CREEPS, MINIONS) == 0 then
         CastBuff("poison", false)
      end
   end

	-- auto stuff that should happen if you didn't do something more important

   -- low priority hotkey actions, e.g. killing minions, moving
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   return false
end
function FollowUp()
   -- singed has a very different move pattern than other melees
   -- if IsOn("move") then
   --    if MeleeMove() then
   --       return true
   --    end
   -- end

   return false
end

local function onCreate(object)
   PersistBuff("poison", object, "Acidtrail")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)
