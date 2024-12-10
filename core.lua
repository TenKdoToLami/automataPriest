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

-- Function to suggest the next spell
local function SuggestNextSpell()
    -- Example logic for selecting a spell
    local spellName, icon
    if IsUsableSpell("Shadow Word: Pain") then
        spellName = "Shadow Word: Pain"
        icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain"
    elseif IsUsableSpell("Mind Blast") and not IsSpellOnCooldown("Mind Blast") then
        spellName = "Mind Blast"
        icon = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy"
    else
        spellName = nil
        icon = nil
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
    if event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_TARGET_CHANGED" then
        SuggestNextSpell()
    end
end)

-- Register events
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")

-- Initial suggestion
SuggestNextSpell()
