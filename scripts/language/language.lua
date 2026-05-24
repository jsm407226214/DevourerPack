local MOD_Language = TUNING.MOD_LANGUAGE
if MOD_Language == "auto" or MOD_Language == nil then
    local loc = require "languages/loc"
    local lan
    if loc and loc.IsLocalized() then
        lan = loc.CurrentLocale.code
    end
    if lan and (lan == "zh" or lan == "zhr") then
        MOD_Language = "_cn"
    else
        MOD_Language = "_en"
    end
end
-- MOD_Language = "_en"
modimport("scripts/language/strings" .. MOD_Language)
