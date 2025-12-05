--========================================--
-- Monitor Blackjack Casino (ASCII UI)
--========================================--

local betChest = peripheral.wrap("bottom")
local bankChest = peripheral.wrap("back")
local mon = peripheral.wrap("right")

math.randomseed(os.time())

mon.setTextScale(0.5)
mon.setBackgroundColor(colors.black)
mon.setTextColor(colors.white)
mon.clear()

--========================================--
-- HELPER FUNCTIONS
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
    local label
    if hidden then
        label = "??"
    else
        if value == 11 then label = "A" else label = tostring(value) end
    end

    mon.setCursorPos(x, y)
    mon.write("+-----+")
    mon.setCursorPos(x, y + 1)

    local inside = " " .. label .. " "
    while #inside < 5 do inside = inside .. " " end

    mon.write("|" .. inside .. "|")

    mon.setCursorPos(x, y + 2)
    mon.write("+-----+")
end

local function showHands(playerCards, dealerCards, hideDealer)
    mon.clear()
    centerText(1, "BLACKJACK CASINO", colors.yellow)

    centerText(3, "Dealer:", colors.red)
    local startX = 2
    local yDealer = 5

    for i, card in ipairs(dealerCards) do
        local hidden = (hideDealer and i >= 2)
        drawCardAscii(startX + (i - 1) * 9, yDealer, card, hidden)
    end

    centerText(11, "Player:", colors.green)
    local yPlayer = 13

    for i, card in ipairs(playerCards) do
        drawCardAscii(startX + (i - 1) * 9, yPlayer, card, false)
    end
end

--========================================--
-- BANK CHECK
--========================================--

local function casinoHasFunds()
    for slot = 1, bankChest.size() do
        local item = bankChest.getItemDetail(slot)
        if item and item.name == "minecraft:diamond" and item.count > 0 then
            return true
        end
    end
    return false
end

local function showCasinoBroke()
    mon.clear()
    centerText(10, "THE CASINO IS BROKE!", colors.red)
    centerText(12, "Add diamonds to the bank chest.", colors.red)
end

--========================================--
-- CHEST LOGIC (MULTI-SLOT)
--========================================--

local function getBet()
    local total = 0
    local slots = {}

    for slot = 1, betChest.size() do
        local item = betChest.getItemDetail(slot)
        if item and item.name == "minecraft:diamond" then
            total = total + item.count
            table.insert(slots, {slot = slot, count = item.count})
        end
    end

    return total, slots
end

local function isChestEmpty()
    for slot = 1, betChest.size() do
        if betChest.getItemDetail(slot) then
            return false
        end
    end
    return true
end

local function removeBetDiamonds(slotInfo)
    for _, entry in ipairs(slotInfo) do
        betChest.pushItems("back", entry.slot, entry.count)
    end
end

--========================================--
-- BLACKJACK LOGIC
--========================================--

local function drawCard()
    local c = math.random(2, 14)
    if c >= 12 then return 10 end
    if c == 11 then return 11 end
    return c
end

local function handValue(cards)
    local total = 0
    local aces = 0

    for _, c in ipairs(cards) do
        total = total + c
        if c == 11 then aces = aces + 1 end
    end

    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end

    return total
end

local function showHandsWithTotals(playerCards, dealerCards, hideDealer)
    showHands(playerCards, dealerCards, hideDealer)

    if hideDealer then
        centerText(9, "Dealer Showing", colors.white)
    else
        centerText(9, "Dealer Total: " .. handValue(dealerCards), colors.white)
    end

    centerText(17, "Your Total: " .. handValue(playerCards), colors.white)
end

--========================================--
-- PLAYER TURN
--========================================--

local function playerTurn(playerCards, dealerCards)
    while true do
        showHandsWithTotals(playerCards, dealerCards, true)

        centerText(20, "Tap HIT or STAND", colors.white)

        local hit = "[ HIT ]"
        local stand = "[ STAND ]"

        local w, _ = mon.getSize()
        local hitX = math.floor(w / 4 - #hit / 2)
        local standX = math.floor(3 * w / 4 - #stand / 2)
        local yButton = 22

        mon.setCursorPos(hitX, yButton)
        mon.write(hit)
        mon.setCursorPos(standX, yButton)
        mon.write(stand)

        if handValue(playerCards) > 21 then
            return handValue(playerCards)
        end

        local event, side, x, y = os.pullEvent("monitor_touch")

        if y == yButton and x >= hitX and x <= hitX + #hit - 1 then
            table.insert(playerCards, drawCard())
        end

        if y == yButton and x >= standX and x <= standX + #stand - 1 then
            return handValue(playerCards)
        end
    end
end

--========================================--
-- DEALER TURN
--========================================--

local function dealerTurn(playerCards, dealerCards)
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
-- PLAY AGAIN / CASH OUT
--========================================--

local function askPlayAgain()
    centerText(19, "Play again?", colors.white)

    local yes = "[ YES ]"
    local no = "[ NO ]"
    local w, _ = mon.getSize()

    local yesX = math.floor(w / 4 - #yes / 2)
    local noX = math.floor(3 * w / 4 - #no / 2)
    local yButton = 21

    mon.setCursorPos(yesX, yButton)
    mon.write(yes)
    mon.setCursorPos(noX, yButton)
    mon.write(no)

    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")

        if y == yButton and x >= yesX and x <= yesX + #yes - 1 then
            return "yes"
        end

        if y == yButton and x >= noX and x <= noX + #no - 1 then
            return "no"
        end
    end
end

local function waitForChestEmpty()
    mon.clear()
    centerText(10, "Please take your diamonds", colors.white)
    centerText(12, "from the chest below...", colors.white)
    centerText(14, "Waiting for chest to be empty.", colors.white)

    while not isChestEmpty() do sleep(0.5) end

    mon.clear()
    centerText(10, "Thanks for playing!", colors.white)
    sleep(2)
end

--========================================--
-- FULL BLACKJACK ROUND
--========================================--

local function playBlackjackRound()
    local player = { drawCard(), drawCard() }
    local dealer = { drawCard(), drawCard() }

    local p = playerTurn(player, dealer)
    if p > 21 then
        showHandsWithTotals(player, dealer, false)
        centerText(19, "You bust! Dealer wins.", colors.red)
        sleep(2)
        return "lose"
    end

    local d = dealerTurn(player, dealer)

    if d > 21 then
        centerText(19, "Dealer busts! You win!", colors.green)
        sleep(2)
        return "win"
    end

    if p > d then
        centerText(19, "You win!", colors.green)
        sleep(2)
        return "win"
    else
        centerText(19, "Dealer wins!", colors.red)
        sleep(2)
        return "lose"
    end
end

--========================================--
-- PAYOUT
--========================================--

local function payout(betAmount, slotInfo, result)
    removeBetDiamonds(slotInfo)

    if result == "win" then
        local payoutAmount = betAmount * 2
        local needed = payoutAmount

        for slot = 1, bankChest.size() do
            local item = bankChest.getItemDetail(slot)
            if item and item.name == "minecraft:diamond" then
                local moved = bankChest.pushItems("bottom", slot, needed)
                needed = needed - moved
                if needed <= 0 then break end
            end
        end
    end
end

--========================================--
-- MAIN LOOP
--========================================--

local function showWaiting()
    mon.clear()

    if not casinoHasFunds() then
        showCasinoBroke()
        return false
    end

    centerText(10, "Place diamonds in the", colors.white)
    centerText(12, "chest below to play!", colors.white)
    return true
end

while true do
    sleep(1)

    if not showWaiting() then
        sleep(1)
        goto continue
    end

    local bet, slotInfo = getBet()

    if bet > 0 then
        mon.clear()
        centerText(10, "Bet detected: " .. bet .. " diamonds.", colors.white)
        sleep(1)

        local result = playBlackjackRound()
        payout(bet, slotInfo, result)

        if result == "win" then
            showWaiting()
            centerText(16, "Your winnings are in the chest.", colors.green)
            local ans = askPlayAgain()

            if ans == "no" then
                waitForChestEmpty()
            end
        end
    end

    ::continue::
end
