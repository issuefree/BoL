require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Twisted Fate")

InitAAData({
	baseAttackSpeed = 0.651,
	speed = 1500, windup=.4,
	particles = {"TwistedFateBasicAttack_mis", "TwistedFateStackAttack_mis", "PickaCard_blue", "PickaCard_red", "PickaCard_yellow"}	
})

local card = "blue"
local gating = false

function getCard()
   return card
end

AddToggle("pick", {on=true, key=112, label="Auto Pick", auxLabel="{0}", args={getCard}})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["wild"] = {
	key="Q", 
	range=1450, 
	color=violet, 
	base={60,110,160,210,260}, 
	ap=.65,
	delay=.2,
	speed=1000,
	width=75,
	cost={60,70,80,90,100},
	noblock=true
}
spells["pick"] = {
	key="W",
	cost={40,55,70,85,100}
}
spells["blue"] = {
	key="W", 
	range=GetAARange, 
	type="e2e",
	base={40,60,80,100,120}, 
	ap=.5,
	type="M"
}
spells["red"] = {
	key="W", 
	range=GetAARange, 
	type="e2e",
	base={30,45,60,75,90}, 
	ap=.5, 
	type="M"
}
spells["gold"] = {
	key="W", 
	type="e2e",
	range=GetAARange, 
	base={15,22.5,30,37.5,45}, 
	ap=.5, 
	type="M"
}

spells["stacked"] = {
	key="E", 
	range=GetAARange, 
	type="e2e",
	base={55,80,105,130,155}, 
	ap=.5, 
	type="M"
}

spells["card"] = nil

function canPick()
	return CanUse("pick") and not selecting and not P.card
end

function pick()
	Cast("pick", me)
end

selecting = false
function Run()
	if find(GetSpellInfo("W").name, "lock") then
		selecting = true
	else
		selecting = false
	end

	if selecting and not P.card and find(GetSpellInfo("W").name, card) then		
		if IsOn("pick") then
			CastSpell(_W)			
			
			PrintAction("Pick "..card, nil, .5)
		end
	end

	if not P.card then
      spells["card"] = nil
   end

   if Alone() and not gating then
   	card = "blue"
   else
   	card = "gold"
   end

   spells["AA"].bonus = GetSpellDamage("card")
   if P.stacked then 
   	spells["AA"].bonus = spells["AA"].bonus + GetSpellDamage("stacked")
   end

   if StartTickActions() then
      return true
   end

   if CastAtCC("wild") then
      return true
   end

	if HotKey() and CanAct() then
      if Action() then
      	return true
      end         
   end

   if canPick() and
      not gating and
   	VeryAlone() and
   	#GetInRange(me, "AA", MINIONS) >= 3 and
   	GetMPerc(me) < .9 
   then
   	pick()
   end

	if IsOn("lasthit") and Alone() and not gating then

		if canPick() then
			local minions = GetInAARange(me, MINIONS)
			for _,minion in ipairs(minions) do
            if minion.health < GetAADamage(minion)+GetSpellDamage(card, minion) and
            	not WillKill("AA", minion)
            then
            	pick()
					PrintAction("Pick for lasthit")
					return true
            end
         end
		end

		-- TODO last hitter with wild (three line bestinline)

	end

	EndTickActions()
end

selectStart = 0
function Action()
   if IsOn("pick") and canPick() then
   	if GetWeakestEnemy("AA",100) then
	      pick()
	      PrintAction("Picking action card", card)
     	end
   end

   if SkillShot("wild") then
   	return true
   end

   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
   if AutoAA(target) then
      return true
   end
   return false
end

function onCreateObj(object)
	if PersistBuff("card", object, "Card_", 200) then
		if find(object.name, "gold") then
			spells["card"] = spells["gold"]
		elseif find(object.name, "red") then
			spells["card"] = spells["red"]
		elseif find(object.name, "blue") then
			spells["card"] = spells["blue"]
		end
	end

	Persist("stacked", object, "stackready")
end

function onSpell(unit, spell)
--Destiny, gate
	if IsMe(unit) then
		
		if spell.name == "Destiny" then
         card = "gold"         
         gating = true
         if IsOn("pick") and canPick() then
            pick()
         end
      end

		if spell.name == "gate" then
         gating = false
      end
      
	end
end

AddOnSpell(onSpell)
AddOnCreate(onCreateObj)
AddOnTick(Run)