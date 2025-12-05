--========================================--
-- Monitor Blackjack Casino (ASCII UI)
--========================================--

-- CONFIG: peripherals
local betChest = peripheral.wrap("bottom")  -- player chest (bets & winnings)
local bankChest = peripheral.wrap("back")   -- casino bank chest
local mon = peripheral.wrap("right")        -- advanced monitor on the right

-- Seed RNG
math.randomseed(os.time())

-- Monitor setup
mon.setTextScale(0.5)
mon.setBackgroundColor(colors.black)
mon.setTextColor(colors.white)
mon.clear()

--========================================--
-- HELPER FUNCTIONS (DRAWING / TEXT)
--========================================--

local function clearLine(y)
    mon.setCursorPos(1, y)
    mon.clearLine()
end

local function centerText(y, text, color)
    local w, _ = mon.getSize()
    local x = math.floor((w - #text) / 2) + 1
    clearLine(y)
    mon.setCursorPos(x, y)
    if color then mon.setTextColor(color) end
    mon.write(text)
    mon.setTextColor(colors.white)
end

local function drawCardAscii(x, y, value, hidden)
    -- Draw a 3-line ASCII card starting at (x,y)
    -- hidden = true -> show "??"
    local label
    if hidden then
        label = "??"
    else
        if value == 11 then
            label = "A"
        else
            label = tostring(value)
        end
    end

    -- Card is 7 characters wide: "+-----+"
    mon.setCursorPos(x, y)
    mon.write("+-----+")
    mon.setCursorPos(x, y + 1)
    local inside = " " .. label .. " "
    while #inside < 5 do
        inside = inside .. " "
    end
    mon.write("|" .. inside .. "|")
    mon.setCursorPos(x, y + 2)
    mon.write("+-----+")
end

local function showHands(playerCards, dealerCards, hideDealer)
    mon.clear()
    centerText(1, "BLACKJACK CASINO", colors.yellow)

    -- Dealer area
    centerText(3, "Dealer:", colors.red)

    local startX = 2
    local yDealer = 5
    for i, card in ipairs(dealerCards) do
        local x = startX + (i - 1) * 9
        local hidden = false
        if hideDealer and i >= 2 then
            hidden = true
        end
        drawCardAscii(x, yDealer, card, hidden)
    end

    if not hideDealer then
        local dealerTotal = 0
        -- we have a function later, but can't call before it's defined
        -- we'll redraw totals after the function definition
    end

    -- Player area
    centerText(11, "Player:", colors.green)
    local yPlayer = 13
    for i, card in ipairs(playerCards) do
        local x = startX + (i - 1) * 9
        drawCardAscii(x, yPlayer, card, false)
    end
end

--========================================--
-- CHEST / BET LOGIC
--========================================--

local function getBet()
    -- Find diamonds in the bet chest
    for slot = 1, betChest.size() do
        local item = betChest.getItemDetail(slot)
        if item and item.name == "minecraft:diamond" then
            return slot, item.count
        end
    end
    return nil, 0
end

local function isChestEmpty()
    for slot = 1, betChest.size() do
        local item = betChest.getItemDetail(slot)
        if item then
            return false
        end
    end
    return true
end

--========================================--
-- BLACKJACK LOGIC
--========================================--

local function drawCard()
    -- 2-10 = numeric, 11 = Ace, 12-14 = face cards (value 10)
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

    -- Turn Aces from 11 -> 1 if needed
    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end

    return total
end

-- now we can extend showHands to also show totals
local function showHandsWithTotals(playerCards, dealerCards, hideDealer)
    showHands(playerCards, dealerCards, hideDealer)

    if not hideDealer then
        local dealerTotal = handValue(dealerCards)
        centerText(9, "Dealer Total: " .. dealerTotal, colors.white)
    else
        centerText(9, "Dealer Showing", colors.white)
    end

    local playerTotal = handValue(playerCards)
    centerText(17, "Your Total: " .. playerTotal, colors.white)
end

--========================================--
-- PLAYER TURN (TOUCH INPUT)
--========================================--

local function playerTurn(playerCards, dealerCards)
    while true do
        showHandsWithTotals(playerCards, dealerCards, true)

        centerText(20, "Tap HIT or STAND on the monitor", colors.white)
        -- Draw simple "buttons"
        local hitText = "[ HIT ]"
        local standText = "[ STAND ]"

        local w, _ = mon.getSize()
        local hitX = math.floor(w / 4 - #hitText / 2)
        local standX = math.floor(3 * w / 4 - #standText / 2)
        local buttonY = 22

        mon.setCursorPos(hitX, buttonY)
        mon.write(hitText)
        mon.setCursorPos(standX, buttonY)
        mon.write(standText)

        local playerTotal = handValue(playerCards)
        if playerTotal > 21 then
            return playerTotal
        end

        local event, side, x, y = os.pullEvent("monitor_touch")

        -- Check HIT press
        if y == buttonY and x >= hitX and x <= hitX + #hitText - 1 then
            table.insert(playerCards, drawCard())
        end

        -- Check STAND press
        if y == buttonY and x >= standX and x <= standX + #standText - 1 then
            return handValue(playerCards)
        end
    end
end

--========================================--
-- DEALER TURN
--========================================--

local function dealerTurn(playerCards, dealerCards)
    -- Reveal dealer hand and then draw until 17+
    while handValue(dealerCards) < 17 do
        showHandsWithTotals(playerCards, dealerCards, false)
        centerText(19, "Dealer drawing...", colors.white)
        sleep(1)
        table.insert(dealerCards, drawCard())
    end

    showHandsWithTotals(playerCards, dealerCards, false)
    return handValue(dealerCards)
end

--========================================--
-- PLAY AGAIN / CASH OUT SCREEN
--========================================--

local function askPlayAgain()
    local w, _ = mon.getSize()
    centerText(19, "Play again?", colors.white)

    local yesText = "[ YES ]"
    local noText = "[ NO ]"
    local yesX = math.floor(w / 4 - #yesText / 2)
    local noX = math.floor(3 * w / 4 - #noText / 2)
    local buttonY = 21

    mon.setCursorPos(yesX, buttonY)
    mon.write(yesText)
    mon.setCursorPos(noX, buttonY)
    mon.write(noText)

    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")

        if y == buttonY and x >= yesX and x <= yesX + #yesText - 1 then
            return "yes"
        end

        if y == buttonY and x >= noX and x <= noX + #noText - 1 then
            return "no"
        end
    end
end

local function waitForChestEmpty()
    mon.clear()
    centerText(10, "Please take your diamonds", colors.white)
    centerText(12, "from the chest below...", colors.white)
    centerText(14, "Waiting for chest to be empty.", colors.white)

    while true do
        if isChestEmpty() then
            break
        end
        sleep(0.5)
    end

    mon.clear()
    centerText(10, "Thanks for playing!", colors.white)
    sleep(2)
end

--========================================--
-- FULL ROUND
--========================================--

local function playBlackjackRound()
    -- Deal initial hands
    local playerCards = { drawCard(), drawCard() }
    local dealerCards = { drawCard(), drawCard() }

    -- Player phase
    local playerTotal = playerTurn(playerCards, dealerCards)
    if playerTotal > 21 then
        showHandsWithTotals(playerCards, dealerCards, false)
        centerText(19, "You bust! Dealer wins.", colors.red)
        sleep(2)
        return "lose"
    end

    -- Dealer phase
    local dealerTotal = dealerTurn(playerCards, dealerCards)

    if dealerTotal > 21 then
        centerText(19, "Dealer busts! You win!", colors.green)
        sleep(2)
        return "win"
    end

    local finalText
    local result

    if playerTotal > dealerTotal then
        finalText = "You win!"
        result = "win"
    elseif dealerTotal > playerTotal then
        finalText = "Dealer wins!"
        result = "lose"
    else
        finalText = "Push (tie) - house wins."
        result = "lose"
    end

    centerText(19, finalText, result == "win" and colors.green or colors.red)
    sleep(2)
    return result
end

--========================================--
-- PAYOUT LOGIC
--========================================--

local function payout(betAmount, result)
    -- Move the bet from player chest to bank chest
    local slot, amount = getBet()
    if slot and betAmount > 0 then
        betChest.pushItems("back", slot, betAmount)
    end

    if result == "win" then
        -- Pay 2x bet back to player chest (winnings)
        local payoutAmount = betAmount * 2
        bankChest.pushItems("bottom", 1, payoutAmount)
    end
end

--========================================--
-- MAIN LOOP
--========================================--

local function showWaitingForBet()
    mon.clear()
    centerText(10, "Place diamonds in the", colors.white)
    centerText(12, "chest below to play!", colors.white)
end

showWaitingForBet()

while true do
    sleep(1)

    local slot, bet = getBet()
    if bet > 0 then
        -- We detected a bet, play a round
        mon.clear()
        centerText(10, "Bet detected: " .. bet .. " diamonds.", colors.white)
        sleep(1)

        local result = playBlackjackRound()
        payout(bet, result)

        if result == "win" then
            -- Ask if they want to continue or cash out
            showWaitingForBet()
            centerText(16, "Your winnings are in the chest.", colors.green)
            local answer = askPlayAgain()
            if answer == "no" then
                waitForChestEmpty()
                showWaitingForBet()
            else
                showWaitingForBet()
            end
        else
            -- Just go back to waiting for a bet
            showWaitingForBet()
        end
    end
end
