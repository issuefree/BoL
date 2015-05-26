require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: check for maxed ferocity
-- TODO: maybe need to track trophies for unseen predator's range increase

pp("\nTim's Rengar")

InitAAData({ 
--    extraRange=-20,
--    attacks = {"attack"} 
   resets={GetSpellInfo("Q").name} -- need to make sure this reflects the empowered version as well
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

spells["savagery"] = {
   key="Q", 
   base={30,60,90,120,150}, 
   ad={0,.05,.1,.15,.2},
   type="P",
   modAA="savagery",
   object="TODO",
   range=GetAARange,
   rangeType="e2e",
   cost=0
} 
spells["empsavagery"] = {
   key="--",
   base=0,
   byLevel={30,45,60,75,90,105,120,135,150,160,170,180,190,200,210,220,230,240},
   ad=.5,
   type="P",
   modAA="empsavagery",
   object="TODO",
   range=GetAARange,
   rangeType="e2e",
   cost=0
}

spells["roar"] = {
   key="W", 
   range=500, 
   color=yellow, 
   base={50,80,110,140,170}, 
   ap=.8,
   cost=0
} 
spells["emproar"] = {
   key="--", 
   range=500, 
   color=yellow, 
   base=0, 
   byLevel={40,55,70,85,100,115,130,145,160,170,180,190,200,210,220,230,240,250}
   ap=.8,
   cost=0
} 
spells["emproarheal"] = {
   key="--",
   base=0,
   byLevel=function() return 8+(4*me.level) end,
   scale=function() 
      local missingHealthPerc = 1-GetHPerc(me)
      return .065*missingHealthPerc
   end,
   type="H",
   cost=0,
}

spells["bola"] = {
   key="E", 
   range=1000, 
   color=violet, 
   base={50,100,150,200,250}, 
   adBonus=.7,
   type="P",
   delay=.25,  -- test
   speed=1200, -- test
   width=80,   -- test
   minRange=GetAARange,
   cost=0
} 
spells["empbola"] = {
   key="--",
   range=1000,
   color=violet,
   base=0,
   byLevel={50,75,100,125,150,175,200,225,250,260,270,280,290,300,310,320,330,340},
   adBonus=.7,
   type="P",
   delay=.25,  -- test
   speed=1200, -- test
   width=80,   -- test
   minRange=GetAARange,
   cost=0,
}

spells["thrill"] = {
   key="R", 
   cost=0
} 

function Run()
   if StartTickActions() then
      return true
   end

   if CastAtCC("bola") then
      return true
   end

   -- high priority hotkey actions, e.g. killing enemies
	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if CanUse("emproar") and VeryAlone() and GetHPerc() < .75 then
      Cast("emproar", me)
      PrintAction("Roar alone for heal", nil, .5)
   end

	-- auto stuff that should happen if you didn't do something more important
   if IsOn("lasthit") then
      if Alone() then
         if KillMinion("savagery") then
            return true
         end

         -- I'm not sure if I want this cast a lot but I may
         if KillMinion("bola", "far") then
            return true
         end

         if KillMinionsInPB("roar", 2) then
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

-- It seems like it's best to blow your empowered abilities asap so you can get back to spamming
-- Heal when needed seems like the most important
-- Savagery seems like a great one to just blast off
-- Bola is last resort.

function Action()
   if CanUse("emproar") and GetHPerc() < .33 then
      Cast("emproar", me)
      PrintAction("Roar for heal", nil, .5)
   end

   if CastBest("empsavagery") then
      return true
   end

   if CastBest("savagery") then
      return true
   end

   if SkillShot("bola") then
      return true
   end

   if SkillShot("empbola") then
      return true
   end

   if CanUse("roar") then
      if #GetInRange(me, "roar", ENEMIES) >= 1 then
         Cast("roar", me)
         PrintAction("Roar", nil, .5)
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
   -- if GetDistance(object) < 150 then
   --    pp(object.name)
   -- end
end

local function onSpell(unit, spell)
   -- if IsMe(unit) then
   --    pp(spell.name)
   -- end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

