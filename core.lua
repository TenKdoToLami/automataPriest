-- Create a frame for the addon
local frame = CreateFrame("Frame", "SpellSuggester", UIParent)
frame:SetSize(50, 50)
frame:SetPoint("CENTER")
frame.texture = frame:CreateTexture(nil, "BACKGROUND")
frame.texture:SetAllPoints()
frame.texture:SetTexture(nil) -- Default icon
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Delay for human input
local HumanFactor = 0.025
-- Adjustable for ideal Shadowfiend usage 0.5 -> 50%
local LowPower = 0.5
-- Deactivate/Activate addon
local deactivate = true

local SpellIcons = {
    VampiricTouch   = "Interface\\Icons\\Spell_Holy_Stoicism",
    DevouringPlague = "Interface\\Icons\\Spell_Shadow_DevouringPlague",
    ShadowWordPain  = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    MindFlay        = "Interface\\Icons\\Spell_Shadow_SiphonMana",
    MindBlast       = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    Shadowfiend     = "Interface\\Icons\\Spell_Shadow_Shadowfiend",
    VampiricEmbrace = "Interface\\Icons\\Spell_shadow_UnsummonBuilding",
    InnerFire       = "Interface\\Icons\\Spell_Holy_InnerFire",
    ShadowWordDeath = "Interface\\Icons\\Spell_Shadow_DemonicFortitude"
}

-- Function to check if a debuff is applied to the target and return the remaining time
local function GetDebuffRemainingTime(debuffName, unit)
    for i = 1, 99 do
        local name, _, _, _, _, _, timeLeft = UnitDebuff(unit, i, "PLAYER")
        if not name then
            break
        end
        if name == debuffName then
            local currentTime = GetTime()
            local remainingTime = timeLeft - currentTime
            return remainingTime -- Return the remaining time if the debuff is found
        end
    end
    return 0 -- Return 0 if the debuff is not found
end

-- Function to get the Shadow Weaving stack count
local function GetShadowWeavingStacks()
    for i = 1, 99 do
        local name, _, _, count = UnitBuff("PLAYER", i)
        if not name then
            break
        end
        if name == "Shadow Weaving" then
            return count -- Return the Shadow Weaving count
        end
    end
    return 0 -- Return 0 if Shadow Weaving buff is not found
end

-- Function to check if a buff exists on the player
local function BuffExists(buff)
    for i = 1, 99 do
        local name, _, _, count = UnitBuff("PLAYER", i)
        if not name then
            break
        end
        if name == buff then
            return true -- Return true if buff exists
        end
    end
    return false -- Return false if buff is not found
end

-- Function to get the time remaining for a cast
local function GetTimeToEndCast()
    -- Check if the unit is currently casting
    local spellName, _, _, _, startTime, endTime = UnitCastingInfo("PLAYER")
    if not spellName then
        -- Check if the unit is channeling instead
        spellName, _, _, _, startTime, endTime = UnitChannelInfo("PLAYER")
    end

    -- Calculate remaining cast time if applicable
    local remainingTime = 0
    if spellName and startTime and endTime then
        local currentTime = GetTime() * 1000
        remainingTime = (endTime - currentTime) / 1000
        remainingTime = remainingTime > 0 and remainingTime or 0
    end

    -- Check the GCD
    local gcdStart, gcdDuration = GetSpellCooldown(61304) -- 61304 is the GCD spell ID
    local gcdRemaining = (gcdStart + gcdDuration - GetTime())

    -- Return the greater of GCD or cast time if GCD is active
    if gcdDuration > 0 then
        return math.max(gcdRemaining, remainingTime), spellName
    end

    return remainingTime, spellName -- Return remaining cast time if it's greater than GCD
end


local lastTarget = nil
local lastSpell = nil
local lastSpellRemainingTime = 0
local lastShadowWeaving = -1
local change = true
-- Function to suggest the next spell
local function SuggestNextSpell()
    if not BuffExists("Inner Fire") then
        frame.texture:SetTexture(SpellIcons.InnerFire)
        return
    elseif not BuffExists("Vampiric Embrace") then
        frame.texture:SetTexture(SpellIcons.VampiricEmbrace)
        return
    end

    -- Check if you either have or can attack the target
    if not UnitCanAttack("player", "target") then
        frame.texture:SetTexture(nil)
        return
    end

    
    local CurrentCastTimeRemaining, currentSpellCasted = GetTimeToEndCast()
    local ShadowWeaving_Count = GetShadowWeavingStacks()
    local currentTarget = UnitGUID("target")

    if not change then
        if (CurrentCastTimeRemaining < lastSpellRemainingTime and currentTarget == lastTarget and lastSpell == currentSpellCasted and lastShadowWeaving == ShadowWeaving_Count) then
            return
        end
    end
    change = false
    -- Stores next spell suggestion
    local icon

    -- Checks for debuff remaining times
    local SWP_TimeLeft = GetDebuffRemainingTime("Shadow Word: Pain", "target")
    local DP_TimeLeft = GetDebuffRemainingTime("Devouring Plague", "target")
    local VT_TimeLeft = GetDebuffRemainingTime("Vampiric Touch", "target")

    -- Stores amount of Shadow Weaving stacks


    -- Provides Mana calculations
    local power = UnitPower("PLAYER")
    local powerMax = UnitPowerMax("PLAYER")
    local relativePower = power / powerMax

    local _, gcdDuration = GetSpellCooldown(61304)

     -- Get cooldowns for spells
    local _, Shadowfiend_Cooldown = GetSpellCooldown("Shadowfiend")
    if (Shadowfiend_Cooldown <= gcdDuration + HumanFactor) then
        Shadowfiend_Cooldown = 0
    end

    local _, Mindblast_Cooldown = GetSpellCooldown("Mind Blast")
    if (Mindblast_Cooldown <= gcdDuration + HumanFactor) then
        Mindblast_Cooldown = 0
    end

    local _, ShadowWordDeath_Cooldown = GetSpellCooldown("Shadow Word: Death")
    
    if (ShadowWordDeath_Cooldown <= gcdDuration + HumanFactor) then
        ShadowWordDeath_Cooldown = 0
    end

    local _, _, _, _, _, _, MindBlast_CastTime = GetSpellInfo("Mind Blast")
    MindBlast_CastTime = MindBlast_CastTime / 1000
    if MindBlast_CastTime > 0.95 then
        MindBlast_CastTime = true
    else
        MindBlast_CastTime = false
    end


    if currentSpellCasted == "Mind Flay" then
        ShadowWeaving_Count = ShadowWeaving_Count + 1
    end

    if relativePower < LowPower and Shadowfiend_Cooldown == 0 then
        icon = SpellIcons.Shadowfiend
    elseif GetUnitSpeed("PLAYER") > 0 then
        if SWP_TimeLeft == 0 and ShadowWeaving_Count == 5 then
            icon = SpellIcons.ShadowWordPain
        elseif ShadowWordDeath_Cooldown < HumanFactor then
            icon = SpellIcons.ShadowWordDeath
        else
            icon = SpellIcons.DevouringPlague
        end
        change = true
    elseif SWP_TimeLeft > 0 and SWP_TimeLeft < 2 then
        icon = SpellIcons.MindFlay
    elseif currentSpellCasted ~= "Vampiric Touch" and VT_TimeLeft < CurrentCastTimeRemaining + HumanFactor + 1 then
        icon = SpellIcons.VampiricTouch
    elseif DP_TimeLeft < HumanFactor + CurrentCastTimeRemaining then
        icon = SpellIcons.DevouringPlague
        change = true
    elseif currentSpellCasted ~= "Vampiric Touch" and VT_TimeLeft < CurrentCastTimeRemaining + HumanFactor + 2 and Mindblast_Cooldown == 0 and MindBlast_CastTime then
        icon = SpellIcons.MindBlast
    elseif DP_TimeLeft < HumanFactor + CurrentCastTimeRemaining + 1 and Mindblast_Cooldown == 0 and MindBlast_CastTime then
        icon = SpellIcons.MindBlast
    elseif SWP_TimeLeft < CurrentCastTimeRemaining + HumanFactor and ShadowWeaving_Count == 5 then
        icon = SpellIcons.ShadowWordPain
        change = true
    else
        icon = SpellIcons.MindFlay
    end


    frame.texture:SetTexture(icon)
    lastSpellRemainingTime = CurrentCastTimeRemaining
    lastSpell = currentSpellCasted
    lastTarget = currentTarget
    lastShadowWeaving = ShadowWeaving_Count
end

-- Event handler to update suggestions
frame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        SuggestNextSpell()
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_TARGET_CHANGED" then
        SuggestNextSpell()
    elseif event == "UNIT_AURA" and unit == "target" then
        SuggestNextSpell()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
        SuggestNextSpell()
    elseif event == "ACTIONBAR_UPDATE_COOLDOWN" then
        SuggestNextSpell()
    end
end)


-- Toggle function to enable or disable the addon
function SetState()
    if deactivate == false then
        frame:Show()
        frame:EnableMouse(true)
        frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        frame:RegisterEvent("UNIT_AURA")
        frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
        frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
        print("Automatapriest enabled.")
        deactivate = true
    else
        print("Automatapriest disabled.")
        deactivate = false
        frame:Hide()
        frame:EnableMouse(false) -- Disable mouse interaction
        frame:UnregisterAllEvents() -- Unregister all events to stop any processing
    end
end

-- Slash command to toggle the addon
SLASH_AUTOMATAPriest1 = "/automatapriest"
SlashCmdList["AUTOMATAPriest"] = function(msg)
    SetState()
end

-- Register events
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
