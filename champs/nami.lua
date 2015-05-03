require "issuefree/timCommon"
require "issuefree/modules"


pp("\nTim's Nami")

InitAAData({ 
   speed=1300,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

SetChampStyle("support")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["prison"] = {
   key="Q", 
   range=875, 
   color=violet, 
   base={75,130,185,240,295}, 
   ap=.5,
   delay=.25+.875, -- test
   speed=0, -- wiki
   radius=162, -- wiki
   noblock=true,
   cost=60,
} 
spells["ebb"] = {
   key="W", 
   range=725, 
   color=cyan, 
   base={70,110,150,190,230}, 
   ap=.5,
   type="M",
   radius=650-25, -- object seems to have a max experimental travel of 650.
   cost={70,85,100,115,130}
} 
spells["flow"] = {
   key="W", 
   range=726, 
   color=green, 
   base={65,95,125,155,185}, 
   ap=.3,
   type="H",
   radius=650-25,
   cost={70,85,100,115,130}
} 
spells["blessing"] = {
   key="E",
   range=800, 
   color=yellow, 
   base={25,40,55,70,85},
   ap=.2,
   cost={55,60,65,70,75}
} 
spells["wave"] = {
   key="R", 
   range=2750, 
   color=blue, 
   base={150,250,350}, 
   ap=.6,
   delay=.25, --test
   speed=859, -- wiki
   width=562, -- wiki
   noblock=true,
   cost=100
} 

function Run()
   spells["AA"].bonus = 0
   if P.blessing then
      spells["AA"].bonus = GetSpellDamage("blessing")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("prison") then
      return true
   end

   if CastAtCC("prison") then
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

   -- ebb and flow
   -- can be used for straight up heal
   -- can be used for straight up damage
   -- can be used for a double or a triple
   -- I'm going to assume it bounces to the closest valid target

   -- I feel like I should always look for a triple bounce and go for that first
   -- then a double
   -- single damage seems unlikely as it'll probably bounce back to me
   -- single heal only at relatively high mana or if the ally is very low

   if CanUse("ebb") then
      -- look for a triple

      -- loop through allies in order of health and fire at the first one that gets a triple.
      local allies = SortByHealth(GetInRange(me, "ebb", ALLIES))
      for _,ally in ipairs(allies) do
         local enemy = SortByDistance(GetInRange(ally, spells["ebb"].radius, ENEMIES), ally)[1]
         if enemy then
            bounceAlly = SortByDistance( 
               GetInRange(enemy, spells["ebb"].radius, RemoveFromList(ALLIES, ally)), 
               enemy) [1]
            if bounceAlly then
               Cast("flow", ally)
               PrintAction("Flow for triple: ", ally.charName.."->"..enemy.charName.."->"..bounceAlly.charName)
               return true
            end
         end
      end

      -- loop through enemies in order of health and fire at the first one that gets a triple
      local enemies = SortByHealth(GetInRange(me, "ebb", ENEMIES), "ebb")
      for _,enemy in ipairs(enemies) do
         local ally = SortByDistance(GetInRange(enemy, spells["ebb"].radius, ALLIES), enemy)[1]
         if ally then
            bounceEnemy = SortByDistance(GetInRange(ally, spells["ebb"].radius, RemoveFromList(ENEMIES, enemy)), ally)[1]
            if bounceEnemy then
               Cast("ebb", enemy)
               PrintAction("Flow for triple: ", enemy.charName.."->"..ally.charName.."->"..bounceEnemy.charName)
               return true
            end
         end
      end

      -- look for a good double from an injured ally
      local allies = SortByHealth(GetInRange(me, "ebb", ALLIES))
      for _,ally in ipairs(allies) do
         if ally.health + GetSpellDamage("flow") < ally.maxHealth then
            local enemy = SortByDistance(GetInRange(ally, spells["ebb"].radius, ENEMIES), ally)[1]
            if enemy then
               Cast("flow", ally)
               PrintAction("Flow for double: ", ally.charName.."->"..enemy.charName)
               return true
            end
         end
      end

      -- look for a good double from an enemy to an injured ally
      local enemies = SortByHealth(GetInRange(me, "ebb", ENEMIES), "ebb")
      for _,enemy in ipairs(enemies) do
         local ally = SortByDistance(GetInRange(enemy, spells["ebb"].radius, ALLIES), enemy)[1]
         if ally and ally.health + GetSpellDamage("flow") < ally.maxHealth then
            Cast("ebb", enemy)
            PrintAction("Flow for double: ", enemy.charName.."->"..ally.charName)
            return true
         end
      end

      -- don't look for a single for damage
      -- look for a necessary single target heal
      -- if ally is under .5 then heal them no matter what
      -- if ally can use a top off and I'm high mana and we're alone

      local allies = SortByHealth(GetInRange(me, "ebb", ALLIES))
      for i,ally in ipairs(allies) do
         if GetHPerc(ally) < .5 or
            (Alone() and (ally.health + GetSpellDamage("flow")) < ally.maxHealth and GetMPerc() > .9)
         then
            Cast("flow", ally)
            PrintAction("Flow for heal", ally)
            return true
         end
      end

   end

   if CanUse("blessing") then
      -- find all of the allies that have an enemy within 90% of their attack range
      local attackers = {}      
      local allies = GetInRange(me, "blessing", ALLIES)
      for _,ally in ipairs(allies) do
         if #GetInE2ERange(ally, GetAARange(ally)*.9, ENEMIES) > 0 then
            table.insert(attackers, ally)
         end
      end
      if #attackers > 0 then
         -- find the attacker with the highest attack speed
         local attacker = SelectFromList(attackers, function(item) return item.attackSpeed end)
         Cast("blessing", attacker)
         PrintAction("Blessing", attacker)
         return true
      end
   end

   if GetMPerc() > .75 and
      SkillShot("prison", nil, nil, 2) 
   then
      return true
   end
   if SkillShot("prison", nil, nil, 3) then
      return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function onCreate(object)
   PersistBuff("blessing", object, "Nami_Base_E_buf")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

