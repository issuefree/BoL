require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: track thirst/price counter
-- TODO: track if I'm thirst or price

pp("\nTim's Aatrox")

InitAAData({ 
--    speed = 1300,
--    minMoveTime = 0,
--    extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("dive", {on=false, key=112, label="Dive"})
AddToggle("ult", {on=false, key=113, label="Auto Ult"})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["flight"] = {
   key="Q", 
   range=650, 
   color=yellow, 
   base={70,115,160,205,250}, 
   adBonus=.6,
   delay=.25,  -- ???
   speed=1200, -- ???
   radius=GetWidth(me),
   noblock=true,
   cost=0
} 
spells["thirst"] = {
   key="W", 
   base={20,25,30,35,40}, 
   adBonus=.25,
   scale=function()
      if GetHPerc(me) < .5 then
         return 3
      end
   end,
   type="H",
   cost=0,
}
spells["price"] = {
   key="W", 
   base={60,95,130,165,200}, 
   adBonus=1,
   type="P",
   cost=0,
} 

spells["blades"] = {
   key="E", 
   range=1000, 
   color=violet, 
   base={75,110,145,180,215}, 
   ap=.6,
   bonusAd=.6,
   type="M",
   delay=.25,  -- ???
   speed=1200, -- ???
   width=80,   -- ???
   noblock=true,
   cost=0
} 

spells["massacre"] = {
   key="R", 
   range=550, 
   color=red, 
   base={200,300,400}, 
   ap=1,
   cost=0,
} 

spells["AA"].damOnTarget = 
   function(target)
      if P.price and bloodStacked then
         return GetSpellDamage("price")
      end
   end

local bloodStacked = false

function Run()
   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if IsOn("dive") and CheckDisrupt("dive") then
      return true
   end

   if CastAtCC("blades") then
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
         if KillMinionsInLine("blades") then
            return true
         end
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
   -- TestSkillShot("blades")

   if SkillShot("blades") then
      return true
   end

   if IsOn("dive") then
      if Skirmishing() then
         local hits, kills, score = GetBestArea(me, "flight", 1, 5, ENEMIES)
         if score >= 2 then
            CastXYZ("flight", GetCastPoint(hits, "flight"))
            PrintAction("Dive dive dive", #hits)
            return true
         end
      end

      local target = GetSkillShot("flight")
      if WillKill("flight", "AA", "blades", "massacre", target) then
         CastFireahead("flight", target)
         PrintAction("Dive for execute", target)
         return true
      end
   end

   if IsOn("ult") then
      local inRange = GetInRange(me, "massacre", ENEMIES)
      local stretchRange = GetInRange(me, GetSpellRange("massacre")+100, ENEMIES)
      if #inRange >= 2 and #stretchRange <= #inRange then
         Cast("massacre", me)
         PrintAction("Massacre for AoE", #inRange)
         return true
      end

   end

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
   PersistBuff("thirst", object, "TODO")
   PersistBuff("price", object, "TODO")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

