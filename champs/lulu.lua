require "issuefree/timCommon"
require "issuefree/modules"

pp("\nTim's Lulu")

-- SetChampStyle("caster")
SetChampStyle("support")

InitAAData({
	speed = 1450,
	extraWindup=.2,
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
spells["pixLance"] = copy(spells["lance"])

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
	P.pix = P.pix or me
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
			-- not last hitting with pix because her auto attack is blocked and slow and probably not worth the effort

			if CanUse("lance") then
				local myHits,myKills,myScore    = GetBestLine(me, "lance", .05, .95, MINIONS)
				local pixHits,pixKills,pixScore = GetBestLine(P.pix, "lance", .05, .95, MINIONS)

				local hits = nil
				local kills = nil
				local score = nil
				local lanceSource = nil
				local spellName = "lance"

				if myScore >= pixScore then
					if myScore > GetThreshMP("lance", .1, 1.5) then
						hits = myHits
						kills = myKills
						score = myScore
						spellName = "lance"
						lanceSource = "me"
					end
				else
					if pixScore > GetThreshMP("lance", .1, 1.5) then
						hits = pixHits
						kills = pixKills
						score = pixScore
						spellName = "pixLance"
						lanceSource = "pix"
					end
				end
				if hits then
			      local point = GetCastPoint(hits, "lance")
			      CastXYZ("lance", point)
			      AddWillKill(kills, spellName)
			      PrintAction("Lance from "..lanceSource.." for LH", score)
			      return true
			  	end
			end

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

	-- pix lance
	if CanUse("lance") then
		local enemies = SortByHealth(GetInRange(P.pix, "lance", ENEMIES), "lance")
		for _,e in ipairs(enemies) do
			local point, chance = GetSpellFireahead("lance", e, P.pix)
			if (GetMPerc() > .66 and chance >= 1) or
				chance >= 2 
			then
				CastXYZ("lance", point)
				PrintAction("Lance from Pix", e)
				return true
			end
		end
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