require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Jayce")

InitAAData({ 
   speed = 1900, -- aadebug
   extraWindup=.2,
--    extraRange=-20,
--    attacks = {"attack"},
   minMoveTime=.25, -- for hyper
   particles={"Jayce_Base_Range_Basic_Mis"},
   resets={"jaycehypercharge"}
})

SetChampStyle("marksman")

AddToggle("dive", {on=false, key=112, label="Dive"})
AddToggle("gateBlast", {on=true, key=113, label="Auto gate blast"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["skies"] = {
   key="Q", 
   range=600, 
   color=yellow, 
   base={20,65,110,155,200}, 
   adBonus=1,
   type="P",
   radius=150, -- test
   cost={40,45,50,55,60}
} 
spells["blast"] = {
   key="--", 
   range=
      function() 
         if CanUse("gate") and me.mana > (GetSpellCost("blast") + GetSpellCost("gate")) then
            return 1470
         else
            return 1050
         end
      end,
   baseRange=1050,
   color=violet, 
   base={60,115,170,225,280}, 
   adBonus=1.2,
   type="P",
   delay=.35,  -- tss
   speed=1450, -- wiki
   width=100,  -- reticle
   -- radius=125, -- visual
   cost={55,60,65,70,75}
}

spells["field"] = {
   key="W", 
   range=285, 
   color=orange, 
   base={100,170,240,310,380}, 
   ap=1,
   cost=40
} 
spells["hyper"] = {
   key="--",
   multiplier={.7,.8,.9,1,1.1},
   cost=40
}

spells["blow"] = {
   key="E", 
   range=240,
   rangeType="e2e",
   color=violet, 
   base=0, 
   targetMaxHealth={.08,.11,.14,.17,.2},
   adBonus=1,
   cost={40,50,60,70,80}
} 
spells["gate"] = {
   key="E", 
   range=650, 
   color=cyan, 
   cost=50
} 

spells["mercury"] = {
   key="R", 
   base={20,60,100}, 
   ap=.4,
   cost=0,
} 

spells["AA"].scale = 
   function()
      if P.hyper then
         return GetLVal(GetSpell("hyper"), "multiplier")
      end
   end

function Run()
   if P.cannon then
      spells["skies"].key = "--"
      spells["blast"].key = "Q"
      -- spells["gateBlast"].key = "Q"

      spells["field"].key = "--"
      spells["hyper"].key = "W"

      spells["blow"].key = "--"
      spells["gate"].key = "E"
   else
      spells["skies"].key = "Q"
      spells["blast"].key = "--"
      -- spells["gateBlast"].key = "--"

      spells["field"].key = "W"
      spells["hyper"].key = "--"

      spells["blow"].key = "E"
      spells["gate"].key = "--"
   end

   spells["AA"].bonus = 0
   if not P.cannon and P.hammer then
      spells["AA"].bonus = GetSpellDamage("mercury")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("blow") then
      return true
   end

   if CastAtCC("blast") then
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
      if Alone() then
         if KillMinionsInPB("field", 3) then
            return true
         end

         -- if KillMinionsInArea("blast") then
         --    PauseToggle("gateBlast", 1)
         --    return true
         -- end
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
   -- if TestSkillShot("blast", "Jayce_Base_OrbLightning.troy") then
   --    return true
   -- end

   if CanUse("blast") then
      local target = GetSkillShot("blast", "best")
      if target then
         if GetDistance(target) < 650 then
            PauseToggle("gateBlast", 1)
         end
         CastFireahead("blast", target)
         PrintAction("Blast", target)
         return true
      end      
   end

   if CanUse("hyper") then
      local target = GetWeakestEnemy("AA", -50)
      if target then
         Cast("hyper", me)
         PrintAction("Hypercharge", target)
         return true
      end
   end

   if CanUse("blow") then
      local target = GetWeakestEnemy("blow")
      if target and WillKill("blow", target) then
         Cast("blow", target)
         PrintAction("Blow for execute", target)
         return true
      end
   end

   if CastBest("field") then
      return true
   end

   if not CanUse("field") and not P.field then
      if CastBest("blow") then
         return true
      end
   end

   if IsOn("dive") then
      local target = GetWeakestEnemy("skies")
      
      if target and not IsInAARange(target) then
         Cast("skies", target)
         PrintAction("Skies", target)
         return true
      end
   end

   local target 
   if P.cannon then
      target = GetMarkedTarget() or GetWeakestEnemy("AA")
   else
      target = GetMarkedTarget() or GetMeleeTarget()
   end
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if Alone() then
      if GetSpellLevel("field") > 0 and GetMPerc() < .9 and not P.cannon then
         if HitMinion("AA", "strong") then
            return true
         end

         if CanUse("Tiamat") or CanUse("Ravenous Hydra") then
            local minions = GetInRange(me, item, MINIONS)
            if #minions >= 2 then
               Cast("Tiamat", me)
               Cast("Ravenous Hydra", me)
               PrintAction("Crescent for clear")
               return true
            end
         end
      end
   end

   return false
end

--local function jungle()
--    local creep = GetBiggestCreep(GetInE2ERange(me, GetAARange()+100, CREEPS))
--    local score = ScoreCreeps(creep)
--    if AA(creep) then
--       PrintAction("AA "..creep.charName)
--       return true
--    end
-- end   
-- SetAutoJungle(jungle)

local function onCreate(object)
   PersistBuff("cannon", object, "Jayce_Base_Stance_Range.troy")
   PersistBuff("hyper", object, "Jayce_Base_Hex_Buff_Ready")
   PersistBuff("hammer", object, "Jayce_Base_PassiveReadyMelee.troy")
   PersistBuff("field", object, "Jayce_Base_StaticStormShock")

   -- if GetDistance(object) < 150 then
   --    pp(object.name)
   -- end
end

local function onSpell(unit, spell)
   if IsOn("gateBlast") and CanUse("gate") then
      if ICast("blast", unit, spell) then
         local point = Projection(me, spell.endPos, 550)
         CastXYZ("gate", point)
         PrintAction("Gate blast")
         StartChannel()
      end
   end

   if CanUse("mercury") then
      if ICast("blow", unit, spell) then
         if #GetInRange(me, GetAARange(), ENEMIES) == 0 then
            Cast("mercury", me)
            PrintAction("Cannon to followup blow")
         end
      end
   end

   if ICast("field", unit, spell) then
      PersistTemp("field", .25)
   end

   -- if IsMe(unit) then
   --    pp(spell.name)
   -- end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)