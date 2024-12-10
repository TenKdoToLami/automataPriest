-- Create a frame for the addon
local frame = CreateFrame("Frame", "SpellSuggester", UIParent)
frame:SetSize(50, 50)
frame:SetPoint("CENTER")
frame.texture = frame:CreateTexture(nil, "BACKGROUND")
frame.texture:SetAllPoints()
frame.texture:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain") -- Default icon

-- Secure action button for casting spells
local castButton = CreateFrame("Button", "CastButton", UIParent, "SecureActionButtonTemplate")
castButton:SetSize(50, 50)
castButton:SetPoint("CENTER", frame, "CENTER")
castButton:SetAttribute("type", "spell")
castButton:SetAttribute("spell", "Shadow Word: Pain") -- Default spell

-- Function to check if Shadow Word: Pain is applied to the target
local function IsDebuffApplied(debuffName, unit)
    for i = 0, 40 do
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
    local spellName, icon

    -- Check if Shadow Word: Pain is applied to the target
    if IsDebuffApplied("Shadow Word: Pain", "target") then
        if IsUsableSpell("Mind Flay") and not IsSpellOnCooldown("Mind Flay") then
            spellName = "Mind Flay"
            icon = "Interface\\Icons\\Spell_Shadow_SiphonMana"
        end
    elseif IsUsableSpell("Shadow Word: Pain") and not IsSpellOnCooldown("Shadow Word: Pain") then
        spellName = "Shadow Word: Pain"
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain"
    end

   
    -- Update the frame and button
    if spellName then
        frame.texture:SetTexture(icon)
        castButton:SetAttribute("spell", spellName)
    else
        frame.texture:SetTexture(nil) -- Hide the icon if no suggestion
        castButton:SetAttribute("spell", nil)
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
