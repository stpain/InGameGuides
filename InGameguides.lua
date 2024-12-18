


--[[


    InGameGuides

    This addon serves as an interface for guides related to World of Warcraft
    Guides can be for professions, reputations, leveling and almost anything else
    
    Example guides for professions exist and provide the template guide authors 
    will need to use for their guide to function in this addon

    Guides will need to use X-IGG tags in thier .toc files so they can be identified
    The current tags are

    X-IGG-Title 
    X-IGG-Author 
    X-IGG-Title [optional]


]]

local addonName, addon = ...;

local locale = GetLocale()
local Tradeskills = addon.Tradeskills;

--taken from the wiki
local function TryLoadAddOn(name)
	local loaded, reason = C_AddOns.LoadAddOn(name)
    --DevTools_Dump({reason = reason, loaded = loaded})
	if not loaded then
		if reason == "DISABLED" then
			C_AddOns.EnableAddOn(name)
			C_AddOns.LoadAddOn(name)
		else
			local failed_msg = format("%s - %s", reason, _G["ADDON_"..reason])
			error(ADDON_LOAD_FAILED:format(name, failed_msg))
		end
	end
end


--look for addons using the X-IGG tags in their .toc files
local function GetAllAddons()

    local t = {}

    for i = 1, C_AddOns.GetNumAddOns() do

        local title = C_AddOns.GetAddOnMetadata(i, "X-IGG-Title")
        local author = C_AddOns.GetAddOnMetadata(i, "X-IGG-Author")
        local icon = C_AddOns.GetAddOnMetadata(i, "X-IGG-Icon")

        if title then
            local name, _, notes, loadable, reason, security, updateAvailable = C_AddOns.GetAddOnInfo(i)
            table.insert(t, {
                title = title,
                author = author,
                icon = icon,
                addonName = name,
                addonIndex = i,
            })
        end
        
    end

    return t;
end



InGameGuidesMixin = {}

function InGameGuidesMixin:OnLoad()

    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
    self:RegisterEvent("AUCTION_HOUSE_CLOSED")

    self:RegisterForDrag("LeftButton")
    self.resize:Init(self, 360, 300, 500, 800)

    self:SetTitle("In Game Guides")
    self.viewAllGuides:SetText(addon.locales[locale].SELECT_GUIDE)

    self.portraitMask = self:CreateMaskTexture()
    self.portraitMask:SetAllPoints(InGameGuidesPortrait)
    self.portraitMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    InGameGuidesPortrait:AddMaskTexture(self.portraitMask)
    InGameGuidesPortrait:SetDrawLayer("ARTWORK")
    InGameGuidesPortrait:SetAtlas("ClassHall_StoneFrame-BackgroundTile")

    --InGameGuidesPortrait:SetTexture("Interface/Addons/InGameGuides/Media/books.png") --<a href="https://www.freepik.com/free-vector/set-old-books-scrolls-parchments-papers_12120863.htm#fromView=author&page=1&position=49&uuid=2d0abaeb-8769-42e2-8ab1-ce75083a72ec">Image by valadzionak_volha on Freepik</a>
    --InGameGuidesPortrait:SetTexCoord(0.45, 1, 0, 0.66)

    self.icon = InGameGuides:CreateTexture(nil, "ARTWORK", nil, 1)
    
    self.icon:SetTexture("Interface/Addons/InGameGuides/Media/BookStackImage")
    self.icon:SetTexCoord(0.2, 0.8, 0.2, 0.8)
    self.icon:SetPoint("TOPLEFT", InGameGuidesPortrait, "TOPLEFT", -5, 5)
    self.icon:SetPoint("BOTTOMRIGHT", InGameGuidesPortrait, "BOTTOMRIGHT", 5, -5)
    
    self.iconMask = self:CreateMaskTexture()
    self.iconMask:SetAllPoints(InGameGuidesPortrait)
    self.iconMask:SetTexture("Interface/CHARACTERFRAME/TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    self.icon:AddMaskTexture(self.iconMask)

    local frameInset = _G["InGameGuidesInset"]
    frameInset:SetPoint("TOPLEFT", 4, -80)

    self.loadAuctionData:SetText(addon.locales[locale].SHOP_MATERIALS_AUCTION)

    self.hideCompletedSteps.label:SetText(addon.locales[locale].HIDE_COMPLETED_STEPS)
    self.hideCompletedSteps:SetScript("OnClick", function ()
        if self.loadedGuide then
            self:LoadGuide(self.loadedGuide)
        end
    end)

    SLASH_INGAMEGUIDES1 = '/igg'
    SlashCmdList['INGAMEGUIDES'] = function(msg)
        if msg == "" then
            self:Show()
        end
    end

    self.viewAllGuides:SetScript("OnClick", function ()
        self:LoadAllGuides()
    end)

    IGG.CallbackRegistry:RegisterCallback("Guide_OnGuideLoaded", self.Guide_OnGuideLoaded, self)
    IGG.CallbackRegistry:RegisterCallback("Guide_OnGuideSelected", self.Guide_OnGuideSelected, self)
end

--when a guide addon is loaded we store the guide data using the addon name as key
function InGameGuidesMixin:Guide_OnGuideLoaded(name, guideData)
    if not IGG.GuideData then
        IGG.GuideData = {}
    end

    IGG.GuideData[name] = guideData;

    --if this addon was loaded on demand then push the guide
    if self.awaitingAddonLoad then
        self:LoadGuide(IGG.GuideData[name])
        self.awaitingAddonLoad = false;
    end
end

function InGameGuidesMixin:Guide_OnGuideSelected(guide)
    
    if not IGG.GuideData[guide.addonName] then
        self.awaitingAddonLoad = true
        TryLoadAddOn(guide.addonName)
    else
        self:LoadGuide(IGG.GuideData[guide.addonName])
    end
end

function InGameGuidesMixin:OnEvent(event, ...)
    if self[event] then
        self[event](self, ...)
    end
end

function InGameGuidesMixin:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(...)
    if (... == 21) and self.loadAuctionData:IsVisible() and self.loadedGuide and self.loadedGuide.materials then
        self.loadAuctionData:Enable()
        self:PrepareAuctionDataButton(self.loadedGuide.materials)
    end
end

function InGameGuidesMixin:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(...)
    if (... == 21) and self.loadAuctionData:IsVisible() then
        self.loadAuctionData:Disable()
    end
end

function InGameGuidesMixin:AUCTION_HOUSE_CLOSED(...)
    self.loadAuctionData:Disable()
end

function InGameGuidesMixin:LoadAllGuides()

    self.loadedGuide = nil;

    self:SetNewDataProvider()

    self.showMaterials:Hide()

    self:ToggleView()

    local guides = GetAllAddons()

    if guides then
        for _, guide in ipairs(guides) do
            self.guideListview.DataProvider:Insert({
                template = "IGGSelectGuideButtonTemplete",
                height = 50,
                initializer = function(frame)
                    frame:SetGuide(guide)
                end,
            })
        end
    end
end

function InGameGuidesMixin:ToggleView(view)
    
    self.hideCompletedSteps:Hide()
    self.loadAuctionData:Hide()
    
    if view == "steps" then
        self.hideCompletedSteps:Show()
    
    elseif view == "materials" then
        self.loadAuctionData:Show()

    end
end

function InGameGuidesMixin:LoadGuide(guide)

    if not self.loadedGuide then
        self.loadedGuide = guide;
    end

    if guide.name then
        self.guideTitle:SetText(guide.name)
    end

    if guide.steps then

        self.hideCompletedSteps:Show()

        if guide.type == "tradeskill" then
            
            self:SetNewDataProvider()


            --for tradeskill guides IGG will handle the step completion logic
            --this requires a few additional keys being set in the guide
            --update this function when expanding beyond classic clients
            local skills = self:GetPlayerSkillLevels()
            local stepCompletedFunc = function (step)
                if skills[guide.skillLineID] then
                    if guide.expansionSkillLineID and type(skills[guide.skillLineID]) == "table" and skills[guide.skillLineID][guide.expansionSkillLineID] then
                        
                    else
                        if (type(skills[guide.skillLineID]) == "number") and (step.skillLevel[2] < skills[guide.skillLineID]) then
                            return true;
                        end
                    end
                else
                    return false
                end
            end
            
            --pre load the steps
            self:LoadSteps(guide.steps, guide.stepTemplate, guide.stepTemplateHeight, guide.stepInitializerFunc, stepCompletedFunc)

            if type(guide.materials) == "table" then

                self.showMaterials:SetText(addon.locales[locale].SHOW_MATERIALS)
                self.showMaterials:Show()
                self.showMaterials.state = false

                self.showMaterials:SetScript("OnClick", function(b)
                    if b.state == false then
                        self:ToggleView("materials")
                        self:LoadMaterials(guide.materials)
                        b:SetText(addon.locales[locale].SHOW_STEPS)
                    else
                        self:ToggleView("steps")
                        self:LoadSteps(guide.steps, guide.stepTemplate, guide.stepTemplateHeight, guide.stepInitializerFunc, stepCompletedFunc)
                        b:SetText(addon.locales[locale].SHOW_MATERIALS)
                    end

                    b.state = not b.state;
                end)
            end

        end
    end
end

function InGameGuidesMixin:SetNewDataProvider()
    self.guideListview.DataProvider = CreateDataProvider({})
    self.guideListview.scrollView:SetDataProvider(self.guideListview.DataProvider)
end



--[[
    guide addons can provide various functions to determine how the guide displays

    stepTemplate can be passed as a simple string in which case it needs to be converted
    into a local function returining said string
    
    stepHeight can be a number or a function, again convert into a function if just a
    is passed

    stepInitializerFunc can be used to 'load' the step data into the step frame template

    stepCompletedFunc is used to determine if the step has been completed by the player
]]
function InGameGuidesMixin:LoadSteps(steps, stepTemplate, stepHeight, stepInitializerFunc, stepCompletedFunc)
    self:SetNewDataProvider()

    local hideCompleted = self.hideCompletedSteps:GetChecked()

    if type(stepHeight) == "number" then
        local x = stepHeight
        stepHeight = function(step)
            return x;
        end
    end

    if type(stepTemplate) == "string" then
        local x = stepTemplate
        stepTemplate = function(step)
            return x;
        end
    end


    if type(steps) == "table" then
        for k, step in ipairs(steps) do
            local addStep = true

            if stepCompletedFunc then
                if stepCompletedFunc(step) then

                    --set a flag for the template to show a green tick
                    step.isCompleted = true

                    if hideCompleted then
                        addStep = false;
                    end
                else

                end
            end


            -- if hideCompleted and stepCompletedFunc then
            --     if not stepCompletedFunc(step) then
            --         addStep = true
            --     end
            -- else
            --     addStep = true
            -- end

            if addStep and (step.template or stepTemplate) and (step.height or stepHeight) then

                self.guideListview.DataProvider:Insert({
                    template = step.template or stepTemplate(step),
                    height = step.height or stepHeight(step),
                    initializer = function(frame)
                        if stepInitializerFunc then
                            stepInitializerFunc(frame, step)

                        else
                            if frame.SetDataBinding then
                                frame:SetDataBinding(step)
                            end
                        end
                    end,
                })
            end
        end
    end
end

function InGameGuidesMixin:LoadMaterials(materials)
    self:SetNewDataProvider()
    
    if type(materials) == "table" then
        for _, itemInfo in ipairs(materials) do
            self.guideListview.DataProvider:Insert({
                template = "IGGMaterialTemplate",
                height = 28,
                initializer = function(frame)
                    frame:SetItem(itemInfo)
                end,
            })
        end
    end

    self.loadAuctionData:Disable()
    self:PrepareAuctionDataButton(materials)
end

function InGameGuidesMixin:PrepareAuctionDataButton(materials)
    if AuctionFrame and AuctionFrame:IsVisible()  then
       
        if Auctionator then

            self.loadAuctionData:Enable()

            local auctionData = {}

            for _, itemInfo in ipairs(materials) do
                local item = Item:CreateFromItemID(itemInfo[1])
                if not item:IsItemEmpty() then
                    item:ContinueOnItemLoad(function()
                        table.insert(auctionData, item:GetItemName())
                    end)
                end
            end

            self.loadAuctionData:SetScript("OnClick", function ()
                Auctionator.API.v1.MultiSearch(addonName, auctionData)
            end)

        else
            self.loadAuctionData:Disable()
        end

    end
end

function InGameGuidesMixin:GetPlayerSkillLevels()

    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then

        local skills = {}
        for s = 1, GetNumSkillLines() do
            local skill, _, _, level, _, _, _, _, _, _, _, _, _ = GetSkillLineInfo(s)
            if skill and (type(level) == "number") then
                local tradeskillId = Tradeskills:GetTradeskillIDFromLocale(skill)
                if tradeskillId then
                    skills[tradeskillId] = level
                end
            end
        end
        return skills;

    end
end