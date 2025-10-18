--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

---@type CW_DialogBubble_C
local M = UnLua.Class()

function M:Initialize(Initializer)
    -- UI组件引用（这些组件在蓝图中定义）：
    -- self.Text_Dialog      - 对话内容文本
    -- self.Overlay_Npc      - NPC头像和名字容器
    -- self.Text_Npc         - NPC名字文本
    -- self.Overlay_Player   - 玩家头像和名字容器
    -- self.Text_Player      - 玩家名字文本
end

--- 设置头像和名字
---@param isPlayer boolean 是否是玩家
---@param name string 角色名字
function M:SetCharacter(isPlayer, name)
    if isPlayer then
        -- 玩家：隐藏NPC，显示Player
        if self.Overlay_Npc then
            self.Overlay_Npc:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        if self.Overlay_Player then
            self.Overlay_Player:SetVisibility(UE.ESlateVisibility.Visible)
        end
        -- 设置玩家名字
        if self.Text_Player then
            self.Text_Player:SetText(name)
        end
    else
        -- NPC：显示NPC，隐藏Player
        if self.Overlay_Npc then
            self.Overlay_Npc:SetVisibility(UE.ESlateVisibility.Visible)
        end
        if self.Overlay_Player then
            self.Overlay_Player:SetVisibility(UE.ESlateVisibility.Collapsed)
        end
        -- 设置NPC名字
        if self.Text_Npc then
            self.Text_Npc:SetText(name)
        end
    end
end

--- 设置dialog内容
---@param text string 对话文本内容
function M:SetText(text)
    if self.Text_Dialog then
        -- UnLua 的 SetText 可以直接接受字符串
        self.Text_Dialog:SetText(text)
    end
end


--function M:PreConstruct(IsDesignTime)
--end

-- function M:Construct()
-- end

--function M:Tick(MyGeometry, InDeltaTime)
--end

return M
