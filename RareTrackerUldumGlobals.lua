-- Redefine often used functions locally.
local GetLocale = GetLocale

-- ####################################################################
-- ##                          Static Data                           ##
-- ####################################################################

-- The zones in which the addon is active.
RTU.target_zones = {
    [1527] = true
}
RTU.parent_zone = 1527

-- NPCs that are banned during shard detection.
-- Player followers sometimes spawn with the wrong zone id.
RTU.banned_NPC_ids = {
    [154297] = true,
    [150202] = true,
    [154304] = true,
    [152108] = true,
    [151300] = true,
    [151310] = true,
    [69792] = true,
    [62821] = true,
    [62822] = true,
    [32639] = true,
    [32638] = true,
    [89715] = true,
}

-- Simulate a set data structure for efficient existence lookups.
function Set (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- The ids of the rares the addon monitors.
RTU.rare_ids = {
    157170, -- "Acolyte Taspu",
    158557, -- "Actiss the Deceiver",
    157593, -- "Amalgamation of Flesh",
    151883, -- "Anaua",
    155703, -- "Anq'uri the Titanic",
    157472, -- "Aphrom the Guise of Madness",
    154578, -- "Aqir Flayer",
    154576, -- "Aqir Titanus",
    162172, -- "Aqir Warcaster",
    162370, -- "Armagedillo",
    152757, -- "Atekhramun",
    162171, -- "Captain Dunewalker",
    157167, -- "Champion Sen-mat",
    162147, -- "Corpse Eater",
    158531, -- "Corrupted Neferset Guard"
    158594, -- "Doomsayer Vathiris",
    158491, -- "Falconer Amenophis",
    157120, -- "Fangtaker Orsa",
    158633, -- "Gaze of N'Zoth",
    158597, -- "High Executor Yothrim",
    158528, -- "High Guard Reshef",
    162163, -- "High Priest Ytaessis",
    151995, -- "Hik-Ten the Taskmaster",
    160623, -- "Hungering Miasma",
    152431, -- "Kaneb-ti",
    155531, -- "Infested Wastewander Captain",
    157134, -- "Ishak of the Four Winds",
    156655, -- "Korzaran the Slaughterer",
    154604, -- "Lord Aj'qirai",
    156078, -- "Magus Rehleth",
    157157, -- "Muminah the Incandescent",
    152677, -- "Nebet the Ascended",
    162196, -- "Obsidian Annihilator",
    162142, -- "Qho",
    157470, -- "R'aas the Anima Devourer",
    156299, -- "R'khuzj the Unfathomable",
    162173, -- "R'krox the Runt",
    157390, -- "R'oyolok the Reality Eater",
    157146, -- "Rotfeaster",
    152040, -- "Scoutmaster Moswen",
    151948, -- "Senbu the Pridefather",
    161033, -- "Shadowmaw",
    156654, -- "Shol'thoss the Doomspeaker",
    160532, -- "Shoth the Darkened",
    157476, -- "Shugshul the Flesh Gorger",
    162140, -- "Skikx'traz",
    162372, -- "Spirit of Cyrus the Black",
    162352, -- "Spirit of Dark Ritualist Zakahn",
    151878, -- "Sun King Nahkotep",
    151897, -- "Sun Priestess Nubitt",
    151609, -- "Sun Prophet Epaphos",
    152657, -- "Tat the Bonechewer",
    158636, -- "The Grand Executor",
    157188, -- "The Tomb Widow",
    158595, -- "Thoughtstealer Vos",
    152788, -- "Uat-ka the Sun's Wrath"
    162170, -- "Warcaster Xeshro",
    151852, -- "Watcher Rehu",
    157473, -- "Yiphrim the Will Ravager",
    157164, -- "Zealot Tekem",
    157469, -- "Zoth'rum the Intellect Pillager",
    162141, -- "Zuythiz",
}

-- Create a table, such that we can look up a rare in constant time.
RTU.rare_ids_set = Set(RTU.rare_ids)

-- Group rares by the assaults they are active in.
-- Notes: used the values found in the HandyNotes_VisionsOfNZoth addon.
RTU.assault_rare_ids = {
    [3165083] = Set({ -- West (AQR)
        155703,
        154578,
        154576,
        162172,
        162370,
        162171,
        162147,
        162163,
        155531,
        157134,
        154604,
        156078,
        162196,
        162142,
        156299,
        162173,
        160532,
        162140,
        162372,
        162352,
        151878,
        162170,
        
        157472, -- "Aphrom the Guise of Madness"
        158531, -- "Corrupted Neferset Guard"
        152431, -- "Kaneb-ti"
        157470, -- "R'aas the Anima Devourer"
        157390, -- "R'oyolok the Reality Eater"
        157476, -- "Shugshul the Flesh Gorger"
        158595, -- "Thoughtstealer Vos"
        157473, -- "Yiphrim the Will Ravager"
        157469, -- "Zoth'rum the Intellect Pillager"
    }),
    [3165092] = Set({ -- South (EMP)
        158557,
        155703,
        154578,
        154576,
        162172,
        158594,
        158491,
        158633,
        158597,
        158528,
        160623,
        155531,
        157134,
        156655,
        162196,
        156299,
        161033,
        156654,
        160532,
        151878,
        158636,
        
        157472, -- "Aphrom the Guise of Madness"
        158531, -- "Corrupted Neferset Guard"
        152431, -- "Kaneb-ti"
        157470, -- "R'aas the Anima Devourer"
        157390, -- "R'oyolok the Reality Eater"
        157476, -- "Shugshul the Flesh Gorger"
        158595, -- "Thoughtstealer Vos"
        157473, -- "Yiphrim the Will Ravager"
        157469, -- "Zoth'rum the Intellect Pillager"
    }),
    [3165098] = Set({ -- East (AMA)
        157170,
        151883,
        155703,
        154578,
        154576,
        162172,
        152757,
        157120,
        151995,
        155531,
        157134,
        157157,
        152677,
        162196,
        157146,
        152040,
        151948,
        162372,
        162352,
        151878,
        151897,
        151609,
        152657,
        151852,
        157164,
        162141,
        157167,
        157593, -- "Amalgamation of Flesh"
        157188, -- "The Tomb Widow"
        152788, -- "Uat-ka the Sun's Wrath"
        
        157472, -- "Aphrom the Guise of Madness"
        158531, -- "Corrupted Neferset Guard"
        152431, -- "Kaneb-ti"
        157470, -- "R'aas the Anima Devourer"
        157390, -- "R'oyolok the Reality Eater"
        157476, -- "Shugshul the Flesh Gorger"
        158595, -- "Thoughtstealer Vos"
        157473, -- "Yiphrim the Will Ravager"
        157469, -- "Zoth'rum the Intellect Pillager"
    })
}

-- Get the rare names in the correct localization.
RTU.localization = GetLocale()
RTU.rare_names = {}

if RTU.localization == "frFR" then
    -- The names to be displayed in the frames and general chat messages for the French localization.
    RTU.rare_names = {
        [157170] = "Acolyte Taspu",
        [158557] = "Actiss le Trompeur",
        [157593] = "Amalgame de chair",
        [151883] = "Anaua",
        [155703] = "Anq'uri le Titanesque",
        [157472] = "Aphrom l'Incarnation de la folie",
        [154578] = "Ecorcheur aqir",
        [154576] = "Titanus aqir",
        [162172] = "Invocateur de guerre aqir",
        [162370] = "Armaglyptodon",
        [152757] = "Atekhramun",
        [162171] = "Capitaine marchedune",
        [157167] = "Champion Sen-mat",
        [162147] = "Mange-cadavres",
        [158531] = "Garde de Neferset corrompu",
        [158594] = "Auspice funeste Vathiris",
        [158491] = "Fauconnier Amenophis",
        [157120] = "Orsa Chasse-crocs",
        [158633] = "Regard de N'Zoth",
        [158597] = "Grand exécuteur Yothrim",
        [158528] = "Haut garde Reshef",
        [162163] = "Grand prêtre Ytaessis",
        [151995] = "Hik-ten le Sous-chef",
        [160623] = "Miasme affamé",
        [152431] = "Kaneb-ti",
        [155531] = "Capitaine bat-le-désert contaminé",
        [157134] = "Ishak des Quatre vents",
        [156655] = "Korzaran le Massacreur",
        [154604] = "Seigneur Aj'qirai",
        [156078] = "Magus Rehleth",
        [157157] = "Muminah l'Incandescent",
        [152677] = "Nebet le Sublimé",
        [162196] = "Annihilateur d'obsidienne",
        [162142] = "Qho",
        [157470] = "R'aas le Dévoreur d'anima",
        [156299] = "R'khuzj l'Insondable",
        [162173] = "R'krox l'Avorton",
        [157390] = "R'oyolok le Bâfreur de réalité",
        [157146] = "Croque-Charogne",
        [152040] = "Maître-éclaireur Moswen",
        [151948] = "Senbu le Père-de-troupe",
        [161033] = "Ombregueule",
        [156654] = "Shol'thoss l'Orateur funeste",
        [160532] = "Shoth l'Assombri",
        [157476] = "Shugshul le Gobeur de chair",
        [162140] = "Skikx'traz",
        [162372] = "Esprit de Cyrus le Noir",
        [162352] = "Esprit du ritualiste sombre Zakahn",
        [151878] = "Roi-soleil Nahkotep",
        [151897] = "Prêtresse du soleil Nabett",
        [151609] = "Prophète du soleil Epaphos",
        [152657] = "Tat le Mâche-les-os",
        [158636] = "Le grand exécuteur",
        [157188] = "La veuve du tombeau",
        [158595] = "Pilleur mental Vos",
        [152788] = "Uat-ka Courroux-du-Soleil",
        [162170] = "Invocateur de guerre Xeshro",
        [151852] = "Guetteur Rehu",
        [157473] = "Yiphrim le Ravageur de volonté",
        [157164] = "Zélote Tekem",
        [157469] = "Zoth'rum le Pilleur d'intellect",
        [162141] = "Zuythiz",
    }
else
    -- The names to be displayed in the frames and general chat messages for the English localizations.
    RTU.rare_names = {
        [157170] = "Acolyte Taspu",
        [158557] = "Actiss the Deceiver",
        [157593] = "Amalgamation of Flesh",
        [151883] = "Anaua",
        [155703] = "Anq'uri the Titanic",
        [157472] = "Aphrom the Guise of Madness",
        [154578] = "Aqir Flayer",
        [154576] = "Aqir Titanus",
        [162172] = "Aqir Warcaster",
        [162370] = "Armagedillo",
        [152757] = "Atekhramun",
        [162171] = "Captain Dunewalker",
        [157167] = "Champion Sen-mat",
        [162147] = "Corpse Eater",
        [158531] = "Corrupted Neferset Guard",
        [158594] = "Doomsayer Vathiris",
        [158491] = "Falconer Amenophis",
        [157120] = "Fangtaker Orsa",
        [158633] = "Gaze of N'Zoth",
        [158597] = "High Executor Yothrim",
        [158528] = "High Guard Reshef",
        [162163] = "High Priest Ytaessis",
        [151995] = "Hik-Ten the Taskmaster",
        [160623] = "Hungering Miasma",
        [152431] = "Kaneb-ti",
        [155531] = "Infested Wastewander Captain",
        [157134] = "Ishak of the Four Winds",
        [156655] = "Korzaran the Slaughterer",
        [154604] = "Lord Aj'qirai",
        [156078] = "Magus Rehleth",
        [157157] = "Muminah the Incandescent",
        [152677] = "Nebet the Ascended",
        [162196] = "Obsidian Annihilator",
        [162142] = "Qho",
        [157470] = "R'aas the Anima Devourer",
        [156299] = "R'khuzj the Unfathomable",
        [162173] = "R'krox the Runt",
        [157390] = "R'oyolok the Reality Eater",
        [157146] = "Rotfeaster",
        [152040] = "Scoutmaster Moswen",
        [151948] = "Senbu the Pridefather",
        [161033] = "Shadowmaw",
        [156654] = "Shol'thoss the Doomspeaker",
        [160532] = "Shoth the Darkened",
        [157476] = "Shugshul the Flesh Gorger",
        [162140] = "Skikx'traz",
        [162372] = "Spirit of Cyrus the Black",
        [162352] = "Spirit of Dark Ritualist Zakahn",
        [151878] = "Sun King Nahkotep",
        [151897] = "Sun Priestess Nubitt",
        [151609] = "Sun Prophet Epaphos",
        [152657] = "Tat the Bonechewer",
        [158636] = "The Grand Executor",
        [157188] = "The Tomb Widow",
        [158595] = "Thoughtstealer Vos",
        [152788] = "Uat-ka the Sun's Wrath",
        [162170] = "Warcaster Xeshro",
        [151852] = "Watcher Rehu",
        [157473] = "Yiphrim the Will Ravager",
        [157164] = "Zealot Tekem",
        [157469] = "Zoth'rum the Intellect Pillager",
        [162141] = "Zuythiz",
    }
end

-- Overrides for display names of rares that are too long.
local rare_display_name_overwrites = {}

rare_display_name_overwrites["enUS"] = {}
rare_display_name_overwrites["enGB"] = {}
rare_display_name_overwrites["itIT"] = {}
rare_display_name_overwrites["frFR"] = {}
rare_display_name_overwrites["zhCN"] = {}
rare_display_name_overwrites["zhTW"] = {}
rare_display_name_overwrites["koKR"] = {}
rare_display_name_overwrites["deDE"] = {}
rare_display_name_overwrites["esES"] = {}
rare_display_name_overwrites["esMX"] = rare_display_name_overwrites["esES"]
rare_display_name_overwrites["ptPT"] = {}
rare_display_name_overwrites["ptBR"] = rare_display_name_overwrites["ptPT"]
rare_display_name_overwrites["ruRU"] = {}

RTU.rare_display_names = {}
for key, value in pairs(RTU.rare_names) do
    if rare_display_name_overwrites[RTU.localization][key] then
        RTU.rare_display_names[key] = rare_display_name_overwrites[RTU.localization][key]
    else
        RTU.rare_display_names[key] = value
    end
end

-- The quest ids that indicate that the rare has been killed already.
RTU.completion_quest_ids = {
    [157170] = 57281, -- "Acolyte Taspu"
    [158557] = 57669, -- "Actiss the Deceiver"
    [157593] = 57667, -- "Amalgamation of Flesh"
    [151883] = 55468, -- "Anaua"
    [155703] = 56834, -- "Anq'uri the Titanic"
    [157472] = 57437, -- "Aphrom the Guise of Madness"
    [154578] = 58612, -- "Aqir Flayer"
    [154576] = 58614, -- "Aqir Titanus"
    [162172] = 58694, -- "Aqir Warcaster"
    [162370] = 58718, -- "Armagedillo"
    [152757] = 55710, -- "Atekhramun"
    [162171] = 58699, -- "Captain Dunewalker"
    [157167] = 57280, -- "Champion Sen-mat"
    [162147] = 58696, -- "Corpse Eater"
    [158531] = 57665, -- "Corrupted Neferset Guard"
    [158594] = 57672, -- "Doomsayer Vathiris"
    [158491] = 57662, -- "Falconer Amenophis"
    [157120] = 57258, -- "Fangtaker Orsa"
    [158633] = 57680, -- "Gaze of N'Zoth"
    [158597] = 57675, -- "High Executor Yothrim"
    [158528] = 57664, -- "High Guard Reshef"
    [162163] = 58701, -- "High Priest Ytaessis"
    [151995] = 55502, -- "Hik-Ten the Taskmaster"
    [160623] = 58206, -- "Hungering Miasma"
    [152431] = 55629, -- "Kaneb-ti"
    [155531] = 56823, -- "Infested Wastewander Captain"
    [157134] = 57259, -- "Ishak of the Four Winds"
    [156655] = 57433, -- "Korzaran the Slaughterer"
    [154604] = 56340, -- "Lord Aj'qirai"
    [156078] = 56952, -- "Magus Rehleth"
    [157157] = 57277, -- "Muminah the Incandescent"
    [152677] = 55684, -- "Nebet the Ascended"
    [162196] = 58681, -- "Obsidian Annihilator"
    [162142] = 58693, -- "Qho"
    [157470] = 57436, -- "R'aas the Anima Devourer"
    [156299] = 57430, -- "R'khuzj the Unfathomable"
    [162173] = 58864, -- "R'krox the Runt"
    [157390] = 57434, -- "R'oyolok the Reality Eater"
    [157146] = 57273, -- "Rotfeaster"
    [152040] = 55518, -- "Scoutmaster Moswen"
    [151948] = 55496, -- "Senbu the Pridefather"
    [161033] = 58333, -- "Shadowmaw"
    [156654] = 57432, -- "Shol'thoss the Doomspeaker"
    [160532] = 58169, -- "Shoth the Darkened"
    [157476] = 57439, -- "Shugshul the Flesh Gorger"
    [162140] = 58697, -- "Skikx'traz"
    [162372] = 58715, -- "Spirit of Cyrus the Black"
    [162352] = 58716, -- "Spirit of Dark Ritualist Zakahn"
    [151878] = 58613, -- "Sun King Nahkotep"
    [151897] = 55479, -- "Sun Priestess Nubitt"
    [151609] = 55353, -- "Sun Prophet Epaphos"
    [152657] = 55682, -- "Tat the Bonechewer"
    [158636] = 57688, -- "The Grand Executor"
    [157188] = 57285, -- "The Tomb Widow"
    [158595] = 57673, -- "Thoughtstealer Vos"
    [152788] = 55716, -- "Uat-ka the Sun's Wrath"
    [162170] = 58702, -- "Warcaster Xeshro"
    [151852] = 55461, -- "Watcher Rehu"
    [157473] = 57438, -- "Yiphrim the Will Ravager"
    [157164] = 57279, -- "Zealot Tekem"
    [157469] = 57435, -- "Zoth'rum the Intellect Pillager"
    [162141] = 58695, -- "Zuythiz"
}

RTU.completion_quest_inverse = {
    [57281] = {157170}, -- "Acolyte Taspu"
    [57669] = {158557}, -- "Actiss the Deceiver"
    [57667] = {157593}, -- "Amalgamation of Flesh"
    [55468] = {151883}, -- "Anaua"
    [56834] = {155703}, -- "Anq'uri the Titanic"
    [57437] = {157472}, -- "Aphrom the Guise of Madness"
    [58612] = {154578}, -- "Aqir Flayer"
    [58614] = {154576}, -- "Aqir Titanus"
    [58694] = {162172}, -- "Aqir Warcaster"
    [58718] = {162370}, -- "Armagedillo"
    [55710] = {152757}, -- "Atekhramun"
    [58699] = {162171}, -- "Captain Dunewalker"
    [57280] = {157167}, -- "Champion Sen-mat"
    [58696] = {162147}, -- "Corpse Eater"
    [57665] = {158531}, -- "Corrupted Neferset Guard"
    [57672] = {158594}, -- "Doomsayer Vathiris"
    [57662] = {158491}, -- "Falconer Amenophis"
    [57258] = {157120}, -- "Fangtaker Orsa"
    [57680] = {158633}, -- "Gaze of N'Zoth"
    [57675] = {158597}, -- "High Executor Yothrim"
    [57664] = {158528}, -- "High Guard Reshef"
    [58701] = {162163}, -- "High Priest Ytaessis"
    [55502] = {151995}, -- "Hik-Ten the Taskmaster"
    [58206] = {160623}, -- "Hungering Miasma"
    [55629] = {152431}, -- "Kaneb-ti"
    [56823] = {155531}, -- "Infested Wastewander Captain"
    [57259] = {157134}, -- "Ishak of the Four Winds"
    [57433] = {156655}, -- "Korzaran the Slaughterer"
    [56340] = {154604}, -- "Lord Aj'qirai"
    [56952] = {156078}, -- "Magus Rehleth"
    [57277] = {157157}, -- "Muminah the Incandescent"
    [55684] = {152677}, -- "Nebet the Ascended"
    [58681] = {162196}, -- "Obsidian Annihilator"
    [58693] = {162142}, -- "Qho"
    [57436] = {157470}, -- "R'aas the Anima Devourer"
    [57430] = {156299}, -- "R'khuzj the Unfathomable"
    [58864] = {162173}, -- "R'krox the Runt"
    [57434] = {157390}, -- "R'oyolok the Reality Eater"
    [57273] = {157146}, -- "Rotfeaster"
    [55518] = {152040}, -- "Scoutmaster Moswen"
    [55496] = {151948}, -- "Senbu the Pridefather"
    [58333] = {161033}, -- "Shadowmaw"
    [57432] = {156654}, -- "Shol'thoss the Doomspeaker"
    [58169] = {160532}, -- "Shoth the Darkened"
    [57439] = {157476}, -- "Shugshul the Flesh Gorger"
    [58697] = {162140}, -- "Skikx'traz"
    [58715] = {162372}, -- "Spirit of Cyrus the Black"
    [58716] = {162352}, -- "Spirit of Dark Ritualist Zakahn"
    [58613] = {151878}, -- "Sun King Nahkotep"
    [55479] = {151897}, -- "Sun Priestess Nubitt"
    [55353] = {151609}, -- "Sun Prophet Epaphos"
    [55682] = {152657}, -- "Tat the Bonechewer"
    [57688] = {158636}, -- "The Grand Executor"
    [57285] = {157188}, -- "The Tomb Widow"
    [57673] = {158595}, -- "Thoughtstealer Vos"
    [55716] = {152788}, -- "Uat-ka the Sun's Wrath"
    [58702] = {162170}, -- "Warcaster Xeshro"
    [55461] = {151852}, -- "Watcher Rehu"
    [57438] = {157473}, -- "Yiphrim the Will Ravager"
    [57279] = {157164}, -- "Zealot Tekem"
    [57435] = {157469}, -- "Zoth'rum the Intellect Pillager"
    [58695] = {162141}, -- "Zuythiz"
}

-- Certain npcs have yell emotes to announce their arrival.
local yell_announcing_rares = {}

-- Concert the ids above to the names.
RTU.yell_announcing_rares = {}
for key, value in pairs(yell_announcing_rares) do
    RTU.yell_announcing_rares[RTU.rare_names[key]] = value
end

-- A set of placeholder icons, which will be used if the rare location is not yet known.
RTU.rare_coordinates = {
    [157170] = {["x"] = 64, ["y"] = 26}, -- "Acolyte Taspu"
    [158557] = {["x"] = 66.77, ["y"] = 74.33}, -- "Actiss the Deceiver"
    [157593] = {["x"] = 70, ["y"] = 50}, -- "Amalgamation of Flesh"
    [151883] = {["x"] = 69, ["y"] = 49}, -- "Anaua"
    [155703] = {["x"] = 32, ["y"] = 64}, -- "Anq'uri the Titanic"
    [157472] = {["x"] = 50, ["y"] = 79}, -- "Aphrom the Guise of Madness"
    [154578] = {["x"] = 39, ["y"] = 25}, -- "Aqir Flayer"
    [154576] = {["x"] = 31, ["y"] = 57}, -- "Aqir Titanus"
    [162172] = {["x"] = 38, ["y"] = 45}, -- "Aqir Warcaster"
    [162370] = {["x"] = 44, ["y"] = 42}, -- "Armagedillo"
    [152757] = {["x"] = 65.3, ["y"] = 51.6}, -- "Atekhramun"
    [162171] = {["x"] = 45, ["y"] = 57}, -- "Captain Dunewalker"
    [157167] = {["x"] = 75, ["y"] = 52}, -- "Champion Sen-mat"
    [162147] = {["x"] = 30, ["y"] = 49}, -- "Corpse Eater"
    [158531] = {["x"] = 50, ["y"] = 79}, -- "Corrupted Neferset Guard"
    [158594] = {["x"] = 49, ["y"] = 38}, -- "Doomsayer Vathiris"
    [158491] = {["x"] = 48, ["y"] = 70}, -- "Falconer Amenophis"
    [157120] = {["x"] = 75, ["y"] = 68}, -- "Fangtaker Orsa"
    [158633] = {["x"] = 55, ["y"] = 53}, -- "Gaze of N'Zoth"
    [158597] = {["x"] = 54, ["y"] = 43}, -- "High Executor Yothrim"
    [158528] = {["x"] = 53.68, ["y"] = 79.33}, -- "High Guard Reshef"
    [162163] = {["x"] = 42, ["y"] = 58}, -- "High Priest Ytaessis"
    [151995] = {["x"] = 80, ["y"] = 47}, -- "Hik-Ten the Taskmaster"
    [160623] = {["x"] = 60, ["y"] = 39}, -- "Hungering Miasma"
    [152431] = {["x"] = 77, ["y"] = 52}, -- "Kaneb-ti"
    [155531] = {["x"] = 19, ["y"] = 58}, -- "Infested Wastewander Captain"
    [157134] = {["x"] = 73, ["y"] = 83}, -- "Ishak of the Four Winds"
    [156655] = {["x"] = 71, ["y"] = 73}, -- "Korzaran the Slaughterer"
    [154604] = {["x"] = 34, ["y"] = 18}, -- "Lord Aj'qirai"
    [156078] = {["x"] = 30, ["y"] = 66}, -- "Magus Rehleth"
    [157157] = {["x"] = 66, ["y"] = 20}, -- "Muminah the Incandescent"
    [152677] = {["x"] = 61, ["y"] = 24}, -- "Nebet the Ascended"
    [162196] = {["x"] = 35, ["y"] = 17}, -- "Obsidian Annihilator"
    [162142] = {["x"] = 37, ["y"] = 59}, -- "Qho"
    [157470] = {["x"] = 51, ["y"] = 88}, -- "R'aas the Anima Devourer"
    [156299] = {["x"] = 58, ["y"] = 57}, -- "R'khuzj the Unfathomable"
    [162173] = {["x"] = 28, ["y"] = 13}, -- "R'krox the Runt"
    -- [157390] -- "R'oyolok the Reality Eater"
    [157146] = {["x"] = 69, ["y"] = 32}, -- "Rotfeaster"
    [152040] = {["x"] = 70, ["y"] = 42}, -- "Scoutmaster Moswen"
    [151948] = {["x"] = 74, ["y"] = 65}, -- "Senbu the Pridefather"
    [161033] = {["x"] = 57, ["y"] = 38}, -- "Shadowmaw"
    [156654] = {["x"] = 59, ["y"] = 83}, -- "Shol'thoss the Doomspeaker"
    [160532] = {["x"] = 61, ["y"] = 75}, -- "Shoth the Darkened"
    [157476] = {["x"] = 55, ["y"] = 80}, -- "Shugshul the Flesh Gorger"
    [162140] = {["x"] = 21, ["y"] = 61}, -- "Skikx'traz"
    [162372] = {["x"] = 67, ["y"] = 68}, -- "Spirit of Cyrus the Black"
    [162352] = {["x"] = 52, ["y"] = 40}, -- "Spirit of Dark Ritualist Zakahn"
    [151878] = {["x"] = 79, ["y"] = 64}, -- "Sun King Nahkotep"
    [151897] = {["x"] = 85, ["y"] = 57}, -- "Sun Priestess Nubitt"
    [151609] = {["x"] = 73, ["y"] = 74}, -- "Sun Prophet Epaphos"
    [152657] = {["x"] = 66, ["y"] = 35}, -- "Tat the Bonechewer"
    [158636] = {["x"] = 49, ["y"] = 82}, -- "The Grand Executor"
    [157188] = {["x"] = 84, ["y"] = 47}, -- "The Tomb Widow"
    [158595] = {["x"] = 65, ["y"] = 72}, -- "Thoughtstealer Vos"
    [152788] = {["x"] = 68, ["y"] = 64}, -- "Uat-ka the Sun's Wrath"
    [162170] = {["x"] = 34, ["y"] = 26}, -- "Warcaster Xeshro"
    [151852] = {["x"] = 80, ["y"] = 52}, -- "Watcher Rehu"
    -- [157473] -- "Yiphrim the Will Ravager"
    [157164] = {["x"] = 80, ["y"] = 57}, -- "Zealot Tekem"
    -- [157469] -- "Zoth'rum the Intellect Pillager"
    [162141] = {["x"] = 40, ["y"] = 41}, -- "Zuythiz"
}