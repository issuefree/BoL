require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Kalista")
pp(" - Soulmarked included in AA damage for lasthit")
pp(" - Rend stacks: LHing, executes, timeout, escapes")
pp(" - Pierce for LH")

InitAAData({ 
   speed = 2000,
   extraWindup=.3,
   particles = {"Kalista_Base_BA_Spear_mis.troy"} 
})

SetChampStyle("marksman")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "pierce"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["pierce"] = {
   key="Q", 
   range=1200, 
   color=violet, 
   base={10,70,130,190,250}, 
   ad=1,
   type="P",
   delay=.45,  -- tss
   speed=2200, -- tss
   width=60,   -- reticle
   cost={50,55,60,65,70}
} 
spells["pierceNB"] = copy(spells["pierce"])
spells["pierceNB"].noblock = true

spells["sentinel"] = {
   key="W", 
   range=5000, 
   color=blue, 
   cost={25}
} 
spells["soulmarked"] = {
   key="W", 
   base=0,
   targetMaxHealth={.12,.14,.16,.18,.20},
   type="M",
   minionCap={75,125,150,175,200},
   cost=25,
   damOnTarget=function(target)
      if IsMinion(target) or IsCreep(target) then
         local tmh = GetLVal("soulmarked", "targetMaxHealth", target)
         local mc = GetLVal("soulmarked", "minionCap")
         if IsMinion(target) and target.health <= 125 then
            mc = math.max(mc, 125) -- wiki says minions will execute at 125
         end
         if tmh > mc then
            -- tmh should be what was already added to damage so we take that away and add the minionCap damage
            return mc - tmh 
         end
      end
   end
} 

spells["rend"] = {
   key="E", 
   range=900,
   color=yellow,
   cost=40,
   base=0,
   type="P",
   timeout=4,
   damOnTarget=function(target)
      if target then
         local stacks = getRendStacks(target)
         if stacks > 0 then
            return (stacks+1)*GetSpellDamage("rendStack")
         end
      end
   end
} 
-- count double for first stack
spells["rendStack"] = {
   key="E",
   base={10,15,20,25,30}, 
   ad=.3,
   type="P",
}

spells["fate"] = {
   key="R", 
   range=1200, 
   color=yellow, 
   cost=100
} 

spells["AA"].damOnTarget = 
   function(target)
      if HasBuff("soulmarked", target) then
         return GetSpellDamage("soulmarked", target)
      end
   end

function getRendStacks(target)
   if HasBuff("rend", target) then
      return #GetInRange(target, 50, GetPersisted("rend"))
   end
   return 0
end

local rendTimeouts = {}

function Run()
   if StartTickActions() then
      return true
   end

   if CastAtCC("pierce") then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") then
      if CanUse("rend") then
         local rendKills = GetKills("rend", GetInRange(me, "rend", MINIONS))
         if (JustAttacked() and #rendKills >= 1) or
            #rendKills >=2
         then
            if KillMinion("rend", "lowMana") then
               -- PrintAction("Rend for LH", #rendKills)
               return true
            end
         end
      end

      if Alone() then
         -- TODO lasthits with piercing pierce could be interesting
         if KillMinion("pierce") then
            return true
         end

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
   -- TestSkillShot("pierce", nil, {"precast"})
   if CanUse("pierce") then
      local targets = GetInRange(me, GetSpellRange(spell)+500, ENEMIES)
      targets = SortByHealth(GetGoodFireaheads("pierceNB", 2, targets), "pierce")
      for i,target in ipairs(targets) do
         local blockers = FilterList(MINIONS, function(thing) return not WillKill("pierce", thing) end)
         if IsUnblocked(target, "pierce", me, ENEMIES, blockers, PETS) then
            CastFireahead("pierce", target)
            PrintAction("Pierce", target)
            return true
         end
      end
   end   

   if CanUse("rend") then
      -- Execute with rend if I can
      local rendKills = GetKills("rend", GetInRange(me, "rend", ENEMIES))
      if #rendKills >= 1 then
         Cast("rend", me)
         PrintAction("Rend for execute", rendKills[1])
         return true
      end

      local rendttl = spells["rend"].timeout
      local rendttlstacks = 0
      for name,timeout in pairs(rendTimeouts) do
         local hero = GetHeroByName(name)
         -- pp(name.."  "..timeout.." "..time())
         if time() > timeout then
            rendTimeouts[name] = nil
         else
            if IsInRange("rend", hero) then
               rendttl = math.min(rendttl, rendTimeouts[name] - time())
               rendttlstacks = getRendStacks(GetHeroByName(name))
            end
         end
      end

      -- if I have rends that are about to expire I should probably pop them.
      -- I don't want to do this if it's a low number and I'm still hitting people
      -- not sure what the tradeoff is here but if there's noone in aa range
      -- then pop my rend for damage
      if rendttl < .5 then
         if #GetInAARange(me, ENEMIES) == 0 or rendttlstacks >= 3 then
            Cast("rend", me)
            PrintAction("Rend on losing stacks", rendttlstacks)
            return true
         end
      end

      for _,enemy in ipairs(GetInRange(me, "rend", GetWithBuff("rend", ENEMIES))) do
         if getRendStacks(enemy) >= 3 then
            local nextPos = VP:GetPredictedPos(enemy, .5, enemy.ms, enemy, false)
            if GetDistance(nextPos) > GetSpellRange("rend") then
               Cast("rend", me)
               PrintAction("Rend escapee", enemy)
               return true
            end
         end
      end
   end

   local soulmarked = GetWeakest("AA", GetWithBuff("soulmarked", ENEMIES))

   local target = GetMarkedTarget() or soulmarked or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   if HotKey() and IsOn("clear") and Alone() then

      if CanAttack() then
         local minion = SortByHealth(GetWithBuff("rend", GetInAARange(me, MINIONS)), "AA", true)[1]
         if minion then
            if AA(minion) then
               PrintAction("Hit rended minion")
               return true
            end
         end
         if HitMinion("AA", "strong") then
            return true
         end
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
   return false
end

--local function jungle()
--    local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
--    local score = ScoreCreeps(creep)
--    if AA(creep) then
--       PrintAction("AA "..creep.charName)
--       return true
--    end
-- end   
-- SetAutoJungle(jungle)

local function onCreate(object)
   PersistOnTargets("soulmarked", object, "Kalista_Base_P_Blade_Left", ENEMIES, PETS, MINIONS, CREEPS)

   PersistAll("rend", object, "Kalista_Base_E_Spear_tar")

   local rended = PersistOnTargets("rend", object, "Kalista_Base_E_Spear_tar", ENEMIES)
   if rended then
      rendTimeouts[rended.charName] = time()+spells["rend"].timeout
   end

   PersistOnTargets("rend", object, "Kalista_Base_E_Spear_tar", PETS, MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

