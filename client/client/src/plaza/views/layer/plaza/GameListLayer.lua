-- 游戏列表
local GameListLayer = class("GameListLayer", ccui.ScrollView)

local ClientUpdate = appdf.req(appdf.BASE_SRC.."app.controllers.ClientUpdate")

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

function GameListLayer:ctor(scene)
	print("============= 游戏列表界面创建 =============")

    self._scene = scene

    self:setDirection(ccui.ScrollViewDir.horizontal)
    self:setScrollBarEnabled(false)
    self:setBounceEnabled(true)
end

--------------------------------------------------------------------------------------------------------------------
-- 功能方法

--更新游戏列表
function GameListLayer:updateGameList(gamelist)

    print("更新游戏列表")

    --保存游戏列表
    self._gameList = gamelist

    --清空子视图
    self:removeAllChildren()

    if #gamelist == 0 then
        return
    end

    for i = 1, #gamelist do
        
        --游戏图标
        local filestr
        if i == 1 then filestr = "GameList/game_"..gamelist[i].."_big.png"
        else filestr = "GameList/game_"..gamelist[i]..".png"
        end

        local p
        if i == 1 then
            p = cc.p(256, 256)
        else
            p = cc.p(256 + math.modf(i / 2) * 392, (i % 2 == 0) and 384 or 125)
        end

        --游戏图标按钮
        local btnGameIcon = ccui.Button:create(filestr, filestr, filestr)
        btnGameIcon:setPosition(p)
        btnGameIcon:setTag(gamelist[i]) --游戏KindID做为Tag
        btnGameIcon:addTo(self)
--        btnGameIcon:addTouchEventListener(function(ref, type)

--            --改变按钮点击颜色
--            if type == ccui.TouchEventType.began then
--                ref:setColor(cc.c3b(200, 200, 200))
--            elseif type == ccui.TouchEventType.ended or ccui.TouchEventType.canceled then
--                ref:setColor(cc.WHITE)
--            end
--        end)
        btnGameIcon:addClickEventListener(function()

            self:onClickGame(self._gameList[i])
        end)
    end

    --设置内容宽度
    local contentSize = self:getContentSize()
    local containerWidth = 256 + math.modf(#gamelist / 2) * 392 + 384 / 2 + 40
    local containerHeiget = contentSize.height
    if containerWidth < contentSize.width then
        containerWidth = contentSize.width
    end
    self:setInnerContainerSize(cc.size(containerWidth, containerHeiget))

    --滚动的到前面
    self:jumpToLeft()
end

--下载游戏
function GameListLayer:downloadGame(gameinfo)

    if self._updategame then
        showToast(nil, "正在更新 “" .. self._updategame._GameName .. "” 请稍后", 2)
        return
    end

    --保存更新的游戏
    self._updategame = gameinfo

    local app = self._scene:getApp()
    local updateUrl = app:getUpdateUrl()

    --下载地址
    local fileurl = updateUrl .. "/game/" .. string.sub(gameinfo._Module, 1, -2) .. ".zip"
    --文件名
    local pos = string.find(gameinfo._Module, "/")
    local savename = string.sub(gameinfo._Module, pos + 1, -2) .. ".zip"
    --保存路径
    local savepath = nil
    local unzippath = nil
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS == targetPlatform then
		savepath = device.writablePath .. "download/game/" .. gameinfo._Type .. "/"
        unzippath = device.writablePath .. "download/"
    else
        savepath = device.writablePath .. "game/" .. gameinfo._Type .. "/"
        unzippath = device.writablePath
	end

    print("savepath: " .. savepath)
    print("savename: " .. savename)
    print("unzippath: " .. unzippath)

    --下载游戏压缩包
    downFileAsync(fileurl, savename, savepath, function(main, sub)

        --对象已经被销毁
        if not appdf.isObject(self) then
            return
        end

		--下载回调
		if main == appdf.DOWN_PRO_INFO then --进度信息
			
            self:showGameProgress(gameinfo._KindID, sub)

		elseif main == appdf.DOWN_COMPELETED then --下载完毕

            local zipfile = savepath .. savename

            --解压
            unZipAsync(zipfile, unzippath, function(result)
				
                --删除压缩文件
                os.remove(zipfile)

                --清空正在更新的游戏状态
                self._updategame = nil

                self:hideGameProgress(gameinfo._KindID)

                if result == 1 then
                    --保存版本记录
                    app:getVersionMgr():setResVersion(gameinfo._ServerResVersion, gameinfo._KindID)

                    showToast(nil, "“" .. gameinfo._GameName .. "” 下载完毕", 2)

                    --播放音效
                    self:playFinishEffect()  
                else
                    showToast(nil, "“" .. gameinfo._GameName .. "” 解压失败", 2)
                end

			end)

		else

            --清空正在更新的游戏状态
            self._updategame = nil

            self:hideGameProgress(gameinfo._KindID)

            showToast(nil, "“" .. gameinfo._GameName .. "” 下载失败，错误码：" .. main .. ", " .. sub, 2)

		end
	end)
end

--更新游戏
function GameListLayer:updateGame(gameinfo)

    if self._updategame then
        showToast(nil, "正在更新 “" .. self._updategame._GameName .. "” 请稍后", 2)
        return
    end

    --保存更新的游戏
    self._updategame = gameinfo

    local app = self._scene:getApp()
    local updateUrl = app:getUpdateUrl()
    local newfileurl = updateUrl.."/game/"..gameinfo._Module.."/res/filemd5List.json"
    local src = nil
	local dst = nil
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS == targetPlatform then
		dst = device.writablePath .. "download/game/" .. gameinfo._Type .. "/"
        src = device.writablePath.."download/game/"..gameinfo._Module.."/res/filemd5List.json"
    else
        dst = device.writablePath .. "game/" .. gameinfo._Type .. "/"
        src = device.writablePath.."game/"..gameinfo._Module.."/res/filemd5List.json"
	end

	local downurl = updateUrl .. "/game/" .. gameinfo._Type .. "/"

	--创建更新
	self._update = ClientUpdate:create(newfileurl,dst,src,downurl)
	self._update:upDateClient(self)
end

--显示游戏进度
function GameListLayer:showGameProgress(wKindID, nPercent)

    --游戏图标
    local gameicon = self:getChildByTag(wKindID)
    if not gameicon then
        return
    end

    local contentSize = gameicon:getContentSize()

    --遮罩
    local mask = gameicon:getChildByTag(1)
    if mask == nil then

        mask = ccui.Layout:create()
                    :setClippingEnabled(true)
                    :setAnchorPoint(cc.p(0, 0))
                    :setPosition(0, 0)
                    :setTag(1)
                    :addTo(gameicon)

        gameicon:clone()
                    :setColor(cc.c3b(150, 150, 150))
                    :setAnchorPoint(cc.p(0, 0))
                    :setPosition(0, 0)
                    :addTo(mask)
    end

    mask:setContentSize(contentSize.width, contentSize.height * (100 - nPercent) / 100)

    --进度
    local progress = gameicon:getChildByTag(2)
    if progress == nil then
        progress = cc.Label:createWithTTF("0%", "fonts/round_body.ttf", 32)
                        :enableOutline(cc.c4b(0,0,0,255), 1)
                        :setPosition(contentSize.width / 2, contentSize.height / 2)
                        :setTag(2)
                        :addTo(gameicon)
    end

    if nPercent == 100 then 
        progress:setString("正在安装...")
    else
        progress:setString(nPercent .. "%")
    end
end

--隐藏游戏进度
function GameListLayer:hideGameProgress(wKindID)

    --游戏图标
    local gameicon = self:getChildByTag(wKindID)
    if not gameicon then
        return
    end

    gameicon:removeAllChildren()
end

--播放完成音效
function GameListLayer:playFinishEffect()
    --播放音效
    ExternalFun.playPlazaEffect("gameDownFinish.mp3")   
end
--------------------------------------------------------------------------------------------------------------------
-- 事件处理

--点击游戏
function GameListLayer:onClickGame(wKindID)

    print("点击游戏图标", wKindID)

    --播放按钮音效
    ExternalFun.playClickEffect()

    local app = self._scene:getApp()

    --判断游戏是否存在
    local gameinfo = app:getGameInfo(wKindID)
    if not gameinfo then 
        showToast(nil, "亲，人家还没准备好呢！", 2)
        return
    end

    local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
    if version == nil then --下载游戏

        self:downloadGame(gameinfo)

    elseif gameinfo._ServerResVersion > version then --更新游戏

        self:updateGame(gameinfo)

    else
        --判断是否开放房间
        if GlobalUserItem.getRoomCount(wKindID) == 0 then
            showToast(nil, "抱歉，游戏房间暂未开放，请稍后再试！", 2)
            return
        end

        --通知进入游戏类型
        if self._scene and self._scene.onClickGame then
            self._scene:onClickGame(wKindID)
        end
    end
end

--------------------------------------------------------------------------------------------------------------------
-- ClientUpdate 回调

--更新进度
function GameListLayer:onUpdateProgress(sub, msg, mainpersent)
    
    if self._updategame then
        self:showGameProgress(self._updategame._KindID, math.ceil(mainpersent))
    end
end

--更新结果
function GameListLayer:onUpdateResult(result,msg)

    self:hideGameProgress(self._updategame._KindID)

    if result == true then
        msg = "“" .. self._updategame._GameName .. "” 更新完毕"

        --保存版本记录
        self._scene:getApp():getVersionMgr():setResVersion(self._updategame._ServerResVersion, self._updategame._KindID)

        --播放音效
        self:playFinishEffect()  
    else
        msg = "“" .. self._updategame._GameName .. "” " .. msg
    end

    --清空正在更新的游戏状态
    self._updategame = nil
    self._update = nil

    showToast(nil, msg, 2)
end

return GameListLayer