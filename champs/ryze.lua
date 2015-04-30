require "issuefree/timCommon"
require "issuefree/modules"

InitAAData({ 
   speed = 2400, 
   extraWindup = .1,
   particles = {"ManaLeach_mis"}
})

pp("Tim's Ryze")
pp(" - prison > overload > flux")
pp(" - lasthit w/overload depending on mana")
pp(" - clear w/overload/flux depending on mana")

SetChampStyle("caster")

spells["overload"] = {
   key="Q", 
   range=900, 
   color=violet, 
   base={65,90,115,140,165}, 
   ap=.55,
   maxMana={.02,.025,.03,.035,.04},
   cost={30,35,40,45,50},
   speed=1400,
   delay=.4, -- tss
   width=60, -- reticle
}
spells["prison"] = {
   key="W", 
   range=600, 
   color=red,    
   base={65,95,125,155,185}, 
   ap=.4, 
   maxMana=.025,
   cost={60,70,80,90,100},
}
spells["flux"] = {
   key="E", 
   range=600, 
   color=violet,
   speed=1400,
   base={50,66,82,98,114},  
   ap=.3, 
   maxMana=.02,
   cost={60,70,80,90,100},
}
spells["fluxBounce"] = {
   base={25,33,41,49,57},
   ap=.15,
   mana=.01,
}
spells["power"] = {
   key="R",
   radius=200,
   cost=0,
}

AddToggle("power", {on=true, key=112, label="Auto Power"})
AddToggle("arcane", {on=true, key=113, label="Manage Arcane"})
AddToggle("tear", {on=true, key=114, label="Charge tear"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "overload"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

local lastCast = 0

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("tear") then
      UseItem("Muramana")
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillMinion("overload", nil, true) then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   if IsOn("arcane") and GetMPerc() > .5 then
      if time() - lastCast > 10 and
         time() - lastCast < 12
      then
         if burnSpell() then
            return true
         end
      end
   end   

   if IsOn("tear") and CanChargeTear() and GetMPerc() > .75 then
      if burnSpell() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("overload", "mis")

   if CanUse("prison") then
      local target = GetWeakestEnemy("prison", 0, 15)
      if target then
         checkPower(target)
         Cast("prison", target)
         PrintAction("Prison", target)
         return true
      end
   end

   if CanUse("overload") then
      local target = GetSkillShot("overload")
      if target then
         checkPower(target)
         CastFireahead("overload", target)
         PrintAction("Overload", target)
         return true
      end
   end

   if CanUse("flux") then
      local target = GetWeakestEnemy("flux", 0, 15)
      if target then
         checkPower(target)
         Cast("flux", target)
         PrintAction("Flux", target)
         return true
      end
   end

   if not CanUse("overload") and
      not CanUse("prison") and
      not CanUse("flux")
   then
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
   end

   return false   
end


function burnSpell()
   if CanUse("overload") then
      if SkillShot("overload") then
         return true
      end

      local targets = SortByDistance(GetInRange(me, "overload", MINIONS, PETS))
      if targets[1] then
         Cast("overload", targets[1])
         PrintAction("Burn overload", targets[1])
         return true
      end

      local bush = GetNearestBush(me, GetSpellRange("overload"))
      if bush then
         CastXYZ("overload", bush)
         PrintAction("Burn overload into a bush")
         return true
      end
   end
end

function checkPower(target)
   if IsOn("power") and CanUse("power") then
      if #GetInRange(target, spells["power"].radius, ENEMIES) > 1 then
         Cast("power", me)
         PrintAction("Power UP", nil, 1)
      end
   end
end

function FollowUp()
   if IsOn("clear") and Alone() then
      local minion = GetWeakest("overload", GetInRange(me, "overload", MINIONS))

      if minion then
         if ( CanChargeTear() and GetMPerc(me) > .33 ) or
            GetMPerc(me) > .75
         then
            if #GetInRange(minion, 200, minions) > 0 and CanUse("flux") then
               Cast("flux", minion)
               PrintAction("Flux for clear")
               return true
            end
         end
      end

      if HitMinion("AA", "strong") then
         return true
      end

   end

   return false
end

local function onObject(object)
   PersistBuff("arcane", object, "PARTICLE") -- I don't know if I need this for anything.
end

local function onSpell(unit, spell)
   if ICast("overload", unit, spell) or
      ICast("prison", unit, spell) or
      ICast("flux", unit, spell) or
      ICast("power", unit, spell)
   then
      lastCast = time()
   end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)