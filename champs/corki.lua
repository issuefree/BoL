require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Corki")

InitAAData({
   speed = 2000,
   particles = {"corki_basicAttack_mis", "Corki_crit_mis"}
})

SetChampStyle("marksman")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("tear", {on=true, key=115, label="Tear"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2} - {3}", args={GetAADamage, "bomb", "barrage", function() return spells["barrage"].charges end}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["bomb"] = {
   key="Q", 
   range=825,
   color=violet,
   base={80,130,180,230,280},
   ap=.5,
   adBonus=.5,
   delay=.24,
   speed=1000,    -- Patch Notes
   radius=300-50,
   cost={60,70,80,90,100},
   noblock=true
}
spells["valk"] = {
   key="W", 
   range=800, 
   color=yellow, 
   base={150,225,300,375,450}, 
   ap=1,
   delay=.2,
   speed=1200,
   width=200,
   cost=100,
   noblock=true
}
spells["gun"] = {
   key="E", 
   range=600, 
   color=red, 
   cone=55,  -- reticle
   noblock=true,
   
   base={20,32,44,56,68}, 
   adBonus=.4,

   cost=50
}
spells["barrage"] = {
   name="MissileBarrageMissile",
   key="R", 
   range=1225,
   color=violet,

   base={100,180,260}, 
   ap=.3,
   ad={.2,.3,.4},
   scale=function() if bigOne then return 1.5 end end,

   delay=.07,
   speed=2000,
   width=80,

   useCharges=true,
   maxCharges=7,
   rechargeTime={12,10,8},
   charges=1,

   cost=20,
}

local mCount = 0
bigOne = false

function Run()
   spells["AA"].bonus = Damage((me.totalDamage)*.1, "T")

   if GetSpellLevel("R") > 0 then
      if me.dead then
         spells["barrage"].charges = 7
         spells["barrage"].lastRecharge = time()
      end
   end

   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end

   -- auto stuff that always happen

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") and Alone() then

      if KillMinionsInArea("bomb", 3) then
         return true
      end

      if CanUse("barrage") and VeryAlone() and spells["barrage"].charges >= 4 then
         local minion = GetWeakest("barrage", GetUnblocked("barrage", me, MINIONS))
         if WillKill("barrage", minion) and
            not IsInAARange(minion)
         then
            CastXYZ("barrage", minion)
            PrintAction("Barrage for lasthit")
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
   -- TestSkillShot("bomb", "Q_Mis")
   -- TestSkillShot("barrage")

   if SkillShot("bomb", nil, nil, 2.5) then
      return true
   end

   if CanUse("barrage") then
      if JustAttacked() or not GetWeakestEnemy("AA") then
         if SkillShot("barrage") then
            return true
         end
      end
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
end

local function onSpell(unit, spell)
   if ICast("barrage", unit, spell) then
      if spell.name == "MissileBarrageMissile2" then
         mCount = 0
         bigOne = false
      else
         mCount = mCount + 1
         if mCount == 2 then
            bigOne = true
         end
      end
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)

