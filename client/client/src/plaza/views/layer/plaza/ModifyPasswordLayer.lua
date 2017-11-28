--修改密码页面
local ModifyPasswordLayer = class("ModifyPasswordLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")

function ModifyPasswordLayer:ctor()

    --初始化变量
    self._btnTabs = {}
    self._editPwds = {}
    self._selectedTab = 1

    --网络处理
	self._modifyFrame = ModifyFrame:create(self, function(result,message)
        self:onModifyCallBack(result,message)
    end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Modify/ModifyPasswordLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")
    self._txtPromptOldPwd = self._content:getChildByName("txt_prompt_old_pwd")
    self._txtPromptNewPwd1 = self._content:getChildByName("txt_prompt_new_pwd_1")
    
    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --取消按钮
    local btnCancel = self._content:getChildByName("btn_cancel")
    btnCancel:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --确定按钮
    local btnOK = self._content:getChildByName("btn_ok")
    btnOK:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickOK()
    end) 

    --选项按钮
    for i = 1, 2 do

        local btnTab = self._content:getChildByName("btn_tab_" .. i)
        btnTab:addEventListener(function()
            self:onSelectTab(i)
        end)

        self._btnTabs[i] = btnTab
    end

    --输入框
    local editNames = { "sp_edit_old_pwd_bg", "sp_edit_new_pwd_bg_1", "sp_edit_new_pwd_bg_2" }
    for i = 1, 3 do

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
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

function ModifyPasswordLayer:onExit()

    --关闭连接
    if self._modifyFrame:isSocketServer() then
        self._modifyFrame:onCloseSocket()
    end
end

--清空编辑框
function ModifyPasswordLayer:onClearEditBoxs()

    for i = 1, #self._editPwds do
        self._editPwds[i]:setText("")
    end
end

--切换选项卡
function ModifyPasswordLayer:onSelectTab(index)

    --播放音效
    ExternalFun.playClickEffect()

    self._selectedTab = index

    --清空编辑框密码
    self:onClearEditBoxs()

    --设置选中状态
    for i = 1, #self._btnTabs do
        self._btnTabs[i]:setSelected(index == i)
    end

    if index == 1 then
        self._txtPromptOldPwd:setString("原登录密码：")
        self._txtPromptNewPwd1:setString("新登录密码：")
    else
        self._txtPromptOldPwd:setString("原银行密码：")
        self._txtPromptNewPwd1:setString("新银行密码：")
    end
end

--点击确定
function ModifyPasswordLayer:onClickOK()
    
    --游客、微信账号不能修改登录密码
    if self._selectedTab == 1 then
        if GlobalUserItem.bVisitor then
            showToast(nil, "游客账号不能修改登录密码！", 2)
            return
        end
        if GlobalUserItem.bWeChat then
            showToast(nil, "微信账号不能修改登录密码！", 2)
            return
        end
    end

    --校验参数
    local szOldPwd = self._editPwds[1]:getText()
    local szNewPwd = self._editPwds[2]:getText()
    local szNewPwd1 = self._editPwds[3]:getText()

    if szOldPwd == "" then
        showToast(nil, "请输入原始密码", 1)
        return
    end

    if szNewPwd == "" then
        showToast(nil, "请输入新密码", 1)
        return
    end

    if szNewPwd1 == "" then
        showToast(nil, "请再次输入新密码", 1)
        return
    end

    if szNewPwd ~= szNewPwd1 then
        showToast(nil, "两次输入的新密码不一致", 1)
        return
    end

    showPopWait()

    if self._selectedTab == 1 then      --修改登录密码
        self._modifyFrame:onModifyLogonPass(szOldPwd, szNewPwd)
    elseif self._selectedTab == 2 then  --修改银行密码
        self._modifyFrame:onModifyBankPass(szOldPwd, szNewPwd)
    end
end

--------------------------------------------------------------------------------------------------------------------
-- ModifyFrame 回调

--操作结果
function ModifyPasswordLayer:onModifyCallBack(result,message)

    dismissPopWait()

	if message ~= nil and message ~= "" then
		showToast(nil,message,2);
	end

    if result == 1 then
        --清空编辑框密码
        self:onClearEditBoxs()
    end
end

return ModifyPasswordLayer