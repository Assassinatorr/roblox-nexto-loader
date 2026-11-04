-- Workspace-cached, hash-checked loader for the original Rugpull ML runtime.
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local Http=game:GetService("HttpService")
local environment=if type(getgenv)=="function"then getgenv()else getfenv()
local config=environment.RugpullMLLoaderConfig or _G.RugpullMLLoaderConfig or {}
local oldIcon=UIS.MouseIconEnabled
UIS.MouseIconEnabled=true
local gui=Instance.new("ScreenGui")
gui.Name="RugpullMLDownload";gui.ResetOnSpawn=false;gui.DisplayOrder=130
local box=Instance.new("TextButton")
box.Name="DownloadStatus";box.Modal=true;box.Size=UDim2.fromOffset(430,120);box.Position=UDim2.new(0.5,-215,0.5,-60)
box.BackgroundColor3=Color3.fromRGB(14,19,29);box.TextColor3=Color3.fromRGB(233,239,250)
box.Font=Enum.Font.Gotham;box.TextSize=14;box.TextWrapped=true
box.Text="RUGPULL ML\nChecking the executor workspace…";box.Parent=gui;gui.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
task.wait()
local manifest= {
["version"]="0.1.0",
["payload"]="RugpullML-0.1.0.client.luau",
["payload_url"]="https://raw.githubusercontent.com/Assassinatorr/roblox-nexto-loader/c9bda2a054f113cba7a9730b898bb1ef388a94da/rugpull/RugpullML-0.1.0.client.luau",
["sha256"]="6d6a27782b32b74c1ec19eef28a3ffab91435f0008020c27dd7743936a030597",
["bytes"]=45181
}
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
local function relative(path)
	assert(type(path)=="string" and #path>0 and #path<180,"Invalid cache path")
	path=path:gsub("\\","/"):gsub("/+$","")
	assert(#path>0 and not path:match("^/") and not path:find(":",1,true) and not path:find("%c"),"Cache paths must be workspace-relative")
	for part in path:gmatch("[^/]+")do assert(part~="." and part~="..","A cache path cannot leave the executor workspace")end
	return path
end
local ok,compiled=pcall(function()
	local supplied=config.FileIO or {}
	local native=getfenv()
	local io={}
	for _,name in {"readfile","writefile","makefolder","isfolder","isfile"}do io[name]=supplied[name] or environment[name] or native[name]end
	assert(type(io.readfile)=="function" and type(io.writefile)=="function" and type(io.makefolder)=="function",
		"The host needs readfile, writefile and makefolder. Set RugpullMLLoaderConfig.FileIO if rewired.")
	local function read(path)
		if io.isfile and not io.isfile(path)then return nil end
		local success,value=pcall(io.readfile,path)
		return if success and type(value)=="string"then value else nil
	end
	local pathFile=relative(config.PathFile or "rugpull-ml-path.json")
	local raw=read(pathFile)
	local selected={cacheFolder="rugpull-ml"}
	if raw then assert(#raw<16384,"Cache path file is too large");selected=Http:JSONDecode(raw);assert(type(selected)=="table","Invalid cache path file")end
	local folder=relative(config.CacheFolder or selected.cacheFolder or "rugpull-ml")
	local current=""
	for part in folder:gmatch("[^/]+")do
		current=if current==""then part else current.."/"..part
		if not (io.isfolder and io.isfolder(current))then
			local created,reason=pcall(io.makefolder,current)
			assert(created or (io.isfolder and io.isfolder(current)),reason)
		end
	end
	if not raw then io.writefile(pathFile,Http:JSONEncode({cacheFolder=folder}))end
	local cryptAPI=environment.crypt or native.crypt
	local nativeHash=nil
	if type(cryptAPI)=="table" and type(cryptAPI.hash)=="function"then
		local success,value=pcall(cryptAPI.hash,"abc","sha256")
		if success and type(value)=="string" and value:lower()=="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"then nativeHash=cryptAPI.hash end
	end
	local function hash(data)return if nativeHash then string.lower(nativeHash(data,"sha256"))else SHA256.digest(data,task.wait)end
	local function valid(source)return type(source)=="string" and #source==manifest.bytes and hash(source)==manifest.sha256 end
	local payloadPath=folder.."/"..manifest.payload
	box.Text="RUGPULL ML\nChecking the cached client…\n"..payloadPath
	local source=read(payloadPath)
	local hit=valid(source)
	if not hit then
		box.Text="RUGPULL ML\nDownloading the open client script…";task.wait()
		source=game:HttpGet(manifest.payload_url)
		assert(valid(source),"Downloaded script failed its byte-length/SHA-256 check")
		local run,reason=loadstring(source,"Rugpull ML "..manifest.version);assert(run,reason)
		io.writefile(payloadPath,source)
		assert(read(payloadPath)==source,"Cache write/read-back check failed")
		io.writefile(folder.."/runtime-"..manifest.version..".json",Http:JSONEncode(manifest))
	end
	local diskSource=assert(read(payloadPath),"The cached client cannot be read")
	assert(diskSource==source and valid(diskSource),"Cache changed before compilation")
	local run,reason=loadstring(diskSource,"Rugpull ML "..manifest.version);assert(run,reason)
	environment.RugpullMLRuntimeDefaults={CacheFolder=folder,FileIO=io}
	environment.RugpullMLCache={path=payloadPath,pathFile=pathFile,verified=true,cacheHit=hit,version=manifest.version,sha256=manifest.sha256}
	return run
end)
if not ok then
	box.Text="RUGPULL ML LOAD FAILED\n"..tostring(compiled).."\nClick to close."
	box.Activated:Connect(function()gui:Destroy();UIS.MouseIconEnabled=oldIcon end)
	return nil
end
gui:Destroy();UIS.MouseIconEnabled=oldIcon
local started,result=pcall(compiled)
if not started then error("Rugpull ML could not initialize: "..tostring(result))end
return result
