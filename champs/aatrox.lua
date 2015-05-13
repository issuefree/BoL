require "issuefree/timCommon"
require "issuefree/modules"

-- TODO: track thirst/price counter
-- TODO: track if I'm thirst or price

pp("\nTim's Aatrox")
pp(" - Manage thirst/price depending on health")
pp(" - Hit stuff if I'm low health to power thirst")
pp(" - Dive disrupt")
pp(" - Blades/Flight LH")
pp(" - Some diving (could be better)")
pp(" - Some auto ult (could be better)")
pp(" - Jungle")

InitAAData({ 
   extraWindup=.1,
--    speed = 1300,
--    minMoveTime = 0,
--    extraRange=-20,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

-- SetChampStyle("marksman")
-- SetChampStyle("caster")

AddToggle("dive", {on=false, key=112, label="Dive"})
AddToggle("ult", {on=true, key=113, label="Auto Ult"})
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
   radius=250-25, -- reticle
   kbRadius=150,
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
   delay=.35,  -- tss
   speed=1200, -- tss
   width=80,   -- ??? I don't really have anything for this shape
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
      if P.priceStacked then
         return GetSpellDamage("price")
      end
   end


function Run()
   spells["AA"].bonus = 0
   if P.priceStacked then
      spells["AA"].bonus = GetSpellDamage("price")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if IsOn("dive") and CheckDisrupt("flight") then
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

   if P.price then
      if VeryAlone() and GetHPerc() < .9 then
         Cast("thirst", me)
         PrintAction("Thirst alone to top off")
         return true
      end

      if GetHPerc() < .5 then
         Cast("thirst", me)
         PrintAction("Thirst to heal")
         return true
      end
   end

   if P.thirst then
      if GetHPerc() > .9 then
         Cast("price", me)
         PrintAction("Price since I'm full")
         return true
      end

      if Engaged() and GetHPerc() > .75 then
         Cast("price", me)
         PrintAction("Price for damage") -- since I'm full enough
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

      if VeryAlone() then
         if KillMinionsInArea("flight", 2) then
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

   if HotKey() then
      if P.thirst and GetHPerc(me) < .5 then
         if HitMinion("AA", "strong") then
            return true
         end
      end
   end
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
      if target then
         if WillKill("flight", "AA", "blades", "massacre", target) then
            CastFireahead("flight", target)
            PrintAction("Dive for execute", target)
            return true
         end
      end
   end

   if IsOn("ult") then
      local inRange = GetInRange(me, "massacre", ENEMIES)
      if Skirmishing() and #inRange >= 2 then
         Cast("massacre", me)
         PrintAction("Massacre for AoE", #inRange)
         return true
      end

      if not CanUse("flight") and not CanUse("blades") and CanUse("massacre") then
         local target = GetKills(GetInRange(me, "massacre"))[1]
         if target then
            Cast("massacre", me)
            PrintAction("Massacre for execute")
            return true
         end
      end


   end

   local target = GetMarkedTarget() or GetMeleeTarget()
   if AutoAA(target) then
      return true
   end

   return false
end
function FollowUp()
   return false
end

local function jungle()
   if CanUse("flight") then
      local hits, kills, score = GetBestArea(me, "flight", 1, .5, CREEPS)
      if score >= 3 then
         CastXYZ("flight", GetCastPoint(hits, "flight"))
         PrintAction("Flight in the jungle", score)
         return true
      end
   end

   if CanUse("blades") then
      local hits, kills, score = GetBestLine(me, "blades", 1, .5, CREEPS)
      if #hits >= 1 then
         CastXYZ("blades", GetCastPoint(hits, "blades"))
         PrintAction("Blades in the jungle", score)
         return true
      end
   end

   local creep = GetBiggestCreep(GetInRange(me, "AA", CREEPS))
   -- local score = ScoreCreeps(creep)
   if AA(creep) then
      PrintAction("AA "..creep.charName)
      return true
   end
end   
SetAutoJungle(jungle)

local function onCreate(object)
   PersistBuff("thirst", object, "Aatrox_Base_W_WeaponLife.troy")
   PersistBuff("price", object, "Aatrox_Base_W_WeaponPower.troy")

   PersistBuff("thirstStacked", object, "Aatrox_Base_W_Buff_Life.troy")
   PersistBuff("priceStacked", object, "Aatrox_Base_W_Buff_Power.troy")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

