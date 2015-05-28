require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Fiora")

InitAAData({ 
--    speed = 1300,
   extraRange=25,
--    attacks = {"attack"} 
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["lunge"] = {
   key="Q", 
   range=600, 
   color=yellow, 
   base={40,65,90,115,140}, 
   adBonus=.6,
   type="P",
   cost=60
} 

spells["riposte"] = {
   key="W", 
   base={60,110,160,210,260}, 
   ap=1,
   cost=45
} 

spells["burst"] = {
   key="E", 
   cost=55
}

spells["waltz"] = {
   key="R", 
   range=400, 
   color=orange, 
   base={125,255,385}, 
   adBonus=.9,
   type="P",
   onHit=true,
   radius=400, -- this seeeems right
   cost=100,
} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   if StartTickActions() then
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
   if CanUse("burst") and JustAttacked() then
      if #GetInAARange(me, ENEMIES) > 0 then
         Cast("burst", me)
         PrintAction("Burst of speed")
         return true
      end
   end

   if CanUse("lunge") then
      local target = GetDive("lunge")
      if target then
         -- do I want to burst of speed in here or do I want to lunge, AA, burst reset etc...
         -- if CanUse("burst") then
         --    Cast("burst", me)
         --    PrintAction("Burst for lunge", nil, .5)
         -- end
         Cast("lunge", target)
         PrintAction("Lunge", target)
         return true
      end
   end

   -- hits 5 times, hits initial target at least 2 times.
   -- if there are 2 targets there's a high (75%) chance it will hit the initial target 3 times

   -- I think I can use this to waltz to a distant enemy for an execute

   if CanUse("waltz") then
      -- check for distant execute
      local targets = SortByHealth(GetInRange(me, "waltz", ENEMIES), "waltz")
      for _,target in ipairs(targets) do
         local damage = GetSpellDamage("waltz", target)
         
         local waltzers = SortByHealth(GetInRange(target, spells["waltz"].radius, ENEMIES), "waltz")
         if #waltzers == 1 then -- 5 hits         
            if target.health > damage then -- don't blow ult for a slivered enemy
               local total = damage + (damage*.4*4)
               if target.health < total then
                  Cast("waltz", target)
                  PrintAction("Waltz for execute", target)
                  return true
               end
            end
         elseif #waltzers == 2 then -- probably 3 hits
            local total = damage + (damage*.4*2)
            if target.health < total then
               Cast("waltz", target)
               PrintAction("Waltz for probable execute", target)
               return true
            end
         else -- at least 2 hits
            local total = damage + damage*.4
            if target.health < total then
               Cast("waltz", target)
               PrintAction("Waltz for execute and AoE")
               return true
            end
         end

         if #waltzers > 1 then
            for _,waltzer in ipairs(waltzers) do
               if waltzer ~= target then
                  local wdam = GetSpellDamage("waltz", waltzer)
                  if #waltzers == 2 then -- secondary target 75% chance of 2 hits
                     wdam = wdam * 1.4
                  else -- 3 or more waltzers means a decent chance of 1 hit
                     -- base damage
                  end
                  if waltzer.health < wdam then
                     Cast("waltz", target)
                     PrintAction("Waltz for secondary execute", waltzer)
                     return true
                  end
               end
            end
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
   if LastHit() then
      return true
   end
   if Alone() and GetHPerc() < .95 and not P.duelist then
      if HitMinion("AA", "strong") then
         return true
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
   PersistBuff("duelist", object, "Fiora_heal_buf")

   -- if GetDistance(object) < 150 then
   --    pp(object.name)
   -- end
end

function getAAPower(enemy)
   if not enemy then return 0 end
   return enemy.totalDamage*(1+enemy.critChance)
end

local function onSpell(unit, spell)
   if CanUse("riposte") then
      if IsEnemy(unit) and spell.target and IsMe(spell.target) then
         if find(spell.name, "attack") then -- is there a better way to detect enemy auto attacks?
            local _, biggestHit = SelectFromList(GetInRange(me, 1000, ENEMIES), getAAPower)
            if getAAPower(unit) > biggestHit*.75 then
               Cast("riposte", me)
               PrintAction("Riposte", unit)               
            end
         end
      end
   end


   -- if IsMe(unit) then
   --    pp(spell.name)
   -- end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

