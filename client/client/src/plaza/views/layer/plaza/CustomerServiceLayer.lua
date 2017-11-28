
-- 客服服务视图
local CustomerServiceLayer = class("CustomerServiceLayer", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local TAG_MASK = 101
local TAG_MASK2 = 102
-- 客服QQ
local BT_QQ = 103
-- 客服电话
local BT_PHONECALL = 104

function CustomerServiceLayer:ctor()

    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("public/CustomerServiceLayer.csb", self)

    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end

    -- 遮罩
    local mask = csbNode:getChildByName("panel_mask")
    mask:setTag(TAG_MASK)
    mask:addTouchEventListener( touchFunC )

    -- 底板
    local panel = csbNode:getChildByName("panel_holder")
    self.m_panelHolder = panel

    -- 客服QQ
    local btn = panel:getChildByName("btn_qq")
    btn:setTag(BT_QQ)
    btn:addTouchEventListener( touchFunC )

    -- 客服电话
    btn = panel:getChildByName("btn_phonecall")
    btn:setTag(BT_PHONECALL)
    btn:addTouchEventListener( touchFunC )

    panel:stopAllActions()
    local call = cc.CallFunc:create(function()
        ExternalFun.popupTouchFilter(1, false)
    end)
    local move = cc.MoveTo:create(0.2, cc.p(0, 0))
    local call2 = cc.CallFunc:create(function()
        ExternalFun.dismissTouchFilter()
    end)
    local seq = cc.Sequence:create(call, move, call2)
    panel:runAction(seq)
end

function CustomerServiceLayer:onButtonClickedEvent(tag, ref)
    if TAG_MASK == tag or TAG_MASK2 == tag then
        self:hide()
    elseif BT_QQ == tag then        
        self:hide()
        --可以直接通过QQ打开，但是不能聊天
        --cc.Application:getInstance():openURL("mqq://im/chat?chat_type=wpa&uin=800196876&version=1&src_type=web&web_src=http://wpa.b.qq.com")
        
        --通过浏览器跳转，可以聊天
        cc.Application:getInstance():openURL("http://wpa.b.qq.com/cgi/wpa.php?ln=2&uin=" .. yl.SERVICE_QQ)
    elseif BT_PHONECALL == tag then        
        self:hide()

        --拨打客服电话
        cc.Application:getInstance():openURL("tel:" .. yl.SERVICE_PHONE)
    end
end

function CustomerServiceLayer:hide( callfun )
    self.m_panelHolder:stopAllActions()
    local call = cc.CallFunc:create(function()
        ExternalFun.popupTouchFilter(1, false)
    end)
    local move = cc.MoveTo:create(0.2, cc.p(0, -150))
    local call2 = cc.CallFunc:create(function()
        ExternalFun.dismissTouchFilter()
        self:removeFromParent()
    end)
    if nil ~= callfun then
        seq = cc.Sequence:create(call, move, callfun, call2)
        self.m_panelHolder:runAction(seq)
    else
        seq = cc.Sequence:create(call, move, call2)
        self.m_panelHolder:runAction(seq)
    end    
end

return CustomerServiceLayer