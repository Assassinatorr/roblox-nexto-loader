-- Rugpull ML 0.1.0: original open source for an owned Roblox simulation.
-- Runs an online LinUCB learner; no pretrained policy or external model service.
local __modules={}

__modules["Learner"]=(function()
-- Disjoint LinUCB: ridge regression with an uncertainty bonus per campaign.
-- Starts untrained and updates only from confirmed completed game rounds.
local Learner={Dimension=8,Arms=12,Schema=1}
Learner.__index=Learner
local D=8
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<1e100 end
local function identity()
	local m=table.create(D*D,0)
	for i=1,D do m[(i-1)*D+i]=1 end
	return m
end
local function inverseSPD(a)
	assert(type(a)=="table" and #a==D*D,"Invalid saved covariance size")
	local l=table.create(D*D,0)
	for i=1,D do for j=1,D do
		local v=a[(i-1)*D+j]
		assert(finite(v) and math.abs(v-a[(j-1)*D+i])<1e-6,"Invalid saved covariance")
	end end
	for i=1,D do for j=1,i do
		local sum=a[(i-1)*D+j]
		for k=1,j-1 do sum-=l[(i-1)*D+k]*l[(j-1)*D+k] end
		if i==j then assert(sum>1e-10,"Saved covariance is not positive definite");l[(i-1)*D+j]=math.sqrt(sum)
		else l[(i-1)*D+j]=sum/l[(j-1)*D+j] end
	end end
	local inv=table.create(D*D,0)
	for col=1,D do
		local y,x=table.create(D,0),table.create(D,0)
		for i=1,D do
			local sum=if i==col then 1 else 0
			for k=1,i-1 do sum-=l[(i-1)*D+k]*y[k] end
			y[i]=sum/l[(i-1)*D+i]
		end
		for i=D,1,-1 do
			local sum=y[i]
			for k=i+1,D do sum-=l[(k-1)*D+i]*x[k] end
			x[i]=sum/l[(i-1)*D+i]
		end
		for i=1,D do inv[(i-1)*D+col]=x[i] end
	end
	return inv
end
local function features(x)
	assert(type(x)=="table" and #x==D,"Expected eight campaign features")
	for _,v in x do assert(finite(v) and math.abs(v)<=2,"Invalid campaign feature")end
end
local function mul(a,x)
	local out=table.create(D,0)
	for i=1,D do for j=1,D do out[i]+=a[(i-1)*D+j]*x[j] end end
	return out
end
local function dot(a,b)local s=0;for i=1,D do s+=a[i]*b[i]end;return s end

function Learner.new(saved,alpha)
	local self=setmetatable({arms={},rounds=0,alpha=alpha or 0.6},Learner)
	assert(finite(self.alpha) and self.alpha>=0 and self.alpha<=5,"Invalid exploration setting")
	if saved then
		assert(saved.schema==1 and saved.dimension==D and type(saved.arms)=="table" and #saved.arms==Learner.Arms,"Incompatible saved model")
	end
	for i=1,Learner.Arms do
		local item=saved and saved.arms[i]
		local a=item and table.clone(item.a) or identity()
		local b=item and table.clone(item.b) or table.create(D,0)
		local n=item and item.n or 0
		assert(#b==D and finite(n) and n>=0 and n%1==0 and n<1e9,"Invalid saved learning count")
		for _,v in b do assert(finite(v),"Invalid saved reward vector")end
		self.arms[i]={a=a,b=b,inv=inverseSPD(a),n=n,total=item and item.total or 0}
		assert(finite(self.arms[i].total),"Invalid saved rewards")
		self.rounds+=n
	end
	return self
end
function Learner:choose(x,serial)
	features(x)
	local best,bestScore,bestMean=nil,-math.huge,0
	local offset=(serial or 0)%Learner.Arms
	for step=1,Learner.Arms do
		local i=(step+offset-1)%Learner.Arms+1
		local item=self.arms[i]
		local ix=mul(item.inv,x)
		local mean=dot(ix,item.b)
		local score=mean+self.alpha*math.sqrt(math.max(0,dot(x,ix)))
		if score>bestScore+1e-10 then best,bestScore,bestMean=i,score,mean end
	end
	return best,bestMean,bestScore
end
function Learner:update(arm,x,reward)
	features(x)
	assert(type(arm)=="number" and arm%1==0 and self.arms[arm],"Unknown campaign arm")
	assert(finite(reward) and math.abs(reward)<=1,"Invalid observed reward")
	local item=self.arms[arm]
	local ix=mul(item.inv,x)
	local denominator=1+dot(x,ix)
	assert(denominator>0,"Invalid model update")
	for i=1,D do
		item.b[i]+=reward*x[i]
		for j=1,D do
			local k=(i-1)*D+j
			item.a[k]+=x[i]*x[j]
			item.inv[k]-=ix[i]*ix[j]/denominator
		end
	end
	item.n+=1;item.total+=reward;self.rounds+=1
end
function Learner:export()
	local out={schema=1,dimension=D,arms={}}
	for i,item in self.arms do out.arms[i]={a=table.clone(item.a),b=table.clone(item.b),n=item.n,total=item.total}end
	return out
end
return Learner

end)()

__modules["Art"]=(function()
-- Original procedural pixel art. 16x16 designs are doubled to a 32x32 RGBA logo.
local Art={}
Art.Themes={
	{name="Cat",category="Animals",icon="🐱",code="CT"},
	{name="Rocket",category="Space",icon="🚀",code="RK"},
	{name="Robot",category="Robots",icon="🤖",code="RB"},
	{name="Donut",category="Food",icon="🍩",code="DN"},
	{name="Ghost",category="Fantasy",icon="🔮",code="GH"},
	{name="Alien",category="Gaming",icon="👾",code="AX"},
}
local palettes={
	{{17,25,43},{121,92,246},{54,211,206},{247,231,139}},
	{{24,30,42},{71,177,248},{241,110,175},{246,246,230}},
	{{33,23,39},{242,107,149},{255,193,87},{244,236,211}},
	{{15,35,35},{82,210,142},{241,200,80},{234,249,224}},
	{{33,28,45},{245,158,65},{170,136,240},{255,243,220}},
	{{17,29,43},{72,213,218},{249,131,97},{246,245,216}},
}
local adjectives={"Neon","Cosmic","Retro","Tiny","Turbo","Lucky","Velvet","Solar","Mint","Nova","Pixel","Amber"}
local function random(seed)
	local state=math.floor(seed)%2147483647
	if state<=0 then state+=2147483646 end
	return function(n)state=(state*48271)%2147483647;return 1+state%n end
end
local function base36(value,width)
	local digits="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local result=""
	for _=1,width do local n=value%36;result=digits:sub(n+1,n+1)..result;value=math.floor(value/36)end
	return result
end
function Art.draft(arm,serial,seed)
	local shape=1+(arm-1)%6
	local theme=Art.Themes[shape]
	local rng=random(seed+serial*7919)
	local palette=rng(#palettes)
	return {serial=serial,seed=seed+serial*7919,shape=shape,palette=palette,
		name=adjectives[rng(#adjectives)].." "..theme.name.." "..base36(serial,3),
		ticker=theme.code..base36(serial,3)..base36(rng(46656)-1,3),category=theme.category,icon=theme.icon,
		description="Original "..theme.name:lower().." pixel art for the in-game market."}
end
local function inside(shape,x,y)
	if shape==1 then
		return (x>=4 and x<=11 and y>=5 and y<=11) or (y>=2 and y<=5 and ((x>=3 and x<=3+y-1) or (x<=12 and x>=12-y+1)))
			or (x>=6 and x<=9 and y>=11 and y<=14)
	elseif shape==2 then
		return (y>=2 and y<=11 and math.abs(x-7.5)<=math.min(3.5,(y-1)*0.7))
			or (y>=9 and y<=12 and ((x>=2 and x<=4) or (x>=11 and x<=13))) or (y>=12 and y<=14 and x>=6 and x<=9)
	elseif shape==3 then
		return (x>=3 and x<=12 and y>=4 and y<=11) or (x>=7 and x<=8 and y>=1 and y<=3)
			or (x>=5 and x<=10 and y>=12 and y<=14)
	elseif shape==4 then
		local d=(x-7.5)^2+(y-7.5)^2
		return d<=36 and d>=7
	elseif shape==5 then
		return ((x-7.5)^2+(y-6)^2<=27 and y<=8) or (x>=3 and x<=12 and y>=6 and y<=12)
			or (y==13 and (x==3 or x==4 or x==7 or x==8 or x==11 or x==12))
	else
		return (y>=5 and y<=10 and x>=3 and x<=12) or (y==4 and x>=5 and x<=10)
			or ((y==2 or y==3) and (x==4 or x==11)) or (y==11 and x>=4 and x<=11)
			or ((y==12 or y==13) and (x==3 or x==5 or x==10 or x==12))
	end
end
function Art.draw(draft)
	assert(type(draft)=="table" and type(draft.shape)=="number" and draft.shape>=1 and draft.shape<=6 and draft.shape%1==0,"Invalid artwork theme")
	local palette=assert(palettes[draft.palette],"Invalid artwork palette")
	local seed=math.floor(draft.seed or 1)
	local rgba=buffer.create(4096)
	local cells={}
	for y=0,15 do for x=0,15 do
		local fill=inside(draft.shape,x,y)
		local outline=not fill and (inside(draft.shape,x-1,y) or inside(draft.shape,x+1,y) or inside(draft.shape,x,y-1) or inside(draft.shape,x,y+1))
		local color=palette[1]
		if fill then
			color=if (x+y+seed)%7==0 then palette[3] else palette[2]
			if draft.shape==4 then color=if y<8 then palette[2] else palette[3] end
			if draft.shape==2 and y>=12 then color=palette[4] end
			if draft.shape==2 and (x-7.5)^2+(y-6)^2<=3 then color=palette[3] end
			if draft.shape~=2 and draft.shape~=4 then
				if (y==6 or y==7) and (x==5 or x==10) then color=palette[4] end
				if y==9 and x>=6 and x<=9 then color=palette[3] end
			end
		elseif outline then color={7,11,20}
		elseif (x*3+y*5+seed)%19==0 then color={palette[1][1]+12,palette[1][2]+12,palette[1][3]+12} end
		cells[y*16+x+1]=color
		for dy=0,1 do for dx=0,1 do
			local offset=((y*2+dy)*32+x*2+dx)*4
			buffer.writeu8(rgba,offset,color[1]);buffer.writeu8(rgba,offset+1,color[2]);buffer.writeu8(rgba,offset+2,color[3]);buffer.writeu8(rgba,offset+3,255)
		end end
	end end
	return rgba,cells
end
function Art.payload(draft,network)
	local logo=Art.draw(draft)
	return {Name=draft.name,Ticker=draft.ticker,Description=draft.description,Category=draft.category,
		Icon=draft.icon,ColorIndex=draft.palette,Network=network,Logo=logo}
end
function Art.signature(rgba)
	local value=5381
	for i=0,buffer.len(rgba)-1 do value=bit32.bxor((value*33)%4294967296,buffer.readu8(rgba,i))end
	return string.format("%08x",value)
end
function Art.message(draft,index,chat)
	local ticker="$"..draft.ticker
	local lines=if chat then {
		"Fresh pixel art on "..ticker.." - "..draft.name.." is live in the game.",
		"Trying a new "..Art.Themes[draft.shape].name:lower().." palette with "..ticker..". Which colour works best?",
		"Pixel-art update: "..ticker.." is on the in-game market. Loving the neon colours.",
	} else {
		draft.name.." "..ticker.." just launched with original pixel art. A fresh look for the in-game market.",
		"A closer look at "..ticker..": "..Art.Themes[draft.shape].name:lower().." pixels, a bright palette and a new chart to watch.",
		"Building a little pixel collection with "..ticker..". What should the next artwork be?",
		"New art, same "..ticker..". Find "..draft.name.." on the in-game market and check the latest chart.",
	}
	return lines[1+(index-1)%#lines]
end
return Art

end)()

__modules["Storage"]=(function()
-- Executor workspace files. JSON is data, never executable policy source.
local Storage={}
Storage.__index=Storage
local function relative(path)
	assert(type(path)=="string" and #path>0 and #path<180,"Invalid workspace path")
	path=path:gsub("\\","/"):gsub("/+$","")
	assert(#path>0 and not path:match("^/") and not path:find(":",1,true) and not path:find("%c"),"Use a workspace-relative path")
	for part in path:gmatch("[^/]+")do assert(part~="." and part~="..","A path cannot leave the executor workspace")end
	return path
end
function Storage.new(config,environment,http,userId)
	local native=getfenv()
	local supplied=config.FileIO or {}
	local io={}
	for _,name in {"readfile","writefile","makefolder","isfolder","isfile"}do io[name]=supplied[name] or environment[name] or native[name]end
	assert(type(io.readfile)=="function" and type(io.writefile)=="function" and type(io.makefolder)=="function",
		"This script needs the host's readfile, writefile and makefolder APIs. Set RugpullMLConfig.FileIO if rewired.")
	local folder=relative(config.CacheFolder or "rugpull-ml")
	local current=""
	for part in folder:gmatch("[^/]+")do
		current=if current=="" then part else current.."/"..part
		if not (io.isfolder and io.isfolder(current)) then
			local ok,reason=pcall(io.makefolder,current)
			assert(ok or (io.isfolder and io.isfolder(current)),reason)
		end
	end
	local name=relative(config.StateFile or ("learning-"..tostring(userId)..".json"))
	return setmetatable({io=io,http=http,path=folder.."/"..name,lastGood=nil},Storage)
end
function Storage:_read(path)
	if self.io.isfile and not self.io.isfile(path) then return nil end
	local ok,data=pcall(self.io.readfile,path)
	if ok and type(data)=="string"then return data end
	return nil
end
function Storage:load(validate)
	local found=false
	for _,suffix in {"",".bak"}do
		local data=self:_read(self.path..suffix)
		if data then
			found=true
			local ok,value=pcall(function()
				assert(#data<524288,"Saved learning file is too large")
				local decoded=self.http:JSONDecode(data)
				validate(decoded)
				return decoded
			end)
			if ok then self.lastGood=data;return value,if suffix==".bak" then "Recovered backup" else "Loaded saved learning" end
		end
	end
	assert(not found,"Saved state is invalid; the files were preserved. Restore a backup or select a new StateFile.")
	return nil,"New learner · no completed rounds"
end
function Storage:save(value)
	local data=self.http:JSONEncode(value)
	assert(#data<524288,"Learning state exceeds its file limit")
	self.io.writefile(self.path..".tmp",data)
	assert(self:_read(self.path..".tmp")==data,"Learning checkpoint write/read-back failed")
	if self.lastGood then self.io.writefile(self.path..".bak",self.lastGood)end
	self.io.writefile(self.path,data)
	assert(self:_read(self.path)==data,"Learning state write/read-back failed")
	self.lastGood=data
	return true
end
Storage.relative=relative
return Storage

end)()

__modules["Adapter"]=(function()
-- Normal client interfaces inspected in the user's open Rugpull Simulator place.
-- No admin, purchase, trade, transfer or integrity interfaces are called.
local Adapter={PlaceId=138310989671326}
Adapter.__index=Adapter
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<1e100 end
function Adapter.new(player,services)
	return setmetatable({player=player,services=services,modules=nil},Adapter)
end
function Adapter:connect()
	if self.modules then return true end
	local scripts=self.player:FindFirstChild("PlayerScripts")
	local controllers=scripts and scripts:FindFirstChild("Controllers")
	local shared=self.services.storage:FindFirstChild("Shared")
	if not controllers or not shared then return false,"Waiting for Controllers and Shared. Finish loading the game." end
	local result={}
	for name,parent in {AccountController=controllers,MarketController=controllers,SocialController=controllers,
		Config=shared,Net=shared,Networks=shared,CoinCatalog=shared}do
		local module=parent:FindFirstChild(name)
		if not module or not module:IsA("ModuleScript")then return false,"Waiting for the game's "..name end
		local ok,value=pcall(self.services.require,module)
		if not ok then return false,"Could not read "..name..": "..tostring(value) end
		result[name]=value
	end
	if type(result.Config)~="table" or result.Config.GameName~="Rugpull Simulator"
		or type(result.AccountController.CreateCoin)~="function" or type(result.SocialController.CreatePost)~="function"
		or type(result.MarketController.coins)~="table" then return false,"This place needs a different game adapter" end
	self.modules=result
	return true
end
function Adapter:snapshot()
	local ok,reason=self:connect()
	if not ok then return nil,reason end
	local m=self.modules
	local account=m.AccountController.account
	if type(account)~="table" or account.id==nil or not finite(account.balance)then return nil,"Waiting for the game's account update" end
	local now=self.services.now()
	local pro=account.passes and account.passes.CreatorPro==true
	local network=m.Networks.get(m.Networks.Default)
	local owned,live,total,heat,change,volume,holders=0,0,0,0,0,0,0
	for _,coin in m.MarketController.coins do
		if type(coin)=="table" and coin.phase~="Rugged"then
			total+=1
			if tostring(coin.creatorId)==tostring(account.id)then owned+=1 end
			if finite(coin.heat)then heat+=coin.heat end
			if finite(coin.change5m)then change+=coin.change5m end
			if finite(coin.volume)then volume+=math.max(0,coin.volume) end
			if finite(coin.holders)then holders+=math.max(0,coin.holders) end
		end
		live+=1
	end
	local divisor=math.max(1,total)
	return {now=now,account=account,coins=m.MarketController.coins,network=m.Networks.Default,
		cost=if pro then 0 else network.LaunchCost,cooldown=if pro then m.Config.Economy.ProCreatorCooldown else m.Config.Economy.CoinCreationCooldown,
		minAge=m.Config.Rug.MinCoinAge,postCooldown=m.Config.Social.PostCooldown,chatCooldown=m.Config.Chat.SendCooldown,
		postMax=m.Config.Social.PostMaxLength,chatMax=m.Config.Chat.MessageMaxLength,rugEnabled=m.Config.Rug.Enabled,
		owned=owned,total=live,features={1,math.min(1,math.log(1+math.max(0,account.balance))/math.log(10000001)),
			math.min(1,owned/6),math.min(1,total/150),math.tanh(heat/divisor/10),math.tanh(change/divisor),
			math.min(1,math.log(1+volume/divisor)/math.log(10000001)),math.min(1,math.log(1+holders/divisor)/math.log(10001))}}
end
function Adapter:create(payload)
	local m=assert(self.modules)
	local category=m.CoinCatalog.ById[payload.Category]
	assert(category and table.find(category.Icons,payload.Icon),"Draft category/icon is unavailable in this version")
	assert(typeof(payload.Logo)=="buffer" and buffer.len(payload.Logo)==4096,"A coin logo must be a 32x32 RGBA buffer")
	assert(#payload.Name>=m.Config.Coin.NameMin and #payload.Name<=m.Config.Coin.NameMax,"Draft name exceeds game limits")
	assert(#payload.Ticker>=m.Config.Coin.TickerMin and #payload.Ticker<=m.Config.Coin.TickerMax and payload.Ticker:match("^[A-Z0-9]+$"),"Invalid draft ticker")
	return m.AccountController:CreateCoin(payload)
end
function Adapter:post(text)
	return self.modules.SocialController:CreatePost(text)
end
function Adapter:chat(text)
	local channels=self.services.chat:FindFirstChild("TextChannels")
	local general=channels and channels:FindFirstChild("RBXGeneral")
	if not general then return {ok=false,error="Chat is unavailable for this client"} end
	local message=general:SendAsync(text)
	if not message or message.Status~=Enum.TextChatMessageStatus.Success then
		return {ok=false,error="Chat was not accepted: "..tostring(message and message.Status)}
	end
	-- Same game-local relay used by ChatPanel, after the moderated channel succeeds.
	self.modules.Net.event("ChatRelay"):FireServer(text)
	return {ok=true}
end
function Adapter:rugInfo(id)
	return self.modules.Net.func("GetRugInfo"):InvokeServer(id)
end
function Adapter:rug(id,ticker)
	return self.modules.Net.func("RequestRug"):InvokeServer(id,ticker)
end
return Adapter

end)()

__modules["Engine"]=(function()
-- Workflow constraints and a learned campaign selector are intentionally explicit.
local Learner=if script then __modules["Learner"]else __modules["Learner"]
local Art=if script then __modules["Art"]else __modules["Art"]
local Engine={Schema=1,PlaceId=138310989671326}
Engine.__index=Engine
local function finite(v)return type(v)=="number" and v==v and math.abs(v)<1e100 end
local function integer(v,maximum)return finite(v) and v>=0 and v%1==0 and v<=(maximum or 1e9)end
local function validDraft(d)
	assert(type(d)=="table" and integer(d.serial) and integer(d.seed,1e15),"Invalid saved draft")
	assert(type(d.name)=="string" and #d.name>=2 and #d.name<=24,"Invalid saved name")
	assert(type(d.ticker)=="string" and #d.ticker>=2 and #d.ticker<=8 and d.ticker:match("^[A-Z0-9]+$"),"Invalid saved ticker")
	assert(integer(d.shape,6) and d.shape>=1 and integer(d.palette,6) and d.palette>=1,"Invalid saved art")
	local theme=Art.Themes[d.shape]
	assert(d.category==theme.category and d.icon==theme.icon and type(d.description)=="string" and #d.description<=200,"Invalid saved coin metadata")
end
function Engine.validate(saved,userId)
	assert(type(saved)=="table" and saved.schema==1 and saved.userId==userId and saved.placeId==Engine.PlaceId,"Saved state belongs to a different profile/account")
	Learner.new(saved.model)
	local s=saved.state
	assert(type(s)=="table" and integer(s.serial) and finite(s.nextLaunchAt) and s.nextLaunchAt>=0,"Invalid saved workflow")
	assert(type(s.history)=="table" and #s.history<=30 and type(s.artHistory)=="table" and #s.artHistory<=64,"Invalid saved history")
	assert(type(s.stats)=="table","Invalid saved statistics")
	assert(s.settings==nil or (type(s.settings)=="table" and type(s.settings.posts)=="boolean" and type(s.settings.chat)=="boolean"),"Invalid saved settings")
	for _,key in {"launches","posts","chats","completed"}do assert(integer(s.stats[key]),"Invalid saved count")end
	if s.round then
		local r=s.round
		validDraft(r.draft)
		assert(integer(r.arm,12) and r.arm>=1 and type(r.features)=="table" and #r.features==8,"Invalid saved campaign")
		for _,v in r.features do assert(finite(v) and math.abs(v)<=2,"Invalid saved features")end
		assert(finite(r.cost) and r.cost>=0 and finite(r.startedAt) and finite(r.nextPostAt) and finite(r.nextChatAt) and finite(r.nextInfoAt),"Invalid saved campaign timing")
		assert(integer(r.posts,20) and integer(r.chats,20),"Invalid saved message counts")
		assert(r.coinId==nil or (type(r.coinId)=="string" and #r.coinId<=128),"Invalid saved coin ID")
	end
	if s.pending then
		assert(s.round and (s.pending.kind=="create" or s.pending.kind=="rug") and finite(s.pending.at),"Invalid saved pending request")
	end
	return true
end
function Engine.new(options)
	local c=options.config or {}
	local self=setmetatable({adapter=options.adapter,save=options.save,userId=options.userId,config=c,
		enabled=false,stopped=false,code="PAUSED",detail="Ready to preview the next campaign.",lastError=nil,
		learner=Learner.new(options.saved and options.saved.model,c.Exploration),snapshot=nil,previewDraft=nil},Engine)
	self.state=if options.saved then options.saved.state else {serial=0,nextLaunchAt=0,history={},artHistory={},stats={launches=0,posts=0,chats=0,completed=0}}
	if options.saved then Engine.validate(options.saved,options.userId)end
	local settings=self.state.settings or {posts=true,chat=true}
	self.config.PostsEnabled=if c.PostsEnabled==nil then settings.posts else c.PostsEnabled~=false
	self.config.ChatEnabled=if c.ChatEnabled==nil then settings.chat else c.ChatEnabled~=false
	for key,default in {ReserveBalance=1000,PostEvery=35,ChatEvery=45,MaxPostsPerCoin=4,MaxChatsPerCoin=3,InfoEvery=10}do
		if c[key]==nil then c[key]=default end
		assert(finite(c[key]) and c[key]>=0 and c[key]<=1e9,"Invalid configuration: "..key)
	end
	assert(c.MaxPostsPerCoin%1==0 and c.MaxPostsPerCoin<=20 and c.MaxChatsPerCoin%1==0 and c.MaxChatsPerCoin<=20,"Message limits must be integers up to 20")
	return self
end
function Engine:export()
	self.state.settings={posts=self.config.PostsEnabled,chat=self.config.ChatEnabled}
	return {schema=1,placeId=Engine.PlaceId,userId=self.userId,model=self.learner:export(),state=self.state}
end
function Engine:persist()self.save(self:export())end
function Engine:status(code,detail)self.code,self.detail=code,detail end
function Engine:pause(reason)
	self.enabled=false
	self:status("PAUSED",reason or "Paused. The current campaign is saved for resuming.")
end
function Engine:setEnabled(value)
	assert(not self.stopped,"This instance is unloaded")
	self.enabled=value==true
	if not self.enabled then self:pause()end
end
function Engine:refresh()
	local s,reason=self.adapter:snapshot()
	self.snapshot=s
	if not s then self:status("CONNECTING",reason);return nil end
	return s
end
function Engine:preview(s)
	if self.state.round then return self.state.round.draft,self.state.round.arm end
	if self.previewDraft then return self.previewDraft.draft,self.previewDraft.arm end
	s=s or self.snapshot
	if not s then return nil end
	local serial=self.state.serial+1
	local arm=self.learner:choose(s.features,serial)
	local seed=math.floor(s.now)+self.userId%2147483647
	local draft=Art.draft(arm,serial,seed)
	self.previewDraft={draft=draft,arm=arm}
	return draft,arm
end
local function owns(coin,s)return coin and tostring(coin.creatorId)==tostring(s.account.id)end
local function transportFailure(result)
	if type(result)~="table" or type(result.ok)~="boolean"then return true end
	local text=type(result.error)=="string" and result.error:lower() or ""
	return text:find("reach the server",1,true)~=nil or text:find("transport",1,true)~=nil
end
function Engine:_attach(id,s)
	local r=self.state.round
	self.rugInfo=nil
	r.coinId=tostring(id);r.startedAt=s.now;r.nextPostAt=s.now;r.nextChatAt=s.now+12;r.nextInfoAt=s.now+s.minAge+2
	self.state.pending=nil
	self.state.stats.launches+=1
	local signature=r.artSignature or Art.signature(Art.draw(r.draft))
	table.insert(self.state.artHistory,1,signature)
	if #self.state.artHistory>64 then table.remove(self.state.artHistory)end
	self.state.nextLaunchAt=s.now+math.max(s.cooldown,1)
	self.previewDraft=nil
	self:persist()
	self:status("LAUNCHED","Created $"..r.draft.ticker..". Waiting for its live market row.")
end
function Engine:_finish(s,payout,learn)
	local r=assert(self.state.round)
	local coin=r.coinId and s.coins[r.coinId]
	local fees=coin and finite(coin.devFees) and math.max(0,coin.devFees) or 0
	local age=coin and finite(coin.createdAt) and math.max(1,s.now-coin.createdAt) or math.max(1,s.now-r.startedAt)
	local net=if learn then payout+fees-r.cost else nil
	local reward=if learn then math.tanh(net/500/math.max(1,age/120)) else nil
	if learn then self.learner:update(r.arm,r.features,reward)end
	table.insert(self.state.history,1,{ticker=r.draft.ticker,arm=r.arm,at=s.now,payout=payout,net=net,reward=reward,learned=learn})
	if #self.state.history>30 then table.remove(self.state.history)end
	self.state.stats.completed+=1
	self.state.round,self.state.pending=nil,nil
	self.rugInfo=nil
	self.previewDraft=nil
	self:persist()
	self:status("ROUND COMPLETE",if learn then string.format("Confirmed payout %.0f · net %.0f · learned reward %.3f",payout,net,reward)
		else "Round ended; payout was not confirmed, so no training sample was added.")
end
function Engine:_reconcile(s)
	local pending=self.state.pending
	local r=self.state.round
	if pending.kind=="create"then
		local found=nil
		for id,coin in s.coins do
			if owns(coin,s) and coin.ticker==r.draft.ticker then
				assert(not found,"Multiple coins match the pending ticker; check the game before continuing")
				found=id
			end
		end
		if found then self:_attach(found,s);return end
	elseif r.coinId and owns(s.coins[r.coinId],s) and s.coins[r.coinId].phase=="Rugged"then
		self:_finish(s,nil,false);return
	end
	self:pause("The previous "..pending.kind.." request has an unconfirmed outcome. Check the coin/wallet; it will not be submitted twice.")
end
function Engine:_create(s)
	if s.now<self.state.nextLaunchAt then self:status("COOLDOWN",string.format("Next launch in %.0f seconds.",self.state.nextLaunchAt-s.now));return end
	if s.account.balance<s.cost+self.config.ReserveBalance then self:status("WAITING FOR BALANCE","The next launch would use the reserved in-game balance.");return end
	if s.owned>=6 then self:status("WAITING FOR SLOT","You already have six live coins. This bot only manages coins it creates.");return end
	local serial=self.state.serial+1
	local arm=self.learner:choose(s.features,serial)
	local draft=Art.draft(arm,serial,math.floor(s.now)+self.userId%2147483647)
	local signature
	for attempt=1,24 do
		local duplicate=false
		for _,coin in s.coins do if coin.ticker==draft.ticker then duplicate=true;break end end
		if not duplicate then break end
		serial+=1;draft=Art.draft(arm,serial,math.floor(s.now)+attempt*997+self.userId%2147483647)
		assert(attempt<24,"Could not allocate a new ticker")
	end
	for attempt=1,40 do
		signature=Art.signature(Art.draw(draft))
		if not table.find(self.state.artHistory,signature)then break end
		draft.seed+=997+attempt*137
		assert(attempt<40,"Could not allocate a different recent pixel-art image")
	end
	self.state.serial=serial
	self.state.round={draft=draft,arm=arm,features=table.clone(s.features),cost=s.cost,startedAt=s.now,
		artSignature=signature,nextPostAt=s.now,nextChatAt=s.now+12,nextInfoAt=s.now+s.minAge+2,posts=0,chats=0}
	self.state.pending={kind="create",at=s.now}
	-- A failed local checkpoint precedes dispatch, so this instance can roll it back.
	local checkpoint,why=pcall(function()self:persist()end)
	if not checkpoint then self.state.pending,self.state.round=nil,nil;error(why)end
	if not self.enabled or self.stopped then self.state.pending,self.state.round=nil,nil;self:persist();return end
	self:status("CREATING","Launching $"..draft.ticker.." with original 32×32 pixel art…")
	local result=self.adapter:create(Art.payload(draft,s.network))
	if transportFailure(result)then self:pause("Creation outcome is unconfirmed. The pending request is saved for reconciliation.");return end
	if result.ok then
		assert(type(result.coinId)=="string" or type(result.coinId)=="number","Created coin ID was not returned; check the pending request")
		self:_attach(result.coinId,s)
	else
		self.state.pending,self.state.round=nil,nil
		self.state.nextLaunchAt=s.now+math.max(15,s.cooldown)
		self:persist();self:status("LAUNCH DECLINED",tostring(result.error or "The game declined this launch"))
	end
end
function Engine:step()
	if not self.enabled or self.stopped then return end
	local s=self:refresh()
	if not s then return end
	if not self.enabled or self.stopped then return end
	assert(finite(s.now) and finite(s.cost) and s.cost>=0 and finite(s.minAge),"Invalid game snapshot")
	if not s.rugEnabled then self:pause("The game's rug mechanic is currently disabled.");return end
	if self.state.pending then self:_reconcile(s);return end
	if not self.state.round then self:_create(s);return end
	local r=self.state.round
	local coin=r.coinId and s.coins[r.coinId]
	if not coin then
		if s.now-r.startedAt>30 then self:pause("The created coin is not in this server's live state. Return to its server before resuming.")
		else self:status("CONNECTING COIN","Waiting for the created coin's live market row.")end
		return
	end
	assert(owns(coin,s) and coin.ticker==r.draft.ticker,"The tracked coin does not belong to this account/campaign")
	if coin.phase=="Rugged"then self:_finish(s,nil,false);return end
	assert(finite(coin.createdAt),"The tracked coin has no creation time")
	local age=math.max(0,s.now-coin.createdAt)
	local patient=r.arm>6
	local hold=math.max(s.minAge+2,s.minAge+(if patient then 90 else 15))
	local latest=hold+90
	r.holdUntil=coin.createdAt+hold
	if s.now>=r.nextInfoAt and age>=s.minAge+2 then
		r.nextInfoAt=s.now+math.max(10,self.config.InfoEvery)
		local info=self.adapter:rugInfo(r.coinId)
		if type(info)=="table"then self.rugInfo=info else self.rugInfo=nil end
	end
	if not self.enabled or self.stopped then return end
	local info=self.rugInfo
	if s.rugEnabled and age>=hold and info and info.eligible==true and finite(info.payout)
		and (info.payout>=math.max(250,r.cost)*(if patient then 2 else 1.25) or age>=latest)then
		self.state.pending={kind="rug",at=s.now}
		local checkpoint,why=pcall(function()self:persist()end)
		if not checkpoint then self.state.pending=nil;error(why)end
		if not self.enabled or self.stopped then self.state.pending=nil;self:persist();return end
		self:status("RUGGING","Submitting the game's fictional rug action for $"..coin.ticker.."…")
		local result=self.adapter:rug(r.coinId,coin.ticker)
		if transportFailure(result)then self:pause("Rug outcome is unconfirmed. The pending request is saved for reconciliation.");return end
		if result.ok then
			if finite(result.payout)then self:_finish(s,result.payout,true)else self:_finish(s,nil,false)end
		else
			self.state.pending=nil;self.rugInfo=nil;r.nextInfoAt=s.now+15;self:persist()
			self:status("RUG LOCKED",tostring(result.error or "The game declined the rug action"))
		end
		return
	end
	if self.config.PostsEnabled and r.posts<self.config.MaxPostsPerCoin and s.now>=r.nextPostAt then
		r.posts+=1;r.nextPostAt=s.now+math.max(self.config.PostEvery,s.postCooldown+1)
		self:persist() -- At most one submission per reserved message slot, even after reload.
		if not self.enabled or self.stopped then return end
		local result=self.adapter:post(Art.message(r.draft,r.posts,false):sub(1,s.postMax))
		if type(result)=="table" and result.ok then self.state.stats.posts+=1;self:persist()
		else r.nextPostAt=s.now+math.max(60,self.config.PostEvery);self.lastError=tostring(type(result)=="table" and result.error or "Post not accepted")end
		self:status(if type(result)=="table" and result.ok then "POSTED" else "POST SKIPPED",if type(result)=="table" and result.ok then "Posted an in-game update about $"..coin.ticker else "Post slot finished; "..self.lastError)
		return
	end
	if self.config.ChatEnabled and r.chats<self.config.MaxChatsPerCoin and s.now>=r.nextChatAt then
		r.chats+=1;r.nextChatAt=s.now+math.max(self.config.ChatEvery,s.chatCooldown+1)
		self:persist()
		if not self.enabled or self.stopped then return end
		local result=self.adapter:chat(Art.message(r.draft,r.chats,true):sub(1,s.chatMax))
		if type(result)=="table" and result.ok then self.state.stats.chats+=1;self:persist()
		else r.nextChatAt=s.now+math.max(60,self.config.ChatEvery);self.lastError=tostring(type(result)=="table" and result.error or "Chat not accepted")end
		self:status("CHAT",if type(result)=="table" and result.ok then "Sent an in-game message about $"..coin.ticker else "Chat slot finished; "..self.lastError)
		return
	end
	self:status("GROWING",string.format("$%s · age %.0fs · learned plan holds at least %.0fs. %s",coin.ticker,age,hold,
		if info and not info.eligible then tostring(info.reason or "Rug eligibility is locked.")else "Watching the live payout estimate."))
end
return Engine

end)()

__modules["UI"]=(function()
-- A small mouse-operated panel; the preview uses ordinary Frames, not EditableImage.
local Art=__modules["Art"]
local UI={}
UI.__index=UI
local colors={bg=Color3.fromRGB(14,19,29),panel=Color3.fromRGB(26,34,49),text=Color3.fromRGB(233,239,250),
	muted=Color3.fromRGB(152,168,194),accent=Color3.fromRGB(119,101,246),good=Color3.fromRGB(66,208,155)}
local function make(class,props,parent)
	local value=Instance.new(class)
	for key,item in props do value[key]=item end
	value.Parent=parent
	return value
end
local function round(value,radius)make("UICorner",{CornerRadius=UDim.new(0,radius)},value)end
local function label(parent,name,text,x,y,w,h,size,color)
	return make("TextLabel",{Name=name,Text=text,BackgroundTransparency=1,TextColor3=color or colors.text,
		Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Font=Enum.Font.Gotham,TextSize=size or 13,
		TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextWrapped=true},parent)
end
local function button(parent,name,text,x,y,w,h)
	local item=make("TextButton",{Name=name,Text=text,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
		Font=Enum.Font.GothamBold,TextSize=13,TextColor3=colors.text,BackgroundColor3=colors.panel,AutoButtonColor=true},parent)
	round(item,8)
	return item
end
function UI.new(player,input,version)
	local self=setmetatable({connections={},input=input,previewKey=nil},UI)
	self.gui=make("ScreenGui",{Name="RugpullML",ResetOnSpawn=false,DisplayOrder=125,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild("PlayerGui"))
	local frame=make("Frame",{Name="Panel",Size=UDim2.fromOffset(460,510),Position=UDim2.new(0.5,-230,0.5,-255),BackgroundColor3=colors.bg,BorderSizePixel=0},self.gui)
	self.frame=frame;round(frame,14)
	make("UIScale",{Scale=1},frame)
	label(frame,"Title","RUGPULL ML",20,13,350,30,23)
	label(frame,"Subtitle","IN-GAME CAMPAIGNS · "..version,20,43,390,22,11,colors.muted)
	self.close=button(frame,"Close","×",410,16,30,30)
	local status=make("Frame",{Name="StatusCard",Position=UDim2.fromOffset(20,76),Size=UDim2.fromOffset(420,75),BackgroundColor3=colors.panel,BorderSizePixel=0},frame)
	round(status,10)
	self.statusTitle=label(status,"Status","LOADING",12,6,395,22,13,colors.good)
	self.statusDetail=label(status,"Detail","Loading local learning and the game adapter…",12,30,395,37,12,colors.muted)
	local art=make("Frame",{Name="PixelPreview",Position=UDim2.fromOffset(20,166),Size=UDim2.fromOffset(128,128),BorderSizePixel=0,BackgroundColor3=colors.panel},frame)
	self.pixels={}
	for y=0,15 do for x=0,15 do
		self.pixels[y*16+x+1]=make("Frame",{Name="P"..(y*16+x),Position=UDim2.fromOffset(x*8,y*8),Size=UDim2.fromOffset(8,8),BorderSizePixel=0,BackgroundColor3=colors.panel},art)
	end end
	self.draftName=label(frame,"DraftName","Waiting for game state",164,167,274,33,16)
	self.ticker=label(frame,"Ticker","NEXT COIN PREVIEW",164,202,274,23,12,colors.muted)
	self.plan=label(frame,"Plan","Learning starts from completed rounds.",164,231,274,60,12,colors.muted)
	self.metrics=label(frame,"Metrics","Rounds learned: 0",20,307,420,24,12)
	self.counts=label(frame,"Counts","Launches 0 · Posts 0 · Messages 0",20,333,420,22,12,colors.muted)
	self.posts=button(frame,"Posts","POSTS: YES",20,372,202,36)
	self.chat=button(frame,"Chat","CHAT: YES",236,372,204,36)
	self.start=button(frame,"Start","CONNECTING…",20,422,265,45)
	self.start.BackgroundColor3=colors.accent
	self.save=button(frame,"Save","SAVE",299,422,65,45)
	self.unload=button(frame,"Unload","UNLOAD",373,422,67,45)
	label(frame,"Footer","F6 start/pause · F7 unload · local learning saved to workspace",20,480,420,16,10,colors.muted)
	local dragging,origin,position=nil,nil,nil
	table.insert(self.connections,frame.InputBegan:Connect(function(event)
		if (event.UserInputType==Enum.UserInputType.MouseButton1 or event.UserInputType==Enum.UserInputType.Touch)
			and event.Position.Y-frame.AbsolutePosition.Y<70 then dragging=event;origin=event.Position;position=frame.Position end
	end))
	table.insert(self.connections,input.InputChanged:Connect(function(event)
		if dragging and (event.UserInputType==Enum.UserInputType.MouseMovement or event==dragging)then
			local delta=event.Position-origin
			frame.Position=UDim2.new(position.X.Scale,position.X.Offset+delta.X,position.Y.Scale,position.Y.Offset+delta.Y)
		end
	end))
	table.insert(self.connections,input.InputEnded:Connect(function(event)
		if event==dragging or event.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil end
	end))
	return self
end
function UI:status(code,detail)
	if self.destroyed then return end
	self.statusTitle.Text=code
	self.statusDetail.Text=tostring(detail)
end
function UI:render(engine,storagePath)
	if self.destroyed then return end
	self:status(engine.code,engine.detail)
	local s=engine.snapshot
	local draft,arm=engine:preview(s)
	if draft then
		local key=draft.ticker..":"..draft.seed
		if key~=self.previewKey then
			local _,cells=Art.draw(draft)
			for i,color in cells do self.pixels[i].BackgroundColor3=Color3.fromRGB(color[1],color[2],color[3])end
			self.previewKey=key
		end
		self.draftName.Text=draft.name
		self.ticker.Text="$"..draft.ticker..(if engine.state.round then " · CURRENT CAMPAIGN" else " · NEXT PREVIEW")
		self.plan.Text=(if arm>6 then "PATIENT" else "QUICK").." · "..Art.Themes[draft.shape].name.." art\n"..(if engine.rugInfo then string.format("Payout estimate: %.0f",engine.rugInfo.payout or 0)else "Waiting for server rug eligibility.")
	end
	self.metrics.Text=string.format("Rounds learned: %d  ·  Balance: %s",engine.learner.rounds,if s then string.format("%.0f",s.account.balance)else "connecting")
	local counts=engine.state.stats
	self.counts.Text=string.format("Launches %d · Posts %d · Messages %d · Finished %d",counts.launches,counts.posts,counts.chats,counts.completed)
	self.posts.Text="POSTS: "..(if engine.config.PostsEnabled then "YES" else "NO")
	self.chat.Text="CHAT: "..(if engine.config.ChatEnabled then "YES" else "NO")
	self.start.Text=if engine.enabled then "PAUSE BOT" elseif s then "START BOT" else "CONNECTING…"
	self.start.Active=s~=nil
	self.start.Modal=not engine.enabled
	self.gui:SetAttribute("LearningFile",storagePath)
end
function UI:destroy()
	if self.destroyed then return end
	self.destroyed=true
	for _,connection in self.connections do connection:Disconnect()end
	self.gui:Destroy()
end
return UI

end)()

local Adapter=__modules["Adapter"]
local Engine=__modules["Engine"]
local Storage=__modules["Storage"]
local UI=__modules["UI"]
local VERSION="0.1.0"
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Http=game:GetService("HttpService")
local environment=if type(getgenv)=="function"then getgenv()else getfenv()
local config=table.clone(environment.RugpullMLConfig or _G.RugpullMLConfig or {})
for key,value in environment.RugpullMLRuntimeDefaults or {}do if config[key]==nil then config[key]=value end end
local player=assert(Players.LocalPlayer,"Run Rugpull ML on the client")
local previous=environment.RugpullML or _G.RugpullML
if previous and not previous.PendingRequest and previous.Stop then previous:Stop()end
local oldIcon=UIS.MouseIconEnabled
UIS.MouseIconEnabled=true
local ui=UI.new(player,UIS,VERSION)
local connections={}
local engine,storage=nil,nil
local stopped,busy,saveQueued=false,false,false
local token,nextStep=nil,0
local api={Version=VERSION,Ready=false,Enabled=false,PendingRequest=false,LastError=nil}
local function render()
	if not stopped and engine then ui:render(engine,storage.path)end
	api.Enabled=engine and engine.enabled or false
end
function api:SetEnabled(value)
	if stopped or not engine or not engine.snapshot then return false end
	engine:setEnabled(value);render();return true
end
function api:Save()
	if not engine or stopped then return false end
	if busy then saveQueued=true;return true end
	local ok,reason=pcall(function()engine:persist()end)
	if not ok then api.LastError=tostring(reason);engine:pause("Save failed: "..tostring(reason))else engine:status("SAVED",storage.path)end
	render();return ok
end
function api:Stop()
	if stopped then return end
	stopped=true;api.Enabled=false
	if engine then
		engine:pause();engine.stopped=true
		if busy then saveQueued=true end
		if not busy then
			local ok,reason=pcall(function()engine:persist()end)
			if not ok then api.LastError=tostring(reason)end
		end
	end
	for _,connection in connections do connection:Disconnect()end
	ui:destroy();UIS.MouseIconEnabled=oldIcon
end
function api:GetDiagnostics()
	return {version=VERSION,ready=api.Ready,enabled=api.Enabled,pending=api.PendingRequest,error=api.LastError,
		learningFile=storage and storage.path,learnedRounds=engine and engine.learner.rounds,
		status=engine and engine.code,detail=engine and engine.detail,
		coinId=engine and engine.state.round and engine.state.round.coinId,
		checkpoint=engine and engine.state.pending and engine.state.pending.kind}
end
table.insert(connections,ui.close.Activated:Connect(function()api:Stop()end))
table.insert(connections,ui.unload.Activated:Connect(function()api:Stop()end))
table.insert(connections,ui.start.Activated:Connect(function()api:SetEnabled(not api.Enabled)end))
table.insert(connections,ui.save.Activated:Connect(function()api:Save()end))
table.insert(connections,ui.posts.Activated:Connect(function()
	if engine then engine.config.PostsEnabled=not engine.config.PostsEnabled;render()end
end))
table.insert(connections,ui.chat.Activated:Connect(function()
	if engine then engine.config.ChatEnabled=not engine.config.ChatEnabled;render()end
end))
table.insert(connections,UIS.InputBegan:Connect(function(event,processed)
	if processed or UIS:GetFocusedTextBox()then return end
	if event.KeyCode==Enum.KeyCode.F6 then api:SetEnabled(not api.Enabled)
	elseif event.KeyCode==Enum.KeyCode.F7 then api:Stop()end
end))
if previous and previous.PendingRequest then
	ui:status("WAITING FOR PREVIOUS REQUEST","The earlier instance still has a game request in flight. Wait for it to finish before reloading.")
	return api
end
environment.RugpullML=api;_G.RugpullML=api
local function work(callback)
	if stopped or busy then return end
	busy=true;api.PendingRequest=true
	local current={};token=current
	task.spawn(function()
		local ok,reason=pcall(callback)
		if not ok then
			api.LastError=tostring(reason)
			if engine then engine:pause("ERROR: "..tostring(reason))end
			if not stopped then ui:status("ERROR",tostring(reason))end
		end
		if saveQueued and engine then
			saveQueued=false
			local saved,why=pcall(function()engine:persist()end)
			if not saved then api.LastError=tostring(why);engine:pause("Save failed: "..tostring(why))end
		end
		if token==current then busy=false;api.PendingRequest=false;token=nil end
		if not stopped then render()end
	end)
	task.delay(math.clamp(tonumber(config.RequestTimeout) or 20,5,120),function()
		if busy and token==current then
			api.LastError="Game request timed out; its result may still arrive. No duplicate request will be sent."
			api.Enabled=false
			if engine then engine:pause(api.LastError)end
			if not stopped then ui:status("WAITING FOR REQUEST",api.LastError)end
		end
	end)
end
work(function()
	storage=Storage.new(config,environment,Http,player.UserId)
	local saved,note=storage:load(function(value)Engine.validate(value,player.UserId)end)
	if stopped then return end
	local adapter=Adapter.new(player,{storage=game:GetService("ReplicatedStorage"),chat=game:GetService("TextChatService"),
		require=require,now=function()return workspace:GetServerTimeNow()end})
	engine=Engine.new({adapter=adapter,save=function(value)storage:save(value)end,saved=saved,config=config,userId=player.UserId})
	engine:refresh();engine:status(if engine.snapshot then "PAUSED" else "CONNECTING",if engine.snapshot then note..". Click Start Bot." else engine.detail)
	api.Ready=true
	if config.StartEnabled==true and engine.snapshot and not api.LastError then engine:setEnabled(true)end
end)
table.insert(connections,RunService.Heartbeat:Connect(function()
	if stopped or not engine then return end
	local now=os.clock()
	if now<nextStep or busy then return end
	nextStep=now+(if engine.enabled then 0.5 else 2)
	work(function()
		if engine.enabled then engine:step()else engine:refresh()end
	end)
end))
return api
