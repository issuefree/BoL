require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: 
-- TODO: 

pp("\nTim's Viktor")

InitAAData({ 
   speed = 2300,
   -- extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0} / {1} / {2}", args={GetAADamage, "siphon", "ray"}})
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
}
spells["discharge"] = {
   base=function() return spells["discharge"].dischargeBonus[me.level] end,
   ap=.5,
   type="M",
   dischargeBonus={20,25,30,35,40,45,50,55,60,70,80,90,110,130,150,170,190,210},
}
spells["field"] = {
   key="W", 
   range=700, 
   color=blue, 
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
   color=yellow, 
   base={70,115,160,205,250}, 
   ap=.7,
   delay=.25,
   speed=1200,
   width=100, -- reticle (looks more like 105 or 110 but 100 will do)
   cost={70,80,90,100,110}
} 
spells["storm"] = {
   key="R", 
   range=700, 
   color=red, 
   base={150,250,350}, 
   ap=.55,
   delay=.25,  -- ???
   speed=0,    -- ???
   radius=325, -- wiki
   cost=100
} 

function getBestAutoRay(targets, hs, ks)
   hs = hs or .05
   ks = ks or .95
   targets = SortByDistance(GetInRange(me, GetSpellRange("ray")+spells["ray"].length, targets))
   local bestT, bestS = SelectFromList(targets, 
      function(target)
         local hits = GetInLine(target, "ray", Projection(me, target, GetDistance(target)+spells["ray"].length), targets)
         if #hits == 0 then
            return 0
         end
         local farHit = SortByDistance(hits)[#hits]
         local rayStart = Projection(farHit, me, spells["ray"].length)
         if not IsInRange("ray", rayStart) then
            return nil, 0
         end
         return scoreHits("ray", hits, hs, ks)
      end
   )
   return bestT, bestS
end

function getBestRay(targets, hs, ks)
   hs = hs or .05
   ks = ks or .95
   targets = SortByDistance(GetInRange(me, GetSpellRange("ray")+spells["ray"].length, targets))
   local bestP = nil
   local bestT = nil
   local bestS = 0
   for i=1,#targets,1 do
      local t1 = targets[i]
      for j=i+1,#targets,1 do
         local t2 = targets[2]
         local rayEnd = Projection(t1, t2, spells["ray"].length)
         local hits = GetInLine(t1, "ray", rayEnd, targets)
         local farHit = SortByDistance(hits)[#hits]
         local rayStart = Projection(farHit, t1, spells["ray"].length)
         if IsInRange("ray", rayStart) then
            local score = scoreHits("ray", hits, hs, ks)
            if score > bestS then
               bestT = farHit
               bestP = rayStart
               bestS = score
            end
         end
      end
   end
   return bestP, bestT, bestS
end

function Run()
   spells["AA"].type = "P"
   spells["AA"].bonus = 0
   if P.discharge then
      spells["AA"].type = "M"
      spells["AA"].bonus = GetSpellDamage("discharge")
   end

   if StartTickActions() then
      return true
   end

   -- seems silly to throw ult for disrupting but it will disrupt...
   -- if CheckDisrupt("storm") then
   --    return true
   -- end

   if CastAtCC("field") 
      -- or CastAtCC("ray")
   then
      return true
   end

	if HotKey() and CanAct() then
		if Action() then
			return true
		end
	end

   if IsOn("lasthit") then
      if Alone() then

         -- siphon is a pretty good last hitter but it doesn't do that much more damage than my auto attack early
         -- the normal rules should be sufficient (out of aa range, just attacked or it requires more than 50% more than an AA)
         -- but it seems to fire more than that.
         -- I also don't want to waste the secondary effect of the spell (big damage on next attack)
         -- I think only siphon for last hit if I can follow up with a charged last hit
         local target = KillMinion("siphon", nil, nil, true)
         if target then
            local minions = SortByHealth(GetInAARange(me, MINIONS))
            minions = RemoveFromList(minions, target)
            for _,minion in ipairs(minions) do
               if GetSpellDamage("discharge", minion) + GetAADamage(minion) > minion.health and
                  GetAADamage(minion) < minion.health
               then
                  Cast("siphon", target)
                  PrintAction("Siphon for LH and discharge LH")
                  return true
               end
            end
         end

         --[[ Alrighty. Free BoL can't handle 2 phase spells like ray.
            If I cast ray it will take the cast position and draw straight out from me.
            This clearly isn't ideal but I can check to see if that line is the best (or good enough)
            and autocast that. If there's a significantly better line I can draw it and manually cast it.
         ]]

         if CanUse("ray") then
            -- lookin for trajectories...
            -- Since I know I want to kill minions lets find all of the minions I can kill in range+length
            -- sort them by distance and look at the out vector of all trajectories
            -- from a willkill look at the next furthest willkill
            -- draw the line and score it

            local targetA, scoreA = getBestAutoRay(MINIONS)
            local targetB1, targetB2, scoreB = getBestRay(MINIONS)

            -- if my auto cast is pretty close to the best possible just throw it.
            if scoreA*1.25 > scoreB and scoreA > GetThreshMP("ray", .1, 2) then
               CastXYZ("ray", targetA)
               PrintAction("Ray for LH", scoreA)
               return true
            else
               if scoreB > GetThreshMP("ray", .1, 2) then
                  LineBetween(targetB1, Projection(targetB1, targetB2, spells["ray"].length), spells["ray"].width, spells["ray"].color)
               end
            end

         end

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
   if CastBest("siphon") then
      return true
   end

   if CanUse("ray") then
      -- check for executes
      local targets = GetInRange(me, GetSpellRange("ray")+spells["ray"].length, ENEMIES)
      local kill = SortByDistance(GetKills("ray", targets))[1]
      if kill then
         CastXYZ("ray", GetCastPoint(kill, "ray"))
         PrintAction("Ray for execute", kill)
         return true
      end

      -- check for max hits
      local hit, score = getBestAutoRay(ENEMIES, 1, 5)
      if score >= 2 or (score >= 1 and #targets == 1) then
         CastXYZ("ray", GetCastPoint(hit, "ray"))
         PrintAction("Ray for hits", score)
         return true
      end

   end

   if SkillShot("field") then
      return true
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
   PersistBuff("discharge", object, "Viktor_Base_Q_Aug_Buff.troy", 200)
   Persist("storm", object, "Viktor_ChaosStorm_green.troy")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

