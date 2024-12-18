

local iggName, addon = ...;

local locale = GetLocale()



--[[

    basic listview, not currently used


IGGListviewMixin = {}

function IGGListviewMixin:OnLoad()

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    ---height is defined in the xml keyValues
    local height = self.elementHeight;
    self.scrollView:SetElementExtent(height);

    self.scrollView:SetElementInitializer(self.itemTemplate, GenerateClosure(self.OnElementInitialize, self));
    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollView);

    self.scrollView:SetPadding(1, 1, 1, 1, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);
    --ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, scrollBoxView)

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 1, -1),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -3, 1),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 1, -1),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);

end

function IGGListviewMixin:OnElementInitialize(element, data, isNew)
    if isNew then
        element:OnLoad();
    end
    element:SetHeight(self.elementHeight)
    element:SetDataBinding(data);
    element:Show()

    -- if self.enableSelection then
    --     if element.selected then
    --         element:HookScript("OnMouseDown", function()
    --             self.scrollView:ForEachFrame(function(f, d)
    --                 f.selected:Hide()
    --             end)
    --             element.selected:Show()
    --         end)
    --     end
    -- end
end

function IGGListviewMixin:OnElementReset(element)
    if element.ResetDataBinding then
        element:ResetDataBinding()
    end
end

]]











--[[

    using a no template listview means we can re-use the Ui for multiple lists
]]

IGGNoTemplateListviewMixin = {}

function IGGNoTemplateListviewMixin:OnLoad()

    self.DataProvider = CreateDataProvider();
    self.scrollView = CreateScrollBoxListLinearView();
    self.scrollView:SetDataProvider(self.DataProvider);

    self.scrollView:SetElementFactory(function(factory, elementData)
		factory(elementData.template, elementData.initializer);
	end);
    self.scrollView:SetElementExtentCalculator(function(_, elementData)
        return elementData.height or 40
    end)

    self.scrollView:SetElementResetter(GenerateClosure(self.OnElementReset, self));

    self.selectionBehavior = ScrollUtil.AddSelectionBehavior(self.scrollView);

    self.scrollView:SetPadding(6, 3, 3, 3, 1);

    ScrollUtil.InitScrollBoxListWithScrollBar(self.scrollBox, self.scrollBar, self.scrollView);
    --ScrollUtil.InitScrollBoxWithScrollBar(scrollBox, scrollBar, scrollBoxView)

    local anchorsWithBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 1, -1),
        CreateAnchor("BOTTOMRIGHT", self.scrollBar, "BOTTOMLEFT", -5, 1),
    };
    local anchorsWithoutBar = {
        CreateAnchor("TOPLEFT", self, "TOPLEFT", 1, -1),
        CreateAnchor("BOTTOMRIGHT", self, "BOTTOMRIGHT", -1, 1),
    };
    ScrollUtil.AddManagedScrollBarVisibilityBehavior(self.scrollBox, self.scrollBar, anchorsWithBar, anchorsWithoutBar);

end

function IGGNoTemplateListviewMixin:OnElementReset(element)
    if element.ResetDataBinding then
        element:ResetDataBinding()
    end
end










IGGSelectGuideButtonMixin = {}

function IGGSelectGuideButtonMixin:OnLoad()
    NineSliceUtil.ApplyLayout(self, NineSliceLayouts.TooltipDefaultLayout)
    self.Center:SetVertexColor(0,0,0)
end

function IGGSelectGuideButtonMixin:SetGuide(guide)
    
    self.title:SetText(guide.title)
    self.author:SetText(guide.author)

    if guide.icon then
        local isFileID = tonumber(guide.icon)
        if isFileID and type(isFileID) == "number" then
            self.icon:SetTexture(isFileID)
        else
            self.icon:SetAtlas(guide.icon)
        end
    end

    self:SetScript("OnClick", function ()
        IGG.CallbackRegistry:TriggerEvent("Guide_OnGuideSelected", guide)
    end)

end

function IGGSelectGuideButtonMixin:OnEnter()
    self.Center:SetVertexColor(0,1,1)
end

function IGGSelectGuideButtonMixin:OnLeave()
    self.Center:SetVertexColor(0,0,0)
end

function IGGSelectGuideButtonMixin:ResetDataBinding()
    self:SetScript("OnClick", nil)
end






IGGStepTemplateMixin = {}
function IGGStepTemplateMixin:OnLoad()
    self.titleDivider:SetTexelSnappingBias(0)
    self.titleDivider:SetSnapToPixelGrid(false)

    self.action:SetScript("OnLeave", function()
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
    end)

    NineSliceUtil.ApplyLayout(self, NineSliceLayouts.ChatBubble)
end



--[[
    template specific to IGG tradeskill guide data
    keys:
        .skillLevel { min, max, }
        .craft {
            itemID,
            amount,
            notes,
        }
    
]]
function IGGStepTemplateMixin:Update()

    if self.data then
        if self.data.skillLevel then
            self.title:SetText(string.format(addon.locales[locale].TRADESKILL_STEP_TITLE, self.data.skillLevel[1], self.data.skillLevel[2]))

        elseif self.data.title then
            self.title:SetText(self.data.title)
        end

        if self.data.isCompleted then
            self.completed:Show()
        else
            self.completed:Hide()
        end

        if self.data.craft then
            if type(self.data.craft.spellID) == "number" then
                local spell = Spell:CreateFromSpellID(self.data.craft.spellID)
                if not spell:IsSpellEmpty() then
                    spell:ContinueOnSpellLoad(function()

                        local spellInfo = C_Spell.GetSpellInfo(self.data.craft.spellID)

                        self.action:SetText(string.format(addon.locales[locale].TRADESKILL_STEP_ACTION_SPELL_LINK, self.data.craft.amount, spellInfo.name))
                        self.icon:SetTexture(spellInfo.iconID)

                        self.action:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
                            GameTooltip:SetSpellByID(self.data.craft.spellID)
                            GameTooltip:Show()
                        end)
                    end)
                end
            elseif type(self.data.craft.itemID) == "number" then
                local item = Item:CreateFromItemID(self.data.craft.itemID)
                if not item:IsItemEmpty() then
                    item:ContinueOnItemLoad(function()
                        self.action:SetText(string.format(addon.locales[locale].TRADESKILL_STEP_ACTION, self.data.craft.amount, item:GetItemLink()))
                        self.action:SetHeight(24)
                        self.icon:SetTexture(item:GetItemIcon())

                        self.action:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(self, 'ANCHOR_TOPRIGHT')
                            GameTooltip:SetItemByID(self.data.craft.itemID)
                            GameTooltip:Show()
                        end)
                    end)
                end
            elseif type(self.data.craft.itemID) == "table" then

                local text = ""
                self.action:SetHeight(14 * #self.data.craft.itemID)

                for _, id in ipairs(self.data.craft.itemID) do
                    local item = Item:CreateFromItemID(id)
                    if not item:IsItemEmpty() then
                        item:ContinueOnItemLoad(function()
                            text = text..string.format(addon.locales[locale].TRADESKILL_STEP_ACTION, self.data.craft.amount, item:GetItemLink()).."\n";
                            --self.icon:SetTexture(item:GetItemIcon())
                            self.action:SetText(text)
                        end)
                    end 
                end
            end
        end

        if self.data.craft.notes then
            self.note:SetText(self.data.craft.notes)
        end

        --action is normally set through the itemID fields/strings but in case of manual inputs/steps
        if self.data.action then
            self.action:SetText(self.data.action)
        end
    end
end

function IGGStepTemplateMixin:SetDataBinding(data)
    self.data = data;
    self:Update()
end

function IGGStepTemplateMixin:ResetDataBinding()
    self.title:SetText("")
    self.action:SetText("")
    self.note:SetText("")
    self.completed:Hide()
    self.data = nil;
    self.action:SetHeight(24)
    self.action:SetScript("OnEnter", nil)
end



IGGMaterialMixin = {}
function IGGMaterialMixin:SetItem(itemInfo)
    local item = Item:CreateFromItemID(itemInfo[1])
    if not item:IsItemEmpty() then
        item:ContinueOnItemLoad(function()

            local count = C_Item.GetItemCount(itemInfo[1])

            self.icon:SetTexture(item:GetItemIcon())
            self.link:SetText(string.format("%d %s", itemInfo[2], item:GetItemLink()))
            self.stock:SetText(count)
        end)
    end
end
function IGGMaterialMixin:OnLoad()
    
end
function IGGMaterialMixin:OnEnter()
    
end
function IGGMaterialMixin:OnLeave()
    
end