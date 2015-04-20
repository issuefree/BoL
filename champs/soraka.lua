require "issuefree/timCommon"
require "issuefree/modules"

pp("Tim's Soraka")

SetChampStyle("support")

InitAAData({ 
	speed = 900,
	particles = {"Soraka_Base_BA_mis"}
})

spells["starcall"] = {
	key="Q", 
	range=970,  
	color=violet,    
	base={70,110,150,190,230},
	ap=.35,
	delay=2.4, --?
	speed=1000,  --?
	radius=300-25, -- reticle
	innerRadius=100,
	noblock=true,
	cost={70,75,80,85,90},
}

spells["starcallPinpoint"] = copy(spells["starcall"])
spells["starcallPinpoint"].radius = spells["starcall"].innerRadius

spells["heal"] = {
	key="W", 
	range=550,  
	color=green,  
	base={110,140,170,200,230}, 
	ap=.6,
	type="H",
	cost={20,25,30,35,40}
}

spells["equinox"] = {
	key="E", 
	range=925,  
	color=blue,    
	base={70,110,150,190,230},
	ap=.4,
	delay=2.4+5-3, 
	speed=0, 
	radius=300, -- reticle
	noblock=true,
	cost=70,
}
spells["wish"] = {
	key="R",
	base={150,250,350},
	ap=.55,
	cost=100
}

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=false, key=116, label="Last Hit", auxLabel="{0} / {1}", args={"AA", "starcall"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function Run()
	if CREEP_ACTIVE then
		PrintState(0, "Creep Active")
	end

   if StartTickActions() then
      return true
   end
		
	Wish()

	if IsRecalling(me) then
		PrintAction("Recalling")
		return
	end

   if healTeam("heal") then
   	return true
   end

   if CheckDisrupt("equinox") then
      return true
   end

   if CastAtCC("starcall") or
   	CastAtCC("equinox")
   then
      return true
   end   

	if HotKey() then
		if Action() then
			return true
		end
	end
	
	if IsOn("lasthit") and Alone() then
		if KillMinionsInArea("starcall") then
			return true
		end
	end

   if HotKey() and CanAct() then -- interrupt because this is low priority stuff
      if FollowUp() then
         return true
      end
   end
   EndTickActions()
end 

function Action()
	-- if SkillShot("equinox") then
	-- 	return true
	-- end

	if CanUse("starcall") then
		if GetHPerc() > .75 then -- for harrass and damage
			if GetMPerc() > .9 then -- throw em with abandon
				if SkillShot("starcall") then
					PrintAction("harass", nil, 1)
					return true
				end
			elseif GetMPerc() > .66 then -- lower mana
				if SkillShot("starcallPinpoint") then
					PrintAction("PP", nil, 1)
					return true
			   end
			end
		else -- for healing
			if GetMPerc() > GetHPerc() then -- I have more mana than health. hit something
				if SkillShot("starcall") then
					PrintAction("M > H", nil, 1)
					return true
				end
			else -- I have more health than mana so be carefull but still hit stuff
				if SkillShot("starcall", nil, nil, 3) then
					PrintAction("< M", nil, 1)
					return true
				end
			end
		end
	end

	return false		
end

function FollowUp()
   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end

	if IsOn("clear") and Alone() then

   end

   return false
end

function healTeam()   
   if not CanUse("heal") then return false end

   if GetHPerc(me) < .25 then return false end
      
   local value = GetSpellDamage("heal")

   local spell = GetSpell("heal")

   local bestInRangeT = nil
   local bestInRangeP = 1
   local bestOutRangeT = nil
   local bestOutRangeP = 1
   
   for _,hero in ipairs(ALLIES) do
   	if not IsMe(hero) then
	      if GetDistance(HOME, hero) > GetSpellRange(spell)+250 and
	         hero.health + value < hero.maxHealth*.9 and
	         GetHPerc(me) >= GetHPerc(hero) and
	         not HasBuff("wound", hero) and 
	         not IsRecalling(hero)
	      then
	         if GetDistance(hero) < GetSpellRange(spell) then        
	            if not bestInRangeT or
	               GetHPerc(hero) < bestInRangeP
	            then           
	               bestInRangeT = hero
	               bestInRangeP = GetHPerc(hero)
	            end
	         elseif GetDistance(hero) < GetSpellRange(spell)+250 then
	            if not bestOutRangeT or
	               GetHPerc(hero) < bestOutRangeP
	            then           
	               bestOutRangeT = hero
	               bestOutRangeP = GetHPerc(hero)
	            end
	         end
	      end
	   end
   end
   if bestInRangeT then
      Circle(bestInRangeT, 100, green)
   end
   if bestOutRangeT and GetDistance(me, bestOutRangeT) > GetSpellRange(spell) then
      Circle(bestOutRangeT, 100, yellow, 4)
   end

   if bestInRangeT then
      Cast(spell, bestInRangeT)
      return true
   end
   return false
end

function Wish()
	if not CanUse("wish") then
		return false
	end
	for _,ally in ipairs(ALLIES) do
		if GetHPerc(ally) < .33 then
			for _,enemy in ipairs(ENEMIES) do
				if GetDistance(ally, enemy) < 1000 then
					-- PlaySound("Beep")
					LineBetween(me, ally, 10, greenB)
					-- return false
				end
			end
		end
	end
	return false
end

local function AutoJungle()
   local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end
end   
SetAutoJungle(AutoJungle)

function onCreateObj(object)
end

AddOnTick(Run)