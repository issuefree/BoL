require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Veigar")
pp(" - Farm up Baleful Strike")
pp(" - Event Horizon to stun enemies")
pp(" - Dark Matter stunned enemies")
pp(" - Hit good Primordial Burst targets while trying not to waste")
pp(" - Clear minion waves with Dark Matter")

InitAAData({
   speed = 1100,
   particles = {"permission_basicAttack_mis"}   
})

spells["strike"] = {
   key="Q", 
   range=950-25, 
   color=violet, 
   base={80,125,170,215,260}, 
   ap=.6,
   speed=2000, -- wiki
   delay=.4, -- tss
   width=85, -- reticle
   cost={60,65,70,75,80},
}
spells["dark"] = {
   key="W", 
   range=900, 
   color=red,    
   base={120,170,220,270,320}, 
   ap=1, 
   delay=1.5,
   speed=0,
   noblock=true,
   radius=225-25,
   cost={70,75,80,85,90},
}
spells["event"] = {
   key="E", 
   range=700, 
   color=yellow, 
   radius=375,
   delay=.75,
   noblock=true,
   cost={80,85,90,95,100},
}
spells["burst"] = {
   key="R", 
   range=650, 
   color=red,    
   base={250,375,500}, 
   ap=1,
   cost=125,
   damOnTarget=
      function(target)
         if target then
            return target.ap*.8
         end
      end,
}

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "strike"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})


function Run()
   if StartTickActions() then
      return true
   end

   -- this will need special work
   -- if CheckDisrupt("event") then
   --    return true
   -- end

   -- looking for the stun obj and throwing darks at it
   if CastAtCC("dark") or
      CastAtCC("strike")
   then
      return true
   end

   if HotKey() then
      if Action() then
         return true
      end
   end

   if IsOn("lasthit") and Alone() then
      if KillMinion("strike", "ignoreMana", true) then
         return true
      end
   end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions(true)
end

function Action()
   -- TestSkillShot("strike")
   
   if CanUse("event") and ( Skirmishing() or (CanUse("dark") and me.mana > GetSpellCost("dark") + GetSpellCost("event")) ) then
      local enemies = SortByDistance(GetInRange(me, "event", ENEMIES))
      for _,enemy in ipairs(enemies) do
         local pred, chance = GetSpellFireahead("event", enemy)
         if chance >= 1 then
            local pos = Projection(pred, enemy, 150)
            if IsInRange("event", pos) then
               CastXYZ("event", pos)
               PrintAction("Event horizon", enemy)
               return true
            end
         end
      end      
   end

   if CanUse("burst") then
      -- if there aren't any of those lets find a good target
      -- I want to do the largest % remaining health but
      -- I don't want to waste my ult on a tank just because he's the only
      -- one in range.
      -- So I'm thinking 2 things:
      --  Look for targets at +50% range and don't fire unless it's the best one of those
      --  Don't fire unless it will do 50% of their remaining health

      local spell = spells["burst"]
      local bestS = 0
      local bestT = nil
      local burstBase = GetSpellDamage("burst")

      -- look for 1 hit kills
      for _,enemy in ipairs(GetInRange(me, GetSpellRange(spell)*1.5 ,ENEMIES)) do
         local tDam = GetSpellDamage("burst", enemy)
         -- one hit kill in range. kill it.
         if tDam > enemy.health and GetDistance(enemy) < GetSpellRange(spell) then
            Cast("burst", enemy)
            PrintAction("Burst for execute", enemy)
            return true
         end

         local score = tDam/enemy.health
         if score > .5 then
            if not bestT or score > bestS then
               bestS = score
               bestT = enemy
            end
         end
         if bestT and GetDistance(bestT) < GetSpellRange(spell) then
            Cast("burst", bestT)
            PrintAction("Burst for damage", enemy)
            return true
         end
      end
   end

   if SkillShot("strike") then
      return true
   end

   if not CanUse("strike") then
      local target = GetMarkedTarget() or GetWeakestEnemy("AA")
      if AutoAA(target) then
         return true
      end
   end

   return false
end

function FollowUp()
   if IsOn("lasthit") and not CanUse("strike") and Alone() then
      if KillMinion("AA") then
         return true
      end
   end

   if IsOn("clear") then
      if HitMinionsInArea("dark", 3) then
         return true
      end
   end

   return false
end

local function onObject(object)
end

local function onSpell(object, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

AddOnTick(Run)
