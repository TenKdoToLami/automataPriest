-- Create a frame for the addon
local frame = CreateFrame("Frame", "SpellSuggester", UIParent)
frame:SetSize(50, 50)
frame:SetPoint("CENTER")
frame.texture = frame:CreateTexture(nil, "BACKGROUND")
frame.texture:SetAllPoints()
frame.texture:SetTexture("Interface\\Icons\\Spell_Shadow_ShadowWordPain") -- Default icon



local GCD = 1
local HumanFactor = 0.0

-- Deactivate/Activate addon
local deactivate = true


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
    for i = 1, 99 do
        local name, _, _, _, _, _,timeLeft = UnitDebuff(unit, i, "PLAYER")
        
        -- No more debuffs
        if not name then 
            break 
        end

        --Found the debuff
        if name == debuffName then
            local currentTime = GetTime()
            local remainingTime = timeLeft - currentTime 
            return remainingTime  -- Return the remaining time if the debuff is found
        end
    end
    return 0  -- Return 0 if the debuff is not found
end

--  Function that returns Shadow Weaving count
local function GetShadowWeavingStacks()
for i = 1, 99 do
        local name, _, _, count = UnitBuff("PLAYER", i)
        
        -- No more buffs
        if not name then 
            break 
        end

        --Found the debuff
        if name == "Shadow Weaving" then
            return count  -- Return the Shadow Weaving count
        end
    end
    return 0  -- Return 0 if Shadow Weaving buff is not found
end



-- Function to suggest the next spell
local function SuggestNextSpell()
    
    -- No action, disabled addon
    if Deactivate then
        return
    end
    

    --Check if you either have or can attack target
    if not UnitCanAttack("player", "target") then
        frame.texture:SetTexture(nil);
        return
    end



    --  Stores next spell suggestion
    local icon 

    -- Checks for SW:Pain
    local SWP_TimeLeft = GetDebuffRemainingTime("Shadow Word: Pain", "target")
    
    -- Checks for Devouring Plague
    local DP_TimeLeft = GetDebuffRemainingTime("Devouring Plague", "target")
    
    -- Checks for VampiricTouch
    local VT_TimeLeft = GetDebuffRemainingTime("Vampiric Touch", "target")

    -- Stores amount of Shadow Weaving stacks
    local ShadowWeaving_Count = GetShadowWeavingStacks()
    
    
    local _, Shadowfiend_Cooldown = GetSpellCooldown("Shadowfiend")

    local _, Mindblast_Cooldown = GetSpellCooldown("Mind Blast")




    --[[
            If Vampiric Touch expires faster than 2 instant then
                - If it expires before first cast is finished do Vampiric Touch
                - If it expires after  first cast is finished do Mind Blast (If ready)
    ]]
    if (VT_TimeLeft < GCD + HumanFactor) or (VT_TimeLeft < 2 * GCD + HumanFactor and Mindblast_Cooldown == 0) then
        if VT_TimeLeft < GCD + HumanFactor then             -- expires before first cast is finished cast do Vampiric Touch
            icon = SpellIcons.VampiricTouch
        else                                                -- expires after  first cast is finished cast do Mind Blast
            icon = SpellIcons.MindBlast
        end
    
    --[[
            If Devouring Plague expired
                - Refresh DevouringPlague
    ]]
    elseif (DP_TimeLeft < 0 + HumanFactor) or (DP_TimeLeft < GCD + HumanFactor) then
        if DP_TimeLeft > HumanFactor then             -- Devouring PLague did not expired yet
            icon = SpellIcons.MindBlast
        else                                          -- Devouring Plague already expired
            icon = SpellIcons.DevouringPlague
        end

    --[[
            If Shadow Word :Pain is not on target
            If ShadowWeaving_Count is on max (5)
    ]]
    elseif SWP_TimeLeft == 0 and ShadowWeaving_Count == 5 then
        icon = SpellIcons.ShadowWordPain
    else
        icon = SpellIcons.MindFlay
    end


    frame.texture:SetTexture(icon)

end


-- Event handler to update suggestions
frame:SetScript("OnEvent", function(self, event, unit, spellName, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, _, _, _, name = CombatLogGetCurrentEventInfo()
        if name == "PLAYER" then
            SuggestNextSpell()
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" or event == "PLAYER_TARGET_CHANGED" then
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
            SuggestNextSpell()    
        end
    end
end)



SLASH_AUTOMATAPriest1 = "/automatapriest"
SlashCmdList["AUTOMATAPriest"] = function(msg)
    deactivate = not deactivate  -- Toggle the addon state
    if deactivate then
        print("Automatapriest enabled.")
    else
        print("Automatapriest disabled.")
        frame.texture:SetTexture(nil)  -- Hide the frame when disabled
    end
end

-- Register events
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
