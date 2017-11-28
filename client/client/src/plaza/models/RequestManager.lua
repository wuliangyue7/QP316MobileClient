--请求管理器
local RequestManager = class("RequestManager")

local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

local function _callback(c, r, m)
    
    if c then
        c(r, m)
    end
end

--获取服务器地址
function RequestManager.requestServerAddress()

    --非正式环境，不使用动态IP
    if appdf.ENV ~= 3 then
        return
    end

    showPopWait()

    --防止重复调用
    if RequestManager._requestServerAddress == true then
        return
    end

    --修改状态
    RequestManager._requestServerAddress = true

    local url = yl.HTTP_URL .. "/WS/NativeWeb.ashx"
    --local url = "http://localhost:12569/WS/NativeWeb.ashx"
    local ostime = os.time()
    appdf.onHttpJsionTable(url ,"GET","action=queryserveraddress",function(jstable,jsdata)

        --修改状态
        RequestManager._requestServerAddress = nil

        dismissPopWait()

        if type(jsdata) == "string" and jsdata ~= "" then
            
            --jsdata = "127.0.0.1" --218.90.200.240 118.184.190.240 118.184.249.7
            --jsdata = "103.198.74.132"

            print("获取到服务器地址", jsdata)
            
            -- 设置第一个为获取到的地址
            yl.SERVER_LIST[1] = jsdata
            yl.CURRENT_INDEX = 1
            yl.LOGONSERVER = yl.SERVER_LIST[yl.CURRENT_INDEX]
        end
    end)
end

--获取抽奖奖品配置
function RequestManager.requestLotteryConfig(callback)

	local url = yl.HTTP_URL .. "/WS/Lottery.ashx"
 	appdf.onHttpJsionTable(url ,"GET","action=LotteryConfig",function(jstable,jsdata)
        
        if type(jstable) == "table" then
            local data = jstable["data"]
            if type(data) == "table" then
                local valid = data["valid"]
                if nil ~= valid and true == valid then
                    local list = data["list"]
                    if type(list) == "table" then
                        for i = 1, #list do
                            --配置转盘
                            local lottery = list[i]

                            GlobalUserItem.dwLotteryQuotas[i] = lottery.ItemQuota
                            GlobalUserItem.cbLotteryTypes[i] = lottery.ItemType
                        end

                        --抽奖已配置
                        GlobalUserItem.bLotteryConfiged = true

                        _callback(callback, 0)

                        return
                    end
                end
            end
        end

        _callback(callback, -1, "数据获取失败")
    end)
end

--获取用户分数信息
function RequestManager.requestUserScoreInfo(callback)

    local ostime = os.time()
	local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
 	appdf.onHttpJsionTable(url ,"GET","action=GetScoreInfo&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime),function(sjstable,sjsdata)
        
        if type(sjstable) == "table" then
            local data = sjstable["data"]
            if type(data) == "table" then
                local valid = data["valid"]
                if true == valid then
                    local score = tonumber(data["Score"]) or 0
                    local bean = tonumber(data["Currency"]) or 0
                    local ingot = tonumber(data["UserMedal"]) or 0
                    local roomcard = tonumber(data["RoomCard"]) or 0

                    local needupdate = false
                    if score ~= GlobalUserItem.lUserScore 
                    	or bean ~= GlobalUserItem.dUserBeans
                    	or ingot ~= GlobalUserItem.lUserIngot
                    	or roomcard ~= GlobalUserItem.lRoomCard then
                    	GlobalUserItem.dUserBeans = bean
                    	GlobalUserItem.lUserScore = score
                    	GlobalUserItem.lUserIngot = ingot
                    	GlobalUserItem.lRoomCard = roomcard
                        needupdate = true
                    end
                    if needupdate then
                        print("update score")
                        --通知更新        
                        local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
                        eventListener.obj = yl.RY_MSG_USERWEALTH
                        cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
                    end 

                    _callback(callback, 0)  
                    
                    return      
                end
            end
        end

        _callback(callback, -1, "数据获取失败")
    end)
end

--发送验证码
function RequestManager.sendSMSCode(mobile, callback)

--    m1=机器码&m2=手机号&m3=时间戳&m4=签名


--    1.m4=md5("m1=机器码&m2=手机号&m3=时间戳&m4=0")
--    2.m3=XorEncrypt("时间戳", m4)
--    3.m2=XorEncrypt("手机号", m3)
--    4.m1=XorEncrpyt("机器码", m2)

    local machineId = MultiPlatform:getInstance():getMachineId()
    local time = tostring(os.time())
    local param = "m1="..machineId.."&m2="..mobile.."&m3="..time.."&m4=6.7.0.1"
    local m4 = md5(param)
    local m3 = ExternalFun.urlSafeBase64(ExternalFun.xorEncrypt(time, m4))
    local m2 = ExternalFun.urlSafeBase64(ExternalFun.xorEncrypt(mobile, m3))
    local m1 = ExternalFun.urlSafeBase64(ExternalFun.xorEncrypt(machineId, m2))

    local encryptParam = "m1="..m1.."&m2="..m2.."&m3="..m3.."&m4="..m4
    
    --发送验证码
    appdf.onHttpJsionTable(yl.HTTP_URL .. "/WS/NativeWeb.ashx","GET","action=SendSMSCode&" .. encryptParam,function(jstable,jsdata)

        if jsdata == "0" then
            _callback(callback, 0, "验证码已发送")
        elseif type(jsdata) == "string" then
            _callback(callback, -1, jsdata)
        else
            _callback(callback, -1, "验证码发送失败")
        end
    end)

end

--获取绑定手机号
function RequestManager.getBindMobile(callback)

    local ostime = os.time()
	local url = yl.HTTP_URL .. "/WS/Account.ashx"
 	appdf.onHttpJsionTable(url ,"GET","action=GetBindMobile&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&signature=".. GlobalUserItem:getSignature(ostime),function(sjstable,sjsdata)
        
        if sjsdata == nil or #sjsdata ~= 11 then
            _callback(callback, -1)
        else
            GlobalUserItem.szBindMobile = sjsdata

            _callback(callback, 0) 
        end

    end)
end

--绑定手机号
function RequestManager.bindMobile(mobile, smscode, callback)

    local ostime = os.time()
	local url = yl.HTTP_URL .. "/WS/Account.ashx"
 	appdf.onHttpJsionTable(url ,"GET","action=BindMobile&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&mobile=" .. mobile .. "&smscode=" .. smscode .. "&signature=".. GlobalUserItem:getSignature(ostime),function(sjstable,sjsdata)
        
        if sjsdata == nil then
            _callback(callback, -1, "绑定失败，网络错误") 
        else
            _callback(callback, 0, sjsdata)
        end

    end)
end

--取消绑定手机号
function RequestManager.unBindMobile(mobile, smscode, callback)

    local ostime = os.time()
	local url = yl.HTTP_URL .. "/WS/Account.ashx"
 	appdf.onHttpJsionTable(url ,"GET","action=UnBindMobile&userid=" .. GlobalUserItem.dwUserID .. "&time=".. ostime .. "&mobile=" .. mobile .. "&smscode=" .. smscode .. "&signature=".. GlobalUserItem:getSignature(ostime),function(sjstable,sjsdata)
        
        if sjsdata == nil then
            _callback(callback, -1, "取消绑定失败，网络错误") 
        else
            _callback(callback, 0, sjsdata)
        end

    end)
end

return RequestManager