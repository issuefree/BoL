require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Lulu")

-- SetChampStyle("caster")
SetChampStyle("support")

InitAAData({
	speed = 2500,
	particles = {"LuluBasicAttack"}
})

spells["pix"] = {
	base=function() return 9 + math.floor((me.level-1)/2)*12 end,
	ap=.15,
	leash=2000,
	allyTimeout=6,
	otherTimeout=4
}

spells["lance"] = {
	key="Q", 
	range=925, 
	color=violet, 
	base={80,125,170,215,260}, 
	ap=.5,
	delay=.26, -- testskillshot
	speed=1500, -- testskillshot
	width=50,
	noblock=true,
	cost={60,65,70,75,80}
}
spells["doubleLance"] = copy(spells["lance"])
spells["doubleLance"].base = mult(spells["lance"].base, 2)
spells["doubleLance"].ap = spells["lance"].ap * 2

spells["whimsy"] = {
	key="W", 
	range=650,  
	color=yellow,
	cost=65,
}
spells["help"] = {
	key="E", 
	range=650,  
	color=blue,  
	base={80,110,140,170,200}, 
	ap=.4,
	cost={60,70,80,90,100}
}
spells["growth"] = {
	key="R", 
	range=900,
	radius=150,
	color=green,  
	base={300,450,600}, 
	ap=.5,
	cost=100
}

AddToggle("shield", {on=true, key=112, label="Auto Shield", auxLabel="{0}", args={"help"}})
AddToggle("ult", {on=true, key=113, label="Auto Ult"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1}", args={GetAADamage, "lance"}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

function Run()
   if StartTickActions() then
      return true
   end

   if IsOn("ult") and CanUse("growth") then
      local targets = GetInRange(me, "growth", ALLIES)
      local bestT
      local bestP
      for _,target in ipairs(targets) do
         local tp = GetHPerc(target)
         if tp < .2 and #GetInRange(target, 500, ENEMIES) > 0 then
            if not bestT or tp < bestP then
               bestT = target
               bestP = tp
            end
         end
      end
      if bestT then
         Cast("growth", bestT)
         PrintAction("Save", bestT)
         return true
      end
   end


   if CheckDisrupt("whimsy") then
      return true
   end

   if CastAtCC("lance") then
   	return true
   end


	if HotKey() then
		if Action() then
			return true
		end
	end

	if IsOn("lasthit") then
		if Alone() then
			local killsNeeded = 2
			if KillMinionsInLine("lance", killsNeeded) then
				return true
			end

			-- weird angles on pix and since I can't detect pix makes creative stuff hard.
			-- no longer true. can do creative stuff

			-- if IsMe(P.pix) or not P.pix then
			-- 	if KillMinionsInLine("doubleLance", 2) then
			-- 		return true
			-- 	end
			-- else
			-- 	local myHits,myKills = GetBestLine(me, "lance", .5, .5, MINIONS)
			-- 	local pixHits = GetInLine(P.pix, "lance", GetAngularCenter(myHits), MINIONS)
			-- 	local pixKills = GetKills("lance", pixHits)

			-- 	-- things both lances hit but neither killed
			-- 	local bothHits = GetIntersection(myHits, pixHits)
			-- 	bothHits = RemoveFromList(bothHits, myKills)
			-- 	bothHits = RemoveFromList(bothHits, pixKills)

			-- 	pixKills = RemoveFromList(pixKills, myKills)
			-- 	local allKills = concat(myKills, pixKills)				

			-- 	for _,hit in ipairs(bothHits) do
			-- 		if WillKill("doubleLance", hit) then
			-- 			table.insert(allKills, hit)
			-- 		end
			-- 	end

			-- 	if #allKills >= killsNeeded then
			-- 		CastXYZ("lance", GetAngularCenter(myHits))
			-- 		AddWillKill(allKills, "lance")
			-- 		PrintAction("Lance for LH", #allKills)
			-- 		return true
			-- 	end
			-- end
		end
	end

   if HotKey() then
      if FollowUp() then
         return true
      end
   end

   EndTickActions()	
end 

function Action()
	-- TestSkillShot("lance")

	if CanUse("growth") and IsOn("ult") then
		for _,ally in ipairs(ALLIES) do
			if #GetInRange(ally, spells["growth"].radius + GetWidth(ally), ENEMIES) >= 2 then
				Cast("growth", ally)
				PrintAction("POPUP!")
				return true
			end
		end
	end

	if SkillShot("lance") then
		return true
	end

	if IsMe(P.pix) or not P.pix then
	   local target = GetMarkedTarget() or GetWeakestEnemy("AA")
	   if AutoAA(target) then
	      return true
	   end
	end

	return false
end

function FollowUp()
   return false
end

local function onCreate(object)
	Persist("pix", object, "RobotBuddy")
end

local function onSpell(unit, spell)
	if IsOn("shield") then
		CheckShield("help", unit, spell)
	end
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)