local mon = peripheral.wrap("right")
mon.setTextScale(0.5)
mon.setBackgroundColor(colors.black)
mon.clear()

function header(text)
    paintutils.drawFilledBox(1, 1, 50, 3, colors.gray)
    mon.setCursorPos(3, 2)
    mon.setTextColor(colors.white)
    mon.write(text)
end

function button(x1, y1, x2, y2, label, color)
    paintutils.drawFilledBox(x1, y1, x2, y2, color)
    mon.setCursorPos(x1 + 1, y1 + math.floor((y2-y1)/2))
    mon.setTextColor(colors.white)
    mon.write(label)
end

header("BLACKJACK CASINO")
button(5, 15, 20, 19, " HIT ", colors.blue)
button(25, 15, 40, 19, " STAND ", colors.red)

while true do
    local event, side, x, y = os.pullEvent("monitor_touch")

    if x >= 5 and x <= 20 and y >= 15 and y <= 19 then
        print("HIT pressed!")
    elseif x >= 25 and x <= 40 and y >= 15 and y <= 19 then
        print("STAND pressed!")
    end
end
