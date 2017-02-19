require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Gangplank")
pp(" - heal up with oranges")
--pp(" - warn for good ult")
pp(" - shoot for lasthit")
pp("if hitting keg will kill multiple minions use it to last hit")

-- track kegs (and their health?)
-- if hitting a keg will hit a champ hit the keg
-- track linked kegs and do above

-- should I place kegs? I'll do them manually for now

InitAAData({
	windup=.25,
	extraRange=15,
	resets={GetSpellInfo("Q").name}
})

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("ult", {on=true, key=115, label="Ult Alert"})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "gun"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["trial"] = {
	base=0,
	bonus=function()
		return 20+(me.level*10)
	end,
	adBonus=1,
	type="T"
}
spells["gun"] = {
	key="Q", 
	range=625, 
	color=violet, 
	base={20,45,70,95,120}, 
	ad=1,
	onHit=true,
	type="P",
	cost=40,
}
spells["oranges"] = {
	key="W",
	base={50,75,100,125,150}, 
	ap=.9,
	bonus=function()
		return (me.maxHealth-me.health)*.15
	end,
	type="H",
	cost={80,90,100,110,120}
}
spells["keg"] = {
	key="E", 
	range=1000, 
	radius=350, --reticle
	color=yellow,
	linkRange=675, -- seems about right
}
spells["barrage"] = {
	key="R",
	base={35,60,85},
	ap=.1,
	area=575, --?
	cost=100,
	waves=12
}

local kegs
local lowKegs
function Run()

	spells["AA"].bonus = 0
	if P.trial then
		spells["AA"].bonus = GetSpellDamage("trial")
	end

	kegs = GetPersisted("keg")
	lowKegs = {}
	for _,keg in ipairs(kegs) do
		if keg.health == 1 then
			table.insert(lowKegs, keg)
		end
	end

   if StartTickActions() then
      return true
   end

	-- if IsOn("ult") and CanUse("barrage") then
	-- 	for _,enemy in ipairs(ENEMIES) do
	-- 		if enemy and enemy.health/enemy.maxHealth < .5 and #GetInRange(enemy, 500, ALLIES) > 0 then
	-- 			PlaySound("Beep")
	-- 		end
	-- 	end
	-- end

	if CanUse("oranges") and
		( GetHPerc(me) < .33 or 
		  GetHPerc(me) < .66 and Alone() )
	then
		PrintAction("oranges")
		Cast("oranges", me)		
		return true
	end

   if HotKey() and CanAct() then
      if Action() then
      	return true
      end
   end

	if IsOn("lasthit") and Alone() then

		if CanUse("gun") then
			local nearKegs = GetInRange(me, "gun", lowKegs)
			local maxScore = 0
			local bestKeg
			for _,keg in ipairs(nearKegs) do
				local score, kills = scoreKegLH(keg)
				if score > maxScore then
					maxScore = score
					bestKeg = keg
				end
			end
			if maxScore >= 2 then
				PrintAction("Hit keg for LH", maxScore)
				Cast("gun", bestKeg)
				return
			end
		end

		if KillMinion("gun", {"far", "lowMana"}, true) then
			return true
		end
	end

   if HotKey() and CanAct() then
	   if FollowUp() then
	   	return true
	   end
	end

	EndTickActions()
end

function Action()
	if CanUse("gun") then
		local nearKegs = GetInRange(me, "gun", lowKegs)
		local maxScore = 0
		local bestKeg
		for _,keg in ipairs(nearKegs) do
			local score, kills = scoreKegChamps(keg)
			if score > maxScore then
				maxScore = score
				bestKeg = keg
			end
		end
		if maxScore >= 1 then
			Cast("gun", bestKeg)
			PrintAction("Hit keg for damage", maxScore)
			return
		end
	end

	if CanUse("gun") then
		local target = GetMarkedTarget() or GetWeakestEnemy("gun")
		if target and Cast("gun", target) then
			PrintAction("Shoot", target)
			return true
		end
	end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end

function scoreKegLH(keg)
	return scoreHits("gun", getKegHits(keg, MINIONS), .05, .95)
end

function scoreKegChamps(keg)
	return scoreHits("gun", getKegHits(keg, ENEMIES), 1, 10)
end

function getKegHits(keg, ...)
	local hits = {}
	for _,lk in ipairs(getLinkedKegs(keg)) do
		hits = concat(hits, GetInRange(lk, spells["keg"].radius, concat(...)))
	end
	return uniques(hits)
end

function getLinkedKegs(keg, remainingKegs, linkedKegs)	
	remainingKegs = remainingKegs or copy(kegs)	
	linkedKegs = linkedKegs or {}

	local nlks = GetInRange(keg, spells["keg"].linkRange, remainingKegs)
	linkedKegs = concat(linkedKegs, nlks)

	if #nlks > 0 then
		remainingKegs = removeItems(remainingKegs, nlks)
		if #remainingKegs > 0 then
			for _,lk in ipairs(linkedKegs) do
				getLinkedKegs(lk, remainingKegs, linkedKegs)
			end
		end
	end

	return linkedKegs
end

function FollowUp()
	return false
end

function onObject(object)
	PersistBuff("trial", object, "Gangplank_Base_P_Buf")
	PersistAll("keg", object, "Barrel")
end

function onSpell(unit, spell)
end

AddOnCreate(onObject)
AddOnSpell(onSpell)

AddOnTick(Run)