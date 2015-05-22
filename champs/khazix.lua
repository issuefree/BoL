require "issuefree/timCommon"
require "issuefree/modules"



pp("\nTim's Kha'Zix")

InitAAData({ 
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
      if target and HasBuff("isolated", target) then
         return 1.3
      end
   end,
   damOnTarget=
} 
spells["claws"] = 
--spells["binding"] = {
--    key="W", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=.25,
--    speed=1200,
--    width=80,
--    cost={10,20,30,40,50}
--} 
--spells["binding"] = {
--    key="E", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=.25,
--    speed=1200,
--    width=80,
--    cost={10,20,30,40,50}
--} 
--spells["binding"] = {
--    key="R", 
--    range=1175, 
--    color=violet, 
--    base={60,110,160,210,260}, 
--    ap=.7,
--    delay=.25,
--    speed=1200,
--    width=80,
--    cost={10,20,30,40,50}
--} 

spells["AA"].damOnTarget = 
   function(target)
      return 0
   end

function Run()
   spells["AA"].bonus = 0
   if P.threat then
      spells["AA"].bonus = GetSpellDamage("threat")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("binding") then
      return true
   end

   if CastAtCC("pillar") then
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

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   -- local target = GetMarkedTarget() or GetMeleeTarget()
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
   PersistBuff("threat", object, "TODO")
   PersistOnTargets("isolated", object, "TODO", ENEMIES)

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

