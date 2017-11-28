--绑定手机页面
local BindingMobileLayer = class("BindingMobileLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

function BindingMobileLayer:ctor(action)

    local csbNode = ExternalFun.loadCSB("BindingMobile/BindingMobileLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --发送验证码
    local btnSMSCode = self._content:getChildByName("btn_smscode")
    btnSMSCode:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onSendSMSCode()
    end)

    --确定绑定
    local btnBind = self._content:getChildByName("btn_bind")
    btnBind:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()
      
        self:onBindMobile()
    end)

    --取消绑定
    local btnUnBind = self._content:getChildByName("btn_unbind")
    btnUnBind:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()
      
        self:onUnBindMobile()
    end)

    --输入框
    local spEditBg = self._content:getChildByName("sp_edit_mobile_bg")
    local sizeBg = spEditBg:getContentSize()
    self._editMobile = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(11)
        :setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:addTo(spEditBg)

    spEditBg = self._content:getChildByName("sp_edit_smscode_bg")
    sizeBg = spEditBg:getContentSize()
    self._editSMSCode = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(6)
        :setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:addTo(spEditBg)

    -- 判断类型
    if action == 1 then 
        
        btnBind:setVisible(true)
        btnUnBind:setVisible(false)
    else

        self._editMobile:setText(GlobalUserItem.szBindMobile)
        self._editMobile:setEnabled(false)

        btnBind:setVisible(false)
        btnUnBind:setVisible(true)
    end

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()

        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        self._editMobile:setContentSize(self._editMobile:getContentSize())
        self._editSMSCode:setContentSize(self._editSMSCode:getContentSize())
    end)
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--发送验证码
function BindingMobileLayer:onSendSMSCode()

    local szMobile = string.gsub(self._editMobile:getText(), " ", "")

    if not ExternalFun.isPhoneNumber(szMobile) then
        showToast(nil, "请输入正确的手机号!", 1)
        return
    end

    showPopWait()

    --发送验证码
    RequestManager.sendSMSCode(szMobile, function(result, message)

        dismissPopWait()

        if nil ~= message then
            showToast(nil, message, 2)
        end
    end)
end

--绑定手机
function BindingMobileLayer:onBindMobile()

    local szMobile = string.gsub(self._editMobile:getText(), " ", "")
    local szSMSCode = string.gsub(self._editSMSCode:getText(), " ", "")

    if not ExternalFun.isPhoneNumber(szMobile) then
        showToast(nil, "请输入正确的手机号!", 1)
        return
    end

    if #szSMSCode ~= 6 then
        showToast(nil, "请输入正确的验证码!", 1)
        return
    end

    showPopWait()

    RequestManager.bindMobile(szMobile, szSMSCode, function(result, message)
        
        dismissPopWait()

        showToast(nil, message, 2)

        if string.find(message, "成功") ~= nil then

            GlobalUserItem.szBindMobile = szMobile

            dismissPopupLayer(self)
        end
    end)
end

--取消绑定手机
function BindingMobileLayer:onUnBindMobile()

    local szMobile = string.gsub(self._editMobile:getText(), " ", "")
    local szSMSCode = string.gsub(self._editSMSCode:getText(), " ", "")

    if not ExternalFun.isPhoneNumber(szMobile) then
        showToast(nil, "请输入正确的手机号!", 1)
        return
    end

    if #szSMSCode ~= 6 then
        showToast(nil, "请输入正确的验证码!", 1)
        return
    end

    showPopWait()

    RequestManager.unBindMobile(szMobile, szSMSCode, function(result, message)
        
        dismissPopWait()

        showToast(nil, message, 2)

        if string.find(message, "成功") ~= nil then

            GlobalUserItem.szBindMobile = ""

            dismissPopupLayer(self)
        end
    end)
end

return BindingMobileLayer