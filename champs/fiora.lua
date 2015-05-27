require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: Keep duelist active by hitting minions

pp("\nTim's Fiora")

InitAAData({ 
--    speed = 1300,
--    extraRange=-20,
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
   onHit=true,
   radius=400, -- TODO TEST this is how far I jump around
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
   if CanUse("burst") then
      if #GetInAARange(me, ENEMIES) > 0 then
         Cast("burst", me)
         PrintAction("Burst of speed")
         return true
      end
   end

   if CanUse("lunge") then
      -- TODO lunge code here
      -- do I want to burst of speed in here? probably
   end

   if CanUse("waltz") then
      -- TODO waltz code here
   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function FollowUp()
   if GetHPerc() < .95 and not P.duelist then
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
   PersistBuff("duelist", object, "TODO")

   -- if GetDistance(object) < 150 then
   --    pp(object.name)
   -- end
end

local function onSpell(unit, spell)
   if CanUse("riposte") then
      if IsEnemy(unit) and spell.target and IsMe(spell.target) then
         if find(spell.name, "attack") then -- is there a better way to detect enemy auto attacks?
            if unit.totalDamage > 100 or unit.totalDamage > me.totalDamage then
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

