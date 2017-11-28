--登录验证页面
local ValidateMobileLayer = class("ValidateMobileLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

function ValidateMobileLayer:ctor(delegate, bindmobile)

    self._delegate = delegate
    self._bindmobile = bindmobile

    local csbNode = ExternalFun.loadCSB("ValidateMobile/ValidateMobileLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    self._txtMobile = self._content:getChildByName("txt_mobile")
    self._txtMobile:setString(string.sub(bindmobile, 1, 3) .. "*****" .. string.sub(bindmobile, 9, 11))

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

    --确定登录
    local btnConfirm = self._content:getChildByName("btn_confirm")
    btnConfirm:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()
      
        self:onConfirm()
    end)

    --输入框
    local spEditBg = self._content:getChildByName("sp_edit_smscode_bg")
    local sizeBg = spEditBg:getContentSize()
    self._editSMSCode = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(6)
        :setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:addTo(spEditBg)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()

        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        self._editSMSCode:setContentSize(self._editSMSCode:getContentSize())
    end)
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--发送验证码
function ValidateMobileLayer:onSendSMSCode()

    local szMobile = self._bindmobile

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
function ValidateMobileLayer:onConfirm()

    local szMobile = self._bindmobile
    local szSMSCode = string.gsub(self._editSMSCode:getText(), " ", "")

    if not ExternalFun.isPhoneNumber(szMobile) then
        showToast(nil, "请输入正确的手机号!", 1)
        return
    end

    if #szSMSCode ~= 6 or tonumber(szSMSCode) == nil then
        showToast(nil, "请输入正确的验证码!", 1)
        return
    end

    if self._delegate and self._delegate.onConfirmMobileValidate then
        self._delegate:onConfirmMobileValidate(szSMSCode)
    end
end

return ValidateMobileLayer