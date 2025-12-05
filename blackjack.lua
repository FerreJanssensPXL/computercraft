--========================================--
-- CONFIG: Chest Locations
--========================================--
local betChest = peripheral.wrap("bottom")  -- Player bet chest
local bankChest = peripheral.wrap("back")   -- Casino bankroll chest

--========================================--
-- Detect bet in chest
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
-- CARD DRAW + HAND VALUES
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

--========================================--
-- PLAYER TURN
--========================================--
local function playerTurn(playerCards)
    while true do
        local total = handValue(playerCards)
        print("")
        print("Your cards: " .. table.concat(playerCards, ", "))
        print("Total: " .. total)

        if total > 21 then
            print("BUST!")
            return total
        end

        print("Hit or Stand? (h/s)")
        local choice = read()

        if choice == "h" then
            print("You draw a card.")
            table.insert(playerCards, drawCard())
        elseif choice == "s" then
            print("You stand.")
            return handValue(playerCards)
        else
            print("Invalid choice. Type h or s.")
        end
    end
end

--========================================--
-- DEALER TURN
--========================================--
local function dealerTurn(dealerCards)
    print("")
    print("Dealer reveals: " .. table.concat(dealerCards, ", "))
    local total = handValue(dealerCards)
    print("Dealer total: " .. total)

    while total < 17 do
        print("Dealer hits...")
        table.insert(dealerCards, drawCard())
        total = handValue(dealerCards)
        print("Dealer now has: " .. table.concat(dealerCards, ", ") .. " (Total: " .. total .. ")")
    end

    return total
end

--========================================--
-- FULL BLACKJACK GAME
--========================================--
local function playBlackjack()
    print("Starting Blackjack...")

    local playerCards = { drawCard(), drawCard() }
    local dealerCards = { drawCard(), drawCard() }

    print("")
    print("Your cards: " .. table.concat(playerCards, ", ") .. " (Total: " .. handValue(playerCards) .. ")")
    print("Dealer shows: " .. dealerCards[1])

    local playerTotal = playerTurn(playerCards)
    if playerTotal > 21 then
        print("Player busts. Dealer wins.")
        return "lose"
    end

    print("")
    print("Dealer's turn...")
    local dealerTotal = dealerTurn(dealerCards)

    if dealerTotal > 21 then
        print("Dealer busts — you win!")
        return "win"
    end

    if playerTotal > dealerTotal then
        print("You win!")
        return "win"
    elseif dealerTotal > playerTotal then
        print("Dealer wins.")
        return "lose"
    else
        print("Tie — house wins ties.")
        return "lose"
    end
end

--========================================--
-- PAYOUT HANDLING
--========================================--
local function payout(betAmount, result)
    local slot, amount = getBet()
    if not slot then
        print("ERROR: Could not find bet to remove.")
        return
    end

    betChest.removeItemFromSlot(slot, betAmount)

    if result == "win" then
        local payoutAmount = betAmount * 2
        print("Paying out " .. payoutAmount .. " diamonds.")
        bankChest.pushItems("bottom", 1, payoutAmount)
    else
        print("Casino keeps the diamonds.")
    end
end

--========================================--
-- MAIN LOOP
--========================================--
print("Welcome to the Blackjack Casino!")
print("Place diamonds in the chest below to begin.")

while true do
    sleep(1)

    local slot, bet = getBet()
    if bet > 0 then
        print("")
        print("-----------------------------------")
        print("Detected bet of " .. bet .. " diamonds.")
        local result = playBlackjack()
        payout(bet, result)
        print("Round complete.")
        print("Place diamonds for another round.")
    end
end
