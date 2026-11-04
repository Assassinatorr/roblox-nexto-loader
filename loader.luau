-- Versioned executor workspace cache. Runtime/model data stay local.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Http=game:GetService("HttpService")
local environment=if type(getgenv)=="function" then getgenv() else getfenv()
environment.RobloxNextoLoaderConfig=environment.RobloxNextoLoaderConfig or _G.RobloxNextoLoaderConfig
local player=assert(Players.LocalPlayer,"Run this loader on the client")
local oldIcon=UIS.MouseIconEnabled
UIS.MouseIconEnabled=true
local gui=Instance.new("ScreenGui")
gui.Name="RobloxNextoDownload"
gui.ResetOnSpawn=false
local box=Instance.new("TextButton")
box.Name="DownloadStatus"
box.Modal=true
box.Size=UDim2.fromOffset(420,110)
box.Position=UDim2.new(0.5,-210,0.5,-55)
box.BackgroundColor3=Color3.fromRGB(14,19,29)
box.TextColor3=Color3.fromRGB(235,242,253)
box.Font=Enum.Font.Gotham
box.TextSize=14
box.TextWrapped=true
box.Text="NEXTO ML\nChecking the executor workspace…"
box.Parent=gui
gui.Parent=player:WaitForChild("PlayerGui")
task.wait()
local SHA256=(function()
-- SHA-256 for loader cache integrity. Only runs during loading, not inference.
local SHA256={}
local K={
	0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
	0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
	0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
	0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
	0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
	0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
	0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
	0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}
local xor,and_,not_,ror,rshift=bit32.bxor,bit32.band,bit32.bnot,bit32.rrotate,bit32.rshift
local MOD=4294967296
local function word(value)
	return string.char(and_(rshift(value,24),255),and_(rshift(value,16),255),and_(rshift(value,8),255),and_(value,255))
end
function SHA256.digest(source,yieldFn)
	local length=#source
	local bitLength=length*8
	local padded=source..string.char(128)..string.rep(string.char(0),(55-length)%64)
		..word(math.floor(bitLength/MOD))..word(bitLength%MOD)
	local h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
	local w=table.create(64,0)
	for offset=1,#padded,64 do
		for i=1,16 do
			local a,b,c,d=string.byte(padded,offset+(i-1)*4,offset+(i-1)*4+3)
			w[i]=a*16777216+b*65536+c*256+d
		end
		for i=17,64 do
			local a,b=w[i-15],w[i-2]
			local s0=xor(ror(a,7),ror(a,18),rshift(a,3))
			local s1=xor(ror(b,17),ror(b,19),rshift(b,10))
			w[i]=(w[i-16]+s0+w[i-7]+s1)%MOD
		end
		local a,b,c,d,e,f,g,hh=table.unpack(h)
		for i=1,64 do
			local s1=xor(ror(e,6),ror(e,11),ror(e,25))
			local ch=xor(and_(e,f),and_(not_(e),g))
			local t1=(hh+s1+ch+K[i]+w[i])%MOD
			local s0=xor(ror(a,2),ror(a,13),ror(a,22))
			local maj=xor(and_(a,b),and_(a,c),and_(b,c))
			local t2=(s0+maj)%MOD
			hh,g,f,e,d,c,b,a=g,f,e,(d+t1)%MOD,c,b,a,(t1+t2)%MOD
		end
		for i,v in {a,b,c,d,e,f,g,hh} do h[i]=(h[i]+v)%MOD end
		if yieldFn and (offset-1)%65536==0 then yieldFn() end
	end
	local result={}
	for i,v in h do result[i]=string.format("%08x",v) end
	return table.concat(result)
end
return SHA256

end)()
local Cache=(function()
-- Executor workspace files only. No filesystem discovery or backend inspection.
local Cache={}
local function relative(path)
	assert(type(path)=="string" and #path>0 and #path<200,"Invalid cache folder")
	path=path:gsub("\\","/")
	assert(not path:match("^/") and not path:find(":",1,true),"Cache folder must be relative to the executor workspace")
	for part in path:gmatch("[^/]+") do assert(part~=".." and part~=".","Cache folder cannot leave the executor workspace") end
	assert(not path:find("%c"),"Invalid cache path")
	return path:gsub("/+$","")
end
function Cache.load(options)
	local env,manifest=options.environment,options.manifest
	local config=env.RobloxNextoLoaderConfig or {}
	local io=config.FileIO or env
	assert(type(io.readfile)=="function" and type(io.writefile)=="function" and type(io.makefolder)=="function",
		"This loader needs readfile, writefile and makefolder from your internal executor. Rewire RobloxNextoLoaderConfig.FileIO.")
	local function read(path)
		local ok,value=pcall(io.readfile,path)
		return if ok and type(value)=="string" then value else nil
	end
	local pathFile=config.PathFile or "roblox-nexto-path.json"
	pathFile=relative(pathFile)
	local raw=read(pathFile)
	local pathConfig={cacheFolder=config.CacheFolder or "roblox-nexto"}
	if raw then
		local parsed=options.decode(raw)
		assert(type(parsed)=="table","The executor path file must contain a JSON object")
		pathConfig=parsed
	end
	local folder=relative(config.CacheFolder or pathConfig.cacheFolder or "roblox-nexto")
	assert(#folder>0,"Cache folder cannot be empty")
	local current=""
	for part in folder:gmatch("[^/]+") do
		current=if current=="" then part else current.."/"..part
		local exists=type(io.isfolder)=="function" and io.isfolder(current)
		if not exists then
			local ok,failure=pcall(io.makefolder,current)
			assert(ok or (type(io.isfolder)=="function" and io.isfolder(current)),failure)
		end
	end
	if not raw then io.writefile(pathFile,options.encode({cacheFolder=folder})) end
	local payloadPath=folder.."/"..manifest.payload
	local function valid(source)
		return type(source)=="string" and #source==manifest.bytes and options.hash(source)==manifest.sha256
	end
	options.status("Checking the cached client…\n"..payloadPath)
	local source=read(payloadPath)
	local cached=valid(source)
	if not cached then
		options.status("Downloading and verifying the pretrained client…")
		source=options.fetch(manifest.payload_url)
		assert(valid(source),"Downloaded client failed its byte-length/SHA-256 check")
		-- Compile before persisting, then check the exact bytes read back from disk.
		local compiled,failure=options.compile(source)
		assert(compiled,failure)
		io.writefile(payloadPath,source)
		assert(read(payloadPath)==source,"Executor cache write/read-back verification failed")
		io.writefile(folder.."/runtime-"..manifest.version..".json",options.encode(manifest))
	end
	local diskSource=assert(read(payloadPath),"The verified executor cache file is unreadable")
	assert(diskSource==source,"Executor cache changed before compilation")
	local compiled,failure=options.compile(diskSource)
	assert(compiled,failure)
	return compiled,{path=payloadPath,pathFile=pathFile,version=manifest.version,sha256=manifest.sha256,
		verified=true,cacheHit=cached,execution="readfile + loadstring"}
end
return Cache

end)()
local manifest= {
    ["version"]="1.4.0",
    ["payload"]="Nexto-1.4.0.client.luau",
    ["payload_url"]="https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/afc727f1b653d90ad9a8503a1eb3a2cb22bbb0aa/Nexto-1.4.0.client.luau",
    ["sha256"]="23d57916aab53b668b16dc41616ace764e06f1df88da415cca7320b5263cefbb",
    ["bytes"]=2453470
}
local hostHash=nil
if type(environment.crypt)=="table" and type(environment.crypt.hash)=="function" then
    local ok,value=pcall(environment.crypt.hash,"abc","sha256")
    if ok and type(value)=="string" and value:lower()=="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" then
        hostHash=environment.crypt.hash
    end
end
local ok,compiled=pcall(function()
    local run,cache=Cache.load({environment=environment,manifest=manifest,
        decode=function(value)return Http:JSONDecode(value)end,
        encode=function(value)return Http:JSONEncode(value)end,
        status=function(value)box.Text="NEXTO ML\n"..value;task.wait()end,
        hash=function(value)
            if hostHash then return string.lower(hostHash(value,"sha256"))end
            return SHA256.digest(value,task.wait)
        end,
        fetch=function(url)return game:HttpGet(url)end,
        compile=function(value)return loadstring(value,"Roblox Nexto "..manifest.version)end})
    environment.RobloxNextoCache=cache
    _G.RobloxNextoCache=cache
    return run
end)
if not ok then
    box.Text="NEXTO LOAD FAILED\n"..tostring(compiled).."\nClick to close."
    box.Activated:Connect(function()gui:Destroy();UIS.MouseIconEnabled=oldIcon end)
    warn(box.Text)
    return nil
end
gui:Destroy()
UIS.MouseIconEnabled=oldIcon
return compiled()
