--实卡支付页面
local CardPayLayer = class("CardPayLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")

local RequestManager = appdf.req(appdf.CLIENT_SRC.."plaza.models.RequestManager")

function CardPayLayer:ctor(amount, count)

    local csbNode = ExternalFun.loadCSB("Pay/CardPayLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --确定支付
    local btnOK = self._content:getChildByName("btn_ok")
    btnOK:addClickEventListener(function()

        self:onClickOK()
    end)

    --取消支付
    local btnCancel = self._content:getChildByName("btn_cancel")
    btnCancel:addClickEventListener(function()

        self:onClickCancel()
    end)

    --卡号
    local spEditCardBg = self._content:getChildByName("sp_edit_card_bg")
    local size = spEditCardBg:getContentSize()
    self._editCard = ccui.EditBox:create(cc.size(size.width - 16, size.height - 16), "")
		    :move(size.width / 2, size.height / 2)
            :setFontSize(30)
            :setFontColor(cc.WHITE)
		    :setFontName("fonts/round_body.ttf")
		    :setMaxLength(50)
            :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		    :addTo(spEditCardBg)

    --密码
    local spEditPasswordBg = self._content:getChildByName("sp_edit_password_bg")
    size = spEditPasswordBg:getContentSize()
    self._editPassword = ccui.EditBox:create(cc.size(size.width - 16, size.height - 16), "")
		    :move(size.width / 2, size.height / 2)
            :setFontSize(30)
            :setFontColor(cc.WHITE)
		    :setFontName("fonts/round_body.ttf")
		    :setMaxLength(50)
            :setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
		    :addTo(spEditPasswordBg)

    -- 内容跳入
    AnimationHelper.jumpIn(self._content, function()
        
        --编辑框在动画后有BUG，调整大小让编辑框可以显示文字
        self._editCard:setContentSize(self._editCard:getContentSize())
        self._editPassword:setContentSize(self._editPassword:getContentSize())
    end)
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

--确定支付
function CardPayLayer:onClickOK()

    --播放音效
    ExternalFun.playClickEffect()

    --检查参数
    local cardid = self._editCard:getText()
    local cardpwd = self._editPassword:getText()

    if cardid == "" then
        showToast(nil, "请输入充值卡号", 2)
        return
    end

    if cardpwd == "" then
        showToast(nil, "请输入充值卡密码", 2)
        return
    end

    --生成订单
    local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
	local action = "action=PayCard&gameid=" .. GlobalUserItem.dwGameID .. "&cardid=" .. cardid .. "&cardpwd=" .. cardpwd

    showPopWait()

    appdf.onHttpJsionTable(url,"GET",action,function(jstable,jsdata)
        
        --"{"code":0,"msg":"抱歉！您要充值的卡号不存在。如有疑问请联系客服中心。","data":{"valid":false}}"
        dismissPopWait()

    	if type(jstable) == "table" then
            
            if type(jstable["msg"]) == "string" and jstable["msg"] ~= "" then
                showToast(nil, jstable["msg"], 2)
            end

			local data = jstable["data"]
			if type(data) == "table" then
				if nil ~= data["valid"] and true == data["valid"] then

                    --充值成功, 刷新分数信息
                    RequestManager.requestUserScoreInfo(function(result, message)

                        if type(message) == "string" and message ~= "" then
                            showToast(nil,message,2)		
	                    end
                    end)

                    dismissPopupLayer(self)

                end
			end

            return
		end

        showToast(nil, "支付异常", 2)
    end)
end

--取消支付
function CardPayLayer:onClickCancel()

    --播放音效
    ExternalFun.playClickEffect()

    dismissPopupLayer(self)
end

return CardPayLayer