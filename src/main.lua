-- ============================================================
-- THE OTHER SIDE OF THE GRIND
-- A Parody Survivalcraft Experience™
-- "From the visionary team that brought you nothing"
-- ============================================================

-- Tile size for rendering (scaled up from 18px source)
local TILE_SIZE = 40
local MAP_W, MAP_H = 60, 45
local SCREEN_W, SCREEN_H = 800, 600

-- Camera
local camera = { x = 0, y = 0 }
local screenShake = { timer = 0, intensity = 0 }

-- Spritesheets
local tileSheet, charSheet
local tileQuads = {}
local charQuads = {}

-- Tile types
local T = {
    GRASS = 1, DIRT = 2, WATER = 3, TREE = 4, ROCK = 5,
    STUMP = 6, RUBBLE = 7, FLOWER = 8, MUSHROOM = 9,
    CACTUS = 10, SAND = 11, SWAMP = 12, TALL_GRASS = 13,
    BERRY_BUSH = 14, DEAD_TREE = 15,
}

-- Tile properties
local tileProps = {
    [T.GRASS]      = { solid = false, name = "Grass" },
    [T.DIRT]       = { solid = false, name = "Artisanal Dirt™" },
    [T.WATER]      = { solid = true,  name = "Monetizable Water™" },
    [T.TREE]       = { solid = true,  name = "Organic Free-Range Tree™", resource = "wood", hp = 3 },
    [T.ROCK]       = { solid = true,  name = "Blockchain Ore Node™", resource = "stone", hp = 5 },
    [T.STUMP]      = { solid = false, name = "Disrupted Stump™" },
    [T.RUBBLE]     = { solid = false, name = "Decentralized Gravel™" },
    [T.FLOWER]     = { solid = false, name = "Cosmetic Flower (DLC)" },
    [T.MUSHROOM]   = { solid = false, name = "Suspicious Mushroom™", resource = "mushroom_sus", hp = 1 },
    [T.CACTUS]     = { solid = true,  name = "Hostile Succulent™", resource = "fiber", hp = 2 },
    [T.SAND]       = { solid = false, name = "Desert Biome Content™" },
    [T.SWAMP]      = { solid = false, name = "Swamp (Premium Biome)" },
    [T.TALL_GRASS] = { solid = false, name = "Tall Grass (May contain loot boxes)" },
    [T.BERRY_BUSH] = { solid = true,  name = "Organic Micro-Berry™", resource = "berries", hp = 1 },
    [T.DEAD_TREE]  = { solid = true,  name = "Post-Mortem Tree™", resource = "wood", hp = 2 },
}

-- Biome definitions
local BIOME = { FOREST = 1, DESERT = 2, SWAMP = 3, PLAINS = 4 }
local biomeMap = {}

-- Map data and resource HP
local map = {}
local mapHP = {}

-- Player
local player = {
    x = 10, y = 10,
    facing = "down",
    inventory = {
        wood = 0, stone = 0, fiber = 0, berries = 0,
        mushroom_sus = 0, existential_dread = 1, bug_reports = 0,
    },
    stats = {
        hunger = 100, thirst = 100, boredom = 0,
        engagement_metrics = 100, will_to_live = 100,
        sanity = 100,
    },
    alive = true,
    moveTimer = 0,
    moveDelay = 0.12,
    attackTimer = 0,
    attackAnim = nil,
    statusEffects = {},  -- {name, timer, color}
    totalTreesPunched = 0,
    totalRocksMined = 0,
    totalEnemiesDefeated = 0,
    totalDeaths = 0,
    totalStepsTaken = 0,
    totalCrafts = 0,
}

-- Crafting recipes
local recipes = {
    {
        name = "Artisanal Workbench™",
        desc = "A table. For putting things on. Revolutionary.",
        cost = { wood = 3 },
        unlocks = "You can now craft more useless things!",
    },
    {
        name = "Premium Wooden Sword (F2P Edition)",
        desc = "Does 1 damage. Upgrade to Founder's Pack for +0.5!",
        cost = { wood = 5, stone = 2 },
        unlocks = "You can now ineffectively defend yourself!",
    },
    {
        name = "NFT Campfire",
        desc = "Proof that you, and only you, own this fire.",
        cost = { wood = 4, stone = 3 },
        unlocks = "Night is slightly less terrifying! (Not really)",
    },
    {
        name = "Battle Pass Sleeping Bag",
        desc = "Skip the night for only 950 V-Bucks.",
        cost = { wood = 8, stone = 2 },
        unlocks = "You've unlocked... rest? As a concept?",
    },
    {
        name = "Suspicious Mushroom Stew",
        desc = "Side effects include: fun. (Banned in 12 countries.)",
        cost = { mushroom_sus = 2, wood = 1 },
        unlocks = "You feel... different. Sanity restored!",
        effect = function() player.stats.sanity = 100; player.stats.hunger = 100 end,
    },
    {
        name = "Berry Smoothie (Season Pass Tier 47)",
        desc = "Restores thirst. Somehow.",
        cost = { berries = 3 },
        unlocks = "Hydration achieved through fruit. Science!",
        effect = function() player.stats.thirst = 100; player.stats.hunger = math.min(100, player.stats.hunger + 30) end,
    },
    {
        name = "Cactus Fiber Armor (Cosmetic Only)",
        desc = "Looks cool. Does nothing. +0 defense.",
        cost = { fiber = 5, stone = 2 },
        unlocks = "You look slightly more prepared to die!",
    },
    {
        name = "Bug Report Form",
        desc = "For filing complaints about this game. With this game.",
        cost = { wood = 2, stone = 1, fiber = 1 },
        unlocks = "Your feedback has been filed directly into /dev/null!",
        effect = function() player.inventory.bug_reports = player.inventory.bug_reports + 1 end,
    },
    {
        name = "The Game (You Just Lost It)",
        desc = "A metagame artifact. Crafting it means you've already lost.",
        cost = { wood = 10, stone = 10, fiber = 5, berries = 3, mushroom_sus = 2 },
        unlocks = "ACHIEVEMENT UNLOCKED: You lost The Game.",
    },
}

-- Game state
local gameTime = 0
local dayLength = 90
local dayPhase = "day"
local tutorialMessages = {}
local currentTutorial = nil
local tutorialTimer = 0
local notifications = {}
local gameStarted = false
local loadingScreen = true
local loadingTimer = 0
local loadingTips = {
    "TIP: Trees are made of wood. We spent $2M on this research.",
    "TIP: Hunger decreases over time. Just like your expectations.",
    "TIP: The crafting system has recipes. We call it 'deep'.",
    "TIP: Night is coming. It's basically the same but darker.",
    "TIP: This game is in Early Access. It will never leave.",
    "TIP: Press WASD to move. Our QA team discovered this.",
    "TIP: Rocks contain stone. Focus group validated this.",
    "TIP: You can die. The only feature that works as intended.",
    "TIP: Our AI director creates unique experiences. (math.random).",
    "TIP: Survival is optional. The grind is forever.",
    "DID YOU KNOW: This game has more trees than story.",
    "DID YOU KNOW: Our procedural generation is just a for loop.",
    "TIP: The desert biome was added to pad the Steam store page.",
    "TIP: Mushrooms restore sanity. Which you'll need.",
    "TIP: Berries exist because we googled 'survival game checklist'.",
    "TIP: The swamp biome tested well with focus groups of zero.",
    "DID YOU KNOW: Every tree was hand-placed by math.random.",
    "TIP: The boss was designed by our intern. On their first day.",
    "TIP: Weather effects may cause feelings. This is not a bug.",
}
local currentLoadingTip = 1

-- Enemies
local enemies = {}
local enemySpawnTimer = 0
local bossActive = false
local boss = nil

-- Particles
local particles = {}
local floatingTexts = {}
local playerLunge = { ox = 0, oy = 0 }
local punchCombo = 0
local punchComboTimer = 0

-- Hit messages (escalating)
local hitMessages = {
    "*bonk*", "*thwack*", "*CRACK*", "*WHAM*", "*KAPOW*",
    "*DEVASTATING BLOW*", "*CRITICAL BONK*", "*ULTRA PUNCH*",
    "*WOMBO COMBO*", "*OVERKILL*",
}

local treeFallMessages = {
    "The tree didn't consent to this.",
    "Deforestation speedrun any%%.",
    "PETA would like a word.",
    "That tree had a family.",
    "Another tree sacrificed to the content pipeline.",
    "The environmentalists are typing...",
    "This tree was an NFT. You just rugged it.",
    "If a tree falls in a game and no one streams it...",
    "The tree has been disrupted.",
}

local rockBreakMessages = {
    "This stone was minted on the blockchain.",
    "You've disrupted the geological sector.",
    "Rock and Stone! Wait, wrong game.",
    "The rock didn't even fight back. Coward.",
    "Peak mining gameplay achieved.",
    "You just ground a rock. This is the content.",
    "The rock market just crashed.",
    "Stoned. Wait, that came out wrong.",
}

-- Crafting menu
local craftingOpen = false
local craftingSelection = 1
local craftedItems = {}

-- Fake store
local storeOpen = false
local storeSelection = 1
local storeItems = {
    { name = "Founder's Pack ($49.99)", desc = "Includes: A hat. That's it. That's the pack.", price = "YOUR DIGNITY" },
    { name = "Season Pass ($29.99/mo)", desc = "Unlock the ability to unlock things.", price = "YOUR FIRSTBORN" },
    { name = "1000 GrindCoins ($9.99)", desc = "The premium currency that buys nothing.", price = "REAL MONEY LOL" },
    { name = "XP Booster (24hr)", desc = "There's no XP system. This does nothing.", price = "$4.99" },
    { name = "Cosmetic Skin: 'Default But Blue'", desc = "It's the same skin but blue. Groundbreaking.", price = "$12.99" },
    { name = "Remove Ads (there are no ads)", desc = "We'll add ads, then you can pay to remove them.", price = "$1.99" },
    { name = "WHALE PACKAGE ($999.99)", desc = "For the discerning spender. Includes nothing x1000.", price = "YOUR MORTGAGE" },
}

-- Weather system
local weather = {
    current = "clear",
    timer = 0,
    raindrops = {},
    fogAlpha = 0,
}
local weatherTypes = {
    { name = "clear", desc = "Clear Skies (Boring)", duration = {20, 40}, weight = 40 },
    { name = "rain", desc = "Monetizable Rain™", duration = {15, 30}, weight = 25 },
    { name = "fog", desc = "Mysterious Fog (GPU Saver)", duration = {10, 25}, weight = 15 },
    { name = "blood_moon", desc = "BLOOD MOON (Content Warning)", duration = {10, 20}, weight = 5 },
    { name = "pixel_storm", desc = "Pixel Storm (Known Bug)", duration = {5, 15}, weight = 10 },
    { name = "existential", desc = "Existential Weather™", duration = {8, 15}, weight = 5 },
}

-- Achievement system
local achievements = {}
local achievementQueue = {}
local currentAchievement = nil
local achievementTimer = 0
local achievementsDefs = {
    { id = "first_tree", name = "Punch Drunk", desc = "Punched your first tree. Like every game.", check = function() return player.totalTreesPunched >= 1 end },
    { id = "ten_trees", name = "Deforestation Enthusiast", desc = "10 trees punched. The planet weeps.", check = function() return player.totalTreesPunched >= 10 end },
    { id = "first_rock", name = "Between a Rock and a Hard Place", desc = "Mined your first rock. You're basically Minecraft.", check = function() return player.totalRocksMined >= 1 end },
    { id = "first_death", name = "Skill Issue", desc = "Died for the first time. git gud.", check = function() return player.totalDeaths >= 1 end },
    { id = "five_deaths", name = "Frequent Dier", desc = "Died 5 times. Have you tried not dying?", check = function() return player.totalDeaths >= 5 end },
    { id = "first_craft", name = "Industrial Revolution", desc = "Crafted something. Capitalism intensifies.", check = function() return player.totalCrafts >= 1 end },
    { id = "walker", name = "Pedestrian", desc = "Walked 100 steps. There's no fast travel.", check = function() return player.totalStepsTaken >= 100 end },
    { id = "marathon", name = "Marathon Runner", desc = "500 steps. Your character has no stamina bar. Yet.", check = function() return player.totalStepsTaken >= 500 end },
    { id = "hoarder", name = "Hoarder (Derogatory)", desc = "30+ total resources. You'll never use them.", check = function() return (player.inventory.wood + player.inventory.stone + player.inventory.fiber + player.inventory.berries) >= 30 end },
    { id = "first_enemy", name = "Violence Is An Option", desc = "Defeated your first enemy. Wholesome.", check = function() return player.totalEnemiesDefeated >= 1 end },
    { id = "dread_collector", name = "Collector of Dread", desc = "5+ existential dread. Are you ok?", check = function() return player.inventory.existential_dread >= 5 end },
    { id = "opened_store", name = "Whale Watching", desc = "Opened the store. We see you.", check = function() return achievements["opened_store"] end },
    { id = "night_survivor", name = "Nocturnalist", desc = "Survived a full night. Barely.", check = function() return achievements["night_survivor"] end },
    { id = "boss_slayer", name = "Algorithm Breaker", desc = "Defeated The Algorithm. You're free. (Not really.)", check = function() return achievements["boss_slayer"] end },
    { id = "mushroom_eater", name = "Mycological Adventurer", desc = "Ate suspicious mushrooms. Bold choice.", check = function() return player.inventory.mushroom_sus >= 1 or craftedItems["Suspicious Mushroom Stew"] end },
}

-- Random events / patch notes
local patchNoteTimer = 0
local patchNotes = {
    { note = "PATCH 0.0.2: Fixed bug where fun was accidentally possible.", effect = function() addNotification("Engagement metrics reduced by 10%."); player.stats.engagement_metrics = math.max(0, player.stats.engagement_metrics - 10) end },
    { note = "PATCH 0.0.3: Added more trees by popular demand. (Your demand.)", effect = function() end },
    { note = "PATCH 0.0.4: Nerfed player happiness. Was OP.", effect = function() player.stats.boredom = math.min(100, player.stats.boredom + 20) end },
    { note = "HOTFIX: Rocks now contain stone. Previously contained nothing.", effect = function() end },
    { note = "PATCH 0.0.5: Added weather. Not because you asked.", effect = function() end },
    { note = "PATCH 0.0.6: Zombies buffed. Players nerfed. Balance.", effect = function() end },
    { note = "COMMUNITY UPDATE: We heard your feedback. We ignored it.", effect = function() addNotification("Your feedback has been acknowledged and discarded.") end },
    { note = "HOTFIX: Fixed exploit where players were having fun.", effect = function() player.stats.will_to_live = math.max(0, player.stats.will_to_live - 5) end },
    { note = "PATCH 0.0.7: Added microtransaction store. You're welcome.", effect = function() end },
    { note = "SEASON 2 ANNOUNCED: Same game but the number is different.", effect = function() addNotification("Season 2 content: Renamed 'Wood' to 'Season 2 Wood'.") end },
    { note = "SERVER MAINTENANCE: The servers are (the game is singleplayer).", effect = function() end },
    { note = "BALANCE UPDATE: Trees now fight back. (Not yet implemented.)", effect = function() end },
}

-- Review popup
local reviewPopup = false
local reviewTimer = 0
local hasBeenAskedForReview = false

-- "Server" messages
local serverMessages = {
    "Connecting to server... (this is a singleplayer game)",
    "Syncing cloud save... (there is no cloud save)",
    "Checking for updates... (there are no updates)",
    "Verifying purchase... (you didn't buy anything)",
    "Loading user profile... (you don't have one)",
    "Anti-cheat scan complete. (There's nothing to cheat at.)",
    "Matchmaking... (you are alone)",
    "Downloading Day 1 patch... (it's Day 10,000)",
    "Telemetry uploaded. We know everything. (We know nothing.)",
}
local serverMsgTimer = 0
local currentServerMsg = nil
local serverMsgDisplayTimer = 0

-- Death screen
local deathMessages = {
    "YOU DIED\n\nCause: Capitalism",
    "YOU DIED\n\nCause: Engagement metrics reached zero",
    "YOU DIED\n\nCause: Failed to monetize survival",
    "YOU DIED\n\nCause: The algorithm found you unworthy",
    "YOU DIED\n\nCause: Ran out of content (we ran out of content)",
    "YOU DIED\n\nCause: Skill issue (our fault actually)",
    "YOU DIED\n\nCause: Forgotten by the matchmaking server",
    "YOU DIED\n\nCause: The grind won",
    "YOU DIED\n\nCause: Existential overflow error",
}
local deathMessage = ""

-- Minimap
local minimapSize = 100
local minimapScale = 2

-- Sound system (procedural)
local sounds = {}

-- ============================================================
-- HELPERS
-- ============================================================
local function makeTileQuad(col, row, sheet)
    local stride = 19
    return love.graphics.newQuad(col * stride, row * stride, 18, 18, sheet:getDimensions())
end

local function makeCharQuad(col, row, sheet)
    local stride = 25
    return love.graphics.newQuad(col * stride, row * stride, 24, 24, sheet:getDimensions())
end

local function addNotification(text)
    table.insert(notifications, { text = text, timer = 3.5 })
    -- Keep notifications manageable
    while #notifications > 8 do
        table.remove(notifications, 1)
    end
end

local function shakeScreen(intensity, duration)
    screenShake.intensity = math.max(screenShake.intensity, intensity)
    screenShake.timer = math.max(screenShake.timer, duration or 0.2)
end

local function spawnParticles(worldX, worldY, count, color, speed, sizeRange)
    speed = speed or 150
    sizeRange = sizeRange or {2, 5}
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.5 + math.random() * 0.5)
        table.insert(particles, {
            x = worldX + math.random(-8, 8),
            y = worldY + math.random(-8, 8),
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd - math.random(50, 120),
            life = 0.4 + math.random() * 0.4,
            maxLife = 0.8,
            color = color,
            size = sizeRange[1] + math.random() * (sizeRange[2] - sizeRange[1]),
            gravity = 300,
        })
    end
end

local function addFloatingText(worldX, worldY, text, color)
    table.insert(floatingTexts, {
        x = worldX, y = worldY,
        text = text, timer = 1.2,
        color = color or {1, 1, 1},
    })
end

local function lungePlayer(dx, dy)
    playerLunge.ox = dx * TILE_SIZE * 0.4
    playerLunge.oy = dy * TILE_SIZE * 0.4
end

local function unlockAchievement(id)
    if not achievements[id] then
        achievements[id] = true
        for _, def in ipairs(achievementsDefs) do
            if def.id == id then
                table.insert(achievementQueue, def)
                break
            end
        end
    end
end

local function checkAchievements()
    for _, def in ipairs(achievementsDefs) do
        if not achievements[def.id] and def.check() then
            unlockAchievement(def.id)
        end
    end
end

local function addStatusEffect(name, duration, color)
    table.insert(player.statusEffects, { name = name, timer = duration, color = color or {1,1,1} })
    addNotification("Status effect: " .. name)
end

local function playSound(name)
    if sounds[name] then
        sounds[name]:stop()
        sounds[name]:play()
    end
end

local function changeWeather()
    local totalWeight = 0
    for _, w in ipairs(weatherTypes) do totalWeight = totalWeight + w.weight end
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, w in ipairs(weatherTypes) do
        cumulative = cumulative + w.weight
        if roll <= cumulative then
            weather.current = w.name
            weather.timer = w.duration[1] + math.random() * (w.duration[2] - w.duration[1])
            addNotification("Weather: " .. w.desc)
            if w.name == "blood_moon" then
                addNotification("The monsters are restless...")
                shakeScreen(5, 0.5)
            elseif w.name == "existential" then
                addNotification("You question the nature of this simulation.")
                player.stats.sanity = math.max(0, player.stats.sanity - 10)
            end
            return
        end
    end
end

-- ============================================================
-- MAP GENERATION
-- ============================================================
local function generateBiomes()
    -- Simple voronoi-ish biome placement
    local biomePoints = {}
    local biomeTypes = { BIOME.FOREST, BIOME.DESERT, BIOME.SWAMP, BIOME.PLAINS }
    for _ = 1, 12 do
        table.insert(biomePoints, {
            x = math.random(1, MAP_W),
            y = math.random(1, MAP_H),
            biome = biomeTypes[math.random(#biomeTypes)],
        })
    end
    -- Force spawn area to be forest
    table.insert(biomePoints, { x = 10, y = 10, biome = BIOME.FOREST })

    for y = 1, MAP_H do
        biomeMap[y] = {}
        for x = 1, MAP_W do
            local closestDist = 999999
            local closestBiome = BIOME.FOREST
            for _, bp in ipairs(biomePoints) do
                local dist = (x - bp.x)^2 + (y - bp.y)^2
                if dist < closestDist then
                    closestDist = dist
                    closestBiome = bp.biome
                end
            end
            biomeMap[y][x] = closestBiome
        end
    end
end

local function generateMap()
    math.randomseed(os.time())
    generateBiomes()

    for y = 1, MAP_H do
        map[y] = {}
        mapHP[y] = {}
        for x = 1, MAP_W do
            if x == 1 or x == MAP_W or y == 1 or y == MAP_H then
                map[y][x] = T.WATER
            else
                local biome = biomeMap[y][x]
                local r = math.random(100)

                if biome == BIOME.FOREST then
                    if r <= 25 then map[y][x] = T.GRASS
                    elseif r <= 35 then map[y][x] = T.DIRT
                    elseif r <= 72 then map[y][x] = T.TREE
                    elseif r <= 82 then map[y][x] = T.ROCK
                    elseif r <= 86 then map[y][x] = T.FLOWER
                    elseif r <= 90 then map[y][x] = T.MUSHROOM
                    elseif r <= 94 then map[y][x] = T.BERRY_BUSH
                    elseif r <= 97 then map[y][x] = T.TALL_GRASS
                    else map[y][x] = T.WATER
                    end
                elseif biome == BIOME.DESERT then
                    if r <= 50 then map[y][x] = T.SAND
                    elseif r <= 65 then map[y][x] = T.DIRT
                    elseif r <= 80 then map[y][x] = T.ROCK
                    elseif r <= 90 then map[y][x] = T.CACTUS
                    elseif r <= 95 then map[y][x] = T.DEAD_TREE
                    else map[y][x] = T.SAND
                    end
                elseif biome == BIOME.SWAMP then
                    if r <= 20 then map[y][x] = T.SWAMP
                    elseif r <= 35 then map[y][x] = T.WATER
                    elseif r <= 55 then map[y][x] = T.TREE
                    elseif r <= 65 then map[y][x] = T.DEAD_TREE
                    elseif r <= 75 then map[y][x] = T.MUSHROOM
                    elseif r <= 85 then map[y][x] = T.TALL_GRASS
                    elseif r <= 90 then map[y][x] = T.DIRT
                    else map[y][x] = T.SWAMP
                    end
                else -- PLAINS
                    if r <= 45 then map[y][x] = T.GRASS
                    elseif r <= 55 then map[y][x] = T.TALL_GRASS
                    elseif r <= 70 then map[y][x] = T.FLOWER
                    elseif r <= 80 then map[y][x] = T.TREE
                    elseif r <= 88 then map[y][x] = T.BERRY_BUSH
                    elseif r <= 95 then map[y][x] = T.ROCK
                    else map[y][x] = T.DIRT
                    end
                end
            end
            local props = tileProps[map[y][x]]
            if props and props.hp then
                mapHP[y][x] = props.hp
            end
        end
    end
    -- Clear spawn area
    for cy = 8, 13 do
        for cx = 8, 13 do
            if cy >= 1 and cy <= MAP_H and cx >= 1 and cx <= MAP_W then
                map[cy][cx] = T.GRASS
                mapHP[cy][cx] = nil
            end
        end
    end
    player.x = 10
    player.y = 10
end

-- ============================================================
-- TUTORIAL SYSTEM
-- ============================================================
local function queueTutorial(msg)
    table.insert(tutorialMessages, msg)
end

local function initTutorials()
    queueTutorial("Welcome to THE OTHER SIDE OF THE GRIND™!")
    queueTutorial("An OPEN WORLD SURVIVAL CRAFTING experience!")
    queueTutorial("Featuring FOUR procedurally generated biomes!")
    queueTutorial("(They're just different colored tiles.)")
    queueTutorial("Press WASD to move. Yes, we patented this.")
    queueTutorial("Press SPACE to punch things. The core gameplay.")
    queueTutorial("Press TAB for CRAFTING. Press F for STORE.")
    queueTutorial("Press M to toggle the MINIMAP. (It's tiny.)")
    queueTutorial("SURVIVE. CRAFT. GRIND. REPEAT. MONETIZE.")
    queueTutorial("Now go punch some trees, like every other game.")
end

-- ============================================================
-- PROCEDURAL SOUND GENERATION
-- ============================================================
local function generateSounds()
    local sampleRate = 44100

    -- Hit sound (short noise burst)
    local hitData = love.sound.newSoundData(math.floor(sampleRate * 0.08), sampleRate, 16, 1)
    for i = 0, hitData:getSampleCount() - 1 do
        local t = i / sampleRate
        local env = math.max(0, 1 - t / 0.08)
        local sample = (math.random() * 2 - 1) * env * 0.4
        sample = sample + math.sin(t * 800 * math.pi * 2) * env * 0.3
        hitData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    sounds.hit = love.audio.newSource(hitData)

    -- Break sound (longer crunch)
    local breakData = love.sound.newSoundData(math.floor(sampleRate * 0.2), sampleRate, 16, 1)
    for i = 0, breakData:getSampleCount() - 1 do
        local t = i / sampleRate
        local env = math.max(0, 1 - t / 0.2)
        local sample = (math.random() * 2 - 1) * env * 0.5
        sample = sample + math.sin(t * 400 * math.pi * 2) * env * 0.2
        sample = sample + math.sin(t * 200 * math.pi * 2) * env * 0.2
        breakData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    sounds.break_sfx = love.audio.newSource(breakData)

    -- Achievement jingle
    local achData = love.sound.newSoundData(math.floor(sampleRate * 0.4), sampleRate, 16, 1)
    local notes = {523.25, 659.25, 783.99, 1046.50}  -- C5, E5, G5, C6
    for i = 0, achData:getSampleCount() - 1 do
        local t = i / sampleRate
        local noteIdx = math.floor(t / 0.1) + 1
        if noteIdx > #notes then noteIdx = #notes end
        local env = math.max(0, 1 - (t % 0.1) / 0.15) * math.max(0, 1 - t / 0.5)
        local sample = math.sin(t * notes[noteIdx] * math.pi * 2) * env * 0.3
        achData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    sounds.achievement = love.audio.newSource(achData)

    -- Death sound
    local deathData = love.sound.newSoundData(math.floor(sampleRate * 0.5), sampleRate, 16, 1)
    for i = 0, deathData:getSampleCount() - 1 do
        local t = i / sampleRate
        local freq = 400 - t * 600
        local env = math.max(0, 1 - t / 0.5)
        local sample = math.sin(t * freq * math.pi * 2) * env * 0.4
        sample = sample + (math.random() * 2 - 1) * env * 0.1
        deathData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    sounds.death = love.audio.newSource(deathData)

    -- Craft sound
    local craftData = love.sound.newSoundData(math.floor(sampleRate * 0.15), sampleRate, 16, 1)
    for i = 0, craftData:getSampleCount() - 1 do
        local t = i / sampleRate
        local env = math.max(0, 1 - t / 0.15)
        local sample = math.sin(t * 1200 * math.pi * 2) * env * 0.2
        sample = sample + math.sin(t * 900 * math.pi * 2) * env * 0.15
        craftData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    sounds.craft = love.audio.newSource(craftData)

    -- Pickup / collect
    local pickupData = love.sound.newSoundData(math.floor(sampleRate * 0.1), sampleRate, 16, 1)
    for i = 0, pickupData:getSampleCount() - 1 do
        local t = i / sampleRate
        local freq = 600 + t * 4000
        local env = math.max(0, 1 - t / 0.1)
        local sample = math.sin(t * freq * math.pi * 2) * env * 0.2
        pickupData:setSample(i, math.max(-1, math.min(1, sample)))
    end
    sounds.pickup = love.audio.newSource(pickupData)
end

-- ============================================================
-- LOAD
-- ============================================================
function love.load()
    love.graphics.setBackgroundColor(0.15, 0.15, 0.18)
    love.graphics.setDefaultFilter("nearest", "nearest")

    tileSheet = love.graphics.newImage("assets/pixel-platformer/Tilemap/tilemap.png")
    charSheet = love.graphics.newImage("assets/pixel-platformer/Tilemap/tilemap-characters.png")

    -- Tile quads
    tileQuads.grass1     = makeTileQuad(0, 0, tileSheet)
    tileQuads.grass2     = makeTileQuad(1, 0, tileSheet)
    tileQuads.dirt1      = makeTileQuad(3, 0, tileSheet)
    tileQuads.dirt2      = makeTileQuad(4, 0, tileSheet)
    tileQuads.tree       = makeTileQuad(8, 3, tileSheet)
    tileQuads.trunk      = makeTileQuad(8, 4, tileSheet)
    tileQuads.rock       = makeTileQuad(9, 4, tileSheet)
    tileQuads.water      = makeTileQuad(13, 3, tileSheet)
    tileQuads.stump      = makeTileQuad(7, 4, tileSheet)
    tileQuads.rubble     = makeTileQuad(5, 0, tileSheet)
    tileQuads.heart      = makeTileQuad(0, 2, tileSheet)
    tileQuads.coin       = makeTileQuad(3, 2, tileSheet)
    tileQuads.attack     = makeTileQuad(2, 2, tileSheet)
    tileQuads.flower     = makeTileQuad(6, 4, tileSheet)
    tileQuads.mushroom   = makeTileQuad(10, 4, tileSheet)
    tileQuads.cactus     = makeTileQuad(7, 3, tileSheet)
    tileQuads.sand       = makeTileQuad(4, 0, tileSheet)
    tileQuads.swamp      = makeTileQuad(2, 0, tileSheet)
    tileQuads.tall_grass = makeTileQuad(1, 0, tileSheet)
    tileQuads.berry_bush = makeTileQuad(5, 3, tileSheet)
    tileQuads.dead_tree  = makeTileQuad(9, 3, tileSheet)
    tileQuads.key        = makeTileQuad(4, 2, tileSheet)
    tileQuads.flag       = makeTileQuad(5, 2, tileSheet)
    tileQuads.gem        = makeTileQuad(2, 2, tileSheet)

    -- Character quads
    charQuads.player_down  = makeCharQuad(8, 0, charSheet)
    charQuads.player_up    = makeCharQuad(8, 0, charSheet)
    charQuads.player_left  = makeCharQuad(8, 0, charSheet)
    charQuads.player_right = makeCharQuad(8, 0, charSheet)
    charQuads.zombie1 = makeCharQuad(0, 1, charSheet)
    charQuads.zombie2 = makeCharQuad(1, 1, charSheet)
    charQuads.zombie3 = makeCharQuad(2, 1, charSheet)
    charQuads.zombie4 = makeCharQuad(3, 1, charSheet)
    charQuads.zombie5 = makeCharQuad(4, 1, charSheet)
    charQuads.boss    = makeCharQuad(4, 2, charSheet)

    generateSounds()
    generateMap()
    initTutorials()
    changeWeather()
end

-- ============================================================
-- UPDATE
-- ============================================================
function love.update(dt)
    gameTime = gameTime + dt

    -- Loading screen
    if loadingScreen then
        loadingTimer = loadingTimer + dt
        if loadingTimer > 1.5 then
            currentLoadingTip = math.random(#loadingTips)
        end
        return
    end

    if not player.alive then return end

    -- Timers
    player.moveTimer = player.moveTimer - dt
    player.attackTimer = player.attackTimer - dt

    -- Attack animation
    if player.attackAnim then
        player.attackAnim.timer = player.attackAnim.timer - dt
        if player.attackAnim.timer <= 0 then player.attackAnim = nil end
    end

    -- Player lunge spring-back
    playerLunge.ox = playerLunge.ox * (1 - dt * 18)
    playerLunge.oy = playerLunge.oy * (1 - dt * 18)
    if math.abs(playerLunge.ox) < 0.5 then playerLunge.ox = 0 end
    if math.abs(playerLunge.oy) < 0.5 then playerLunge.oy = 0 end

    -- Screen shake decay
    if screenShake.timer > 0 then
        screenShake.timer = screenShake.timer - dt
        if screenShake.timer <= 0 then screenShake.intensity = 0 end
    end

    -- Punch combo timer
    if punchComboTimer > 0 then
        punchComboTimer = punchComboTimer - dt
        if punchComboTimer <= 0 then punchCombo = 0 end
    end

    -- Status effects
    for i = #player.statusEffects, 1, -1 do
        player.statusEffects[i].timer = player.statusEffects[i].timer - dt
        if player.statusEffects[i].timer <= 0 then
            table.remove(player.statusEffects, i)
        end
    end

    -- Continuous movement
    if player.moveTimer <= 0 and not craftingOpen and not storeOpen and not reviewPopup then
        local dx, dy = 0, 0
        if love.keyboard.isDown("w") or love.keyboard.isDown("up") then dy = -1; player.facing = "up" end
        if love.keyboard.isDown("s") or love.keyboard.isDown("down") then dy = 1; player.facing = "down" end
        if love.keyboard.isDown("a") or love.keyboard.isDown("left") then dx = -1; player.facing = "left" end
        if love.keyboard.isDown("d") or love.keyboard.isDown("right") then dx = 1; player.facing = "right" end

        if dx ~= 0 or dy ~= 0 then
            local nx, ny = player.x + dx, player.y + dy
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                local tile = map[ny][nx]
                if not tileProps[tile].solid then
                    player.x = nx
                    player.y = ny
                    player.moveTimer = player.moveDelay
                    player.totalStepsTaken = player.totalStepsTaken + 1

                    -- Walking on special tiles
                    if tile == T.FLOWER then
                        if math.random() < 0.1 then
                            addNotification("You crushed a flower. Monster.")
                        end
                    elseif tile == T.TALL_GRASS then
                        if math.random() < 0.05 then
                            local loot = math.random(100)
                            if loot < 50 then
                                player.inventory.fiber = player.inventory.fiber + 1
                                addNotification("+1 Fiber found in tall grass!")
                                playSound("pickup")
                            else
                                addNotification("The tall grass was empty. Like this game.")
                            end
                        end
                    elseif tile == T.SWAMP then
                        if math.random() < 0.08 then
                            addStatusEffect("Swamp Foot™", 5, {0.3, 0.6, 0.2})
                            player.moveDelay = 0.2
                        end
                    end
                end
            end
        end
    end

    -- Reset move delay if swamp foot expired
    local hasSwampFoot = false
    for _, e in ipairs(player.statusEffects) do
        if e.name == "Swamp Foot™" then hasSwampFoot = true end
    end
    if not hasSwampFoot then player.moveDelay = 0.12 end

    -- Camera follow
    camera.x = player.x * TILE_SIZE - SCREEN_W / 2
    camera.y = player.y * TILE_SIZE - SCREEN_H / 2
    camera.x = math.max(0, math.min(camera.x, MAP_W * TILE_SIZE - SCREEN_W))
    camera.y = math.max(0, math.min(camera.y, MAP_H * TILE_SIZE - SCREEN_H))

    -- Day/night cycle
    local dayProgress = (gameTime % dayLength) / dayLength
    local prevPhase = dayPhase
    if dayProgress < 0.4 then dayPhase = "day"
    elseif dayProgress < 0.5 then dayPhase = "dusk"
    elseif dayProgress < 0.85 then dayPhase = "night"
    else dayPhase = "dawn"
    end
    -- Track surviving a full night
    if prevPhase == "night" and dayPhase == "dawn" then
        unlockAchievement("night_survivor")
    end

    -- Survival stats drain
    local drainMult = 1
    if weather.current == "blood_moon" then drainMult = 2 end
    if weather.current == "existential" then
        player.stats.sanity = math.max(0, player.stats.sanity - dt * 5)
    end

    player.stats.hunger = math.max(0, player.stats.hunger - dt * 2.0 * drainMult)
    player.stats.thirst = math.max(0, player.stats.thirst - dt * 2.5 * drainMult)
    player.stats.boredom = math.min(100, player.stats.boredom + dt * 1.0)
    player.stats.engagement_metrics = math.max(0, player.stats.engagement_metrics - dt * 0.6)
    player.stats.will_to_live = math.max(0, player.stats.will_to_live - dt * 0.3)
    player.stats.sanity = math.max(0, player.stats.sanity - dt * 0.2)

    -- Death checks
    if player.stats.hunger <= 0 then
        player.alive = false
        deathMessage = "YOU DIED\n\nCause: Starvation\n(Should have punched more trees)"
    elseif player.stats.will_to_live <= 0 then
        player.alive = false
        deathMessage = deathMessages[math.random(#deathMessages)]
    elseif player.stats.sanity <= 0 then
        player.alive = false
        deathMessage = "YOU DIED\n\nCause: Sanity reached zero\n(The mushrooms weren't enough)"
    end
    if not player.alive then
        player.totalDeaths = player.totalDeaths + 1
        playSound("death")
        checkAchievements()
        return
    end

    -- Tutorial system
    if currentTutorial then
        tutorialTimer = tutorialTimer - dt
        if tutorialTimer <= 0 then currentTutorial = nil end
    elseif #tutorialMessages > 0 then
        currentTutorial = table.remove(tutorialMessages, 1)
        tutorialTimer = 3.0
    end

    -- Notifications
    for i = #notifications, 1, -1 do
        notifications[i].timer = notifications[i].timer - dt
        if notifications[i].timer <= 0 then table.remove(notifications, i) end
    end

    -- Achievement display
    if currentAchievement then
        achievementTimer = achievementTimer - dt
        if achievementTimer <= 0 then currentAchievement = nil end
    elseif #achievementQueue > 0 then
        currentAchievement = table.remove(achievementQueue, 1)
        achievementTimer = 4.0
        playSound("achievement")
    end

    -- Weather
    weather.timer = weather.timer - dt
    if weather.timer <= 0 then changeWeather() end

    -- Rain particles
    if weather.current == "rain" then
        for _ = 1, 3 do
            table.insert(weather.raindrops, {
                x = camera.x + math.random(0, SCREEN_W),
                y = camera.y - 10,
                speed = 400 + math.random() * 200,
                life = 1.5,
            })
        end
    end
    for i = #weather.raindrops, 1, -1 do
        local r = weather.raindrops[i]
        r.y = r.y + r.speed * dt
        r.x = r.x - 30 * dt
        r.life = r.life - dt
        if r.life <= 0 or r.y > camera.y + SCREEN_H + 20 then
            table.remove(weather.raindrops, i)
        end
    end

    -- Fog
    if weather.current == "fog" then
        weather.fogAlpha = math.min(0.4, weather.fogAlpha + dt * 0.3)
    else
        weather.fogAlpha = math.max(0, weather.fogAlpha - dt * 0.5)
    end

    -- Server messages
    serverMsgTimer = serverMsgTimer + dt
    if serverMsgTimer > 25 + math.random() * 20 then
        serverMsgTimer = 0
        currentServerMsg = serverMessages[math.random(#serverMessages)]
        serverMsgDisplayTimer = 4
    end
    if serverMsgDisplayTimer > 0 then
        serverMsgDisplayTimer = serverMsgDisplayTimer - dt
        if serverMsgDisplayTimer <= 0 then currentServerMsg = nil end
    end

    -- Patch notes / random events
    patchNoteTimer = patchNoteTimer + dt
    if patchNoteTimer > 45 + math.random() * 30 then
        patchNoteTimer = 0
        local patch = patchNotes[math.random(#patchNotes)]
        addNotification("=== " .. patch.note .. " ===")
        patch.effect()
        shakeScreen(3, 0.2)
    end

    -- Review popup
    if not hasBeenAskedForReview and gameTime > 60 then
        reviewPopup = true
        hasBeenAskedForReview = true
    end

    -- Enemy spawning
    local canSpawn = dayPhase == "night" or weather.current == "blood_moon"
    local maxEnemies = dayPhase == "night" and 10 or 4
    if weather.current == "blood_moon" then maxEnemies = 15 end

    if canSpawn then
        enemySpawnTimer = enemySpawnTimer + dt
        local spawnInterval = weather.current == "blood_moon" and 2 or 3.5
        if enemySpawnTimer > spawnInterval and #enemies < maxEnemies then
            enemySpawnTimer = 0
            local ex, ey
            for _ = 1, 50 do
                ex = math.random(2, MAP_W - 1)
                ey = math.random(2, MAP_H - 1)
                local dist = math.abs(ex - player.x) + math.abs(ey - player.y)
                if not tileProps[map[ey][ex]].solid and dist > 8 and dist < 20 then
                    break
                end
            end
            local names = {
                "Procedurally Generated Zombie™",
                "AI-Driven Skeleton™",
                "Machine Learning Ghoul™",
                "Cloud-Native Creeper™",
                "As-A-Service Specter™",
                "Blockchain Shambler™",
                "Web3 Wraith™",
                "Agile Abomination™",
                "Scrum Master of the Dead™",
                "DevOps Demon™",
                "Full-Stack Phantom™",
                "Minimum Viable Ghoul™",
            }
            local sprites = { "zombie1", "zombie2", "zombie3", "zombie4", "zombie5" }
            table.insert(enemies, {
                x = ex, y = ey,
                sprite = sprites[math.random(#sprites)],
                name = names[math.random(#names)],
                moveTimer = 0,
                hp = weather.current == "blood_moon" and 4 or 2,
                damage = weather.current == "blood_moon" and 20 or 12,
                speed = 0.6 + math.random() * 0.4,
            })
            addNotification("A " .. enemies[#enemies].name .. " has appeared!")
        end
    else
        if dayPhase == "dawn" and #enemies > 0 and not bossActive then
            local count = #enemies
            enemies = {}
            addNotification("The monsters despawned. (" .. count .. " bugs fixed)")
        end
    end

    -- Boss spawning
    if not bossActive and player.totalEnemiesDefeated >= 5 and dayPhase == "night" and math.random() < 0.001 then
        bossActive = true
        local bx, by = player.x + 12, player.y
        bx = math.max(2, math.min(MAP_W - 1, bx))
        by = math.max(2, math.min(MAP_H - 1, by))
        boss = {
            x = bx, y = by,
            sprite = "boss",
            name = "THE ALGORITHM",
            moveTimer = 0,
            hp = 20,
            maxHp = 20,
            damage = 25,
            speed = 0.5,
            phase = 1,
        }
        addNotification("=== BOSS: THE ALGORITHM HAS ARRIVED ===")
        addNotification("It determines your engagement. It determines your fate.")
        shakeScreen(20, 1.0)
    end

    -- Enemy movement
    for _, e in ipairs(enemies) do
        e.moveTimer = e.moveTimer + dt
        if e.moveTimer > e.speed then
            e.moveTimer = 0
            local dx, dy = 0, 0
            if math.random() > 0.3 then
                if e.x < player.x then dx = 1 elseif e.x > player.x then dx = -1 end
                if e.y < player.y then dy = 1 elseif e.y > player.y then dy = -1 end
                if dx ~= 0 and dy ~= 0 then
                    if math.random() > 0.5 then dx = 0 else dy = 0 end
                end
            else
                local dirs = {{1,0},{-1,0},{0,1},{0,-1}}
                local d = dirs[math.random(#dirs)]
                dx, dy = d[1], d[2]
            end
            local nx, ny = e.x + dx, e.y + dy
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                if not tileProps[map[ny][nx]].solid then
                    e.x = nx; e.y = ny
                end
            end
            if e.x == player.x and e.y == player.y then
                player.stats.will_to_live = player.stats.will_to_live - e.damage
                shakeScreen(8, 0.2)
                spawnParticles((player.x-1)*TILE_SIZE + TILE_SIZE/2, (player.y-1)*TILE_SIZE + TILE_SIZE/2,
                    8, {1, 0.2, 0.2}, 100, {2, 4})
                addNotification("A " .. e.name .. " vibed at you! (-" .. e.damage .. " Will to Live)")
                playSound("hit")
            end
        end
    end

    -- Boss movement
    if boss then
        boss.moveTimer = boss.moveTimer + dt
        if boss.moveTimer > boss.speed then
            boss.moveTimer = 0
            -- Boss always moves toward player
            local dx, dy = 0, 0
            if boss.x < player.x then dx = 1 elseif boss.x > player.x then dx = -1 end
            if boss.y < player.y then dy = 1 elseif boss.y > player.y then dy = -1 end
            if dx ~= 0 and dy ~= 0 then
                if math.random() > 0.5 then dx = 0 else dy = 0 end
            end
            local nx, ny = boss.x + dx, boss.y + dy
            if nx >= 1 and nx <= MAP_W and ny >= 1 and ny <= MAP_H then
                if not tileProps[map[ny][nx]].solid then
                    boss.x = nx; boss.y = ny
                end
            end
            if boss.x == player.x and boss.y == player.y then
                player.stats.will_to_live = player.stats.will_to_live - boss.damage
                player.stats.engagement_metrics = math.max(0, player.stats.engagement_metrics - 15)
                shakeScreen(15, 0.4)
                addNotification("THE ALGORITHM optimized your suffering! (-" .. boss.damage .. " WtL, -15 Engagement)")
                playSound("hit")
            end
            -- Boss phase 2 at half health: faster
            if boss.hp <= boss.maxHp / 2 and boss.phase == 1 then
                boss.phase = 2
                boss.speed = 0.3
                addNotification("THE ALGORITHM enters Phase 2: Aggressive Monetization!")
                shakeScreen(10, 0.5)
            end
        end
    end

    -- Particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            p.vy = p.vy + p.gravity * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.size = p.size * (1 - dt * 2)
        end
    end

    -- Floating texts
    for i = #floatingTexts, 1, -1 do
        local ft = floatingTexts[i]
        ft.timer = ft.timer - dt
        ft.y = ft.y - 40 * dt
        if ft.timer <= 0 then table.remove(floatingTexts, i) end
    end

    -- Achievement checks
    checkAchievements()
end

-- ============================================================
-- DRAW
-- ============================================================
local function drawTile(quad, x, y)
    love.graphics.draw(tileSheet, quad, x, y, 0, TILE_SIZE / 18, TILE_SIZE / 18)
end

local function drawChar(quad, x, y, sx, sy)
    love.graphics.draw(charSheet, quad, x, y, 0, (sx or 1) * TILE_SIZE / 24, (sy or 1) * TILE_SIZE / 24)
end

function love.draw()
    -- Loading screen
    if loadingScreen then
        love.graphics.setColor(0.05, 0.05, 0.08)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("THE OTHER SIDE OF THE GRIND", 0, 120, SCREEN_W, "center")
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("An Open World Survival Crafting Experience™", 0, 150, SCREEN_W, "center")
        love.graphics.printf("\"From the visionary team that brought you nothing\"", 0, 175, SCREEN_W, "center")
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.printf("Featuring: Trees, Rocks, and Existential Dread", 0, 210, SCREEN_W, "center")
        love.graphics.printf("4 Biomes! Weather! A Boss! Achievements!", 0, 230, SCREEN_W, "center")
        love.graphics.printf("All procedurally generated (it's math.random)", 0, 250, SCREEN_W, "center")

        -- Fake loading bar
        local progress = math.min(loadingTimer / 5.0, 1.0)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 200, 320, 400, 20)
        love.graphics.setColor(0.2, 0.7, 0.3)
        love.graphics.rectangle("fill", 200, 320, 400 * progress, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(string.format("Loading assets... %d%%", math.floor(progress * 100)), 200, 323, 400, "center")

        -- Second fake bar that goes slower
        local progress2 = math.min(loadingTimer / 6.0, 1.0)
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", 200, 350, 400, 12)
        love.graphics.setColor(0.7, 0.3, 0.2)
        love.graphics.rectangle("fill", 200, 350, 400 * progress2, 12)
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(string.format("Compiling shader pipeline... %d%%", math.floor(progress2 * 100)), 200, 350, 400, "center")

        -- Third even slower bar
        if loadingTimer > 2 then
            local progress3 = math.min((loadingTimer - 2) / 5.0, 1.0)
            love.graphics.setColor(0.3, 0.3, 0.3)
            love.graphics.rectangle("fill", 200, 370, 400, 12)
            love.graphics.setColor(0.3, 0.3, 0.7)
            love.graphics.rectangle("fill", 200, 370, 400 * progress3, 12)
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf(string.format("Initializing blockchain... %d%%", math.floor(progress3 * 100)), 200, 370, 400, "center")
        end

        love.graphics.setColor(0.8, 0.8, 0.5)
        love.graphics.printf(loadingTips[currentLoadingTip], 80, 420, 640, "center")

        if loadingTimer > 6.0 then
            love.graphics.setColor(1, 1, 1, 0.5 + 0.5 * math.sin(gameTime * 4))
            love.graphics.printf("Press any key to begin your suffering", 0, 480, SCREEN_W, "center")
        end

        love.graphics.setColor(1, 0.3, 0.3, 0.4)
        love.graphics.printf("EARLY ACCESS - v0.0.1a (Pre-Alpha Founder's Edition)", 0, 560, SCREEN_W, "center")
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.printf("© 2026 Grindstone Studios. All rights reserved. No refunds.", 0, 580, SCREEN_W, "center")
        return
    end

    -- Day/night tint
    local dayTint = { 1, 1, 1 }
    if dayPhase == "dusk" then dayTint = { 0.9, 0.7, 0.5 }
    elseif dayPhase == "night" then dayTint = { 0.3, 0.3, 0.5 }
    elseif dayPhase == "dawn" then dayTint = { 0.7, 0.6, 0.7 }
    end
    if weather.current == "blood_moon" then dayTint = { 0.6, 0.2, 0.2 } end
    if weather.current == "existential" then dayTint = { 0.5, 0.4, 0.6 } end

    -- Camera transform with shake
    love.graphics.push()
    local shakeX, shakeY = 0, 0
    if screenShake.timer > 0 then
        shakeX = (math.random() - 0.5) * 2 * screenShake.intensity
        shakeY = (math.random() - 0.5) * 2 * screenShake.intensity
    end
    love.graphics.translate(-camera.x + shakeX, -camera.y + shakeY)

    -- Only draw visible tiles (optimization for large map)
    local startCol = math.max(1, math.floor(camera.x / TILE_SIZE))
    local endCol = math.min(MAP_W, math.ceil((camera.x + SCREEN_W) / TILE_SIZE) + 1)
    local startRow = math.max(1, math.floor(camera.y / TILE_SIZE))
    local endRow = math.min(MAP_H, math.ceil((camera.y + SCREEN_H) / TILE_SIZE) + 1)

    for y = startRow, endRow do
        for x = startCol, endCol do
            local tile = map[y][x]
            local px = (x - 1) * TILE_SIZE
            local py = (y - 1) * TILE_SIZE
            love.graphics.setColor(dayTint[1], dayTint[2], dayTint[3])

            if tile == T.GRASS then drawTile(tileQuads.grass1, px, py)
            elseif tile == T.DIRT then drawTile(tileQuads.dirt1, px, py)
            elseif tile == T.WATER then
                -- Animated water tint
                local wt = math.sin(gameTime * 2 + x * 0.5 + y * 0.3) * 0.1
                love.graphics.setColor(dayTint[1] * (0.9 + wt), dayTint[2] * (0.9 + wt), dayTint[3])
                drawTile(tileQuads.water, px, py)
            elseif tile == T.TREE then
                drawTile(tileQuads.grass1, px, py)
                -- Slight sway
                local sway = math.sin(gameTime * 1.5 + x * 2 + y) * 1.5
                love.graphics.draw(tileSheet, tileQuads.tree, px + TILE_SIZE/2 + sway, py, 0,
                    TILE_SIZE/18, TILE_SIZE/18, 9, 0)
            elseif tile == T.ROCK then
                drawTile(tileQuads.grass1, px, py)
                drawTile(tileQuads.rock, px, py)
            elseif tile == T.STUMP then
                drawTile(tileQuads.grass1, px, py)
                drawTile(tileQuads.stump, px, py)
            elseif tile == T.RUBBLE then
                drawTile(tileQuads.rubble, px, py)
            elseif tile == T.FLOWER then
                drawTile(tileQuads.grass1, px, py)
                local bob = math.sin(gameTime * 2 + x + y * 3) * 2
                love.graphics.setColor(dayTint[1], dayTint[2], dayTint[3])
                love.graphics.draw(tileSheet, tileQuads.flower, px, py + bob, 0, TILE_SIZE/18, TILE_SIZE/18)
            elseif tile == T.MUSHROOM then
                drawTile(tileQuads.grass1, px, py)
                -- Pulsing glow for suspicious mushrooms
                local glow = 0.5 + 0.5 * math.sin(gameTime * 3 + x + y)
                love.graphics.setColor(dayTint[1] * (0.8 + glow * 0.4), dayTint[2] * 0.8, dayTint[3] * (0.8 + glow * 0.3))
                drawTile(tileQuads.mushroom, px, py)
            elseif tile == T.CACTUS then
                drawTile(tileQuads.sand, px, py)
                love.graphics.setColor(dayTint[1], dayTint[2], dayTint[3])
                drawTile(tileQuads.cactus, px, py)
            elseif tile == T.SAND then
                drawTile(tileQuads.sand, px, py)
            elseif tile == T.SWAMP then
                -- Bubbly swamp
                local sw = math.sin(gameTime * 1.5 + x * 3 + y * 2) * 0.15
                love.graphics.setColor(dayTint[1] * (0.6 + sw), dayTint[2] * (0.7 + sw), dayTint[3] * 0.5)
                drawTile(tileQuads.swamp, px, py)
            elseif tile == T.TALL_GRASS then
                drawTile(tileQuads.grass1, px, py)
                local sway = math.sin(gameTime * 2 + x * 1.5 + y * 0.7) * 2
                love.graphics.setColor(dayTint[1] * 0.8, dayTint[2] * 1.0, dayTint[3] * 0.7)
                love.graphics.draw(tileSheet, tileQuads.tall_grass, px + sway, py, 0, TILE_SIZE/18, TILE_SIZE/18)
            elseif tile == T.BERRY_BUSH then
                drawTile(tileQuads.grass1, px, py)
                love.graphics.setColor(dayTint[1], dayTint[2], dayTint[3])
                drawTile(tileQuads.berry_bush, px, py)
            elseif tile == T.DEAD_TREE then
                local biome = biomeMap[y] and biomeMap[y][x]
                if biome == BIOME.DESERT then
                    drawTile(tileQuads.sand, px, py)
                else
                    drawTile(tileQuads.swamp, px, py)
                end
                love.graphics.setColor(dayTint[1] * 0.7, dayTint[2] * 0.6, dayTint[3] * 0.5)
                drawTile(tileQuads.dead_tree, px, py)
            end
        end
    end

    -- Draw enemies
    for _, e in ipairs(enemies) do
        love.graphics.setColor(dayTint[1], dayTint[2], dayTint[3])
        local bob = math.sin(gameTime * 4 + e.x + e.y) * 2
        drawChar(charQuads[e.sprite], (e.x - 1) * TILE_SIZE, (e.y - 1) * TILE_SIZE + bob)
    end

    -- Draw boss
    if boss then
        local pulse = 1 + math.sin(gameTime * 6) * 0.1
        if boss.phase == 2 then
            love.graphics.setColor(1, 0.3, 0.3)
        else
            love.graphics.setColor(1, 0.8, 0.2)
        end
        drawChar(charQuads.boss, (boss.x - 1) * TILE_SIZE, (boss.y - 1) * TILE_SIZE, pulse, pulse)
        -- Boss health bar
        local bhx = (boss.x - 1) * TILE_SIZE
        local bhy = (boss.y - 1) * TILE_SIZE - 8
        love.graphics.setColor(0.3, 0, 0)
        love.graphics.rectangle("fill", bhx, bhy, TILE_SIZE, 4)
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", bhx, bhy, TILE_SIZE * (boss.hp / boss.maxHp), 4)
    end

    -- Draw player
    love.graphics.setColor(dayTint[1], dayTint[2], dayTint[3])
    local playerQuad = charQuads["player_" .. player.facing]
    drawChar(playerQuad,
        (player.x - 1) * TILE_SIZE + playerLunge.ox,
        (player.y - 1) * TILE_SIZE + playerLunge.oy)

    -- Attack animation
    if player.attackAnim then
        local a = player.attackAnim
        local flash = math.sin(a.timer * 30) > 0
        if flash then
            love.graphics.setColor(1, 1, 0.5)
            drawTile(tileQuads.attack, (a.x - 1) * TILE_SIZE, (a.y - 1) * TILE_SIZE)
        end
    end

    -- Particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x - p.size/2, p.y - p.size/2, p.size, p.size)
    end

    -- Floating texts
    for _, ft in ipairs(floatingTexts) do
        local alpha = math.min(ft.timer / 0.3, 1)
        local scale = 1 + (1.2 - ft.timer) * 0.5
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(ft.x, ft.y)
        love.graphics.scale(scale, scale)
        love.graphics.print(ft.text, -#ft.text * 3, 0)
        love.graphics.pop()
    end

    -- Rain
    if weather.current == "rain" then
        love.graphics.setColor(0.6, 0.7, 1, 0.4)
        for _, r in ipairs(weather.raindrops) do
            love.graphics.line(r.x, r.y, r.x - 3, r.y + 12)
        end
    end

    -- Pixel storm
    if weather.current == "pixel_storm" then
        for _ = 1, 20 do
            love.graphics.setColor(math.random(), math.random(), math.random(), 0.3)
            local sx = camera.x + math.random(0, SCREEN_W)
            local sy = camera.y + math.random(0, SCREEN_H)
            love.graphics.rectangle("fill", sx, sy, math.random(3, 12), math.random(3, 12))
        end
    end

    love.graphics.pop()

    -- ==================== HUD ====================

    -- Fog overlay
    if weather.fogAlpha > 0 then
        love.graphics.setColor(0.6, 0.65, 0.7, weather.fogAlpha)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    -- Blood moon vignette
    if weather.current == "blood_moon" then
        love.graphics.setColor(0.5, 0, 0, 0.15 + math.sin(gameTime * 2) * 0.05)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end

    -- Existential weather
    if weather.current == "existential" then
        love.graphics.setColor(0, 0, 0, 0.1 + math.sin(gameTime * 0.5) * 0.05)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
        love.graphics.setColor(1, 1, 1, 0.05)
        love.graphics.printf("What is the point?", 0, SCREEN_H/2 + math.sin(gameTime) * 50, SCREEN_W, "center")
    end

    -- HUD background
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, SCREEN_W, 70)

    -- Survival bars
    local bars = {
        { label = "Hunger",     val = player.stats.hunger,             color = {0.9, 0.5, 0.2} },
        { label = "Thirst",     val = player.stats.thirst,             color = {0.3, 0.6, 0.9} },
        { label = "Boredom",    val = player.stats.boredom,            color = {0.6, 0.6, 0.6} },
        { label = "Engage",     val = player.stats.engagement_metrics, color = {0.9, 0.3, 0.8} },
        { label = "Will2Live",  val = player.stats.will_to_live,       color = {0.3, 0.9, 0.4} },
        { label = "Sanity",     val = player.stats.sanity,             color = {0.9, 0.9, 0.3} },
    }
    for i, bar in ipairs(bars) do
        local bx = 5
        local by = 3 + (i - 1) * 11
        love.graphics.setColor(0.15, 0.15, 0.15)
        love.graphics.rectangle("fill", bx + 55, by, 70, 8)
        local barColor = bar.color
        -- Flash red when low
        if bar.val < 20 and bar.label ~= "Boredom" then
            local flash = math.sin(gameTime * 8) > 0
            if flash then barColor = {1, 0.1, 0.1} end
        end
        love.graphics.setColor(barColor)
        love.graphics.rectangle("fill", bx + 55, by, 70 * (bar.val / 100), 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(bar.label, bx, by - 1)
    end

    -- Inventory
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(string.format("Wood:%d Stone:%d Fiber:%d Berry:%d Shroom:%d Dread:%d",
        player.inventory.wood, player.inventory.stone, player.inventory.fiber,
        player.inventory.berries, player.inventory.mushroom_sus,
        player.inventory.existential_dread), 140, 5)

    -- Status effects
    local effectStr = ""
    for _, e in ipairs(player.statusEffects) do
        effectStr = effectStr .. "[" .. e.name .. "] "
    end
    if effectStr ~= "" then
        love.graphics.setColor(0.8, 0.8, 0.2)
        love.graphics.print(effectStr, 140, 19)
    end

    -- Day/night + weather
    local phaseNames = { day = "Day (Safe-ish)", dusk = "Dusk (Uh Oh)", night = "NIGHT (Content!)", dawn = "Dawn (Phew)" }
    love.graphics.setColor(1, 1, 0.7)
    love.graphics.print(phaseNames[dayPhase] .. " | " .. weather.current:upper(), 140, 33)

    -- Biome display
    local currentBiome = biomeMap[player.y] and biomeMap[player.y][player.x]
    local biomeNames = { [BIOME.FOREST] = "Forest", [BIOME.DESERT] = "Desert (DLC)", [BIOME.SWAMP] = "Swamp (Premium)", [BIOME.PLAINS] = "Plains" }
    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("Biome: " .. (biomeNames[currentBiome] or "???"), 140, 47)

    -- Time survived
    local minutes = math.floor(gameTime / 60)
    local seconds = math.floor(gameTime % 60)
    love.graphics.print(string.format("Survived: %d:%02d | Kills: %d", minutes, seconds, player.totalEnemiesDefeated), 140, 57)

    -- Combo meter
    if punchCombo >= 2 then
        local comboAlpha = 0.5 + 0.5 * math.sin(gameTime * 10)
        love.graphics.setColor(1, 0.8, 0.2, comboAlpha)
        love.graphics.printf("x" .. punchCombo .. " COMBO!", 0, 75, SCREEN_W, "center")
    end

    -- Tile tooltip (what player is facing)
    local tdx, tdy = 0, 0
    if player.facing == "up" then tdy = -1 elseif player.facing == "down" then tdy = 1
    elseif player.facing == "left" then tdx = -1 elseif player.facing == "right" then tdx = 1 end
    local ttx, tty = player.x + tdx, player.y + tdy
    if ttx >= 1 and ttx <= MAP_W and tty >= 1 and tty <= MAP_H then
        local facingTile = map[tty][ttx]
        local facingProps = tileProps[facingTile]
        if facingProps then
            love.graphics.setColor(1, 1, 1, 0.7)
            local tooltipText = facingProps.name
            if facingProps.resource and mapHP[tty] and mapHP[tty][ttx] then
                tooltipText = tooltipText .. " [HP: " .. mapHP[tty][ttx] .. "]"
            end
            love.graphics.printf(tooltipText, 0, SCREEN_H - 30, SCREEN_W, "center")
        end
    end

    -- EARLY ACCESS watermark
    love.graphics.setColor(1, 0.2, 0.2, 0.12)
    love.graphics.printf("EARLY ACCESS", 0, SCREEN_H / 2 - 30, SCREEN_W, "center")

    -- Minimap
    love.graphics.setColor(0, 0, 0, 0.7)
    local mmx = SCREEN_W - minimapSize - 10
    local mmy = SCREEN_H - minimapSize - 35
    love.graphics.rectangle("fill", mmx - 2, mmy - 2, minimapSize + 4, minimapSize + 4)
    local mmTileW = minimapSize / MAP_W
    local mmTileH = minimapSize / MAP_H
    for y = 1, MAP_H do
        for x = 1, MAP_W do
            local tile = map[y][x]
            if tile == T.WATER then love.graphics.setColor(0.2, 0.3, 0.7, 0.8)
            elseif tile == T.TREE or tile == T.DEAD_TREE then love.graphics.setColor(0.1, 0.5, 0.2, 0.8)
            elseif tile == T.ROCK then love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
            elseif tile == T.SAND then love.graphics.setColor(0.8, 0.7, 0.4, 0.8)
            elseif tile == T.SWAMP then love.graphics.setColor(0.3, 0.4, 0.2, 0.8)
            elseif tile == T.CACTUS then love.graphics.setColor(0.2, 0.6, 0.3, 0.8)
            else love.graphics.setColor(0.3, 0.5, 0.3, 0.5)
            end
            love.graphics.rectangle("fill", mmx + (x-1) * mmTileW, mmy + (y-1) * mmTileH, mmTileW, mmTileH)
        end
    end
    -- Player dot on minimap
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", mmx + (player.x-1) * mmTileW - 1, mmy + (player.y-1) * mmTileH - 1, 3, 3)
    -- Enemy dots
    love.graphics.setColor(1, 0, 0)
    for _, e in ipairs(enemies) do
        love.graphics.rectangle("fill", mmx + (e.x-1) * mmTileW, mmy + (e.y-1) * mmTileH, 2, 2)
    end
    if boss then
        love.graphics.setColor(1, 0, 1)
        love.graphics.rectangle("fill", mmx + (boss.x-1) * mmTileW - 1, mmy + (boss.y-1) * mmTileH - 1, 4, 4)
    end

    -- Tutorial popup
    if currentTutorial then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 100, SCREEN_H - 110, SCREEN_W - 200, 60, 8, 8)
        love.graphics.setColor(1, 0.9, 0.3)
        love.graphics.printf(currentTutorial, 110, SCREEN_H - 100, SCREEN_W - 220, "center")
    end

    -- Notifications
    for i, n in ipairs(notifications) do
        local alpha = math.min(n.timer, 1)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.printf(n.text, 10, SCREEN_H - 150 - (i - 1) * 16, SCREEN_W - minimapSize - 40, "right")
    end

    -- Achievement popup
    if currentAchievement then
        local aw = 350
        local ah = 60
        local ax = (SCREEN_W - aw) / 2
        local ay = 80
        local slide = math.min(achievementTimer / 0.3, 1)
        ay = ay - (1 - slide) * 50

        love.graphics.setColor(0.15, 0.1, 0.3, 0.95)
        love.graphics.rectangle("fill", ax, ay, aw, ah, 8, 8)
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.rectangle("line", ax, ay, aw, ah, 8, 8)
        love.graphics.printf("ACHIEVEMENT UNLOCKED", ax, ay + 5, aw, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(currentAchievement.name, ax, ay + 22, aw, "center")
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf(currentAchievement.desc, ax + 10, ay + 38, aw - 20, "center")
    end

    -- Server message
    if currentServerMsg then
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, SCREEN_H - 20, SCREEN_W, 20)
        love.graphics.setColor(0.5, 0.8, 0.5, 0.8)
        love.graphics.printf(currentServerMsg, 0, SCREEN_H - 18, SCREEN_W, "center")
    end

    -- Boss health bar (top of screen)
    if boss then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 200, 72, 400, 20, 4, 4)
        local bossColor = boss.phase == 2 and {1, 0.2, 0.2} or {0.8, 0.2, 0.8}
        love.graphics.setColor(bossColor)
        love.graphics.rectangle("fill", 202, 74, 396 * (boss.hp / boss.maxHp), 16, 3, 3)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("THE ALGORITHM" .. (boss.phase == 2 and " [ENRAGED]" or ""),
            200, 75, 400, "center")
    end

    -- ==================== MENUS ====================

    -- Crafting menu
    if craftingOpen then
        love.graphics.setColor(0, 0, 0, 0.92)
        love.graphics.rectangle("fill", 50, 60, SCREEN_W - 100, SCREEN_H - 100, 8, 8)

        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf("CRAFTING MENU™ (Patent Pending)", 50, 70, SCREEN_W - 100, "center")
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("\"We spent 3 months on this UI.\"", 50, 86, SCREEN_W - 100, "center")

        local scrollOffset = math.max(0, (craftingSelection - 4) * 65)
        love.graphics.setScissor(50, 100, SCREEN_W - 100, SCREEN_H - 180)
        for i, recipe in ipairs(recipes) do
            local ry = 105 + (i - 1) * 65 - scrollOffset
            local canCraft = true
            local costStr = ""
            for item, amount in pairs(recipe.cost) do
                local has = player.inventory[item] or 0
                if has < amount then canCraft = false end
                costStr = costStr .. item .. ": " .. amount .. "(" .. has .. ")  "
            end

            if i == craftingSelection then
                love.graphics.setColor(0.25, 0.25, 0.35)
                love.graphics.rectangle("fill", 60, ry - 3, SCREEN_W - 120, 60, 4, 4)
            end

            love.graphics.setColor(canCraft and {1,1,1} or {0.4,0.4,0.4})
            love.graphics.print(recipe.name, 70, ry)
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(recipe.desc, 70, ry + 15)
            love.graphics.setColor(0.9, 0.7, 0.3)
            love.graphics.print("Cost: " .. costStr, 70, ry + 32)

            if craftedItems[recipe.name] then
                love.graphics.setColor(0.3, 0.9, 0.3)
                love.graphics.print("[CRAFTED]", SCREEN_W - 170, ry)
            end
        end
        love.graphics.setScissor()

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("Up/Down to select, ENTER to craft, TAB to close", 50, SCREEN_H - 60, SCREEN_W - 100, "center")
    end

    -- Fake store
    if storeOpen then
        love.graphics.setColor(0, 0, 0, 0.95)
        love.graphics.rectangle("fill", 50, 60, SCREEN_W - 100, SCREEN_H - 100, 8, 8)

        love.graphics.setColor(1, 0.5, 0.2)
        love.graphics.printf("PREMIUM STORE™", 50, 70, SCREEN_W - 100, "center")
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("\"Give us money for nothing\"", 50, 86, SCREEN_W - 100, "center")

        for i, item in ipairs(storeItems) do
            local sy = 105 + (i - 1) * 55
            if i == storeSelection then
                love.graphics.setColor(0.3, 0.2, 0.1)
                love.graphics.rectangle("fill", 60, sy - 3, SCREEN_W - 120, 50, 4, 4)
            end
            love.graphics.setColor(1, 0.9, 0.6)
            love.graphics.print(item.name, 70, sy)
            love.graphics.setColor(0.6, 0.6, 0.6)
            love.graphics.print(item.desc, 70, sy + 15)
            love.graphics.setColor(0.9, 0.3, 0.3)
            love.graphics.print("Price: " .. item.price, 70, sy + 30)
        end

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("Up/Down to browse, ENTER to 'purchase', F to close", 50, SCREEN_H - 60, SCREEN_W - 100, "center")
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.printf("(Nothing is real. Nothing works. That's the point.)", 50, SCREEN_H - 45, SCREEN_W - 100, "center")
    end

    -- Review popup
    if reviewPopup then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

        love.graphics.setColor(0.15, 0.15, 0.2, 0.95)
        love.graphics.rectangle("fill", 150, 180, 500, 240, 12, 12)
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.rectangle("line", 150, 180, 500, 240, 12, 12)

        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("ENJOYING THE GAME?", 150, 195, 500, "center")
        love.graphics.setColor(0.7, 0.7, 0.7)
        love.graphics.printf("You've been playing for " .. math.floor(gameTime) .. " seconds!\nThat's longer than our QA testing!", 170, 225, 460, "center")
        love.graphics.printf("Please rate us 5 stars on the store!", 170, 275, 460, "center")

        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf("★ ★ ★ ★ ★", 150, 305, 500, "center")

        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.printf("[Y] Yes, 5 stars! (does nothing)    [N] No (also does nothing)", 150, 360, 500, "center")
        love.graphics.printf("[X] Ask me again later (we will)", 150, 380, 500, "center")
    end

    -- Death screen
    if not player.alive then
        love.graphics.setColor(0, 0, 0, 0.88)
        love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf(deathMessage, 100, SCREEN_H / 2 - 80, SCREEN_W - 200, "center")
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.printf("Deaths: " .. player.totalDeaths .. " | Trees Punched: " .. player.totalTreesPunched .. " | Time Wasted: " .. math.floor(gameTime) .. "s", 100, SCREEN_H / 2 + 20, SCREEN_W - 200, "center")
        love.graphics.printf("Press R to respawn and continue the grind", 100, SCREEN_H / 2 + 60, SCREEN_W - 200, "center")
        love.graphics.printf("Press ESC to reclaim your time", 100, SCREEN_H / 2 + 80, SCREEN_W - 200, "center")
    end
end

-- ============================================================
-- INPUT
-- ============================================================
function love.keypressed(key)
    -- Loading screen
    if loadingScreen then
        if loadingTimer > 6.0 then
            loadingScreen = false
            gameStarted = true
        end
        return
    end

    -- Review popup
    if reviewPopup then
        if key == "y" then
            reviewPopup = false
            addNotification("Thanks! Your 5-star review has been discarded!")
            player.stats.engagement_metrics = math.min(100, player.stats.engagement_metrics + 10)
        elseif key == "n" then
            reviewPopup = false
            addNotification("Your negative feedback has been noted and ignored!")
            player.stats.will_to_live = math.max(0, player.stats.will_to_live - 5)
        elseif key == "x" then
            reviewPopup = false
            hasBeenAskedForReview = false  -- Will ask again!
            addNotification("We'll ask again. Oh, we'll ask again.")
        end
        return
    end

    -- Death screen
    if not player.alive then
        if key == "r" then
            player.alive = true
            player.stats.hunger = 100
            player.stats.thirst = 100
            player.stats.boredom = 0
            player.stats.engagement_metrics = 100
            player.stats.will_to_live = 100
            player.stats.sanity = 100
            player.statusEffects = {}
            player.inventory.existential_dread = player.inventory.existential_dread + 1
            enemies = {}
            boss = nil
            bossActive = false
            addNotification("You respawned! Existential dread +1.")
            addNotification("Your items are safe because we're not THAT cruel.")
        elseif key == "escape" then
            love.event.quit()
        end
        return
    end

    if key == "escape" then
        if craftingOpen then craftingOpen = false
        elseif storeOpen then storeOpen = false
        else
            addNotification("Quitting? But you haven't bought the Season Pass!")
            love.event.quit()
        end
        return
    end

    -- Crafting
    if key == "tab" then
        craftingOpen = not craftingOpen
        storeOpen = false
        if craftingOpen then addNotification("CRAFTING MENU opened. This changes everything.") end
        return
    end

    -- Store
    if key == "f" then
        storeOpen = not storeOpen
        craftingOpen = false
        if storeOpen then
            unlockAchievement("opened_store")
            addNotification("PREMIUM STORE opened. Your wallet trembles.")
        end
        return
    end

    -- Menu navigation
    if craftingOpen then
        if key == "up" then craftingSelection = math.max(1, craftingSelection - 1)
        elseif key == "down" then craftingSelection = math.min(#recipes, craftingSelection + 1)
        elseif key == "return" then
            local recipe = recipes[craftingSelection]
            local canCraft = true
            for item, amount in pairs(recipe.cost) do
                if (player.inventory[item] or 0) < amount then canCraft = false end
            end
            if canCraft and not craftedItems[recipe.name] then
                for item, amount in pairs(recipe.cost) do
                    player.inventory[item] = player.inventory[item] - amount
                end
                craftedItems[recipe.name] = true
                player.totalCrafts = player.totalCrafts + 1
                player.stats.engagement_metrics = math.min(100, player.stats.engagement_metrics + 20)
                player.stats.boredom = math.max(0, player.stats.boredom - 15)
                if recipe.effect then recipe.effect() end
                addNotification("CRAFTED: " .. recipe.name)
                addNotification(recipe.unlocks)
                playSound("craft")
                shakeScreen(5, 0.2)
                checkAchievements()
            elseif craftedItems[recipe.name] then
                addNotification("Already crafted. No duplicating joy in this economy.")
            else
                addNotification("Not enough resources. The grind continues.")
            end
        end
        return
    end

    if storeOpen then
        if key == "up" then storeSelection = math.max(1, storeSelection - 1)
        elseif key == "down" then storeSelection = math.min(#storeItems, storeSelection + 1)
        elseif key == "return" then
            local item = storeItems[storeSelection]
            addNotification("PURCHASE FAILED: " .. item.price .. " not found in your account.")
            addNotification("(This store doesn't work. It's a metaphor.)")
            shakeScreen(3, 0.15)
        end
        return
    end

    -- Attack / harvest with space
    if key == "space" then
        local dx, dy = 0, 0
        if player.facing == "up" then dy = -1
        elseif player.facing == "down" then dy = 1
        elseif player.facing == "left" then dx = -1
        elseif player.facing == "right" then dx = 1
        end

        lungePlayer(dx, dy)

        local tx, ty = player.x + dx, player.y + dy
        if tx >= 1 and tx <= MAP_W and ty >= 1 and ty <= MAP_H then
            local tile = map[ty][tx]
            local props = tileProps[tile]
            local hitWorldX = (tx - 1) * TILE_SIZE + TILE_SIZE / 2
            local hitWorldY = (ty - 1) * TILE_SIZE + TILE_SIZE / 2

            -- Check boss hit
            if boss and boss.x == tx and boss.y == ty then
                boss.hp = boss.hp - 1
                player.attackAnim = { x = tx, y = ty, timer = 0.4 }
                shakeScreen(10, 0.25)
                spawnParticles(hitWorldX, hitWorldY, 20, {1, 0, 1}, 250, {3, 8})
                addFloatingText(hitWorldX, hitWorldY - 20, "-1 HP!", {1, 0.3, 1})
                playSound("hit")
                if boss.hp <= 0 then
                    shakeScreen(25, 1.0)
                    spawnParticles(hitWorldX, hitWorldY, 60, {1, 0.8, 0.2}, 350, {4, 12})
                    spawnParticles(hitWorldX, hitWorldY, 40, {1, 0, 1}, 300, {3, 10})
                    addFloatingText(hitWorldX, hitWorldY - 40, "DEFEATED!", {1, 0.8, 0.2})
                    addNotification("=== THE ALGORITHM HAS BEEN DEFEATED ===")
                    addNotification("You are free from the engagement loop!")
                    addNotification("...until Season 2.")
                    player.stats.engagement_metrics = 100
                    player.stats.will_to_live = 100
                    player.stats.boredom = 0
                    unlockAchievement("boss_slayer")
                    boss = nil
                    bossActive = false
                    playSound("break_sfx")
                else
                    addNotification("Hit THE ALGORITHM! (" .. boss.hp .. "/" .. boss.maxHp .. " HP)")
                end
                return
            end

            -- Check enemy hit
            local hitEnemy = false
            for i, e in ipairs(enemies) do
                if e.x == tx and e.y == ty then
                    e.hp = e.hp - 1
                    hitEnemy = true
                    player.attackAnim = { x = tx, y = ty, timer = 0.3 }
                    shakeScreen(6, 0.15)
                    spawnParticles(hitWorldX, hitWorldY, 12, {1, 0.3, 0.3}, 200, {3, 7})
                    addFloatingText(hitWorldX, hitWorldY - 20, "BONK!", {1, 0.4, 0.4})
                    playSound("hit")
                    if e.hp <= 0 then
                        shakeScreen(12, 0.3)
                        spawnParticles(hitWorldX, hitWorldY, 25, {1, 0.2, 0.2}, 250, {4, 9})
                        addFloatingText(hitWorldX, hitWorldY - 40, "DEFEATED!", {1, 0.8, 0.2})
                        addNotification("Defeated " .. e.name .. "! No loot though.")
                        table.remove(enemies, i)
                        player.totalEnemiesDefeated = player.totalEnemiesDefeated + 1
                        player.stats.engagement_metrics = math.min(100, player.stats.engagement_metrics + 10)
                        playSound("break_sfx")
                    else
                        addNotification("Bonked " .. e.name .. "! (" .. e.hp .. " HP left)")
                    end
                    break
                end
            end

            -- Harvest resource
            if not hitEnemy and props and props.resource then
                player.attackAnim = { x = tx, y = ty, timer = 0.3 }
                punchCombo = punchCombo + 1
                punchComboTimer = 2.0
                playSound("hit")

                local msgIdx = math.min(punchCombo, #hitMessages)
                local hitMsg = hitMessages[msgIdx]
                local shakeAmt = math.min(3 + punchCombo * 2, 15)
                shakeScreen(shakeAmt, 0.1 + punchCombo * 0.02)
                local particleCount = math.min(5 + punchCombo * 3, 30)

                mapHP[ty][tx] = mapHP[ty][tx] - 1
                if mapHP[ty][tx] <= 0 then
                    local resource = props.resource
                    local amount = math.random(1, 3) + math.floor(punchCombo / 3)
                    player.inventory[resource] = (player.inventory[resource] or 0) + amount
                    player.stats.hunger = math.min(100, player.stats.hunger + 5)
                    player.stats.thirst = math.min(100, player.stats.thirst + 2)
                    shakeScreen(15, 0.35)
                    playSound("break_sfx")

                    if tile == T.TREE or tile == T.DEAD_TREE then
                        map[ty][tx] = T.STUMP
                        spawnParticles(hitWorldX, hitWorldY, 35, {0.6, 0.4, 0.2}, 220, {3, 8})
                        spawnParticles(hitWorldX, hitWorldY, 15, {0.3, 0.7, 0.2}, 180, {2, 5})
                        addFloatingText(hitWorldX, hitWorldY - 20, "+" .. amount .. " WOOD!", {0.4, 1, 0.4})
                        addNotification("+" .. amount .. " Artisanal Organic Wood™!")
                        addNotification(treeFallMessages[math.random(#treeFallMessages)])
                        player.totalTreesPunched = player.totalTreesPunched + 1
                    elseif tile == T.ROCK then
                        map[ty][tx] = T.RUBBLE
                        spawnParticles(hitWorldX, hitWorldY, 35, {0.6, 0.6, 0.7}, 250, {3, 9})
                        spawnParticles(hitWorldX, hitWorldY, 10, {1, 0.8, 0.3}, 150, {2, 4})
                        addFloatingText(hitWorldX, hitWorldY - 20, "+" .. amount .. " STONE!", {0.7, 0.7, 1})
                        addNotification("+" .. amount .. " Blockchain Ore™!")
                        addNotification(rockBreakMessages[math.random(#rockBreakMessages)])
                        player.totalRocksMined = player.totalRocksMined + 1
                    elseif tile == T.CACTUS then
                        map[ty][tx] = T.SAND
                        spawnParticles(hitWorldX, hitWorldY, 20, {0.2, 0.7, 0.3}, 180, {2, 5})
                        addFloatingText(hitWorldX, hitWorldY - 20, "+" .. amount .. " FIBER!", {0.3, 0.9, 0.5})
                        addNotification("+" .. amount .. " Hostile Fiber™ extracted! Ouch.")
                        player.stats.will_to_live = math.max(0, player.stats.will_to_live - 3)
                    elseif tile == T.MUSHROOM then
                        map[ty][tx] = T.GRASS
                        spawnParticles(hitWorldX, hitWorldY, 15, {0.8, 0.3, 0.8}, 120, {2, 6})
                        addFloatingText(hitWorldX, hitWorldY - 20, "+" .. amount .. " SUS SHROOM!", {0.8, 0.3, 0.8})
                        addNotification("+" .. amount .. " Suspicious Mushroom™ acquired!")
                        addNotification("The mushroom whispers forbidden truths.")
                        player.stats.sanity = math.max(0, player.stats.sanity - 5)
                        addStatusEffect("Mycological Insight™", 8, {0.8, 0.3, 0.8})
                    elseif tile == T.BERRY_BUSH then
                        map[ty][tx] = T.GRASS
                        spawnParticles(hitWorldX, hitWorldY, 15, {0.8, 0.2, 0.3}, 150, {2, 5})
                        addFloatingText(hitWorldX, hitWorldY - 20, "+" .. amount .. " BERRIES!", {0.9, 0.3, 0.4})
                        addNotification("+" .. amount .. " Organic Micro-Berries™ harvested!")
                        player.stats.hunger = math.min(100, player.stats.hunger + 10)
                    end
                    playSound("pickup")
                    punchCombo = 0
                else
                    -- Hit particles
                    if tile == T.TREE or tile == T.DEAD_TREE then
                        spawnParticles(hitWorldX, hitWorldY, particleCount, {0.6, 0.4, 0.2}, 150, {2, 5})
                        spawnParticles(hitWorldX, hitWorldY, math.floor(particleCount/3), {0.3, 0.8, 0.2}, 100, {1, 3})
                    elseif tile == T.ROCK then
                        spawnParticles(hitWorldX, hitWorldY, particleCount, {0.6, 0.6, 0.7}, 180, {2, 6})
                    elseif tile == T.CACTUS then
                        spawnParticles(hitWorldX, hitWorldY, particleCount, {0.2, 0.6, 0.3}, 140, {2, 4})
                    end
                    addFloatingText(hitWorldX, hitWorldY - 10, hitMsg, {1, 1, 0.6})
                    if punchCombo >= 3 then
                        addNotification(hitMsg .. " x" .. punchCombo .. " COMBO! (" .. mapHP[ty][tx] .. " left)")
                    else
                        addNotification(hitMsg .. " (" .. mapHP[ty][tx] .. " hits remaining)")
                    end
                end
            elseif not hitEnemy and not (props and props.resource) then
                spawnParticles(hitWorldX, hitWorldY, 3, {0.5, 0.5, 0.5}, 50, {1, 3})
                addFloatingText(hitWorldX, hitWorldY - 10, "whiff", {0.5, 0.5, 0.5})
                addNotification("You swing at nothing. Peak gameplay.")
                player.attackAnim = { x = tx, y = ty, timer = 0.2 }
                punchCombo = 0
            end
        end
        return
    end
end
