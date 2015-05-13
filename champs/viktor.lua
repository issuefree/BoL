require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: 
-- TODO: 

pp("\nTim's Viktor")

InitAAData({ 
--    speed = 1300,
--    extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["siphon"] = {
   key="Q", 
   range=600, 
   color=violet, 
   base={40,60,80,100,120}, 
   ap=.2,
   --speed=2000,   
   cost={45,50,55,60,65},
   dischargeBonus={20,25,30,35,40,45,50,55,60,70,80,90,110,130,150,170,190,210},
} 
spells["field"] = {
   key="W", 
   range=700, 
   color=yellow, 
   delay=.25,  -- ???
   speed=0,
   radius=300, --???
   noblock=true,
   cost={65}
} 
spells["ray"] = {
   key="E", 
   range=525, 
   length=500,
   color=red, 
   base={70,115,160,205,150}, 
   ap=.7,
   -- TODO handle this line draw effect
   -- delay=.25,
   -- speed=1200,
   -- width=80,
   cost={10,20,30,40,50}
} 
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
   spells["AA"].type = "P"
   spells["AA"].ap = 0
   spells["AA"].bonus = 0
   if P.discharge then
      spells["AA"].type = "M"
      spells["AA"].ap = .5
      spells["AA"].bonus = spells["siphon"].dischargeBonus[me.level]
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
--    local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
--    local score = ScoreCreeps(creep)
--    if AA(creep) then
--       PrintAction("AA "..creep.charName)
--       return true
--    end
-- end   
-- SetAutoJungle(jungle)

local function onCreate(object)
   PersistBuff("discharge", object, "TODO")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

