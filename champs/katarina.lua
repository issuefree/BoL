require "issuefree/timCommon"
require "issuefree/modules"

InitAAData({
   particles={"Katarina_BasicAttack_tar"}
})

spells["flourish"] = {
   range=340 - 15, -- wiki
   base=0,
   byLevel={75,80,87,94,102,111,120,131,143,155,168,183,198,214,231,248,267,287},
   adBonus=1,
   ap = 
      function(target)
         if me.level < 6 then
            return .55
         elseif me.level < 11 then
            return .7
         elseif me.level < 16 then
            return .85
         else
            return 1
         end
      end,
}
spells["blades"] = {
   key="Q", 
   range=625, 
   color=violet, 
   base={75,105,135,165,195}, 
   ap=.3,
   name="KatarinaQ"
}
spells["preparation"] = {
   key="W", 
}
spells["shunpo"] = {
   key="E", 
   range=725, 
   color=yellow, 
   base={30,45,60,75,90}, 
   ap=.25,
   ad=.5,
   name="KatarinaE"
}
spells["lotus"] = {
   key="R", 
   range=550, 
   color=red,
   base={375,562.5,750},
   ap=2.85,
   adBonus=3.3,
   channel=true,
   object="Katarina_Base_r_tar.troy",
   objectTimeout=.5,
   name="KatarinaR"
}


AddToggle("", {on=true, key=112, label="- - -"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "blades"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

pp("Tim's Katarina")

local daggers = {}
function Run()
   daggers = GetPersisted("dagger")

   if IsChannelling("lotus") then
      if not P.lotus or #GetInRange(me, GetSpellRange("lotus"), ENEMIES) == 0 then
         P.lotus = nil
      else
         PrintAction("LOTUS")
         return true
      end
   end

   if StartTickActions() then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") then
      if FarmBlades() then
         return true
      end

      if CanUse("shunpo") then

         if VeryAlone() then
            local bestDagger, bestScore = SelectFromList(
               GetInRange(me, "shunpo", daggers),               
               function(dagger)
                  if UnderTower(dagger) then
                     return 0
                  end
                  local minions = GetInRange(dagger, "flourish", MINIONS)
                  return scoreHits("flourish", minions, .05, .95)
               end 
            )            
            if bestScore >= 2 then
               Cast("shunpo", bestDagger)
               PrintAction("Shunpo for flourish LH", bestScore)
               return true
            end

            local minions = SortByDistance(GetInRange(me, "shunpo", MINIONS))
            for _,minion in ipairs(minions) do
               if not IsInAARange(minion) and
                  not UnderTower(minion) and
                  WillKill("shunpo", minion)
               then
                  Cast("shunpo", minion)
                  PrintAction("Shunpo LH", minion)
                  return true
               end
            end

         end

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
   if CanUse("blades") then
      local target = GetMarkedTarget() or GetWeakestEnemy("blades")
      if target then
         Cast("blades", target)
         PrintAction("Blades", target)
         return true
      end
   end

   if CanUse("lotus") then      
      if GetMarkedTarget() and IsInRange(GetSpellRange("lotus")*.5, GetMarkedTarget()) then
         if CanUse("preparation") then
            Cast("preparation", me)
            PrintAction("Preparation pre Lotus")
            return true
         end
         Cast("lotus", me)
         PrintAction("Lotus marked", GetMarkedTarget())
         return true
      end

      local enemies = GetInRange(me, GetSpellRange("lotus")*.75, ENEMIES)

      local kills = GetKills("lotus", enemies)
      if #kills > 0 then
         if CanUse("preparation") then
            Cast("preparation", me)
            PrintAction("Preparation pre Lotus")
            return true
         end
         Cast("lotus", me)
         PrintAction("Lotus for kill", kills[1])
         return true
      end

      if #enemies >= 2 then
         if CanUse("preparation") then
            Cast("preparation", me)
            PrintAction("Preparation pre Lotus")
            return true
         end
         Cast("lotus", me)
         PrintAction("Lotus for aoe", #enemies)
         return true
      end
   end

   if CanUse("shunpo") then
      
      local target = GetWeakestEnemy("shunpo")
      if target then
         local dam = GetSpellDamage("shunpo")
         if CanUse("preparation") then
            dam = dam + GetSpellDamage("flourish", target)
         end
         if CanUse("lotus") then
            dam = dam + GetSpellDamage("lotus", target)
         end
         if CalculateDamage(target, dam) > target.health then
            Cast("shunpo", target)
            PrintAction("Shunpo", target)
            return true
         end
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


-- preferrs throws that include hitting heroes.
-- will keep throwing until heroes get pretty close.
function FarmBlades()
   if CanUse("blades") then
      local nearTargets = GetInRange(me, 3000, MINIONS, ENEMIES)
      local initialTargets = SortByDistance(GetInRange(me, GetSpellRange("blades")+150, MINIONS, ENEMIES))

      -- bounce path with the best score      
      local bestKills = 0
      local bestKillTargets = nil
      local bestKillDeaths  = nil
      
      for _, initialTarget in ipairs(initialTargets) do
         local tKills, tKillTargets, tKillDeaths = getBouncePath(initialTarget, nearTargets) 
      
         if tKills > bestKills then
            bestKillTargets = tKillTargets
            bestKills = tKills
            bestKillDeaths = tKillDeaths
         end
      end
      
      if bestKillTargets then
         PrintState(0, "Farm score: "..bestKills)
         Circle(bestKillTargets[1], 90, violet)
         for i,t in ipairs(bestKillTargets) do
            local bkti = bestKillTargets[i]
            if i > 1 then
               LineBetween(bestKillTargets[i-1], bkti)
            end
            if not find(bkti.charName, "Minion") then
               Circle(bkti, 80, green)
            end
            if bestKillDeaths[i] then
               Circle(bkti, 70, red, 3)
            else
               Circle(bkti, 70, yellow)                        
            end
         end
         if GetDistance(bestKillTargets[1]) < GetSpellRange("blades") then
            if #GetInRange(me, 1500, ENEMIES) > 0 and UnderTower() then
               -- do nothing if there's a hero nearby and i'm under a tower
            elseif bestKills >= 1 then
               Cast("blades", bestKillTargets[1])
               PrintAction("Blades for lasthit", bestKills)
               return true
            end
         end
      end
   end
end

function getBouncePath(target, nearTargets)
   local tKills = 0 
   local tKillTargets = {}
   local tKillDeaths  = {}

   local bbDam = GetSpellDamage("blades") -- reset blades damage for next path
   local testNearby = copy(nearTargets)
   local jumps = 0
   while jumps <= 2 do
      local nearestI = GetNearestIndex(target, testNearby)
      if nearestI then
         if target and GetDistance(target, testNearby[nearestI]) > 375 then
            break
         end
         target = testNearby[nearestI]
         local isHero = not IsMinion(target)
         table.insert(tKillTargets, target)
         if CalculateDamage(target, bbDam) > target.health then
            if isHero then
               tKills = tKills + 5  -- 5 points for a hero kill
            else
               tKills = tKills + 1  -- 1 point for a minion kill
            end
            table.insert(tKillDeaths, true)
         else
            if isHero then
               tKills = tKills + (5-jumps)/5
            end
            table.insert(tKillDeaths, false)
         end
         table.remove(testNearby, nearestI)
      else
         break  -- out of bounce targets
      end
      jumps = jumps+1
      bbDam = bbDam*.9 
   end
   return tKills, tKillTargets, tKillDeaths
end


harrass = Combo("harrass", 2, function() Toggle("harrass", false) end)
harrass:addState("prep",
   function(combo)
      if CanUse("preparation") and
         CanUse("shunpo") and
         not CanUse("blades")
      then
         Cast("strike", me)
         PrintAction(combo, combo.target)
      else
         combo.state = "attack"
      end
   end
)
harrass:addState("attack",
   function(combo)
      AutoAA(watched)
      if JustAttacked() then
         combo.state = "return"
      end
   end
)
harrass:addState("return",
   function(combo)
      if CanUse("safeguard") then
         Cast("safeguard", combo:get("bounceTarget"))
         PrintAction(combo)
      else
         combo:reset()
      end
   end
)


function onObject(object)
   PersistAll("dagger", object, "Katarina_Base_W_Indicator")
end

function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)