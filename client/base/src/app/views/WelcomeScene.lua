--[[
	欢迎界面
			2015_12_03 C.P
	功能：本地版本记录读取，如无记录，则解压原始大厅及附带游戏
--]]

local WelcomeScene = class("WelcomeScene", cc.load("mvc").ViewBase)

local ClientUpdate = appdf.req(appdf.BASE_SRC .. "app.controllers.ClientUpdate")
local QueryDialog = appdf.req(appdf.BASE_SRC .. "app.views.layer.other.QueryDialog")
local ClientConfig = appdf.req(appdf.BASE_SRC .."app.models.ClientConfig")

if cc.FileUtils:getInstance():isFileExist(device.writablePath .. "client/src/plaza/models/yl.lua") or
    cc.FileUtils:getInstance():isFileExist(device.writablePath .. "client/src/plaza/models/yl.luac") then
    appdf.req(appdf.CLIENT_SRC .. "plaza.models.yl")
end

--全局toast函数(ios/android端调用)
cc.exports.g_NativeToast = function (msg)
	local runScene = cc.Director:getInstance():getRunningScene()
	if nil ~= runScene then
		showToastNoFade(runScene, msg, 2)
	end
end

--平台
local targetPlatform = cc.Application:getInstance():getTargetPlatform()

function WelcomeScene:onCreate()

    --初始化变量
    self._updateQueue = {}
    self._updateIndex = 1

    --背景
    cc.Sprite:create("base/res/background.jpg")
        :setPosition(appdf.WIDTH/2, appdf.HEIGHT/2)
        :addTo(self)

    --logo
    cc.Sprite:create("base/res/logo.png")
        :setPosition(185, 670)
        :setVisible(yl and not yl.APPSTORE_VERSION)
        :addTo(self)

    --animal
    cc.Sprite:create("base/res/animal.png")
        :setPosition(appdf.WIDTH / 2 + 45, appdf.HEIGHT / 2 + 15)
        :addTo(self)

    --提示文本
	self._txtTips = cc.Label:createWithTTF("", "fonts/round_body.ttf", 24)
		:setTextColor(cc.WHITE)
		:setAnchorPoint(cc.p(1,0))
		:enableOutline(cc.c4b(0,0,0,255), 1)
		:move(appdf.WIDTH,0)
		:addTo(self)

    --进度条
    self._loadingBg = cc.Sprite:create("base/res/loading_bg.png")
                        :setPosition(appdf.WIDTH / 2, 104)
                        :addTo(self)
    self._loadingBar = cc.Sprite:create("base/res/loading_bar.png")
                        :setAnchorPoint(0, 0)
                        :setPosition(0, 0)
    self._loadingLayout = ccui.Layout:create()
                            :setClippingEnabled(true)
                            :setContentSize(self._loadingBar:getContentSize())
                            :setAnchorPoint(cc.p(0, 0.5))
                            :setPosition((appdf.WIDTH - self._loadingBar:getContentSize().width) / 2, 110)
                            :addChild(self._loadingBar)
                            :addTo(self)
    self._txtProgress = cc.Label:createWithTTF("100%", "fonts/round_body.ttf", 24)
		                    :setTextColor(cc.WHITE)
		                    :enableOutline(cc.c4b(0,0,0,255), 1)
		                    :move(appdf.WIDTH / 2, 104)
		                    :addTo(self)

    --隐藏进度条
    self:showProgressBar(false)

    if isDebug() and cc.PLATFORM_OS_WINDOWS == targetPlatform then
        for k ,v in pairs(appdf.BASE_GAME) do
		    self:getApp()._version:setResVersion(v.version,v.kind)
        end
    end

    --无版本信息, 解压自带ZIP
    local nResversion = tonumber(self:getApp()._version:getResVersion())
	if nil == nResversion then
        --解压客户端
	 	self:unZipApp()        
	else
	    --获取服务器配置
	    self:requestServerConfig()
	end
end

function WelcomeScene:onExit()
    print("WelcomeScene onExit");
end

--解压客户端
function WelcomeScene:unZipApp()

    if cc.PLATFORM_OS_WINDOWS == targetPlatform then
        self:enterClient()
        return
    end

	if self._unZip == nil then --大厅解压
		-- 状态提示
		self._txtTips:setString("请稍候...")
		self._unZip = 0
		--解压
		local dst = device.writablePath
		unZipAsync(cc.FileUtils:getInstance():fullPathForFilename("client.zip"),dst,function(result)
				self:unZipApp()
			end)
	elseif self._unZip == 0 then --默认游戏解压
		self._unZip = 1
		--解压
		local dst = device.writablePath
		unZipAsync(cc.FileUtils:getInstance():fullPathForFilename("game.zip"),dst,function(result)
				self:unZipApp()
			end)
	else 			-- 解压完成
		self._unZip = nil
		--更新本地版本号
		self:getApp()._version:setResVersion(appdf.BASE_C_RESVERSION)
        --设置自带游戏版本号（苹果因为要审核，所以必须要自带游戏，这里设置自带游戏默认版本号）
        if targetPlatform == cc.PLATFORM_OS_IPHONE or targetPlatform == cc.PLATFORM_OS_IPAD then
		    for k ,v in pairs(appdf.BASE_GAME) do
			    self:getApp()._version:setResVersion(v.version,v.kind)
		    end
        end
		--self._txtTips:setString("解压完成！")

		--解压完了请求服务器配置
	    self:requestServerConfig()
	end
end

--更新客户端
function WelcomeScene:updateApp()

    QueryDialog:create("有新的版本，是否现在下载升级？",function(bConfirm)

	        if bConfirm == true then       
                         	
			    print("更新客户端")	
                
                if device.platform == "ios" then
                    cc.Application:getInstance():openURL(self._iosUpdateUrl)
                else    
                    cc.Application:getInstance():openURL(self._androidUpdateUrl)
                end
		    else
			    os.exit(0)
	        end					
	    end)
	    :addTo(self)
end

--更新资源
function WelcomeScene:updateRes()

    if #self._updateQueue == 0 then
        
        --进入客户端
        self:enterClient()
    else
        
        --下载当前项
        local config = self._updateQueue[self._updateIndex]
        self._update = ClientUpdate:create(config.newfileurl, config.dst, config.src, config.downurl)
		self._update:upDateClient(self)
    end
end

--显示进度条
function WelcomeScene:updateProgressBar(percent)
    
    if self._loadingBar:isVisible() == false then
        self:showProgressBar(true)
    end
    
    local contentSize = self._loadingBar:getContentSize()

    self._loadingLayout:setContentSize(contentSize.width * percent / 100, contentSize.height)
    self._txtProgress:setString(math.ceil(percent) .. "%")
end

--隐藏进度条
function WelcomeScene:showProgressBar(isShow)
    
    self._loadingBg:setVisible(isShow)
    self._loadingBar:setVisible(isShow)
    self._loadingLayout:setVisible(isShow)
    self._txtProgress:setVisible(isShow)
end

--进入客户端
function WelcomeScene:enterClient()

	--重置大厅与游戏
	for k ,v in pairs(package.loaded) do
		if k ~= nil then 
			if type(k) == "string" then
				if string.find(k,"plaza.") ~= nil or string.find(k,"game.") ~= nil then
					print("package kill:"..k) 
					package.loaded[k] = nil
				end
			end
		end
	end	

    --重置配置参数
    yl = nil

    --显示版本号
	self._txtTips:setString("v " .. appdf.BASE_C_VERSION .. "." .. (self:getApp()._version:getResVersion() or appdf.BASE_C_RESVERSION))

	--场景切换
    self:runAction(cc.Sequence:create(
			--cc.DelayTime:create(1),
			cc.CallFunc:create(function()
				self:getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene",nil,0)
			end)
	))	
end

--------------------------------------------------------------------------------------------------------------------
-- ClientUpdate 回调

--下载开始
function WelcomeScene:onUpdateBegin(count)
    
    if count == 0 then 
        return
    end

    local config = self._updateQueue[self._updateIndex]

    if config.isBase then

        --需要重启客户端s
        self._needRestart = true 
        --设置base更新状态
        cc.UserDefault:getInstance():setBoolForKey("baseupdate", true)
        --显示状态
        self._txtTips:setString("更新主程序资源...")

    elseif config.isClient then
        
        --显示状态
        self._txtTips:setString("更新大厅资源...")

    end
end

--下载进度
function WelcomeScene:onUpdateProgress(sub, msg, mainpersent)

    --更新进度条
    self:updateProgressBar(mainpersent)
end

--下载结果
function WelcomeScene:onUpdateResult(result,msg)

    if result == true then

        local config = self._updateQueue[self._updateIndex]
        if config.isBase then
            --设置base更新状态
            cc.UserDefault:getInstance():setBoolForKey("baseupdate", false)
        end

        --下载下一项
        if self._updateIndex < #self._updateQueue then

            self._updateIndex = self._updateIndex + 1
            self:updateRes()

        else --下载完成

            --隐藏进度条
            self:showProgressBar(false)

            --更新本地大厅版本
			self:getApp()._version:setResVersion(self._newResVersion)

            if self._needRestart then

                --重启客户端
                QueryDialog:create("本次更新需要重启才能生效，请重新启动客户端",function(bConfirm)
			        os.exit(0)				
	            end, nil, QueryDialog.QUERY_SURE)
	            :addTo(self)
            else

                --进入登录界面
                self:enterClient()
            end
        end
    else

    	--重试询问
		QueryDialog:create("("..self._update:getUpdateFileName()..")".. msg.."\n是否重试？",function(bReTry)
				if bReTry == true then
					self:updateRes()
				else
					os.exit(0)
				end
			end)
			:addTo(self)
    end
end

--------------------------------------------------------------------------------------------------------------------
-- 网路请求

--请求服务器配置
function WelcomeScene:requestServerConfig()

	self._txtTips:setString("获取服务器信息...")

	--数据解析
	local vcallback = function(datatable)
	 	local succeed = false
	 	local msg = "网络获取失败！"
	 	if type(datatable) == "table" then	 		
            local databuffer = datatable["data"]
            if databuffer then
                --返回结果
	 		    succeed = databuffer["valid"]
	 		    --提示文字
	 		    local tips = datatable["msg"]
	 		    if tips and tips ~= cjson.null then
	 			    msg = tips
	 		    end
	 		    --获取信息
	 		    if succeed == true then	 
	 		    	self:getApp()._serverConfig = databuffer		     
 				    --下载地址
 				    self:getApp()._updateUrl = databuffer["downloadurl"]								--test zhong "http://172.16.4.140/download/"
 				    --大厅版本
 				    self._newVersion = tonumber(databuffer["clientversion"])          						--test zhong  0
 				    --大厅资源版本
 				    self._newResVersion = tonumber(databuffer["resversion"])
 				    --苹果大厅更新地址
 				    self._iosUpdateUrl = databuffer["ios_url"]
                    --安卓大厅更新地址
                    self._androidUpdateUrl = databuffer["android_url"]

 				    local nNewV = self._newResVersion
					local nCurV = tonumber(self:getApp()._version:getResVersion())
					if nNewV and nCurV then
						if nNewV > nCurV then

                            --更新目录
                            local updatefolders = { "base", "client" }

                            for i = 1, #updatefolders do
                                
                                local folder = updatefolders[i]
                                local updateConfig = {}

                                updateConfig.isBase = (folder == "base")
					 		    updateConfig.isClient = (folder == "client")
					 		    updateConfig.newfileurl = self:getApp()._updateUrl.."/" .. folder .. "/res/filemd5List.json"
							    updateConfig.downurl = self:getApp()._updateUrl .. "/"

                                if cc.PLATFORM_OS_WINDOWS == targetPlatform then
                                    updateConfig.dst = device.writablePath .. "download/"
                                    updateConfig.src = device.writablePath .. "download/" .. folder .. "/res/filemd5List.json"
                                else
                                    updateConfig.dst = device.writablePath
							        updateConfig.src = device.writablePath .. folder .. "/res/filemd5List.json"
                                end

					 		    table.insert(self._updateQueue, updateConfig)
                            end
						end
					end		 

 				    --游戏列表
 				    local rows = databuffer["gamelist"]
 				    self:getApp()._gameList = {}
 				    for k,v in pairs(rows) do
 					    local gameinfo = {}
 					    gameinfo._KindID = v["KindID"]
                        gameinfo._GameName = v["KindName"]
 					    gameinfo._KindName = string.lower(v["ModuleName"]) .. "."
 					    gameinfo._Module = string.gsub(gameinfo._KindName, "[.]", "/")
 					    gameinfo._KindVersion = v["ClientVersion"]
 					    gameinfo._ServerResVersion = tonumber(v["ResVersion"])
 					    gameinfo._Type = gameinfo._Module
 					    --检查本地文件是否存在
 					    local path = device.writablePath .. "game/" .. gameinfo._Module
 					    gameinfo._Active = cc.FileUtils:getInstance():isDirectoryExist(path)
 					    local e = string.find(gameinfo._KindName, "[.]")
 					    if e then
 					    	gameinfo._Type = string.sub(gameinfo._KindName,1,e - 1)
 					    end
 					    -- 排序
 					    gameinfo._SortId = tonumber(v["SortID"]) or 0

 					    table.insert(self:getApp()._gameList, gameinfo)
 				    end

 				    table.sort( self:getApp()._gameList, function(a, b)
 				    	return a._SortId > b._SortId
 				    end)
	 		    end
            end	 		
	 	end

        
        if succeed then --成功

            --判断是否需要重新下载完整App
 	        if self._newVersion and self._newVersion > appdf.BASE_C_VERSION then
                --更新客户端
                self:updateApp()
            else
                --更新资源
                self:updateRes()
            end
        else            --失败

            --提示重试
            self._txtTips:setString("")
	        QueryDialog:create(msg.."\n是否重试？",function(bReTry)
			        if bReTry == true then
				        self:requestServerConfig()
			        else
				        os.exit(0)
			        end
		        end)
		        :addTo(self)
        end


	end

    local typeID = (device.platform == "ios" and 1 or 2) --1.ios 2.android
	appdf.onHttpJsionTable(appdf.HTTP_URL .. "/WS/MobileInterface.ashx","get","action=getgamelist&TypeID="..typeID,vcallback)
end

return WelcomeScene