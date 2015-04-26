require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Gragas")

SetChampStyle("caster")

InitAAData({
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "barrel"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["barrel"] = {
   key="Q", 
   range=850, 
   color=violet, 
   base={80,120,160,200,240},
   ap=.6,
   delay=.2,
   speed=1200,
   radius=275,
   noblock=true,
   overShoot=50,
   scale=function(target) if IsMinion(target) then return .7 end end,
   cost={60,65,70,75,80},
}

spells["rage"] = {
   key="W",
   base={20,50,80,110,140},
   ap=.3,
   percMaxHealth={.08,.09,.10,.11,.12},
   cost=30,
}
spells["slam"] = {
   key="E", 
   range=650,
   color=yellow, 
   base={80,130,180,230,280}, 
   ap=.6,
   delay=.16,
   speed=9,
   area=150,
   cost=50,
}
spells["cask"] = {
   key="R", 
   range=1050,
   color=red, 
   base={200,300,400}, 
   ap=.7,
   delay=.16,
   speed=3000,
   radius=400,
   cost=100,
}

local barrelTime = 0

function getBarrel()
   if P.barrel and P.barrel.x and P.barrel.z then
      return P.barrel
   end
   return nil
end

function Run()
   spells["AA"].bonus = 0
   if P.rage then
      spells["AA"].bonus = GetSpellDamage("rage", target)
   end

   if getBarrel() and CanUse("barrel") then
      local mult = .5*math.min(time() - barrelTime, 2) / 2
      spells["barrel"].bonus = GetSpellDamage("barrel") * mult
   else
      spells["barrel"].bonus = 0
   end

   if StartTickActions() then
      return true
   end


   if getBarrel() and CanUse("barrel") then
      local spell = GetSpell("barrel")
      local enemies = GetInRange(getBarrel(), spell.radius, ENEMIES)
      for _,enemy in ipairs(enemies) do
         if WillKill("barrel", enemy) then
            Cast(spell, me, true)
            PrintAction("Pop to kill", enemy)
            break
         end
         local nextPos = VP:GetPredictedPos(enemy, .5, enemy.ms, me, false)
         if GetDistance(getBarrel(), nextPos) > spell.radius then
            Cast(spell, me, true)
            PrintAction("Pop escapees", nil, 1)
            break
         end
      end

      -- if #GetInRange(getBarrel(), spells["barrel"].radius, ENEMIES) > 0 then
      --    Cast("barrel", me, true)
      --    PrintAction("BOOM")
      -- end

      local minions = GetInRange(getBarrel(), spells["barrel"].radius, MINIONS)
      local kills = GetKills("barrel", minions)
      if #kills >= 2 then
         Cast("barrel", me, true)
         PrintAction("Pop to kill "..#kills.." minions", nil, .5)
      end

   end

   if not getBarrel() then
      if CastAtCC("barrel") then
         return true
      end
   end

   if HotKey() and CanAct() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and CanUse("barrel") and not getBarrel() and VeryAlone() then
      -- lasthit with barrel if it kills 3 minions or more
      if KillMinionsInArea("barrel") then
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
   if not getBarrel() then
      if SkillShot("barrel") then
         return true
      end
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end
end

function FollowUp()
end

local function onObject(object)
   if Persist("barrel", object, "Gragas_Base_Q_Ally") then
      barrelTime = time()+.5
   end
   PersistBuff("rage", object, "Gragas_Base_W_Buf_Hands")
end

local function onSpell(unit, spell)
   if ICast("barrel", unit, spell) then
      PersistTemp("barrel", .5)
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
