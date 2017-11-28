--我的推荐人页面
local MySpreaderLayer = class("MySpreaderLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local ModifyFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.ModifyFrame")
local loginCMD = appdf.req(appdf.HEADER_SRC .. "CMD_LogonServer")

function MySpreaderLayer:ctor(info)

    --网络处理
	self._modifyFrame = ModifyFrame:create(self, function(result,message)
		self:onModifyCallBack(result,message)
	end)

    --节点事件
    ExternalFun.registerNodeEvent(self)

    local csbNode = ExternalFun.loadCSB("Spreader/MySpreaderLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --确定
    local btnOK = self._content:getChildByName("btn_ok")
    btnOK:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onClickOK()        
    end)

    --输入框
    local spEditBg = self._content:getChildByName("sp_edit_spreader_id")
    local sizeBg = spEditBg:getContentSize()
    self._editSpreaderId = ccui.EditBox:create(cc.size(sizeBg.width - 16, sizeBg.height - 16), "")
		:move(sizeBg.width / 2, sizeBg.height / 2)
        :setFontSize(30)
        :setFontColor(cc.WHITE)
		:setFontName("fonts/round_body.ttf")
		:setMaxLength(12)
        :setInputMode(cc.EDITBOX_INPUT_MODE_NUMERIC)
		:addTo(spEditBg)

    --判断是否已经有推荐人
    self._noSpreader = GlobalUserItem.szSpreaderAccount == nil or GlobalUserItem.szSpreaderAccount == ""
    self._editSpreaderId:setText(GlobalUserItem.szSpreaderAccount)
    self._editSpreaderId:setEnabled(self._noSpreader)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()

        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        self._editSpreaderId:setContentSize(self._editSpreaderId:getContentSize())
    end)

    --查询用户信息
    if self._noSpreader then
        self._modifyFrame:onQueryUserInfo()
    end
end

function MySpreaderLayer:onExit()
    
    --关闭网络
    if self._modifyFrame:isSocketServer() then
        self._modifyFrame:onCloseSocket()
    end
end

--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击确定
function MySpreaderLayer:onClickOK()

    if not self._noSpreader then
        showToast(nil, "推荐人已存在，不能重复设置！", 2)
        return
    end

    local txt = string.gsub(self._editSpreaderId:getText(), "[.]", "")
	if txt == "" then
		showToast(nil, "推广员ID不能为空!", 2)
		return
	end

	txt = tonumber(txt)
	if nil == txt then
		showToast(nil, "请输入合法的推广员ID!", 2)
		return
	end

    if txt == GlobalUserItem.dwGameID then
        showToast(nil, "推广员不能设置为自己", 2)
        return
    end

	showPopWait()
	self._modifyFrame:onBindSpreader(txt)
end

--------------------------------------------------------------------------------------------------------------------
-- ModifyFrame 回调

--操作结果
function MySpreaderLayer:onModifyCallBack(result,message)

	dismissPopWait()

	if  message ~= nil and message ~= "" then
		showToast(nil,message,2);
	end

	if -1 == result then
		return
	end

    if loginCMD.SUB_GP_USER_INDIVIDUAL == result then
        --更新推荐人信息
        self._noSpreader = GlobalUserItem.szSpreaderAccount == nil or GlobalUserItem.szSpreaderAccount == ""
        self._editSpreaderId:setText(GlobalUserItem.szSpreaderAccount)
        self._editSpreaderId:setEnabled(self._noSpreader)
	elseif self._modifyFrame.INPUT_SPREADER == result then

        --关闭窗口
        dismissPopupLayer(self)
	end	
end

return MySpreaderLayer