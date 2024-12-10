-- Create a frame for the addon
local frame = CreateFrame("Frame", "SpellSuggester", UIParent)
frame:SetSize(50, 50)
frame:SetPoint("CENTER")
frame.texture = frame:CreateTexture(nil, "BACKGROUND")
frame.texture:SetAllPoints()
frame.texture:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain") -- Default icon

-- Function to check if Shadow Word: Pain is applied to the target
local function IsDebuffApplied(debuffName, unit)
    for i = 1, 40 do
        local name = UnitDebuff(unit, i)
        if not name then break end
        if name == debuffName then
            return true
        end
    end
    return false
end

-- Function to suggest the next spell
local function SuggestNextSpell()
    local icon

    -- Check if Shadow Word: Pain is applied to the target
    if IsDebuffApplied("Shadow Word: Pain", "target") then
        icon = "Interface\\Icons\\Spell_Shadow_SiphonMana" -- Mind Flay icon
    elseif IsUsableSpell("Shadow Word: Pain") and not IsSpellOnCooldown("Shadow Word: Pain") then
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" -- Shadow Word: Pain icon
    end

    -- Update the frame's texture
    if icon then
        frame.texture:SetTexture(icon)
    else
        frame.texture:SetTexture(nil) -- Hide the icon if no suggestion
    end
end

-- Event handler to update suggestions
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_TARGET_CHANGED" or event == "UNIT_AURA" then
        SuggestNextSpell()
    end
end)

-- Register events
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_AURA")

-- Initial suggestion
SuggestNextSpell()
