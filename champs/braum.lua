require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Braum")
pp(" - Don't do much")

InitAAData({ 
--    extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

-- I actually don't see any reason to track or use this.
spells["blows"] = {
   base=0,
   byLevel=function() return 32+8*me.level end,
}

spells["bite"] = {
   key="Q", 
   range=1000, 
   color=violet, 
   base={60,105,150,195,240}, 
   maxHealth=.025,
   delay=.35,  -- tss
   speed=1650, -- tss
   width=80,   -- reticle
   cost={55,60,65,70,75}
} 

spells["stand"] = {
   key="W", 
   range=650, 
   color=cyan, 
   cost={50,55,60,65,70}
} 

spells["unbreakable"] = {
   key="E", 
   cost={30,35,40,45,50}
} 

spells["fissure"] = {
   key="R", 
   range=1250, 
   color=red, 
   base={150,250,350}, 
   ap=.6,
   delay=.75,  -- tss meh
   speed=1200, -- tss meh
   width=150,  -- reticle
   radius=225, -- reticle
   noblock=true,
   cost={10,20,30,40,50}
} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if StartTickActions() then
      return true
   end

   if CastAtCC("bite") then
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
      if VeryAlone() then
         if KillMinion("bite") then
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
   -- if TestSkillShot("bite", "Braum_Base_Q_mis") then
   --    return true
   -- end

   -- if TestSkillShot("fissure", "Braum_Base_R_mis.troy") then
   --    return true
   -- end

   if SkillShot("bite") then
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

local function onCreate(object)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

