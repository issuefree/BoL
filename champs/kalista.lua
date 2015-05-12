require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Kalista")

-- TODO: track oathsworn?
-- TODO: track enemies and minions that my oathsworn has hit for easier lasthits or maximize damage

-- There may be some weird stuff to do here for her kiting due to her passive
InitAAData({ 
--    speed = 1300,
--    minMoveTime = 0,
--    extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

SetChampStyle("marksman")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["pierce"] = {
   key="Q", 
   range=1200, 
   color=violet, 
   base={10,70,130,190,250}, 
   ad=1,
   type="P",
   delay=.25,   -- ???
   speed=1200, -- ???
   width=80,   -- ???
   cost={50,55,60,65,70}
} 

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

-- TODO: track spears
spells["rend"] = {
   key="E", 
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
-- TODO track and return stacks
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

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if CanUse("rend") then
         local rendKills = GetKills("rend", MINIONS)
         if #rendKills >= 1 then
            Cast("rend", me)
            PrintAction("Rend for LH", #rendKills)
            return true
         end
      end

      if Alone() then
         -- TODO lasthits with piercing pierce could be interesting
         if KillMinion("pierce") then
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

   if CanUse("pierce") then
      -- TODO look at skillshot with pierce if I cast through an almost dead minion
      -- since this is a larger pool of targets I should do this before I check for
      -- unblocked skillshots      

      if SkillShot("pierce") then
         return true
      end
   end   

   if CanUse("rend") then
      -- Execute with rend if I can
      local rendKills = GetKills("rend", ENEMIES)
      if #rendKills >= 1 then
         Cast("rend", me)
         PrintAction("Rend for execute", rendKills[1])
         return true
      end

      local rendttl = spells["rend"].timeout
      local rendttlstacks = 0
      for name,timeout in pairs(rendTimeouts) do
         if timeout > time() then
            rendTimeouts[name] = nil
         else
            rendttl = math.min(rendttl, rendTimeouts[name] - time())
            rendttlstacks = getRendStacks(getHeroByName(name))
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
   end

   local soulmarked = GetWeakestEnemy("AA", GetWithBuff("soulmarked", ENEMIES))

   local target = GetMarkedTarget() or soulmarked or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
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
   PersistOnTargets("soulmarked", object, "TODO", ENEMIES, PETS, MINIONS, CREEPS)
   local rended = PersistOnTargets("rend", object, "TODO", ENEMIES)
   if rended then
      rendTimeouts[rended.charName] = time()+spells["rend"].timeout
   end
   PersistOnTargets("rend", object, "TODO", PETS, MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

