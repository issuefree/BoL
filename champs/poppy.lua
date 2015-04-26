require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Poppy")

InitAAData({ 
   particles = {"Poppy_DevastatingBlow_tar"},
   resets = {GetSpellInfo("Q").name},
})


AddToggle("autoUlt", {on=true, key=112, label="AutoUlt"})
AddToggle("jungle", {on=true, key=113, label="Jungle"})
AddToggle("kb", {on=true, key=114, label="Auto KB"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "blow"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move to Mouse"})

spells["blow"] = {
   key="Q", 
   base={20,40,60,80,100}, 
   max={75,150,225,300,375},
   targetMaxHealth=.08,
   ap=.6, 
   modAA="blow", -- modAA calcs won't be quite right because I don't convert the AA damage to magic
   object="Poppy_DevastatingBlow_buf",
   range=GetAARange,
   rangeType="e2e",
   type="M",
   cost=55,
}
spells["paragon"] = {
   key="W",
   cost={70,75,80,85,90},
}
spells["charge"] = {
   key="E", 
   range=525, 
   color=violet, 
   base={50,75,100,125,150}, 
   ap=.4,
   type="M",
   knockback=300,
   cost={60,65,70,75,80},
}
spells["collision"] = {
   key="E", 
   base={75,125,175,225,275}, 
   ap=.4,
   type="M",
   cost={60,65,70,75,80},
}
spells["immunity"] = {
   key="R", 
   range=900, 
   color=blue,
   cost=100,
}

function Run()
   if StartTickActions() then
      return true
   end

   if CheckDisrupt("charge") then
      return true
   end

   -- if CanUse("charge") then
   --    local target = GetWeakestEnemy("charge")
   --    if target then
   --       DrawKnockback(target, "charge")
   --    end
   -- end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if ModAAFarm("blow") then
         return true
      end
   end      

   if IsOn("jungle") and GetMPerc(me) > .25 then
      if ModAAJungle("blow") then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end   

   EndTickActions()
end

function Action()
   -- local creep = SortByDistance(CREEPS)[1]
   -- if creep and IsInRange("charge", creep) then
   --    if CanUse("charge") then
   --       Cast("charge", creep)
   --       Cast("blow", me)
   --    elseif IsInAARange(creep) then
   --       AA(creep)
   --    end
   --    return true
   -- end

   if CanUse("charge") then
      local target = GetWeakestEnemy("charge")      
      if target and not IsInAARange(target) then
         if WillKill("charge", "blow", target) or
            WillKill("charge", "AA", target)
         then
            MarkTarget(target)
            Cast("charge", target)
            if CanUse("blow") then
               Cast("blow", me)
            end
            PrintAction("Charge for the finish")
            return true
         end
      end
   end

   local enemy = checkCharge()
   if enemy then
      MarkTarget(enemy)
      Cast("charge", enemy)
      PrintAction("Charge for slam", enemy)
      if CanUse("blow") then
         Cast("blow", me)
         PrintAction("  w/blow")
      end
      return true
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if target then
      if AutoAA(target, "blow") then
         return true
      end
   end

   return false
end

function FollowUp()
   return false
end

function checkCharge()
   if IsOn("kb") and CanUse("charge") then
      local enemies = SortByHealth(GetInRange(me, "charge", ENEMIES), "charge")
      for _,enemy in ipairs(enemies) do
         local kb = GetKnockback("charge", me, enemy)
         if WillCollide(enemy, kb) then
            return enemy
         end
      end
   end
   return nil
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)
