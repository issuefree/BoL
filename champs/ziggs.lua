require "issuefree/timCommon"
require "issuefree/modules"

-- TODO use satchel in creative ways
-- TODO look for good ults

pp("\nTim's Ziggs")
pp(" - First bounce bomb and long bounce bomb")
pp(" - Satchel for melees")
pp(" - Throw some mines")
pp(" - LH with bombs and mines")
pp(" - Look for decent megas")


InitAAData({ 
   speed=1500,
--    particles = {"TeemoBasicAttack_mis", "Toxicshot_mis"} 
})

SetChampStyle("caster")

AddToggle("", {on=true, key=112, label=""})
AddToggle("", {on=true, key=113, label=""})
AddToggle("", {on=true, key=114, label=""})
AddToggle("", {on=true, key=115, label=""})

AddToggle("lasthit", {on=true, key=116, label="Last Hit", auxLabel="{0}", args={GetAADamage}})
AddToggle("clear", {on=false, key=117, label="Clear Minions"})
AddToggle("move", {on=true, key=118, label="Move"})

spells["fuse"] = {
   base=0, 
   ap=.25,
   byLevel={20,24,28,32,36,40,48,56,64,72,80,88,100,112,124,136,148,160}
} 
spells["bomb"] = {
   key="Q", 
   range=850, 
   color=violet, 
   base={75,120,165,210,255}, 
   ap=.65,
   delay=.35,  -- tss
   speed=1750, -- math
   radius=150, -- wiki
   noblock=true,
   cost={50,55,60,65,70}
}

spells["bombLong"] = copy(spells["bomb"])
spells["bombLong"].noblock=false
spells["bombLong"].width=150
spells["bombLong"].range=1400
spells["bombLong"].speed=950

spells["satchel"] = {
   key="W", 
   range=1000, 
   color=yellow, 
   base={70,105,140,175,210}, 
   ap=.35,
   delay=.25,  -- test
   speed=1200, -- test
   radius=325, -- wiki
   noblock=true,
   cost=65
} 

spells["minefield"] = {
   key="E", 
   range=900, 
   color=orange, 
   base={40,65,90,115,140}, 
   ap=.3,
   delay=.25,  -- test
   speed=2000*3, -- test
   radius=250, -- wiki
   noblock=true,
   cost={70,80,90,100,110}
} 

spells["mega"] = {
   key="R", 
   range=5300, 
   color=red, 
   base={200,300,400}, 
   ap=.72,
   delay=2,  -- wiki
   speed=3500, -- wiki+math
   radius=550, -- wiki
   noblock=true,
   cost=100
} 


function Run()
   spells["AA"].bonus = 0
   if P.fuse then
      spells["AA"].bonus = GetSpellDamage("fuse")
   end

   if StartTickActions() then
      return true
   end

   -- auto stuff that always happen
   if CheckDisrupt("satchel") then
      return true
   end

   if CastAtCC("bomb") or
      CastAtCC("minefield")
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
         if KillMinionsInArea("bomb") then
            return true
         end
         if KillMinionsInArea("minefield") then
            return true
         end
      end
   end
   
   if HotKey() and CanAct() then
      if FollowUp() then
         return true
      end
   end

   if CanUse("mega") then
      local hits, kills, score = GetBestArea(me, "mega", 1, 5, ENEMIES)
      if hits[1] then
         LineBetween(me, hits[1])
      end
      if score > 2 then
         LineBetween(me, GetCenter(hits), 100, red)
         Circle(GetCenter(hits), spells["mega"].radius)
      end
   end

   EndTickActions()
end

function Action()
   -- TestSkillShot("bomb", "_mis_01")

   if SkillShot("bomb") then
      return true
   end

   if SkillShot("minefield") then
      return true
   end

   if CanUse("satchel") then
      local melee = SortByDistance(GetInRange(me, 250, ENEMIES))[1]
      if melee then
         CastXYZ("satchel", Projection(me, melee, GetDistance(melee)/2))
         PrintAction("Satchel to clear melee", melee)
         return true
      end
   end

   if SkillShot("bombLong", nil, nil, 2.5) then
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

local function onCreate(object)
   PersistBuff("fuse", object, "Ziggs_Base_P_buf")
   Persist("satchel", object, "Ziggs_Base_W_aoe_green.troy")
end

local function onSpell(unit, spell)
end

AddOnCreate(onCreate)
AddOnSpell(onSpell)
AddOnTick(Run)

