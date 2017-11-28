
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath("base/src/")
cc.FileUtils:getInstance():addSearchPath("base/res/")
cc.FileUtils:getInstance():addSearchPath("client/src/")
cc.FileUtils:getInstance():addSearchPath("client/res/")

require "config"
require "cocos.init"

local function main()
    
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
