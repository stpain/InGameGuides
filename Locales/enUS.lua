local _, addon = ...;

if not addon.locales then
    addon.locales = {}
end

addon.locales.enUS = {

    SELECT_GUIDE = "Select Guide",

    SHOW_MATERIALS = "Show Materials",
    SHOW_STEPS = "Show Steps",

    HIDE_COMPLETED_STEPS = "Hide completed steps",

    SHOP_MATERIALS_AUCTION = "Shop in Auctionator",

    TRADESKILL_STEP_TITLE = "Skill levels: %d - %d",
    TRADESKILL_STEP_ACTION = "Craft: %d - %s",

    TRADESKILL_STEP_ACTION_SPELL_LINK = "Craft: %d - [%s]",
}