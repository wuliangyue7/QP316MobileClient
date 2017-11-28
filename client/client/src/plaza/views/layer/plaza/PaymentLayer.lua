--支付页面
local PaymentLayer = class("PaymentLayer", cc.Layer)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local AnimationHelper = appdf.req(appdf.EXTERNAL_SRC .. "AnimationHelper")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

function PaymentLayer:ctor(amount, count, appid, callback)

    --保存参数
    self._amount = amount
    self._count = count
    self._appid = appid
    self._callback = callback

    local csbNode = ExternalFun.loadCSB("Pay/PaymentLayer.csb"):addTo(self)
    self._content = csbNode:getChildByName("content")
    self._txtName = self._content:getChildByName("txt_name")
    self._txtAmount = self._content:getChildByName("txt_amount")

    --设置商品名称
    self._txtName:setString(count .. "游戏豆")
    --设置价格
    self._txtAmount:setString(amount .. "元")

    --关闭
    local btnClose = self._content:getChildByName("btn_close")
    btnClose:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        dismissPopupLayer(self)
    end)

    --微信
    local btnWechatpay = self._content:getChildByName("btn_wechatpay")
    btnWechatpay:addClickEventListener(function()
        
        --播放音效
        ExternalFun.playClickEffect()

        self:onThirdPartyPay(yl.ThirdParty.WECHAT)
    end)

    --支付宝
    local btnAlipay = self._content:getChildByName("btn_alipay")
    btnAlipay:addClickEventListener(function()

        --播放音效
        ExternalFun.playClickEffect()

        self:onThirdPartyPay(yl.ThirdParty.ALIPAY)
    end)

    --是否显示支付宝
    local bShowAlipay = (device.platform ~= "ios")
    btnAlipay:setVisible(bShowAlipay)

    if not bShowAlipay then
        local x, y = btnWechatpay:getPosition();
        btnWechatpay:setPosition(self._content:getContentSize().width / 2, y)
    end

    -- 内容跳入
    AnimationHelper.jumpIn(self._content)
end

------------------------------------------------------------------------------------------------------------
-- 事件处理

--第三方支付
function PaymentLayer:onThirdPartyPay(plat)

    local platNameEN = ""
    local platNameCN = ""
    if plat == yl.ThirdParty.WECHAT then
        platNameEN = "wx"
        platNameCN = "微信"
    elseif plat == yl.ThirdParty.ALIPAY then
        platNameEN = "zfb"
        platNameCN = "支付宝"
    else
        return
    end
    
    --判断应用是否安装
    if false == MultiPlatform:getInstance():isPlatformInstalled(plat) then
        showToast(nil, platNameCN .. "未安装, 无法进行" .. platNameCN .. "支付", 2)
        return
    end 

    --生成订单
    local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
	local action = "action=CreatPayOrderID&gameid=" .. GlobalUserItem.dwGameID .. "&amount=" .. self._amount .. "&paytype=" .. platNameEN .. "&appid=" .. self._appid

    showPopWait()

    appdf.onHttpJsionTable(url,"GET",action,function(jstable,jsdata)

        dismissPopWait()

    	if type(jstable) == "table" then
			local data = jstable["data"]
			if type(data) == "table" then
				if nil ~= data["valid"] and true == data["valid"] then
					local payparam = {}
					if plat == yl.ThirdParty.WECHAT then --微信支付
						--获取微信支付订单id
						local paypackage = data["PayPackage"]
						if type(paypackage) == "string" then
							local ok, paypackagetable = pcall(function()
					       		return cjson.decode(paypackage)
					    	end)
					    	if ok then
					    		local payid = paypackagetable["prepayid"]
					    		if nil == payid then
									showToast(nil, "微信支付订单获取异常", 2)
									return 
								end
								payparam["info"] = paypackagetable
					    	else
					    		showToast(nil, "微信支付订单获取异常", 2)
					    		return
					    	end
						end
                    end
					--订单id
					payparam["orderid"] = data["OrderID"]						
					--价格
					payparam["price"] = self._amount
					--商品名
					payparam["name"] = self._txtName:getString()

					local function payCallBack(param)

						if type(param) == "string" and "true" == param then
                            GlobalUserItem.setTodayPay()
                                
							showToast(nil, "支付成功", 2)

                            self._callback(0)

                            dismissPopupLayer(self)
						else
							showToast(nil, "支付失败", 2)
						end
					end
					MultiPlatform:getInstance():thirdPartyPay(plat, payparam, payCallBack)
				else
                    if type(jstable["msg"]) == "string" and jstable["msg"] ~= "" then
                        showToast(nil, jstable["msg"], 2)
                    end
                end
			end
		end
    end)
end

return PaymentLayer