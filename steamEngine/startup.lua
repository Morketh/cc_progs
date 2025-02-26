
-- Tank Sizes
local FuelTankCap = 504000

-- Throttle Settings
local PassiveThrottle = 32
local LowThrottle = 128
local HighThrottle = 256

-- Peripheral Names
local EnginePump = "Create_RotationSpeedController_1"
local NetworkStress = "Create_Stressometer_2"
local Battery = "capacitor_mv_0"
local StarterMotor = "electric_motor_1"
local GearBox = "Create_SequencedGearshift_0"
local CurrentTransformer = "current_transformer_0"
local FuelTank = "create:fluid_tank_0"

-- Display Screen
local Left   = "monitor_0"
local Center = "monitor_1"
local Right  = "monitor_2"

-- Bundled Output
RS_Connector = "top"

-- Clutch Wires
-- OUTPUT
local PTO = colors.red
local alternator = colors.green
local auxPower = colors.black

local fuelPumpWire = colors.magenta

-- Steam Engine Clutches
local E1_C1 = colors.lime
local E1_C2 = colors.pink
local E1_C3 = colors.gray
local E1_C4 = colors.lightGray

local E2_C1 = colors.cyan
local E2_C2 = colors.purple
local E2_C3 = colors.blue
local E2_C4 = colors.brown

-- INPUT
local AE2_Switch = colors.yellow
local KillSwitch = colors.lightBlue

-- RESET
local BundledOFF = 0

-- Set Bundled cable outputs per engine state
rsStarterBat = colors.combine(PTO,auxPower)

-- Bundles for Factory Sections
rsRun = colors.combine(alternator,auxPower)
AuxPower = colors.combine(alternator,PTO)

-- Clutch Mode
Neutral = colors.combine(alternator,PTO,auxPower)

-- Wrap peripherals
Tank = peripheral.wrap(FuelTank)
Throttle = peripheral.wrap(EnginePump)
NetStress = peripheral.wrap(NetworkStress)
StarterBattery = peripheral.wrap(Battery)
StarterCoil = peripheral.wrap(StarterMotor)
Gauges = peripheral.wrap(Center)
FuelPumpGearBox = peripheral.wrap(GearBox)
Transformer = peripheral.wrap(CurrentTransformer)

-- GLOBAL Switches
PTO_MODE = false
RUNNING = false
FuelPumpStat = "Stand By"

sleep(10)

-- Split String
function strSplit(delim,str)
    local t = {}

    for substr in string.gmatch(str, "[^".. delim.. "]*") do
        if substr ~= nil and string.len(substr) > 0 then
            table.insert(t,substr)
        end
    end
    
    return t
end

-- Engine Battery Level
function BatLevel()
    return (StarterBattery.getEnergyStored() / StarterBattery.getMaxEnergyStored() * 100);
end

-- Stress Capacity
function stressPercent()
    return (NetStress.getStress() / NetStress.getStressCapacity() * 100)
end
-- Fuel Pump
function FuelPump(running,CableState)
    if (running) then
        rs.setBundledOutput(RS_Connector,colors.subtract(CableState,fuelPumpWire))
        sleep(5)
        FuelPumpGearBox.rotate(90,-1) -- turn pumps on
        FuelPumpStat = "ON"        
    else
        FuelPumpGearBox.rotate(90,1) -- turn pumps off
        sleep(5)
        rs.setBundledOutput(RS_Connector,CableState)
        FuelPumpStat = "OFF"
    end
    print(string.format("Fuel Pump Status: %s",FuelPumpStat))
end

-- Print Gauges
function getFuelGauge()
    if not (FluidData[1] == nil) then
        return (FluidData[1]["amount"]/FuelTankCap) * 100
    else
        return 0
    end
end

function PrintGauges(mode)

    batLvl = string.format("Battery: %s", BatLevel())
    stressLvl = string.format("Stress: %s", stressPercent())
    EngineState = string.format("Mode: %s", mode)
    PowerTransfer = string.format("Avg Power: %s fe/t", Transformer.getAveragePower())
    if not (FluidData[1] == nil) then
        FuelName = string.format("Fuel Type: %s", strSplit(":", FluidData[1]["name"])[2])
        TankLevel = string.format("Fuel Level: %s", (FluidData[1]["amount"]/FuelTankCap)*100)
    else
        FuelName = "Fuel Type: N/A"
        TankLevel = "Fuel Level: NULL"
    end
    StressCap = string.format("Stress Cap: %s", NetStress.getStressCapacity())
    PumpStatus = string.format("Pumps: %s", FuelPumpStat)
    PumpRPM = string.format("Pump RPM: %s",Throttle.getTargetSpeed())

    Gauges.clear()

    -- print gagues
    Gauges.setCursorPos(1,2)
    Gauges.write(batLvl)
    Gauges.setCursorPos(1,3)
    Gauges.write(stressLvl)
    Gauges.setCursorPos(1,4)
    Gauges.write(StressCap)
    Gauges.setCursorPos(1,5)
    Gauges.write(EngineState)
    Gauges.setCursorPos(1,6)
    Gauges.write(PowerTransfer)
    Gauges.setCursorPos(1,8)
    Gauges.write("==============================")
    Gauges.setCursorPos(1,9)
    Gauges.write(PumpStatus)
    Gauges.setCursorPos(1,10)
    Gauges.write(PumpRPM)
    Gauges.setCursorPos(1,11)
    Gauges.write(FuelName)
    Gauges.setCursorPos(1,12)
    Gauges.write(TankLevel)

end

function SteamEngineClutches(mode)
    if mode == "stop" then
        print("Stage: stop")
        return colors.combine(E1_C1,E2_C1,E1_C2,E2_C2,E1_C3,E2_C3,E1_C4,E2_C4)
    elseif mode == "start" then
        print("Stage: start")
        return colors.combine(E1_C1,E2_C1,E1_C2,E2_C2,E1_C3,E2_C3)
    elseif mode == "stage 1" then
        print("Stage: 1")
        return colors.combine(E1_C1,E2_C1,E1_C2,E2_C2)
    elseif mode == "stage 2" then
        print("Stage: 2")
        return colors.combine(E1_C1,E2_C1)
    elseif mode == "stage 3" then
        print("Stage: 3")
        return 0
    else
        print("Missing or invalid Engine Stage")
    end
end

function StartupScreen()
    Gauges.clear()
    Gauges.setCursorPos(1,2)
    Gauges.write("Starting Steam Engine")
    Gauges.setCursorPos(1,3)
    Gauges.write("Control Center!!!")
end

function setPTOShaftOut(switchMode)
    print(string.format("setPTOShaftOut( %s, %s )",switchMode,PTO_MODE))
    if (switchMode and not PTO_MODE) then -- 
        Throttle.setTargetSpeed(HighThrottle)
        sleep(10)
        FuelPump(true,AuxPower)
        PTO_MODE = true
    elseif (switchMode and PTO_MODE) then
        PrintGauges("Charging AUX Batteries")
        Throttle.setTargetSpeed(HighThrottle)
        FuelPump(true,colors.combine(alternator))
    elseif (not switchMode and PTO_MODE) then
        PTO_MODE = false
        sleep(1)
        FuelPump(true,rsRun)
        Throttle.setTargetSpeed(LowThrottle)
        PrintGauges("PTO Low Throttle")
    elseif (not switchMode and not PTO_MODE) then
        PrintGauges("PTO High Throttle")
        Throttle.setTargetSpeed(HighThrottle)
        FuelPump(true,colors.combine(alternator,auxPower)) -- Turn off main and Aux Alternators
    end
end

function StartEngine()
    PrintGauges("Starting Engine!")
    local state = colors.combine(Neutral,SteamEngineClutches("start"))
    
    rs.setBundledOutput(RS_Connector, state)
    StarterCoil.setSpeed(32)
    Throttle.setTargetSpeed(32)
    sleep(15)
    StarterCoil.stop()
    PrintGauges("Stage 2")
    state = colors.combine(Neutral,SteamEngineClutches("stage 1"))
    FuelPump(false,state)
    sleep(15)
    state = colors.combine(Neutral,SteamEngineClutches("stage 2"))
    FuelPump(false,state)
    PrintGauges("Stage 3")
    sleep(15)
    state = colors.combine(Neutral,SteamEngineClutches("stage 3"))
    FuelPump(false,state)
    PrintGauges("Stage 4")
    sleep(15)
    RUNNING = true
end

--Starter Battery
function StarterBat()
    if (BatLevel() < 25) then
        PrintGauges("Starter Batery LOW!")
        sleep(4)
        FuelPump(true,rsStarterBat)
        PrintGauges("Starter Battery Charging!")
        Throttle.setTargetSpeed(HighThrottle)
        while BatLevel() < 90 and stressPercent() < 95 do
            PrintGauges("Charging Battery")
            sleep(5)
        end
        Throttle.setTargetSpeed(LowThrottle)
    end
end

-- Stop Engine
function StopEngine()
    Throttle.setTargetSpeed(0)
    StarterCoil.setSpeed(0)
    rs.setBundledOutput(RS_Connector,colors.combine(Neutral,SteamEngineClutches("stop")))
    RUNNING = false
    sleep(5)
end

-- start up sequence
StartupScreen()
sleep(30)
StopEngine()
sleep(25)

while true do
    -- grab switch status at start of loop
    -- Get All Values
    FluidData = Tank.tanks()
    -- get battery level signal from remote computer on AE2_Switch channel (see colors above)
    ptoSwitch = rs.testBundledInput(RS_Connector, AE2_Switch)
    KILL = rs.testBundledInput(RS_Connector, KillSwitch)
    
    if (KILL == false and RUNNING == true) then
        if (NetStress.getStressCapacity() == 0 and NetStress.getStress(0)) then
            print("Start up sequence!")
            StartEngine()
            FuelPump(false, Neutral) 
            print(string.format("NetStress.getStressCapacity( %s )", NetStress.getStressCapacity()))
        elseif (NetStress.getStressCapacity() < 4097 and RUNNING) then
            FuelPump(true, Neutral) -- Get fuel into boilers first
            PrintGauges("Neutral")
        elseif (NetStress.getStressCapacity() > 98000 and RUNNING) then        
            -- Charge AUX Batteries?
            StarterBat()
            setPTOShaftOut(ptoSwitch)
        elseif (NetStress.getStressCapacity() < 97999 and NetStress.getStressCapacity() > 4098 and RUNNING and getFuelGauge() > 30) then
            PrintGauges("Medium Throttle")
            FuelPump(true, Neutral)

        else
            PrintGauges("Passive Throttle")
            FuelPump(false, Neutral)
            Throttle.setTargetSpeed(LowThrottle)
        end
        sleep(10)
    elseif (KILL and RUNNING) then
        StopEngine()
    elseif (KILL and not RUNNING) then
        PrintGauges("Stand By!")
    elseif (not KILL and not RUNNING) then
        --print(string.format("Kill Switch: %s, Running: %s", KILL, RUNNING))
        StartEngine()
    end
end


-- Start Engine

-- Passive Mode
-- Add Fuel
-- Check Stress
-- Turn on Main Power Shaft
-- Charg Aux Batteries