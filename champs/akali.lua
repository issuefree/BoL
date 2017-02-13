require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Akali")
pp(" - Mark enemies that have no mark")
pp(" - Slash nearby enemies")
pp(" - Dance to far enemies")
pp(" - Mark for last hit")
pp(" - Slash for last hit >= 2")

SetChampStyle("caster")

InitAAData({ 
})

AddToggle("ultSpam", {on=true, key=112, label="Ult Spam"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "mark", "slash"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["force"] = {
   base=0,
   byLevel={10,12,14,16,18,20,22,24,26,28,30,40,50,60,70,80,90,100},
   adBonus=.5,
   ap=.65
}
spells["mark"] = {
  key="Q",
  range=600,
  color=violet,
  base={35,55,75,95,115},
  ap=.4,
  cost=60
}
spells["detonate"] = {
   base={45,70,95,120,145},
   ap=.5
}
spells["shroud"] = {
   key="W", 
   range=250, 
   color=blue, 
   radius=475, -- wiki
   cost={60,55,50,45,40}
}
spells["slash"] = {
   key="E", 
   range=325, 
   color=red,
   base={70,100,130,160,190}, 
   ap=.6,
   adBonus=.8,
   type="P",
   cost={60,55,50,45,40},
}
spells["dance"] = {
   key="R", 
   range=700, 
   color=yellow, 
   base={50,100,150}, 
   ap=.35
}

function getDetonateDam(target)
   if HasBuff("mark", target) then
      return GetSpellDamage("detonate")
   end
   return 0
end

spells["AA"].damOnTarget = getDetonateDam

function Run()
   spells["AA"].bonus = 0
   if P.twinMight then
      
   elseif not P.twinMight and P.twinForce then
      spells["AA"].bonus = GetSpellDamage("force")
   end

   for _,m in ipairs(GetWithBuff("mark", MINIONS, CREEPS, ENEMIES)) do
      Circle(m)
   end

   if StartTickActions() then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") and Alone() then
      if CanUse("slash") then
         local kills = GetKills("slash", GetInRange(me, "slash", MINIONS))         
         if #kills >= 2 or (JustAttacked() and #kills == 1) then
            Cast("slash", me)
            PrintAction("Slash for lasthit", #kills)
            return true
         end

      end

      if KillMinion("mark", "burn") then
         return true
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
   if CanUse("mark") then
      local target = GetMarkedTarget() or GetWeakestEnemy("mark")
      if target and not HasBuff("mark", target) then
         Cast("mark", target)
         PrintAction("Mark", target)
         return true
      end
   end

   if CastBest("slash") then
      Cast("slash", me)
      return true
   end

   -- TODO dance linking for execute

   if CanUse("dance") then
      local target = GetMarkedTarget() or GetWeakestEnemy("dance")
      if target and 
         ( not IsInRange("AA", target) or ( IsOn("ultSpam") and JustAttacked() ) )
      then
         Cast("dance", target)
         PrintAction("Dance", target)
         return true
      end
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

local function onObject(object)
   PersistOnTargets("mark", object, "Akali_Base_markOftheAssasin_marker_tar", ENEMIES, CREEPS, MINIONS)

   Persist("shroud", object, "Akali_Base_smoke_bomb_tar_team_green")

   PersistBuff("twinMight", object, "Akali_Base_P_LHand_buf")
   PersistBuff("twinForce", object, "Akali_Base_P_RHand_buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
