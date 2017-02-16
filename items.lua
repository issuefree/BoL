ITEMS = {}

--Active offense
ITEMS["Bilgewater Cutlass"]       = {id=3144, name="BilgewaterCutlass", range=550, itemType="active", color=violet}
ITEMS["Hextech Gunblade"]         = {id=3146, name="HextechGunblade", range=700, itemType="active", color=violet}
ITEMS["Blade of the Ruined King"] = {id=3153, name="ItemSwordOfFeastAndFamine", range=550, itemType="active", color=violet}
ITEMS["Tiamat"]                   = {id=3077, name="ItemTiamatCleave", range=400-25, ad=.6, itemType="active", color=red}
ITEMS["Ravenous Hydra"]           = {id=3074, name="ItemTiamatCleave", range=400-25, ad=.6, itemType="active", color=red}
ITEMS["Frost Queen's Claim"]      = {id=3092, name="ItemGlacialSpikeCast", range=600, itemType="active", radius=200, color=blue}

ITEMS["Randuin's Omen"]           = {id=3143, name="RanduinsOmen", range=500, itemType="active", color=yellow}

ITEMS["Entropy"]			      = {id=3184, name="OdinEntropicClaymore"}
ITEMS["Youmuu's Ghostblade"]      = {id=3142, name="YoumusBlade", itemType="active"}

--Active defense
ITEMS["Locket of the Iron Solari"] = {id=3190, name="IronStylus", range=700, itemType="active", color=green}
ITEMS["Locket of the Iron Solari Aura"] = {id=3190, range=1200, itemType="aura", color=green}
ITEMS["Guardian's Horn"] = {id=2051, name="ItemHorn", itemType="active"}
ITEMS["Zhonya's Hourglass"] = {id=3157, name="ZhonyasHourglass", itemType="active"}
ITEMS["Seraph's Embrace"] = {id=3040, name="ItemSeraphsEmbrace", itemType="active"}


--Aura offense
ITEMS["Abyssal Scepter"] = {id=3001, range=700, itemType="aura", color=violet}
ITEMS["Frozen Heart"]    = {id=3110, range=700, itemType="aura", color=blue}

--Aura Defense
ITEMS["Mana Manipulator"]     = {id=3037, range=1200, itemType="aura", color=blue}
ITEMS["Aegis of Legion"]      = {id=3105, range=1200, itemType="aura", color=green}
ITEMS["Banner of Command"]    = {id=3060, range=1000, itemType="aura", color=yellow}
ITEMS["Emblem of Valor"]      = {id=3097, range=1200, itemType="aura", color=green}
ITEMS["Runic Bulwark"]        = {id=3107, range=1200, itemType="aura", color=green}
ITEMS["Zeke's Herald"]        = {id=3050, range=1200, itemType="aura", color=yellow}

--Active cleanse
ITEMS["Quicksilver Sash"]   = {id=3140, name="QuicksilverSash", itemType="active"}
ITEMS["Mercurial Scimitar"] = {id=3139, name="ItemMercurial", itemType="active"}
ITEMS["Mikael's Crucible"]  = {id=3222, name="ItemMorellosBane", range=750, itemType="active"}

--On Hit
ITEMS["Wit's End"] = {id=3091, base={42}, itemType="M"}
ITEMS["Nashor's Tooth"] = {id=3115, name="Malady", base={15}, ap=.15, itemType="M"}
ITEMS["Kitae's Bloodrazor"] = {id=3186, itemType="M"}
ITEMS["Madred's Razors"] = {id=3106, base=50, itemType="M"}
ITEMS["Wriggle's Lantern"] = {id=3154, base=75, itemType="M"}
ITEMS["Feral Flare"] = {id=3160, base=25, itemType="M"}

ITEMS["Sheen"]         = {id=3057, base={0}, adBase=1, itemType="P"}
ITEMS["Trinity Force"] = {id=3078, base={0}, adBase=2, itemType="P"}
ITEMS["Lich Bane"]     = {id=3100, base={50}, ap=.75, itemType="M"}
ITEMS["Iceborn Gauntlet"] = {id=3025, base={0}, adBase=1.25, itemType="P"}

-- Tear
ITEMS["Tear of the Goddess"] = {id=3070, name="TearsDummySpell"}
ITEMS["Archangel's Staff"] = {id=3003, name="ArchAngelsDummySpell"}
ITEMS["Manamune"] = {id=3004, name="ManamuneDummySpell"}
ITEMS["Muramana"] = {id=3042, name="Muramana"}

ITEMS["Crystaline Flask"] = {id=2041}

ITEMS["Sightstone"] = {id=2049}
ITEMS["Ruby Sightstone"] = {id=2045}

ITEMS["Warding Totem"] = {id=3340}
ITEMS["Greater Stealth Totem"] = {id=3361}
ITEMS["Greater Vision Totem"] = {id=3362}

ITEMS["Sweeping Lens"] = {id=3341}
ITEMS["Oracle's Lens"] = {id=3364}

ITEMS["Scrying Orb"] = {id=3342}

local ITEMSBYID = {}
for name,item in ipairs(ITEMS) do
	if not item.name then
		item.name = name
	end
	ITEMSBYID[item.id] = item
end

function GetItemByID(id)
	return ITEMSBYID[id]
end