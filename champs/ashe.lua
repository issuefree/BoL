require "issuefree/timCommon"
require "issuefree/modules"

-- TODO I may want to incorporate the new frost shot mechanics into last hitting.

pp("\nTim's Ashe")

SetChampStyle("marksman")

InitAAData({
   speed = 2500, -- patch notes
   minMoveTime = .25, -- ashe can't get move commands too early for some reason
   particles = {"Ashe_Base_BA_mis", "Ashe_Base_Q_mis"},
   attacks = {"attack"}
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "volley"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["focus"] = {
   key="Q",
   cost=50
}
spells["flurry"] = {
   key="Q",
   base=0,
   ad={.15,.2,.25,.3,.35}
}

spells["volley"] = {
   key="W", 
   range=1100, 
   color=violet, 
   base={40,50,60,70,80}, 
   ad=1,
   delay=.25,
   speed=9,
   cone=24.32*2, 
   cost=50,
   width=20
}

spells["hawkshot"] = {
   key="E", 
}

spells["arrow"] = {
   key="R",
   base={250,425,600}, 
   ap=1,
   delay=.26,
   speed=1600,
   width=160,
   radius=250,
   cost=100,
   particle="Ashe_Base_R_mis.troy",
   spellName="EnchantedCrystalArrow"
}

spells["AA"].damOnTarget = function(target)
   if target and HasBuff("frosted", target) then
      return me.totalDamage*(.1 + me.critChance)
   end
end

function Run()
   spells["AA"].bonus = 0
   if P.flurry then
      spells["AA"].bonus = GetSpellDamage("flurry")
   end

   if StartTickActions() then
      return true
   end

   -- TODO should write an auto hawkshot for people that run into brush

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end   

   if IsOn("lasthit") and Alone() then
      if KillMinionsInCone("volley") then
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
   -- TestSkillShot("arrow")

   if CanUse("focus") and P.focus then
      if #GetInE2ERange(me, GetAARange()*.75, ENEMIES) >= 1 then
         Cast("focus", me)
         PrintAction("Focus for flurry")
         return true
      end
   end

   if CastBest("volley") then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   return false
end
   

local function onObject(object)
   PersistBuff("focus", object, "Ashe_Base_Q_ready")
   PersistBuff("flurry", object, "Ashe_Base_Q_buf.troy")

   PersistOnTargets("frosted", object, "Ashe_Base_freeze", ENEMIES, MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
