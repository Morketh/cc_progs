

local batteries = { peripheral.find("capacitor_mv") }
local monitors = { peripheral.find("monitor") }
local CurrentTransformer = "current_transformer_1"

Transfer = peripheral.wrap(CurrentTransformer)
while true do
    sleep(5)
    local totalBats = 0
    local tPower = 0
    local tPowerCap = 0
    for _, bat in pairs(batteries) do
        totalBats = totalBats + 1
        tPowerCap = tPowerCap + bat.getMaxEnergyStored()
        tPower = tPower + bat.getEnergyStored()
    end
    print("Total Batteries: ",totalBats)
    print((tPower/tPowerCap)*100)

    for _, mon in pairs(monitors) do
        mon.clear()
        mon.setCursorPos(1,2)
        mon.write(string.format("Total Batteries: %s",totalBats))
        mon.setCursorPos(1,3)
        mon.write(string.format("Total Power: %s",tPower))
        mon.setCursorPos(1,4)
        mon.write(string.format("Max Power Cap: %s",tPowerCap))
        mon.setCursorPos(1,5)
        mon.write(string.format("Capacity %s ", (tPower/tPowerCap)*100))
        mon.setCursorPos(1,7)
        mon.write(string.format("Avg Power Usage: %s Fe/t", Transfer.getAveragePower()))
    end
    if ((tPower/tPowerCap)*100) < 25 then
        --colors.yellow
        rs.setBundledOutput("top", colors.yellow)
    elseif ((tPower/tPowerCap)*100) > 90 then
        rs.setBundledOutput("top", 0)
    end
end
