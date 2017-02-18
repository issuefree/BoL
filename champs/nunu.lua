require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Nunu")

InitAAData({ 
})

AddToggle("boil",  {on=true, key=112, label="Boil ADC"})
AddToggle("blast", {on=true, key=113, label="Auto Blast", auxLabel="{0}", args={"iceblast"}})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "consume"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})


spells["consume"] = {
	key="Q",
	range=225,
	base={400,550,700,850,1000},
	type="T",
	color=yellow,
	cost=60,
	baseCost=60,
}
spells["fed"] = {
	key="Q",
	base={70,115,160,205,250},
	type="H",
	ap=.75,
	cost=60,
	baseCost=60,
}
spells["boil"] = {
	key="W", 
	range=700,  
	color=green,
	cost=50,
	baseCost=50
}
spells["iceblast"] = {
	key="E", 
	range=550,  
	color=violet, 
	base={80,120,160,200,240}, 
	type="M",
	ap=.9,
	cost={70,75,80,85,90},
	baseCost={70,75,80,85,90},
}
spells["zero"] = {
	key="R", 
	range=650, 
	color=red,    
	base={625,875,1125}, 
	ap=2.5,
	type="M",
	cost=100,
	baseCost=100,
	channel=true,
	name="AbsoluteZero",
	object="AbsoluteZero2_green_cas"
}

local lastBoil = time()

function canBoil()
	return CanUse("boil") and
	       time() - lastBoil > 12
end

function boilADC()
	if ADC and
	   ADC.name ~= me.name and
	   GetDistance(ADC) < GetSpellRange("boil")
	then
		Cast("boil", ADC)
		PrintAction("Boil", ADC)
		return true
	end
	return false
end

function Run()
	if P.visionary then
		spells["consume"].cost = 0
		spells["fed"].cost = 0
		spells["boil"].cost = 0
		spells["iceblast"].cost = 0
		spells["zero"].cost = 0
	else
		spells["consume"].cost = spells["consume"].baseCost
		spells["fed"].cost = spells["fed"].baseCost
		spells["boil"].cost = spells["boil"].baseCost
		spells["iceblast"].cost = spells["iceblast"].baseCost
		spells["zero"].cost = spells["zero"].baseCost
	end

   if StartTickActions() then
      return true
   end

	if HotKey() then 
		if Action() then
			return true
		end
	end

	if IsOn("lasthit") then
		if me.maxHealth - me.health > GetSpellDamage("fed") then
			if KillMinion("consume", "burn", true) then
				return true
			end
		end
	end

	EndTickActions()
end

function Action()
	if IsOn("boil") and canBoil() then
		if boilADC() then
			return true
		end
	end
	
	if IsOn("blast") then
		if CanUse("iceblast") then
			if EADC and GetDistance(EADC) < GetSpellRange("iceblast") then
				Cast("iceblast", EADC)
				PrintAction("Iceblast EADC", EADC)
				return true
			else
				local target =  GetMarkedTarget() or GetWeakestEnemy("iceblast")
				if target then
					Cast("iceblast", target)
					PrintAction("Iceblast", target)
					return true
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

local function jungle()
   local camp = GetInRange(me, "iceblast", CREEPS)
   local creep = GetBiggestCreep(camp)
   local campScore = ScoreCreeps(camp)

   -- I don't want to spam spells if I'm low mana
   -- I don't want to waste spells if I don't need them for the camp
   -- Using spells on 3+ pt camps will help with success (more health, less risk, enable ganking (can't gank with low health))
   -- Using spells on 2 pt camps will help with speed at the cost of mana
   -- Don't use spells on 1 pt camps.

   if CanUse("consume") then
   	if campScore >= GetThreshMP("consume", .05, 2) then
	   	if VeryAlone() then
	   		Cast("consume", creep)
	   		PrintAction("Consume biggest creep", creep)
	   		return true
	   	end
	   end

   	-- if there are any enemies nearby make sure we consume for the kill
   	-- we do not want to have buffs/dragon/baron stolen
   	if ScoreCreeps(creep) >= 4 and
   		WillKill("consume", creep) 
   	then
   		Cast("consume", creep)
   		PrintAction("Consume for jungle kill secure", creep)
   		return true
   	end
   end

   if CanUse("iceblast") then
   	if campScore >= GetThreshMP("iceblast", .05, 3) then
   		-- I want to iceblast for big damage and AS slow
   		-- I don't want to blow an iceblast into a nearly dead creep
   		if not WillKill("iceblast", creep) then
	   		Cast("iceblast", creep)
	   		PrintAction("Iceblast in jungle", creep)
	   		return true
	   	end
   	end
   end


   if canBoil() then
   	-- boil if it's less than 15% of my mana
   	if 1 >= GetThreshMP("boil", .15, 0) then
	   	if boilADC() then
	   		return true
	   	end
	   	
	   	local targets = GetInRange(me, "boil", ALLIES, MYMINIONS)
	   	if targets[1] and 
	   		( not IsMe(targets[1]) or not targets[2] )
	   	then
	   		Cast("boil", targets[1])
	   		PrintAction("Boil near")
	   		return true
	   	end

	   	Cast("boil", me)
	   	PrintAction("Boil me in the jungle")
	   	return true
	   end
   end

   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end
end   
SetAutoJungle(jungle)

local function onObject(object)
	PersistBuff("Nunu_Base_P_Free_buff", object, "Visionary_buf")
end

local function onSpell(unit, spell)
	if ICast("boil", unit, spell) then
		lastBoil = time()
	end
end

AddOnCreate(onObject)
AddOnSpell(onSpell)
AddOnTick(Run)