--========================================--
-- Monitor Blackjack Casino (UI Version)
--========================================--

-- CONFIG
local betChest = peripheral.wrap("bottom")
local bankChest = peripheral.wrap("back")
local mon = peripheral.wrap("right")

mon.setTextScale(0.5)
mon.setBackgroundColor(colors.black)
mon.clear()

--========================================--
-- HELPER FUNCTIONS
--========================================--

local function centerText(y, text, color)
    mon.setCursorPos(1, y)
    mon.clearLine()
    local w, h = mon.getSize()
    mon.setCursorPos(math.floor((w - #text) / 2), y)
    mon.setTextColor(color)
    mon.write(text)
end

local function drawBox(x1, y1, x2, y2, color)
    paintutils.drawFilledBox(x1, y1, x2, y2, color)
end

local function drawButton(x1, y1, x2, y2, label, color)
    drawBox(x1, y1, x2, y2, color)
    mon.setTextColor(colors.white)
    mon.setCursorPos(x1 + 1, y1 + 1)
    mon.write(label)
end

--========================================--
-- CHEST LOGIC
--========================================--

local function getBet()
    for slot = 1, betChest.size() do
        local item = betChest.getItemDetail(slot)
        if item and item.name == "minecraft:diamond" then
            return slot, item.count
        end
    end
    return nil, 0
end

--========================================--
-- BLACKJACK LOGIC
--========================================--

local function drawCard()
    local card = math.random(2, 14)
    if card >= 12 then
        return 10
    elseif card == 11 then
        return 11
    else
        return card
    end
end

local function handValue(cards)
    local total = 0
    local aces = 0

    for _, card in ipairs(cards) do
        total = total + card
        if card == 11 then
            aces = aces + 1
        end
    end

    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end

    return total
end

local function drawCardBox(x, y, value)
    drawBox(x, y, x+4, y+3, colors.white)
    mon.setTextColor(colors.black)
    mon.setCursorPos(x+2, y+1)
    mon.write(value)
end

local function showHands(playerCards, dealerCards, hideDealer)
    mon.clear()

    centerText(1, "BLACKJACK CASINO", colors.yellow)

    -- Dealer section
    centerText(3, "Dealer:", colors.red)

    if hideDealer then
        drawCardBox(2, 5, dealerCards[1])
        drawCardBox(8, 5, "?")
    else
        for i, card in ipairs(dealerCards) do
            drawCardBox(2 + (i-1)*6, 5, card)
        end
        local total = handValue(dealerCards)
        centerText(9, "Dealer Total: "..total, colors.white)
    end

    -- Player section
    centerText(11, "Player:", colors.green)

    for i, card in ipairs(playerCards) do
        drawCardBox(2 + (i-1)*6, 13, card)
    end

    local total = handValue(playerCards)
    centerText(17, "Your Total: "..total, colors.white)
end

--========================================--
-- PLAYER TURN (UI BUTTONS)
--========================================--

local function playerTurn(playerCards, dealerCards)
    showHands(playerCards, dealerCards, true)

    drawButton(5, 20, 20, 24, " HIT ", colors.blue)
    drawButton(25, 20, 40, 24, " STAND ", colors.red)

    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")

        -- HIT BUTTON
        if x >= 5 and x <= 20 and y >= 20 and y <= 24 then
            table.insert(playerCards, drawCard())
            showHands(playerCards, dealerCards, true)
            drawButton(5, 20, 20, 24, " HIT ", colors.blue)
            drawButton(25, 20, 40, 24, " STAND ", colors.red)

            if handValue(playerCards) > 21 then
                return handValue(playerCards)
            end
        end

        -- STAND BUTTON
        if x >= 25 and x <= 40 and y >= 20 and y <= 24 then
            return handValue(playerCards)
        end
    end
end

--========================================--
-- DEALER TURN
--========================================--

local function dealerTurn(dealerCards)
    while handValue(dealerCards) < 17 do
        table.insert(dealerCards, drawCard())
    end
    return handValue(dealerCards)
end

--========================================--
-- FULL GAME
--========================================--

local function playBlackjack()
    local playerCards = { drawCard(), drawCard() }
    local dealerCards = { drawCard(), drawCard() }

    local playerTotal = playerTurn(playerCards, dealerCards)
    if playerTotal > 21 then
        showHands(playerCards, dealerCards, false)
        centerText(22, "YOU BUST! DEALER WINS", colors.red)
        sleep(2)
        return "lose"
    end

    local dealerTotal = dealerTurn(dealerCards)

    showHands(playerCards, dealerCards, false)

    if dealerTotal > 21 then
        centerText(22, "DEALER BUSTS! YOU WIN!", colors.green)
        sleep(2)
        return "win"
    end

    if playerTotal > dealerTotal then
        centerText(22, "YOU WIN!", colors.green)
        sleep(2)
        return "win"
    else
        centerText(22, "DEALER WINS!", colors.red)
        sleep(2)
        return "lose"
    end
end

--========================================--
-- PAYOUT LOGIC
--========================================--

local function payout(betAmount, result)
    local slot, amount = getBet()
    if slot then
        betChest.pushItems("back", slot, betAmount)
    end

    if result == "win" then
        bankChest.pushItems("bottom", 1, betAmount * 2)
    end
end

--========================================--
-- MAIN LOOP
--========================================--

mon.clear()
centerText(10, "Place diamonds in chest to play!", colors.white)

while true do
    sleep(1)
    local slot, bet = getBet()

    if bet > 0 then
        local result = playBlackjack()
        payout(bet, result)
        mon.clear()
        centerText(10, "Place diamonds in chest to play again!", colors.white)
    end
end
