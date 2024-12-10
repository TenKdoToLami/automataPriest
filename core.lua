-- Create a frame for the addon
local frame = CreateFrame("Frame", "SpellSuggester", UIParent)
frame:SetSize(50, 50)
frame:SetPoint("CENTER")
frame.texture = frame:CreateTexture(nil, "BACKGROUND")
frame.texture:SetAllPoints()
frame.texture:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain") -- Default icon


local SpellIcons = {
    VampiricTouch   = "Interface\\Icons\\Spell_Holy_Stoicism",
    DevouringPlague = "Interface\\Icons\\Spell_Shadow_DevouringPlague",
    ShadowWordPain  = "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
    MindFlay        = "Interface\\Icons\\Spell_Shadow_SiphonMana",
    MindBlast       = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    Shadowfiend     = "Interface\\Icons\\Spell_Shadow_Shadowfiend"
}



-- Function to check if a debuff is applied to the target and return the remaining time
local function GetDebuffRemainingTime(debuffName, unit)
    for i = 1, 40 do
        local name, _, _, _, _, _,timeLeft = UnitDebuff(unit, i, "PLAYER")
        if not name then break end
        if name == debuffName then
            local currentTime = GetTime()
            local remainingTime = timeLeft - currentTime 
            return remainingTime  -- Return the remaining time if the debuff is found
        end
    end
    return 0  -- Return 0 if the debuff is not found
end

-- Function to suggest the next spell
local function SuggestNextSpell()
    -- No target, hide frame
    if not UnitExists("target") and not UnitIsEnemy("player", "target") then
        frame.texture:SetTexture(nil);
        return
    end
    local icon 
    -- Checks for SW:Pain
    local SWP_TimeLeft = GetDebuffRemainingTime("Shadow Word: Pain", "target")
    
    -- Checks for Devouring Plague
    local DP_TimeLeft = GetDebuffRemainingTime("Devouring Plague", "target")
    
    -- Checks for VampiricTouch
    local VT_TimeLeft = GetDebuffRemainingTime("Vampiric Touch", "target")

    
    print("VT left",VT_TimeLeft)
    if VT_TimeLeft < 2 then
        if (VT_TimeLeft < 1) then    
            icon = SpellIcons.VampiricTouch
        else
            icon = SpellIcons.MindBlast
        end
    elseif SWP_TimeLeft > 0 then
        print("MF")
        icon = SpellIcons.MindFlay
    else
        print("SW:P")
        icon = SpellIcons.ShadowWordPain
    end


    frame.texture:SetTexture(icon)

end

-- Event handler to update suggestions
frame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_TARGET_CHANGED" then
        -- Force a suggestion update for target change
        SuggestNextSpell()
    elseif event == "UNIT_AURA" then
        -- Specifically for the target unit (checking aura for debuff changes)
        if unit == "target" then
            SuggestNextSpell()
        end
    end
end)

-- Event handler to update suggestions
frame:SetScript("OnEvent", function(self, event, unit, spellName, ...)
    if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_TARGET_CHANGED" then
        -- Force a suggestion update for target change
        SuggestNextSpell()
    elseif event == "UNIT_AURA" then
        -- Specifically for the target unit (checking aura for debuff changes)
        if unit == "target" then
            SuggestNextSpell()
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- When the player successfully casts a spell
        if unit == "player" then
            -- Optionally check if the spell casted is the one you're interested in
            if spellName == "Mind Blast" then
                -- For example, reset or update the suggested spell based on Mind Blast cast
                SuggestNextSpell()
            end
        end
    end
end)



-- Register events
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED") -- Add this line for spell casting events

-- Initial suggestion
SuggestNextSpell()

