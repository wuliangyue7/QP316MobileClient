--注册界面

local RegisterLayer = class("RegisterLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local ServiceLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.other.ServiceLayer")

local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

function RegisterLayer:ctor(delegate)

    self._delegate = delegate

    local csbNode = ExternalFun.loadCSB("Logon/RegisterLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --返回
    local btnBack = csbNode:getChildByName("btn_back")
    btnBack:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        --通知关闭
        if self._delegate and self._delegate.onRegisterLayerClose then
            self._delegate:onRegisterLayerClose()
        end

        dismissPopupLayer(self)
    end)

    --输入框
    self._editAccount = self:onCreateEditBox(self._content:getChildByName("sp_edit_account_bg"), false, false, 31)
    self._editNickName = self:onCreateEditBox(self._content:getChildByName("sp_edit_nickname_bg"), false, false, 31)
    self._editPassword = self:onCreateEditBox(self._content:getChildByName("sp_edit_pwd_bg"), true, false, 20)
    self._editMobile = self:onCreateEditBox(self._content:getChildByName("sp_edit_mobile_bg"), false, true, 11)
    self._editSMSCode = self:onCreateEditBox(self._content:getChildByName("sp_edit_smscode_bg"), false, true, 6)

    --同意协议
    self._checkAgreement = self._content:getChildByName("check_agreement")

    --游戏协议
    local btnAgreement = self._content:getChildByName("btn_agreement")
    btnAgreement:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickAgreement()
    end)

    --获取验证码
    local btnSMSCode = self._content:getChildByName("btn_smscode")
    btnSMSCode:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickSMSCode()
    end)

    --注册
    local btnRegister = self._content:getChildByName("btn_register")
    btnRegister:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickRegister()
    end)
end

function RegisterLayer:onShow()
    
    local px, py = self._content:getPosition()

    self._content:setPosition(px, py + appdf.HEIGHT / 2)

    --动画跳入
    self._content:runAction(cc.EaseBackOut:create(cc.MoveTo:create(0.4, cc.p(px, py))))
end

--创建输入框
function RegisterLayer:onCreateEditBox(spEditBg, isPassword, isNumeric, maxLength)
    
    local inputMode = isNumeric and cc.EDITBOX_INPUT_MODE_NUMERIC or cc.EDITBOX_INPUT_MODE_SINGLELINE

    local sizeBg = spEditBg:getContentSize()
    local editBox = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(32)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(maxLength)
        :setInputMode(inputMode)
		:addTo(spEditBg) 

    --密码框
    if isPassword then
        editBox:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
    end

    return editBox
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击游戏条款
function RegisterLayer:onClickAgreement()

    showPopupLayer(ServiceLayer:create(self), false)
end

--点击获取验证码
function RegisterLayer:onClickSMSCode()

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

--注册
function RegisterLayer:onClickRegister()

	-- 判断 非 数字、字母、下划线、中文 的帐号
	local szAccount = self._editAccount:getText()
	local filter = string.find(szAccount, "^[a-zA-Z0-9_\128-\254]+$")
	if szAccount ~= "" and nil == filter then
		showToast(nil, "帐号包含非法字符, 请重试!", 1)
		return
	end

    szAccount = string.gsub(szAccount, " ", "")

    -- 判断 非 数字、字母、下划线、中文 的帐号
	local szNickName = self._editNickName:getText()
	local filter = string.find(szNickName, "^[a-zA-Z0-9_\128-\254]+$")
	if szNickName ~= "" and nil == filter then
		showToast(nil, "昵称包含非法字符, 请重试!", 1)
		return
	end

    szNickName = string.gsub(szNickName, " ", "")

	local szPassword = string.gsub(self._editPassword:getText(), " ", "")
	local szMobile = string.gsub(self._editMobile:getText(), " ", "")
    local szSMSCode = string.gsub(self._editSMSCode:getText(), " ", "")

    local len = ExternalFun.stringLen(szAccount)
	if len < 6 or len > 31 then
		showToast(nil, "游戏帐号必须为6~31个字符，请重新输入！", 2);
		return
	end

    len = ExternalFun.stringLen(szNickName)
	if len < 6 or len > 31 then
		showToast(nil, "游戏昵称必须为6~31个字符，请重新输入！", 2);
		return
	end

	--判断emoji
    if ExternalFun.isContainEmoji(szAccount) then
        showToast(nil, "帐号包含非法字符,请重试", 2)
        return
    end

    if ExternalFun.isContainEmoji(szNickName) then
        showToast(nil, "昵称包含非法字符,请重试", 2)
        return
    end

	--判断是否有非法字符
	if true == ExternalFun.isContainBadWords(szAccount) then
		showToast(nil, "帐号中包含敏感字符,不能注册", 2)
		return
	end

	if true == ExternalFun.isContainBadWords(szNickName) then
		showToast(nil, "昵称中包含敏感字符,不能注册", 2)
		return
	end

	len = ExternalFun.stringLen(szPassword)
	if len < 6 or len > 26 then
		showToast(nil,"密码必须为6~26个字符，请重新输入！",2);
		return
	end	

	-- 与帐号不同
	if string.lower(szPassword) == string.lower(szAccount) then
		showToast(nil,"密码不能与帐号相同，请重新输入！",2);
		return
	end

    -- 检查手机号
  --  if not ExternalFun.isPhoneNumber(szMobile) then
  --      showToast(nil, "请输入正确的手机号!", 2)
  --      return
  --  end

    -- 检查验证码
  --  if tonumber(szSMSCode) == nil or #szSMSCode ~= 6 then
   --     showToast(nil, "请输入正确的验证码!", 2)
   --     return
   -- end

--    if self._checkAgreement:isSelected() == false then
--		showToast(nil,"请先阅读并同意《游戏中心服务条款》！",2);
--		return
--	end

    if self._delegate and self._delegate.onRegisterAccount then
	    self._delegate:onRegisterAccount(szAccount, szNickName, szPassword, szMobile, szSMSCode)
    end
end

--------------------------------------------------------------------------------------------------------------------
-- ServiceLayer 回调

--同意条款
function RegisterLayer:onConfirmAgreement()

    self._checkAgreement:setSelected(true)
end

return RegisterLayer