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
   range=1000-50, --wiki
   color=violet, 
   base={60,85,110,135,160,185}, 
   ap=.45,
   bonus=function()
      return getBonusMana()*.03
   end,
   cost=40,
   speed=1400,
   delay=.4, -- tss
   width=55, -- wiki
   scale=function(target)
      if HasBuff("flux", target) then
         return GetLVal(spells["flux"], "olScale")
      else
         return 1
      end
   end
}
spells["prison"] = {
   key="W", 
   range=615, 
   color=red,    
   base={80,100,120,140,160}, 
   ap=.2, 
   bonus=function()
      return getBonusMana()*.01
   end,
   cost={60,70,80,90,100},
}
spells["flux"] = {
   key="E", 
   range=615, 
   color=yellow,
   speed=1400,
   base={50,75,100,125,150},  
   ap=.3, 
   bonus=function()
      return getBonusMana()*.02
   end,
   cost={40,55,70,85,100},
   olScale={1.4,1.55,1.70,1.85,2}
}
spells["warp"] = {
   key="R",
   range={1750,3000},
   cost=100,
}

AddToggle("-", {on=true, key=112, label=""})
AddToggle("-", {on=true, key=113, label=""})
AddToggle("tear", {on=true, key=114, label="Charge tear"})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "overload"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

local lastCast = 0

local manaByLevel = {400,436,474,513,555,598,642,689,737,787,839,892,948,1005,1063,1124,1186,1250}
function getBonusMana()
   return me.maxMana - manaByLevel[me.level]
end

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

   if IsOn("tear") and CanChargeTear() and GetMPerc() > .75 then
      if burnSpell() then
         return true
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("overload", "mis")

   if CanUse("overload") then
      local target = GetSkillShot("overload")
      if target then
         CastFireahead("overload", target)
         PrintAction("Overload", target)
         return true
      end
   end

   if CanUse("prison") then
      local target = GetWeakestEnemy("prison", 0, 15)
      if target then
         Cast("prison", target)
         PrintAction("Prison", target)
         return true
      end
   end

   if CanUse("flux") then
      local target = GetWeakestEnemy("flux", 0, 15)
      if target then
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

      -- local bush = GetNearestBush(me, GetSpellRange("overload"))
      -- if bush then
      --    CastXYZ("overload", bush)
      --    PrintAction("Burn overload into a bush")
      --    return true
      -- end
   end
end

function FollowUp()
   if IsOn("clear") and Alone() then
      local minion = GetWeakest("overload", GetInRange(me, "overload", MINIONS))

      if minion then
         if ( CanChargeTear() and GetMPerc(me) > .33 ) or
            GetMPerc(me) > .75
         then
         end
      end

      if HitMinion("AA", "strong") then
         return true
      end

   end 

   return false
end

local function onObject(object)
   PersistOnTargets("flux", object, "Ryze_Base_E_Debuff_Timer", ENEMIES, MINIONS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)