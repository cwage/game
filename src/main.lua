-- Tile IDs
local FLOOR = 0
local WALL = 1

-- Tile size in pixels
local TILE_SIZE = 40

-- 20x15 map (800x600 at 40px tiles)
local map = {
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,1},
    {1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
    {1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
    {1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1},
    {1,0,0,1,1,1,0,0,0,0,0,0,0,1,1,1,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
}

local player = {
    x = 2,
    y = 2,
}

local colors = {
    [FLOOR] = {0.3, 0.3, 0.35},
    [WALL]  = {0.5, 0.4, 0.3},
    player  = {0.2, 0.6, 0.9},
}

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
end

function love.draw()
    -- Draw map
    for row = 1, #map do
        for col = 1, #map[row] do
            local tile = map[row][col]
            love.graphics.setColor(colors[tile])
            love.graphics.rectangle("fill",
                (col - 1) * TILE_SIZE,
                (row - 1) * TILE_SIZE,
                TILE_SIZE, TILE_SIZE)
        end
    end

    -- Draw grid lines
    love.graphics.setColor(0.15, 0.15, 0.2)
    for row = 0, #map do
        love.graphics.line(0, row * TILE_SIZE, #map[1] * TILE_SIZE, row * TILE_SIZE)
    end
    for col = 0, #map[1] do
        love.graphics.line(col * TILE_SIZE, 0, col * TILE_SIZE, #map * TILE_SIZE)
    end

    -- Draw player
    love.graphics.setColor(colors.player)
    love.graphics.rectangle("fill",
        (player.x - 1) * TILE_SIZE + 4,
        (player.y - 1) * TILE_SIZE + 4,
        TILE_SIZE - 8, TILE_SIZE - 8)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
        return
    end

    local dx, dy = 0, 0
    if key == "w" then dy = -1
    elseif key == "s" then dy = 1
    elseif key == "a" then dx = -1
    elseif key == "d" then dx = 1
    end

    local nx = player.x + dx
    local ny = player.y + dy

    if nx >= 1 and nx <= #map[1] and ny >= 1 and ny <= #map then
        if map[ny][nx] == FLOOR then
            player.x = nx
            player.y = ny
        end
    end
end
