

local _, addon = ...;


IGG.CallbackRegistry = {}

Mixin(IGG.CallbackRegistry, CallbackRegistryMixin)
IGG.CallbackRegistry:GenerateCallbackEvents({
    "Guide_OnStepCompleted",
    "Guide_OnGuideLoaded",
    "Guide_OnGuideSelected",
    "Tradeskill_OnSkillChanged",
})
CallbackRegistryMixin.OnLoad(IGG.CallbackRegistry);