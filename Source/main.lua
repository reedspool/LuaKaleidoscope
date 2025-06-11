local gfx = playdate.graphics
local geo = playdate.geometry

playdate.display.setRefreshRate(0); -- 0 means infinite (device max is 50)
local w = 400
local h = 240
local d = 467 -- diagonal

local angle_conversion = 2 * math.pi / 360

local images = {
    playdate.graphics.image.new("images/035nest1.png"),
    playdate.graphics.image.new("images/021hex0n.png"),
    playdate.graphics.image.new("images/036noise0.png"),
    playdate.graphics.image.new("images/042scallops0n.png"),
    playdate.graphics.image.new("images/047stones1n.png"),
    playdate.graphics.image.new("images/077flowers0n.png"),
}

gfx.setColor(gfx.kColorBlack)

local topLeft = {pt=geo.point.new(0, 0)}
local topRight = {pt=geo.point.new(w, 0) }
local botLeft = {pt= geo.point.new(0, h) }
local botRight = {pt= geo.point.new(w, h) }
local center = { pt=geo.point.new(w/2, h/2) }

local topEdge = geo.lineSegment.new(topLeft.pt.x, topLeft.pt.y, topRight.pt.x, topRight.pt.y)
local bottomEdge = geo.lineSegment.new(botLeft.pt.x, botLeft.pt.y, botRight.pt.x, botRight.pt.y)
local leftEdge = geo.lineSegment.new(topLeft.pt.x, topLeft.pt.y, botLeft.pt.x, botLeft.pt.y)
local rightEdge = geo.lineSegment.new(topRight.pt.x, topRight.pt.y, botRight.pt.x, botRight.pt.y)
local edges = {topEdge, rightEdge, bottomEdge, leftEdge}

local function spinner(a)
  return geo.lineSegment.new(
        (d/2) * math.cos(a * angle_conversion) + w/2,
        (d/2) * math.sin(a * angle_conversion) + h/2,
        -(d/2) * math.cos(a * angle_conversion) + w/2,
        -(d/2) * math.sin(a * angle_conversion) + h/2
  )
end

local function polyFromPts(...)
    local a = {}
    for k, v in pairs({...}) do
       a[#a + 1] = v.pt
    end

    return geo.polygon.new(table.unpack(a))
end

local crankCounter = 0
local transformCounter = 0;
function playdate.update()
    gfx.fillRect(0, 0, 400, 240)

    local crank = playdate.getCrankChange()
    crankCounter = crankCounter + crank
    local line1 = spinner(crankCounter)
    local line2 = spinner(0.5 * crankCounter + 20)
    local line3 = spinner(0.2 * crankCounter + -10)

    local edgePts = {{}, {}, {}, {}}

    local lines = {
        { line=line1, image1=images[1], image2=images[2] },
        { line=line2, image1=images[3], image2=images[4] },
        { line=line3, image1=images[5], image2=images[6] }}

    for l = 1, #lines do
        local image1 = true
        for i = 1, 4 do
            local edge = edges[i]
            local inter, pt = lines[l].line:intersectsLineSegment(edge)
            if inter then
                local image = lines[l].image1
                if (not image1) then image = lines[l].image2 end
                image1 = not image1
                edgePts[i][#edgePts[i] + 1] = { pt=pt, image=image }
            end
        end
    end

    table.sort(edgePts[1], function(a, b) return a.pt.x < b.pt.x end)
    table.sort(edgePts[2], function(a, b) return a.pt.y < b.pt.y end)
    table.sort(edgePts[3], function(a, b) return b.pt.x < a.pt.x end)
    table.sort(edgePts[4], function(a, b) return b.pt.y < a.pt.y end)
    local topPts = edgePts[1]
    local rightPts = edgePts[2]
    local bottomPts = edgePts[3]
    local leftPts = edgePts[4]

    local firstTop = topPts[1]
    local lastTop = topPts[#topPts]
    local firstRight = rightPts[1]
    local lastRight = rightPts[#rightPts]
    local firstBottom = bottomPts[1]
    local lastBottom = bottomPts[#bottomPts]
    local firstLeft = leftPts[1]
    local lastLeft = leftPts[#leftPts]

    local wedges = {}

    -- polygon containing topLeft as the first corner
    if firstTop then --if any lines are intersecting the top edge
        if lastLeft then
            local wedge = polyFromPts(firstTop, topLeft, lastLeft, center)
            wedge:close()
            table.insert(wedges, { poly=wedge, image=lastLeft.image })
        end
    else
        local wedge = polyFromPts(firstRight, topRight, topLeft, lastLeft, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=lastLeft.image })
    end

    -- polygons exclusively on top
    for i = 1, #topPts - 1 do
        local ptA = topPts[i]
        local ptB = topPts[i + 1]
        local wedge = polyFromPts(ptA, ptB, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=ptA.image })
    end

    -- polygon containing topRight as the first corner
    if firstRight then --if any lines are intersecting the right edge
        if lastTop then
            local wedge = polyFromPts(firstRight, topRight, lastTop, center)
            wedge:close()
            table.insert(wedges, { poly=wedge, image=lastTop.image })
        end
    else
        local wedge = polyFromPts(firstBottom, botRight, topRight, lastTop, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=lastTop.image })
    end

    -- polygons exclusively on right
    for i = 1, #rightPts - 1 do
        local ptA = rightPts[i]
        local ptB = rightPts[i + 1]
        local wedge = polyFromPts(ptA, ptB, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=ptA.image })
    end

    -- polygon containing botRight as the first corner
    if firstBottom then --if any lines are intersecting the bottom edge
        if lastRight then
            local wedge = polyFromPts(firstBottom, botRight, lastRight, center)
            wedge:close()
            table.insert(wedges, { poly=wedge, image=lastRight.image })
        end
    else
        local wedge = polyFromPts(firstLeft, botLeft, botRight, lastRight, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=lastRight.image })
    end

    -- polygons exclusively on bottom
    for i = 1, #bottomPts - 1 do
        local ptA = bottomPts[i]
        local ptB = bottomPts[i + 1]
        local wedge = polyFromPts(ptA, ptB, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=ptB.image })
    end

    -- polygon containing botLeft as the first corner
    if firstLeft then --if any lines are intersecting the left edge
        if lastBottom then
            local wedge = polyFromPts(firstLeft, botLeft, lastBottom, center)
            wedge:close()
            table.insert(wedges, { poly=wedge, image=lastBottom.image })
        end
    else
        local wedge = polyFromPts(firstTop, topLeft, botLeft, lastBottom, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=lastBottom.image })
    end

    -- polygons exclusively on left
    for i = 1, #leftPts - 1 do
        local ptA = leftPts[i]
        local ptB = leftPts[i + 1]
        local wedge = polyFromPts(ptA, ptB, center)
        wedge:close()
        table.insert(wedges, { poly=wedge, image=ptB.image })
    end

    local debugPts = {}
    table.insert(debugPts, topLeft)
    for i = 1, #topPts do
        table.insert(debugPts, topPts[i])
    end
    table.insert(debugPts, topRight)
    for i = 1, #rightPts do
        table.insert(debugPts, rightPts[i])
    end
    table.insert(debugPts, botRight)
    for i = 1, #bottomPts do
        table.insert(debugPts, bottomPts[i])
    end
    table.insert(debugPts, botLeft)
    for i = 1, #leftPts do
        table.insert(debugPts, leftPts[i])
    end

    gfx.pushContext()
    gfx.setColor(gfx.kColorXOR)
    for i = 1, #debugPts do
        local pt = debugPts[i]
        gfx.fillRect(pt.pt.x - 5, pt.pt.y - 5, 10, 10)
    end
    gfx.popContext()

    -- transformCounter = transformCounter + 1
    -- Get a continuous sin wave between 0 and 1
    transformCounter = (math.sin(crankCounter * angle_conversion) + 1) * 0.5
    for i = 1, #wedges do
        local wedge = wedges[i].poly

        -- draw a stencil in a wedge shape
        local wedgeImg = gfx.image.new(w, h, gfx.kColorBlack)
        gfx.pushContext(wedgeImg)
            gfx.setColor(gfx.kColorWhite)
            gfx.fillPolygon(wedge)
        gfx.popContext()

        -- draw a tiled image with that stencil
        gfx.pushContext()
            gfx.setStencilImage(wedgeImg)
            local image = wedges[i].image
            image:drawTiled(
                -- Map 0-1 range to 0-w and 0-h
                0 - (math.floor(transformCounter * w) % w),
                0 - (math.floor(transformCounter * h) % h),
                w + (math.floor(transformCounter * w) % w),
                h + (math.floor(transformCounter * h) % h))
        gfx.popContext()
    end

    playdate.drawFPS(5, 5);
end
