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
   cost={70,85,100,115,130}
} 
spells["flow"] = {
   key="W", 
   range=726, 
   color=green, 
   base={65,95,125,155,185}, 
   ap=.3,
   type="H",
   cost={70,85,100,115,130}
} 
spells["blessing"] = {
   key="E",
   range=800, 
   color=yellow, 
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
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

