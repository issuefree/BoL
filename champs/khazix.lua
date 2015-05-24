require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: Tighten up LHs with spikes. I spam them too much.
--    This is probably like don't use it in melee unless I need the heal
--    
-- TODO: If leap is evolved look for executes as well
-- TODO: Write jungler
-- TODO: Fix leap code to not leap off of good targets

pp("\nTim's Kha'Zix")

InitAAData({ 
--    extraRange=-20,
--    attacks = {"attack"} 
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("dive", {on=false, key=112, label="Dive"})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "taste", "spike"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["threat"] = {
   base=0,
   byLevel={15,20,25,35,45,55,65,75,85,95,110,125,140,150,160,170,180,190},
   ap=.5,
}

spells["taste"] = {
   key="Q", 
   range=325, 
   evolvedRange=375,
   color=orange, 
   base={70,95,120,145,170},    
   adBonus=1.2,
   cost=25,
   scale=function(target)
      if isolated(target) then
         return 1.3
      end
   end,
   damOnTarget=function(target)
      if evolvedQ and isolated(target) then
         return GetSpellDamage("claws")
      end
   end,
} 
spells["claws"] = {
   base=0,
   lvl=10,
   adBonus=1.04,
   scale=1/1.3 -- because I'm going to pass it into taste which already has the scale factored in
}
spells["spike"] = {
   key="W", 
   range=1000, 
   color=violet, 
   base={80,110,140,170,200}, 
   adBonus=1,
   delay=.4,  -- tss
   speed=1650, -- tss
   width=80,   -- reticle
   evolvedCone=55, -- reticle
   cost={55,60,65,70,75},
   scale=function(target)
      if IsCreep(target) then
         return 1.2
      end
   end
} 
spells["leap"] = {
   key="E", 
   range=600, 
   evolvedRange=900,
   color=yellow, 
   base={65,100,135,170,205}, 
   adBonus=.2,
   delay=.1,  -- mathed it
   speed=1000, -- mathed it
   radius=275-200,   -- reticle big reduction because I want to land on people
   noblock=true,
   cost=50,
} 
spells["leapAoE"] = copy(spells["leap"])
spells["leapAoE"].radius = 275

spells["assault"] = {
   key="R", 
   cost=100
} 

spells["AA"].damOnTarget = 
   function(target)
      if P.threat and IsEnemy(target) then
         return GetSpellDamage("threat")
      end
      return 0
   end

evolvedQ = false
evolvedW = false
evolvedE = false
evolvedR = false

function isolated(target)
   return HasBuff("isolated", target)
   -- return IsEnemy(target) and (#GetInRange(target, 500, ENEMIES) == 1)
end

function Run()
   if not evolvedQ and GetSpellInfo("taste").name == "khazixqlong" then
      spells["taste"].range = spells["taste"].evolvedRange
      evolvedQ = true
   end
   if not evolvedW and GetSpellInfo("spike").name == "khazixwlong" then
      -- spells["spike"].cone = spells["spike"].evolvedCone      
      evolvedW = true
   end
   if not evolvedE and GetSpellInfo("leap").name == "khazixelong" then
      spells["leap"].range = spells["leap"].evolvedRange
      evolvedE = true
   end

   if StartTickActions() then
      return true
   end

   if CastAtCC("spike") then
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
         if KillMinion("taste") then
            return true
         end

         if KillMinion("spike") then
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
   local targets = GetInRange(me, GetSpellRange("leap")+100, ENEMIES)   
   targets = FilterList(targets, function(item) return not UnderTower(item) end)
   targets = FilterList(targets, function(item) return not IsInAARange(item) end)
   
   local target = GetSkillShot("leap", nil, targest)
   if IsOn("dive") or isolated(target) then
      if SkillShot("leap") then
         return true
      end
   end

   if CastBest("taste") then
      return true
   end

   if SkillShot("spike") then
      return true
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
   PersistBuff("threat", object, "Khazix_Base_P_")
   -- I probably don't need this.
   PersistBuff("stealth", object, "Khazix_Base_R_Invisible.troy")

   PersistOnTargets("isolated", object, "Khazix_Base_Q_Single", ENEMIES, MINIONS, CREEPS)
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

