--开通银行页面
local BankEnableLayer = class("BankEnableLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local BankFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BankFrame")

function BankEnableLayer:ctor(callback)

    --初始化变量
    self._callback = callback
    self._editPwds = {}

    --网络处理
	self._bankFrame = BankFrame:create(self,function(result,message)
        self:onBankCallBack(result,message)
    end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Bank/Enable/BankEnableLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --开通按钮
    local btnOK = self._content:getChildByName("btn_enable")
    btnOK:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickEnable()
    end) 

    --输入框
    local editNames = { "sp_edit_pwd_bg_1", "sp_edit_pwd_bg_2" }
    for i = 1, #editNames do

        local spEditBg = self._content:getChildByName(editNames[i])
        local sizeBg = spEditBg:getContentSize()
        self._editPwds[i] = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		    :move(sizeBg.width / 2, sizeBg.height / 2)
            :setFontSize(30)
            :setFontColor(cc.WHITE)
		    :setFontName("fonts/round_body.ttf")
		    :setMaxLength(32)
            :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
            :setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		    :addTo(spEditBg)
    end

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()
        
        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        for i = 1, #self._editPwds do
            self._editPwds[i]:setContentSize(self._editPwds[i]:getContentSize())
        end
    end)

    showToast(self, "初次使用，请先开通银行", 2)
end

function BankEnableLayer:onExit()
    
    --关闭网络
    if self._bankFrame:isSocketServer() then
        self._bankFrame:onCloseSocket()
    end
    if nil ~= self._bankFrame._gameFrame then
        self._bankFrame._gameFrame._shotFrame = nil
        self._bankFrame._gameFrame = nil
    end
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击开通
function BankEnableLayer:onClickEnable()

	--参数判断
	local szPass = self._editPwds[1]:getText()
	local szPassConfirm = self._editPwds[2]:getText()

	if #szPass < 1 then 
		showToast(self,"请输入银行密码！",2)
		return
	end
	if #szPass < 6 then
		showToast(self,"密码必须大于6个字符，请重新输入！",2)
		return
	end

	if #szPassConfirm < 1 then 
		showToast(self,"请在确认栏输入银行密码！",2)
		return
	end
	if #szPassConfirm < 6 then
		showToast(self,"确认栏密码必须大于6个字符，请重新输入！",2)
		return
	end

	if szPass ~= szPassConfirm then
		showToast(self,"设置栏和确认栏的密码不相同，请重新输入！",2)
        return
	end

    -- 与帐号不同
    if string.lower(szPass) == string.lower(GlobalUserItem.szAccount) then
        showToast(self,"密码不能与帐号相同，请重新输入！",2)
        return
    end

    -- 银行不同登陆
    if string.lower(szPass) == string.lower(GlobalUserItem.szPassword) then
        showToast(self, "银行密码不能与登录密码一致!", 2)
        return
    end
    
	showPopWait()
	self._bankFrame:onEnableBank(szPass)
end

--------------------------------------------------------------------------------------------------------------------
-- BankFrame 事件处理

--操作结果
function BankEnableLayer:onBankCallBack(result,message)

	dismissPopWait()

	if message ~= nil and message ~= "" then
		showToast(nil,message,2)
	end

	if result == 2 then
		if GlobalUserItem.cbInsureEnabled~=0 then

            local callback = self._callback

            --关闭
            dismissPopupLayer(self)

            if callback then
                callback()
            end

			showToast(nil,"银行开通成功！",2)
		end
	end
end

return BankEnableLayer