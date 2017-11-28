--绑定页面
local BindingLayer = class("BindingLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")
local QueryDialog = appdf.req(appdf.BASE_SRC .. "app.views.layer.other.QueryDialog")

function BindingLayer:ctor()

    --初始化变量
    self._btnTabs = {}
    self._panels = {}
    self._selectedIndex = 1

    --网络处理
	self._modifyFrame = ModifyFrame:create(self, function(result, message)
        self:onModifyCallBack(result, message)
    end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Binding/BindingLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --确定按钮
    local btnBinding = self._content:getChildByName("btn_binding")
    btnBinding:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickBinding()
    end) 

    --选项按钮
    for i = 1, 2 do

        local btnTab = self._content:getChildByName("btn_tab_" .. i)
        btnTab:addEventListener(function()
            self:onSelectTab(i)
        end)

        self._btnTabs[i] = btnTab
        self._panels[i] = self._content:getChildByName("panel_" .. i)
    end

    --输入框
    self._editExistAccounts = self:onCreateEditBox(self._panels[1]:getChildByName("sp_edit_accounts_bg"), false, false, 31)
    self._editExistPassword = self:onCreateEditBox(self._panels[1]:getChildByName("sp_edit_password_bg"), true, false, 20)
    self._editNewAccounts = self:onCreateEditBox(self._panels[2]:getChildByName("sp_edit_accounts_bg"), false, false, 31)
    self._editNewNickName = self:onCreateEditBox(self._panels[2]:getChildByName("sp_edit_nickname_bg"), false, false, 31)
    self._editNewPassword = self:onCreateEditBox(self._panels[2]:getChildByName("sp_edit_password_bg"), true, false, 20)
    self._editSpreader = self:onCreateEditBox(self._panels[2]:getChildByName("sp_edit_spreader_bg"), false, true, 10)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()
        
        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        local editBoxs = { 
            self._editExistAccounts,
            self._editExistPassword,
            self._editNewAccounts,
            self._editNewNickName,
            self._editNewPassword,
            self._editSpreader
            }

        for i = 1, #editBoxs do
            editBoxs[i]:setContentSize(editBoxs[i]:getContentSize())
        end
    end)
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

function BindingLayer:onExit()

    if self._modifyFrame:isSocketServer() then
        self._modifyFrame:onCloseSocket()
    end
end

--创建编辑框
function BindingLayer:onCreateEditBox(spEditBg, isPassword, isNumeric, maxLength)
    
    local inputMode = isNumeric and cc.EDITBOX_INPUT_MODE_NUMERIC or cc.EDITBOX_INPUT_MODE_SINGLELINE

    local sizeBg = spEditBg:getContentSize()
    local editBox = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
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

--切换选项卡
function BindingLayer:onSelectTab(index)

    --播放音效
    ExternalFun.playClickEffect()

    --保存下标
    self._selectedIndex = index

    --设置选中状态
    for i = 1, #self._btnTabs do
        self._btnTabs[i]:setSelected(index == i)
        self._panels[i]:setVisible(index == i)
    end
end

--点击绑定
function BindingLayer:onClickBinding()

    if self._selectedIndex == 1 then        --绑定已存在账号

        local szAccount = self._editExistAccounts:getText()
        local szPassword = self._editExistPassword:getText()

        --输入检测
        if szAccount == nil then
            showToast(nil,"游戏帐号必须为6~31个字符，请重新输入！",2)
            return
        end
        local len = #szAccount
        if len < 6 or len > 31 then
            showToast(nil,"游戏帐号必须为6~31个字符，请重新输入！",2)
            return
        end
        if nil == szPassword then
            showToast(nil,"密码必须大于6个字符，请重新输入！",2)
            return 
        end
        len = #szPassword
        if  len<6 then
            showToast(nil,"密码必须大于6个字符，请重新输入！",2)
            return
        end

        local tips = "绑定帐号后该游客信息将与新帐号合并，游客帐号将会被注销，绑定成功之后需要重新登录,是否绑定帐号?"
        QueryDialog:create(tips, function(ok)
            if ok == true then                
                
                showPopWait()

                self.szAccount = szAccount
                self.szPassword = szPassword
                self._modifyFrame:onAccountBinding(szAccount, md5(szPassword))
            end
        end):addTo(self)

    elseif self._selectedIndex == 2 then    --绑定新账号

        local szAccount = self._editNewAccounts:getText()
        local szNickName = self._editNewNickName:getText()
        local szPassword = self._editNewPassword:getText()
        local szSpreader = self._editSpreader:getText()

        --输入检测
        if szAccount == nil then
            showToast(nil,"游戏帐号必须为6~31个字符，请重新输入！",2)
            return
        end
        if szNickName == nil then
            showToast(nil,"游戏昵称必须为6~31个字符，请重新输入！",2)
            return
        end

        local len = #szAccount
        if len < 6 or len > 31 then
            showToast(nil,"游戏帐号必须为6~31个字符，请重新输入！",2)
            return
        end
        len = #szNickName
        if len < 6 or len > 31 then
            showToast(nil,"游戏昵称必须为6~31个字符，请重新输入！",2)
            return
        end

        if nil == szPassword then
            showToast(nil,"密码必须大于6个字符，请重新输入！",2)
            return 
        end
        len = #szPassword
        if  len<6 then
            showToast(nil,"密码必须大于6个字符，请重新输入！",2)
            return
        end

        local tips = "绑定帐号后该游客信息将与新帐号合并，游客帐号将会被注销，绑定成功之后需要重新登录,是否绑定帐号?"
        QueryDialog:create(tips, function(ok)
            if ok == true then                
                
                showPopWait()

                self.szAccount = szAccount
                self.szPassword = szPassword
                self._modifyFrame:onAccountRegisterBinding(szAccount, szNickName, md5(szPassword), szSpreader)
            end
        end):addTo(self)
    end
end

------------------------------------------------------------------------------------------------------------
-- ModifyFrame 回调

function BindingLayer:onModifyCallBack(result, message)

    dismissPopWait()

    if type(message) == "string" and message ~= "" then
        showToast(nil, message, 2)
    end

	if result == 2 then

        showPopWait()

        GlobalUserItem.setBindingAccount()
        GlobalUserItem.szAccount = self.szAccount
        GlobalUserItem.szPassword = self.szPassword
        
        --保存数据
        GlobalUserItem.onSaveAccountConfig()

        self:runAction(cc.Sequence:create(cc.DelayTime:create(1.0), cc.CallFunc:create(function ()
            
            dismissPopWait()
                  
            --重新登录
            MyApp:getInstance():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene","FADE",1)

            GlobalUserItem.reSetData()
            --读取配置
            GlobalUserItem.LoadData()
        end)))
	end
end

return BindingLayer