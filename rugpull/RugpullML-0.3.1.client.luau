-- Rugpull ML 0.3.1: original open source for an owned Roblox simulation.
-- Runs an online LinUCB learner; no pretrained policy or external model service.
local __modules={}

__modules["PixelLibrary"]=(function()
-- Hand-authored pixel interpretations for an in-game art collection.
-- No images, scripts or executable data are downloaded to generate a logo.
local Library={Themes={}}
local function add(family,category,icon,items)
	for _,item in items do
		table.insert(Library.Themes,{id=item[1],name=item[2],code=item[3],family=family,category=category,icon=icon})
	end
end
add("Companies","Internet","💾",{
	{"apple","Apple","AP"},{"microsoft","Microsoft","MS"},{"google","Google","GG"},{"youtube","YouTube","YT"},
	{"spotify","Spotify","SP"},{"tesla","Tesla","TS"},{"nike","Nike","NK"},{"adidas","Adidas","AD"},
	{"nvidia","Nvidia","NV"},{"discord","Discord","DC"},{"github","GitHub","GT"},
})
add("Companies","Gaming","🎮",{{"roblox","Roblox","RX"},{"nintendo","Nintendo","NT"}})
add("Companies","Food","🍔",{{"mcdonalds","McDonalds","MC"}})
add("Flags","Seasonal","🌸",{
	{"uk","UK Flag","UK"},{"usa","USA Flag","US"},{"france","France Flag","FR"},{"germany","Germany Flag","DE"},
	{"italy","Italy Flag","IT"},{"japan","Japan Flag","JP"},{"ukraine","Ukraine Flag","UA"},{"canada","Canada Flag","CA"},
	{"brazil","Brazil Flag","BR"},{"india","India Flag","IN"},{"spain","Spain Flag","ES"},{"poland","Poland Flag","PL"},
	{"china","China Flag","CN"},{"eu","EU Flag","EU"},
})
add("Hackers","Internet","💾",{{"dedsec","DedSec","DS"},{"anonymous","Anonymous","AN"},{"lulzsec","LulzSec","LZ"},{"ccc","CCC","CC"}})
add("Agencies","Internet","💾",{{"fbi","FBI","FB"},{"cia","CIA","CI"},{"nsa","NSA","NS"},{"mi5","MI5","M5"},{"mi6","MI6","M6"},{"interpol","Interpol","IP"}})
add("Agencies","Space","🚀",{{"nasa","NASA","NA"}})
local font={
	A={"010","101","111","101","101"},B={"110","101","110","101","110"},C={"011","100","100","100","011"},
	D={"110","101","101","101","110"},E={"111","100","110","100","111"},F={"111","100","110","100","100"},
	I={"111","010","010","010","111"},M={"101","111","111","101","101"},N={"101","111","111","111","101"},
	P={"110","101","110","100","100"},S={"011","100","010","001","110"},T={"111","010","010","010","010"},
	["5"]={"111","100","110","001","110"},["6"]={"011","100","110","101","010"},
}
local white={245,247,250};local black={10,13,20};local red={225,40,55};local blue={30,85,190}
local green={35,180,90};local gold={255,203,55};local navy={18,38,77}
function Library.draw(theme,background,seed)
	local cells=table.create(256,background)
	local function pixel(x,y,color)
		if x>=0 and x<16 and y>=0 and y<16 then cells[y*16+x+1]=color end
	end
	local function rect(x1,y1,x2,y2,color)
		for y=y1,y2 do for x=x1,x2 do pixel(x,y,color)end end
	end
	local function circle(cx,cy,r,color)
		for y=0,15 do for x=0,15 do if(x-cx)^2+(y-cy)^2<=r*r then pixel(x,y,color)end end end
	end
	local function line(x1,y1,x2,y2,color,width)
		local dx,dy=math.abs(x2-x1),-math.abs(y2-y1)
		local sx,sy=if x1<x2 then 1 else -1,if y1<y2 then 1 else -1
		local err=dx+dy
		while true do
			rect(x1,y1,x1+(width or 1)-1,y1+(width or 1)-1,color)
			if x1==x2 and y1==y2 then break end
			local e=2*err;if e>=dy then err+=dy;x1+=sx end;if e<=dx then err+=dx;y1+=sy end
		end
	end
	local function polygon(points,color)
		for y=0,15 do for x=0,15 do
			local inside=false;local previous=points[#points]
			for _,p in points do
				if (p[2]>y)~=(previous[2]>y)and x<(previous[1]-p[1])*(y-p[2])/(previous[2]-p[2])+p[1]then inside=not inside end
				previous=p
			end
			if inside then pixel(x,y,color)end
		end end
	end
	local function text(word,y,color)
		local start=math.floor((16-(#word*4-1))/2)
		for i=1,#word do for row,pattern in assert(font[word:sub(i,i)],"Missing pixel glyph")do
			for x=1,3 do if pattern:sub(x,x)=="1"then pixel(start+(i-1)*4+x-1,y+row-1,color)end end
		end end
	end
	-- A small border watermark varies with the draft while emblem colours stay recognisable.
	for i=0,15 do if (seed+i*13)%17<6 then pixel(i,0,{background[1]+12,background[2]+12,background[3]+12})end end
	local id=theme.id
	if theme.family=="Flags"then
		rect(1,3,14,12,white)
		if id=="uk"then
			rect(1,3,14,12,navy);line(1,3,13,11,white,2);line(1,11,13,3,white,2)
			line(1,3,14,12,red);line(1,12,14,3,red);rect(6,3,9,12,white);rect(1,6,14,9,white);rect(7,3,8,12,red);rect(1,7,14,8,red)
		elseif id=="usa"then
			rect(1,1,14,13,white);for y=1,13,2 do rect(1,y,14,y,red)end;rect(1,1,6,7,navy)
			for y=2,6,2 do for x=2,6,2 do pixel(x,y,white)end end
		elseif id=="france"or id=="italy"then rect(1,3,5,12,if id=="france"then blue else green);rect(10,3,14,12,red)
		elseif id=="germany"then rect(1,3,14,5,black);rect(1,6,14,8,red);rect(1,9,14,12,gold)
		elseif id=="japan"then circle(8,8,2,red)
		elseif id=="ukraine"then rect(1,3,14,7,blue);rect(1,8,14,12,gold)
		elseif id=="poland"then rect(1,8,14,12,red)
		elseif id=="spain"then rect(1,3,14,5,red);rect(1,6,14,9,gold);rect(1,10,14,12,red);rect(4,7,5,9,red)
		elseif id=="canada"then
			rect(1,3,4,12,red);rect(11,3,14,12,red)
			polygon({{8,4},{9,7},{11,6},{10,9},{8,10},{6,9},{5,6},{7,7}},red);line(8,8,8,11,red)
		elseif id=="brazil"then rect(1,3,14,12,green);polygon({{8,4},{14,8},{8,12},{2,8}},gold);circle(8,8,2,blue);line(6,7,9,8,white)
		elseif id=="india"then rect(1,3,14,5,{255,145,45});rect(1,10,14,12,green);circle(8,8,1,navy);pixel(8,8,white)
		elseif id=="china"then rect(1,3,14,12,red);polygon({{4,4},{5,6},{7,6},{5,7},{6,9},{4,8},{2,9},{3,7},{1,6},{3,6}},gold)
			for _,p in {{7,4},{8,5},{8,7},{7,9}}do pixel(p[1],p[2],gold)end
		elseif id=="eu"then rect(1,3,14,12,blue);for n=0,11 do local a=n*math.pi/6;pixel(math.floor(8+3*math.cos(a)+0.5),math.floor(8+3*math.sin(a)+0.5),gold)end
		end
	elseif id=="apple"then
		circle(6,8,3,white);circle(10,8,3,white);rect(4,8,12,10,white);rect(5,11,11,12,white);circle(13,6,2,background);line(8,4,10,2,white,2)
	elseif id=="microsoft"then rect(2,2,6,6,red);rect(9,2,13,6,green);rect(2,9,6,13,{45,160,245});rect(9,9,13,13,gold)
	elseif id=="google"then
		for y=1,14 do for x=1,14 do local d=(x-7.5)^2+(y-7.5)^2
			if d>=14 and d<=40 then pixel(x,y,if y<5 then red elseif x<5 then gold elseif y>10 then green else blue)end
		end end
		rect(10,4,14,6,background);rect(8,7,14,9,blue)
	elseif id=="youtube"then rect(2,4,13,11,red);rect(1,5,14,10,red);polygon({{6,5},{11,8},{6,11}},white)
	elseif id=="spotify"then circle(8,8,6,green);line(4,6,7,5,black);line(7,5,12,7,black);line(5,8,8,7,black);line(8,7,11,9,black);line(6,10,8,9,black);line(8,9,10,10,black)
	elseif id=="tesla"then rect(2,2,13,3,red);rect(4,4,11,5,red);rect(7,5,8,13,red);line(5,5,7,7,red);line(10,5,8,7,red)
	elseif id=="nike"then polygon({{2,8},{3,11},{5,12},{15,4},{5,9},{4,6}},white)
	elseif id=="adidas"then
		polygon({{2,10},{4,8},{7,13},{4,13}},white);polygon({{5,7},{7,5},{12,13},{9,13}},white);polygon({{8,4},{10,2},{16,13},{13,13}},white)
	elseif id=="nvidia"then
		polygon({{1,8},{6,3},{13,3},{15,8},{11,12},{5,12}},green);polygon({{4,8},{7,5},{12,6},{13,8},{10,10},{7,10}},black);circle(9,8,2,white);pixel(9,8,green)
	elseif id=="discord"then
		polygon({{4,4},{11,4},{14,11},{11,13},{9,11},{6,11},{4,13},{1,11}}, {105,112,245});rect(4,7,5,8,white);rect(10,7,11,8,white);line(5,10,10,10,white)
	elseif id=="github"then
		circle(8,8,5,white);polygon({{3,6},{3,1},{7,4}},white);polygon({{9,4},{13,1},{13,7}},white);rect(5,11,10,14,white);line(3,12,1,10,white);pixel(5,7,background);pixel(10,7,background)
	elseif id=="roblox"then polygon({{5,1},{15,5},{10,15},{0,10}},white);polygon({{7,6},{11,7},{9,11},{5,9}},background)
	elseif id=="nintendo"then rect(1,4,14,11,red);line(2,3,13,3,white);line(2,12,13,12,white);line(0,5,0,10,white);line(15,5,15,10,white);text("N",5,white)
	elseif id=="mcdonalds"then
		rect(1,1,14,14,red);line(3,12,3,6,gold);line(3,6,5,3,gold);line(5,3,8,12,gold);line(8,12,10,3,gold);line(10,3,12,6,gold);line(12,6,12,12,gold)
	elseif id=="dedsec"then
		rect(2,2,13,12,white);rect(1,5,14,9,white);rect(4,5,6,7,black);rect(9,5,11,7,black);polygon({{8,7},{6,10},{9,10}},black)
		for x=4,11,2 do rect(x,11,x,13,white);pixel(x,11,black)end
		line(0,4,4,4,green);line(11,9,15,9,green);pixel(2,10,red);pixel(13,3,red)
	elseif id=="anonymous"then
		circle(8,7,5,{240,224,190});rect(4,3,11,9,{240,224,190});rect(3,2,12,3,black);rect(5,0,10,2,black)
		line(4,5,6,6,black);line(9,6,11,5,black);pixel(5,7,black);pixel(10,7,black);line(5,9,7,10,black);line(8,10,10,9,black);polygon({{7,11},{9,11},{8,14}},black)
	elseif id=="lulzsec"then
		circle(8,9,5,white);rect(5,1,10,5,white);rect(6,2,9,5,black);rect(3,5,12,6,white);circle(10,9,2,blue);pixel(10,9,black);pixel(5,8,black);line(5,11,10,12,black)
	elseif id=="ccc"then
		text("CCC",5,green);line(1,2,6,2,green);line(6,2,6,4,green);line(14,10,14,13,green);line(8,13,14,13,green);pixel(1,1,white);pixel(8,13,white)
	elseif id=="nasa"then
		circle(8,8,7,blue);line(1,13,14,2,red,2);line(2,5,13,10,white);text("NASA",6,white);pixel(5,3,white);pixel(11,12,white)
	elseif id=="interpol"then
		circle(8,7,6,gold);circle(8,7,5,blue);line(3,7,13,7,gold);line(8,2,8,12,gold);line(5,3,5,11,gold);line(11,3,11,11,gold);rect(1,12,14,14,navy);text("IP",10,white)
	elseif theme.family=="Agencies"then
		local edge=if id=="mi6"then {60,215,180}elseif id=="nsa"then white else gold
		local fill=if id=="mi5"then {15,70,45}else navy
		polygon({{1,1},{15,1},{14,10},{8,15},{2,10}},edge);polygon({{3,3},{13,3},{12,10},{8,13},{4,10}},fill)
		text(id:upper(),5,edge)
	else error("Unknown artwork: "..tostring(id))end
	return cells
end
return Library

end)()

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
function Learner:choose(x,serial,allowed)
	features(x)
	local best,bestScore,bestMean=nil,-math.huge,0
	local offset=(serial or 0)%Learner.Arms
	for step=1,Learner.Arms do
		local i=(step+offset-1)%Learner.Arms+1
		if allowed and not allowed[i]then continue end
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
local Library=if script then __modules["PixelLibrary"]else __modules["PixelLibrary"]
local Art={Sets={"All","Original","Companies","Flags","Hackers","Agencies"}}
Art.Themes={
	{name="Cat",category="Animals",icon="🐱",code="CT"},
	{name="Rocket",category="Space",icon="🚀",code="RK"},
	{name="Robot",category="Robots",icon="🤖",code="RB"},
	{name="Donut",category="Food",icon="🍩",code="DN"},
	{name="Ghost",category="Fantasy",icon="🔮",code="GH"},
	{name="Alien",category="Gaming",icon="👾",code="AX"},
	{name="Flame",category="Internet",icon="🔥",code="FL"},
	{name="Balloon",category="Absurd",icon="🎈",code="BL"},
	{name="Pumpkin",category="Seasonal",icon="🎃",code="PK"},
}
for _,theme in Art.Themes do theme.family="Original";theme.id=theme.name:lower()end
for _,theme in Library.Themes do table.insert(Art.Themes,theme)end
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
function Art.find(value)
	if type(value)~="string"then return nil end
	local key=value:lower():gsub("[%s_%-]","")
	if key=="deadsec"then key="dedsec"end
	for i,theme in Art.Themes do if theme.id==key or theme.name:lower():gsub("[%s_%-]","")==key then return i end end
	return nil
end
function Art.draft(arm,serial,seed,category,options)
	local shape=1+(arm-1)%6
	local rng=random(seed+serial*7919)
	if options then
		local set=options.ArtSet or "All"
		assert(table.find(Art.Sets,set),"Choose All, Original, Companies, Flags, Hackers or Agencies")
		local forced=if options.ArtTheme then assert(Art.find(options.ArtTheme),"Unknown ArtTheme")else nil
		local candidates={}
		for i,theme in Art.Themes do
			if forced then
				if i==forced then table.insert(candidates,i)end
			elseif(set=="All"or theme.family==set)and(not category or theme.category==category)then table.insert(candidates,i)end
		end
		-- An explicit art set still works when the current trend belongs to a different set.
		if #candidates==0 and not options.ArtTheme then
			for i,theme in Art.Themes do if set=="All"or theme.family==set then table.insert(candidates,i)end end
		end
		assert(#candidates>0,"Unknown ArtTheme")
		shape=candidates[1+(serial+arm+rng(#candidates)-1)%#candidates]
	elseif category then for i,theme in Art.Themes do if theme.category==category then shape=i;break end end end
	local theme=Art.Themes[shape]
	local palette=rng(#palettes)
	return {serial=serial,seed=seed+serial*7919,shape=shape,palette=palette,
		name=adjectives[rng(#adjectives)].." "..theme.name.." "..base36(serial,3),
		ticker=theme.code..base36(serial,3)..base36(rng(46656)-1,3),category=theme.category,icon=theme.icon,
		description=if theme.family=="Original"then "Original "..theme.name:lower().." pixel art for the in-game market."else theme.name.." pixel fan art for the in-game market. Unofficial artwork."}
end
local function inside(shape,x,y)
	if shape==7 then return y>=2 and y<=14 and math.abs(x-7.5)<=math.min(5,(y-1)*0.6) and not(x<7 and y<6)
	elseif shape==8 then return (x-7.5)^2/24+(y-6)^2/30<=1 or (x==8 and y>=11 and y<=15)
	elseif shape==9 then return ((x-7.5)^2/35+(y-8)^2/25<=1)or(x>=7 and x<=8 and y>=1 and y<=4)
	elseif shape==1 then
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
	assert(type(draft)=="table" and type(draft.shape)=="number" and draft.shape>=1 and draft.shape<=#Art.Themes and draft.shape%1==0,"Invalid artwork theme")
	local palette=assert(palettes[draft.palette],"Invalid artwork palette")
	local seed=math.floor(draft.seed or 1)
	local rgba=buffer.create(4096)
	local cells={}
	local custom=if draft.shape>9 then Library.draw(Art.Themes[draft.shape],palette[1],seed)else nil
	for y=0,15 do for x=0,15 do
		local color=custom and custom[y*16+x+1]or palette[1]
		if not custom then
		local fill=inside(draft.shape,x,y)
		local outline=not fill and (inside(draft.shape,x-1,y) or inside(draft.shape,x+1,y) or inside(draft.shape,x,y-1) or inside(draft.shape,x,y+1))
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
		end
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

__modules["Trends"]=(function()
-- Treat game posts as data: the only output is a known category name.
local Trends={}
local words={Animals={"animal","cat","frog","dog","shiba"},Space={"space","rocket","moon","cosmic","planet"},
	Food={"food","donut","pizza","burger"},Gaming={"gaming","game","pixel","arcade"},Fantasy={"fantasy","dragon","wizard","ghost"},
	Robots={"robot","robots","droid","circuit"},Internet={"internet","meme","memes","company","companies","hacker","hackers","dedsec","deadsec","anonymous","agency","agencies","fbi","cia","nsa"},
	Absurd={"absurd","balloon","spoon","toaster"},Seasonal={"seasonal","pumpkin","halloween","christmas","snow","flag","flags"}}
function Trends.choose(signals,now)
	local scores={}
	for i,item in signals do
		if i>100 then break end
		local text=type(item.text)=="string" and item.text:sub(1,1000):lower()or ""
		local age=math.max(0,now-(item.at or now))
		local bad=text:find("not trending",1,true)or text:find("no longer",1,true)or text:find("avoid",1,true)or text:find("%f[%a]dead%f[%A]")
		if age<=900 and not bad then
			local hot=text:find("trending",1,true)or text:find("hot",1,true)or text:find("meta",1,true)or text:find("viral",1,true)or text:find("pumping",1,true)
			for category,terms in words do
				local hit=item.category==category or text:find("%f[%a]"..category:lower().."%f[%A]")~=nil
				for _,word in terms do if text:find("%f[%a]"..word.."%f[%A]")then hit=true;break end end
				if hit then scores[category]=(scores[category]or 0)+(if item.official then 8 elseif hot then 4 else 0.3)*math.exp(-age/300)end
			end
		end
	end
	local best,score=nil,0
	for category,value in scores do if value>score then best,score=category,value end end
	return best,score
end
return Trends

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

__modules["RemoteAdapter"]=(function()
-- Uses the game's ordinary remote protocol. No game ModuleScript is imported.
local Trends=if script then __modules["Trends"]else __modules["Trends"]
local Adapter={PlaceId=138310989671326}
Adapter.__index=Adapter
local phases={"Launch","Graduated","Rugged"}
local fields={[2]="price",[3]="mcap",[4]="change",[5]="volume",[6]="holders",[7]="progress",[9]="heat",[10]="liquidity",
	[11]="social",[12]="mentions",[13]="activity",[14]="views",[16]="ath",[17]="ruggedAt",[18]="change5m",
	[19]="buzz",[20]="creatorRep",[21]="logo",[22]="devFees",[23]="topShare",[24]="creatorShare"}
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<1e100 end
function Adapter.new(player,services)
	return setmetatable({player=player,services=services,connections={},coins={},posts={},signals={},seenPosts={},
		pendingRows={},pendingSize=0,removed={},
		coinVersions={},postVersions={},revision=0,postRevision=0,accountRevision=0,nextAccount=0,nextSnapshot=0,nextFeed=0,ready=false,destroyed=false,
		profile=services.profile or {}},Adapter)
end
function Adapter:_wake()if not self.destroyed and self.services.onChange then self.services.onChange()end end
function Adapter:_call(name,...)
	assert(not self.destroyed,"Adapter unloaded")
	local remote=self.root and self.root:FindFirstChild(name)
	assert(remote and remote:IsA("RemoteFunction"),"Waiting for Remotes."..name.." RemoteFunction")
	return remote:InvokeServer(...)
end
function Adapter:_row(coin,row)
	if type(row)~="table"then return end
	coin.prevPrice=coin.price
	for index,key in fields do if finite(row[index])then coin[key]=row[index]end end
	coin.phase=phases[row[8]]or coin.phase
	if finite(row[15])then coin.boostedUntil=row[15]end
end
function Adapter:_fast(coin,row)
	coin.prevPrice=coin.price
	for index,key in {[2]="price",[3]="mcap",[4]="change",[5]="heat",[6]="change5m"}do
		if finite(row[index])then coin[key]=row[index]end
	end
end
function Adapter:_dropPending(id)
	if self.pendingRows[id]then self.pendingRows[id]=nil;self.pendingSize-=1 end
end
function Adapter:_queue(id,row,full)
	local pending=self.pendingRows[id]
	if not pending then
		if self.pendingSize>=256 then
			local oldest,revision=nil,math.huge
			for key,item in self.pendingRows do if item.revision<revision then oldest,revision=key,item.revision end end
			if oldest then self:_dropPending(oldest)end
		end
		pending={};self.pendingRows[id]=pending;self.pendingSize+=1
	end
	pending.revision=self.revision+1
	if full then pending.full=table.clone(row);pending.fast=nil else pending.fast=table.clone(row)end
end
function Adapter:_coin(value,mergePending)
	if type(value)~="table"or value.id==nil then return end
	local id=tostring(value.id)
	local coin=table.clone(value);coin.id=id
	self:_row(coin,value.row)
	local pending=mergePending and self.pendingRows[id]
	if pending then
		if pending.full then self:_row(coin,pending.full)end
		if pending.fast then self:_fast(coin,pending.fast)end
	end
	self.coins[id]=coin
	self.removed[id]=nil;self:_dropPending(id);self:_sample(id)
	return id
end
function Adapter:_bind(name,fn)
	local event=self.root:FindFirstChild(name)
	if event and event:IsA("RemoteEvent")then
		table.insert(self.connections,event.OnClientEvent:Connect(function(...)
			if self.destroyed then return end
			fn(...);self:_wake()
		end))
	end
end
function Adapter:connect()
	if self.root then return true end
	local root=self.services.storage:FindFirstChild("Remotes")
	if not root then return false,"Waiting for ReplicatedStorage.Remotes" end
	for _,name in {"GetAccount","GetSnapshot","GetFeed","RequestCreateCoin","RequestBuy","RequestSell","RequestCreatePost"}do
		local value=root:FindFirstChild(name)
		if not value or not value:IsA("RemoteFunction")then return false,"Waiting for Remotes."..name end
	end
	self.root=root
	self:_bind("AccountUpdate",function(value)
		if type(value)=="table"then self.account=value;self.accountRevision+=1;self:_sample(self.watchedId)end
	end)
	self:_bind("CoinAdded",function(value)
		local id=self:_coin(value)
		if id then self.revision+=1;self.coinVersions[id]=self.revision end
	end)
	self:_bind("CoinRemoved",function(value)
		local id=tostring(value);self.coins[id]=nil;self.revision+=1;self.coinVersions[id]=self.revision
		self.removed[id]=true;self:_dropPending(id)
		if self.watchedId==id then self.observations=nil end
	end)
	self:_bind("MarketTick",function(_,rows,full)
		if type(rows)~="table"then return end
		for _,row in rows do
			if type(row)=="table"and row[1]~=nil then
				local id=tostring(row[1]);local coin=self.coins[id]
				if not coin and self.removed[id]then continue end
				if coin then
					if full then self:_row(coin,row)else self:_fast(coin,row)end
					self:_sample(id)
				else self:_queue(id,row,full)end
				self.revision+=1;self.coinVersions[id]=self.revision
			end
		end
	end)
	self:_bind("PostAdded",function(post)
		if type(post)=="table"and post.id then
			local id=tostring(post.id);self.posts[id]=post;self.postRevision+=1;self.postVersions[id]=self.postRevision
		end
	end)
	self:_bind("PostRemoved",function(value)
		local id=tostring(value);self.posts[id]=nil;self.seenPosts[id]=nil;self.postRevision+=1;self.postVersions[id]=self.postRevision
	end)
	self:_bind("MarketEvent",function(value)
		if type(value)=="table"and type(value.text)=="string"then
			table.insert(self.signals,1,{text=value.text,category=value.category,at=self.services.now(),official=true})
			if #self.signals>40 then table.remove(self.signals)end
		end
	end)
	return true
end
function Adapter:_refresh(now)
	if not self.account or now>=self.nextAccount then
		self.nextAccount=now+10
		local revision=self.accountRevision
		local value=self:_call("GetAccount")
		if self.destroyed then return end
		if revision==self.accountRevision and type(value)=="table"then self.account=value end
	end
	if not self.ready or now>=self.nextSnapshot then
		self.nextSnapshot=now+30
		local revision=self.revision
		local value=self:_call("GetSnapshot")
		if self.destroyed then return end
		if type(value)=="table"and type(value.coins)=="table"then
			local found={}
			for _,coin in value.coins do
				if type(coin)=="table"and coin.id~=nil then
					local id=tostring(coin.id);found[id]=true
					if (self.coinVersions[id]or 0)<=revision then self:_coin(coin)
					elseif not self.coins[id]and not self.removed[id]then self:_coin(coin,true)end
				end
			end
			for id in self.coins do if not found[id]and(self.coinVersions[id]or 0)<=revision then self.coins[id]=nil end end
			self.ready=true
		end
	end
	if now>=self.nextFeed then
		self.nextFeed=now+30
		local revision=self.postRevision
		local ok,rows=pcall(function()return self:_call("GetFeed","latest")end)
		if self.destroyed then return end
		if ok and type(rows)=="table"then
			local found={}
			for _,post in rows do if type(post)=="table"and post.id then
				local id=tostring(post.id);found[id]=true
				if(self.postVersions[id]or 0)<=revision then self.posts[id]=post end
			end end
			for id in self.posts do if not found[id]and(self.postVersions[id]or 0)<=revision then self.posts[id]=nil;self.seenPosts[id]=nil end end
		end
	end
end
function Adapter:_fee(network)
	local base=if network=="ethera"then (self.profile.EtheraFee or 0.02)else(self.profile.SolaraFee or 0.01)
	return base*(if self.account and self.account.passes and self.account.passes.ProTrader then 0.5 else 1)
end
function Adapter:snapshot(network)
	local ok,why=self:connect();if not ok then return nil,why end
	local now=self.services.now();self:_refresh(now)
	if self.destroyed then return nil,"Unloaded" end
	local account=self.account
	if type(account)~="table"or account.id==nil or not finite(account.balance)or not self.ready then return nil,"Waiting for account and market remote responses" end
	network=network or "solara";assert(network=="solara"or network=="ethera","Use solara or ethera")
	local signals=table.clone(self.signals);local count=0
	for id,post in self.posts do
		if count>=60 then break end
		if type(post.text)=="string"and tostring(post.authorId or post.userId or post.creatorId or "")~=tostring(account.id)then
			self.seenPosts[id]=self.seenPosts[id]or now
			table.insert(signals,{text=post.text,at=tonumber(post.createdAt or post.t)or self.seenPosts[id]});count+=1
		end
	end
	local owned,total,heat,change,volume,holders=0,0,0,0,0,0
	for _,coin in self.coins do if coin.phase~="Rugged"then
		total+=1;if tostring(coin.creatorId)==tostring(account.id)then owned+=1 end
		heat+=if finite(coin.heat)then coin.heat else 0
		change+=if finite(coin.change5m)then coin.change5m else 0
		volume+=if finite(coin.volume)then math.max(0,coin.volume)else 0
		holders+=if finite(coin.holders)then math.max(0,coin.holders)else 0
	end end
	local d=math.max(1,total)
	return {now=now,account=account,coins=self.coins,network=network,trend=Trends.choose(signals,now),tradeFee=self:_fee(network),
		cost=if account.passes and account.passes.CreatorPro then 0 elseif network=="ethera"then(self.profile.EtheraLaunchCost or 600)else(self.profile.SolaraLaunchCost or 250),
		cooldown=if account.passes and account.passes.CreatorPro then(self.profile.ProCreatorCooldown or 15)else(self.profile.CreationCooldown or 60),
		postCooldown=self.profile.PostCooldown or 8,chatCooldown=self.profile.ChatCooldown or 1.5,postMax=280,chatMax=200,
		owned=owned,total=total,features={1,math.min(1,math.log(1+math.max(0,account.balance))/math.log(10000001)),math.min(1,owned/6),
			math.min(1,total/150),math.tanh(heat/d/10),math.tanh(change/d),math.min(1,math.log(1+volume/d)/math.log(10000001)),math.min(1,math.log(1+holders/d)/math.log(10001))}}
end
function Adapter:position(id)return self.account and self.account.positions and self.account.positions[id]end
function Adapter:_reserves(id)
	local c=assert(self.coins[id],"Waiting for coin quote")
	assert(finite(c.liquidity)and c.liquidity>0 and finite(c.price)and c.price>0,"Waiting for a valid coin reserve quote")
	return c.liquidity,c.liquidity/c.price,c.network
end
function Adapter:value(id)
	local p=self:position(id)
	if not p or not finite(p.tokens)or p.tokens<=0 then return 0 end
	local cash,tokens,network=self:_reserves(id)
	return cash*p.tokens/(tokens+p.tokens)*(1-self:_fee(network))
end
function Adapter:watch(id)
	if id==nil then self.watchedId=nil;self.observations=nil;return end
	id=tostring(id)
	if self.watchedId==id then return end
	self.watchedId=id;self.observations=nil;self:_sample(id)
end
function Adapter:_sample(id)
	if not id or id~=self.watchedId or self.destroyed then return end
	local p=self:position(id)
	if not p or not finite(p.tokens)or p.tokens<=0 then self.observations=nil;return end
	local ok,value=pcall(self.value,self,id)
	if not ok or not finite(value)or value<0 then return end
	local now=self.services.now();if not finite(now)then return end
	local q=self.observations
	if not q or q.tokens~=p.tokens then q={tokens=p.tokens,peak=value,peakAt=now,count=0};self.observations=q end
	if value>q.peak then q.peak=value;q.peakAt=now end
	q.latest,q.latestAt=value,now;q.count=math.min(q.count+1,1000000)
end
function Adapter:takeObservations(id)
	if self.watchedId~=id then return nil end
	local q=self.observations;self.observations=nil
	local p=self:position(id)
	return if q and p and q.tokens==p.tokens then q else nil
end
function Adapter:_slippage()
	local value=self.account and self.account.prefs and self.account.prefs.Slippage
	return if finite(value)then value else(self.profile.DefaultSlippage or 0.05)
end
function Adapter:create(payload)
	assert(typeof(payload.Logo)=="buffer"and buffer.len(payload.Logo)==4096,"Expected a 32x32 RGBA logo")
	assert(type(payload.Name)=="string"and #payload.Name>=2 and #payload.Name<=24,"Invalid coin name")
	assert(type(payload.Ticker)=="string"and #payload.Ticker>=2 and #payload.Ticker<=8 and payload.Ticker:match("^[A-Z0-9]+$"),"Invalid ticker")
	return self:_call("RequestCreateCoin",payload)
end
function Adapter:buy(id,amount)
	local cash,tokens=self:_reserves(id)
	return self:_call("RequestBuy",id,amount,tokens*amount/(cash+amount),self:_slippage())
end
function Adapter:sell(id)return self:_call("RequestSell",id,{fraction=1},self:value(id),self:_slippage())end
function Adapter:post(text)
	local result=self:_call("RequestCreatePost",text,nil)
	if type(result)=="table"and result.ok and type(result.post)=="table"and result.post.id then self.posts[tostring(result.post.id)]=result.post end
	return result
end
function Adapter:chat(text)
	local channels=self.services.chat:FindFirstChild("TextChannels")
	local channel=channels and channels:FindFirstChild("RBXGeneral")
	if not channel then return {ok=false,error="Chat unavailable"}end
	local result=channel:SendAsync(text)
	if not result or result.Status~=Enum.TextChatMessageStatus.Success then return {ok=false,error="Chat was not accepted"}end
	if self.destroyed then return {ok=true}end
	local relay=self.root:FindFirstChild("ChatRelay")
	assert(relay and relay:IsA("RemoteEvent"),"ChatRelay is unavailable")
	relay:FireServer(text);return {ok=true}
end
function Adapter:destroy()
	self.destroyed=true
	self:watch(nil);table.clear(self.pendingRows);self.pendingSize=0
	for _,connection in self.connections do connection:Disconnect()end
	table.clear(self.connections)
end
return Adapter

end)()

__modules["ExitPolicy"]=(function()
-- Reactive rules for a simulated market; observations do not predict random events.
local Policy={}
local function finite(v)return type(v)=="number"and v==v and math.abs(v)<1e100 end
function Policy.configure(c)
	c.ExitMode=c.ExitMode or "adaptive"
	assert(c.ExitMode=="adaptive"or c.ExitMode=="fixed","ExitMode must be adaptive or fixed")
	for key,default in {CrashDrop=0.20,CrashWindow=5,SellRetrySeconds=2}do if c[key]==nil then c[key]=default end end
	for _,key in {"CrashDrop","TrailDrawdown"}do if c[key]~=nil then assert(finite(c[key])and c[key]>0 and c[key]<1,"Invalid "..key)end end
	for _,key in {"CrashWindow","PumpStallSeconds","MaxHoldSeconds","CashOutValue","SellRetrySeconds"}do
		if c[key]~=nil then assert(finite(c[key])and c[key]>0 and c[key]<1e12,"Invalid "..key)end
	end
	assert(c.SellRetrySeconds>=1 and c.SellRetrySeconds<=60,"SellRetrySeconds must be between 1 and 60")
	if c.PumpMultiple~=nil then assert(finite(c.PumpMultiple)and c.PumpMultiple>=1 and c.PumpMultiple<1e6,"Invalid PumpMultiple")end
end
function Policy.evaluate(r,c,now,value,observed)
	assert(finite(now)and finite(value)and value>=0 and finite(r.buyCost)and r.buyCost>0,"Invalid risk observation")
	local cost=r.buyCost;local patient=r.arm>6
	local target=cost*(c.PumpMultiple or(if patient then 1.65 else 1.35))
	local previousValue,previousAt=r.lastValue,r.lastValueAt
	local oldPeak=r.peak or 0
	local observedPeak=observed and finite(observed.peak)and finite(observed.peakAt)and observed.peakAt<=now and observed.peak>=0
	if observedPeak then
		if observed.peak>(r.peak or 0)then r.peak=observed.peak end
		if observed.peak>=(r.momentumHigh or oldPeak)*1.01 then r.momentumHigh=observed.peak;r.lastHighAt=observed.peakAt end
	end
	r.peak=math.max(r.peak or oldPeak,value)
	r.lastHighAt=r.lastHighAt or now
	if value>=(r.momentumHigh or oldPeak)*1.01 then r.momentumHigh=value;r.lastHighAt=now end
	r.lastValue,r.lastValueAt=value,now
	local trail=c.TrailDrawdown or(if patient then 0.12 else 0.08)
	if r.peak>=cost*100 then trail=math.min(trail,0.03)elseif r.peak>=cost*10 then trail=math.min(trail,0.05)end
	local age=math.max(0,now-(r.boughtAt or r.startedAt))
	local reason=nil
	if c.CashOutValue and value>=c.CashOutValue then reason="Cash-out value"
	elseif finite(previousValue)and previousValue>0 and finite(previousAt)and now>previousAt and now-previousAt<=c.CrashWindow
		and value<=previousValue*(1-c.CrashDrop)then reason="Sudden crash"
	elseif observedPeak and now>observed.peakAt and now-observed.peakAt<=c.CrashWindow and value<=observed.peak*(1-c.CrashDrop)then reason="Sudden crash"
	elseif value<=cost*(1-c.StopLoss)then reason="Stop loss"
	elseif r.peak>=cost*1.15 and value<=r.peak*(1-trail)then reason="Trailing pump exit"
	elseif age>=c.MinHoldSeconds then
		if age>=(c.MaxHoldSeconds or(if patient then 480 else 300))then reason="Maximum hold"
		elseif c.ExitMode=="fixed"and value>=target then reason="Pump target"
		elseif c.ExitMode=="adaptive"and r.peak>=target and now-r.lastHighAt>=(c.PumpStallSeconds or(if patient then 15 else 8))then reason="Pump stalled"end
	end
	return {reason=reason,target=target,trail=trail,age=age,peak=r.peak}
end
return Policy

end)()

__modules["PumpEngine"]=(function()
-- Simulated launch -> 2,000 dev buy -> trend/pump watch -> normal sell -> repeat.
local Learner=if script then __modules["Learner"]else __modules["Learner"]
local Art=if script then __modules["Art"]else __modules["Art"]
local ExitPolicy=if script then __modules["ExitPolicy"]else __modules["ExitPolicy"]
local Engine={Schema=2,PlaceId=138310989671326}
Engine.__index=Engine
local function finite(v)return type(v)=="number"and v==v and math.abs(v)<1e100 end
local function owns(c,s)return c and tostring(c.creatorId)==tostring(s.account.id)end
local function unknown(r)
	return type(r)~="table"or type(r.ok)~="boolean"or(type(r.error)=="string"and r.error:lower():find("reach the server",1,true)~=nil)
end
local function positionTokens(p)return if p and finite(p.tokens)then math.max(0,p.tokens)else 0 end
function Engine.validate(saved,userId)
	assert(type(saved)=="table"and saved.schema==2 and saved.userId==userId and saved.placeId==Engine.PlaceId,"Use the separate pump-learning StateFile for this strategy")
	Learner.new(saved.model)
	local s=saved.state
	assert(type(s)=="table"and finite(s.serial)and s.serial>=0 and s.serial%1==0 and finite(s.nextLaunchAt),"Invalid workflow")
	assert(type(s.stats)=="table"and type(s.history)=="table"and #s.history<=30 and type(s.artHistory)=="table"and #s.artHistory<=64,"Invalid history")
	if s.settings then
		assert(type(s.settings)=="table","Invalid settings")
		assert(s.settings.artSet==nil or table.find(Art.Sets,s.settings.artSet),"Invalid saved art set")
		assert(s.settings.artTheme==nil or Art.find(s.settings.artTheme),"Invalid saved art theme")
	end
	for _,key in {"launches","posts","chats","completed","buys","sells"}do assert(finite(s.stats[key])and s.stats[key]>=0,"Invalid count")end
	if s.round then
		local r=s.round;local d=r.draft
		assert(type(d)=="table"and finite(d.shape)and d.shape%1==0 and Art.Themes[d.shape]and finite(d.seed)and finite(d.palette)and d.palette%1==0 and d.palette>=1 and d.palette<=6,"Invalid draft")
		assert(type(d.ticker)=="string"and #d.ticker<=8 and d.ticker:match("^[A-Z0-9]+$")and type(d.name)=="string"and #d.name<=24,"Invalid coin metadata")
		assert(d.category==Art.Themes[d.shape].category and d.icon==Art.Themes[d.shape].icon and type(d.description)=="string"and #d.description<=200,"Invalid category")
		assert(finite(r.arm)and r.arm%1==0 and r.arm>=1 and r.arm<=12 and type(r.features)=="table"and #r.features==8,"Invalid campaign")
		for _,v in r.features do assert(finite(v)and math.abs(v)<=2,"Invalid feature")end
		for _,key in {"walletStart","startedAt","cost","buyQuote","nextPostAt","nextChatAt","posts","chats"}do assert(finite(r[key]),"Invalid campaign field: "..key)end
		assert(r.network=="solara"or r.network=="ethera","Invalid chain")
		for _,key in {"peak","lastValue","lastValueAt","lastHighAt","momentumHigh","nextRiskSaveAt"}do
			if r[key]~=nil then assert(finite(r[key])and r[key]>=0,"Invalid risk checkpoint: "..key)end
		end
	end
	if s.pending then assert(s.round and ({create=true,buy=true,sell=true})[s.pending.kind]and finite(s.pending.at),"Invalid pending action")end
end
function Engine.new(o)
	local c=o.config or {}
	for k,v in {BuyAmount=2000,ReserveBalance=0,PostEvery=35,ChatEvery=45,MaxPostsPerCoin=4,MaxChatsPerCoin=3,MinHoldSeconds=10,StopLoss=0.25}do
		if c[k]==nil then c[k]=v end;assert(finite(c[k])and c[k]>=0 and c[k]<1e9,"Invalid option: "..k)
	end
	assert(c.BuyAmount>0 and c.StopLoss<1 and c.MaxPostsPerCoin<=20 and c.MaxChatsPerCoin<=20,"Invalid limits")
	ExitPolicy.configure(c)
	local self=setmetatable({config=c,adapter=o.adapter,save=o.save,userId=o.userId,enabled=false,stopped=false,
		learner=Learner.new(o.saved and o.saved.model,c.Exploration),code="PAUSED",detail="Ready for a trend-led pump campaign."},Engine)
	if o.saved then Engine.validate(o.saved,o.userId)end
	self.state=o.saved and o.saved.state or {serial=0,nextLaunchAt=0,history={},artHistory={},stats={launches=0,posts=0,chats=0,completed=0,buys=0,sells=0}}
	local settings=self.state.settings or {posts=true,chat=true}
	c.ArtSet=c.ArtSet or settings.artSet or "All"
	c.ArtTheme=c.ArtTheme or settings.artTheme
	assert(table.find(Art.Sets,c.ArtSet),"Invalid ArtSet")
	assert(c.ArtTheme==nil or Art.find(c.ArtTheme),"Invalid ArtTheme")
	c.PostsEnabled=if c.PostsEnabled==nil then settings.posts else c.PostsEnabled~=false
	c.ChatEnabled=if c.ChatEnabled==nil then settings.chat else c.ChatEnabled~=false
	return self
end
function Engine:export()
	self.state.settings={posts=self.config.PostsEnabled,chat=self.config.ChatEnabled,artSet=self.config.ArtSet,artTheme=self.config.ArtTheme}
	return {schema=2,placeId=Engine.PlaceId,userId=self.userId,model=self.learner:export(),state=self.state}
end
function Engine:persist()self.save(self:export())end
function Engine:status(a,b)self.code,self.detail=a,b end
function Engine:pause(text)self.enabled=false;self:status("PAUSED",text or "Paused; the campaign is saved.")end
function Engine:setEnabled(value)assert(not self.stopped,"Unloaded");self.enabled=value==true;if not value then self:pause()end end
function Engine:refresh()
	local network=self.state.round and self.state.round.network or self.config.Network or(if self.state.serial%2==0 then "solara"else "ethera")
	local s,why=self.adapter:snapshot(network);self.snapshot=s
	if not s then self:status("CONNECTING",why)end;return s
end
function Engine:_draft(s)
	local allowed=nil
	for i,theme in Art.Themes do if theme.category==s.trend and i<=6 then allowed={[i]=true,[i+6]=true};break end end
	local arm=self.learner:choose(s.features,self.state.serial+1,allowed)
	return Art.draft(arm,self.state.serial+1,math.floor(s.now)+self.userId%2147483647,s.trend,{ArtSet=self.config.ArtSet,ArtTheme=self.config.ArtTheme}),arm
end
function Engine:preview(s)
	if self.state.round then return self.state.round.draft,self.state.round.arm end
	s=s or self.snapshot;if s then return self:_draft(s)end
end
function Engine:_intent(kind,s)
	self.state.pending={kind=kind,at=s.now,balanceBefore=s.account.balance,tokensBefore=positionTokens(self.adapter:position(self.state.round.coinId)),ack=false}
	local ok,why=pcall(function()self:persist()end)
	if not ok then self.state.pending=nil;error(why)end
	if not self.enabled or self.stopped then self.state.pending=nil;self:persist();return false end
	return true
end
function Engine:_attached(id,s,devError)
	local r=self.state.round;r.coinId=tostring(id);r.phase="entry";r.devFailed=devError~=nil;r.confirmBy=s.now+30
	self.state.pending=nil;self.state.stats.launches+=1;self.state.nextLaunchAt=s.now+s.cooldown
	table.insert(self.state.artHistory,1,Art.signature(Art.draw(r.draft)));if #self.state.artHistory>64 then table.remove(self.state.artHistory)end
	self:persist();self:status("LAUNCHED","$"..r.draft.ticker.." on "..r.network.."; confirming the 2,000 buy.")
end
function Engine:_holding(s)
	local r=self.state.round
	r.phase="holding";r.buyCost=r.buyQuote;r.boughtAt=s.now;r.peak=0
	r.lastValue,r.lastValueAt,r.lastHighAt=r.buyCost,s.now,s.now
	if self.adapter.watch then self.adapter:watch(r.coinId)end
	self.state.stats.buys+=1;self.state.pending=nil;self:persist()
	self:status("BOUGHT","2,000 entry confirmed for $"..r.draft.ticker..". Watching net sell value.")
end
function Engine:_finished(s,confirmed,reason)
	local r=self.state.round
	if self.adapter.watch then self.adapter:watch(nil)end
	local net=s.account.balance-r.walletStart
	local age=math.max(1,s.now-r.startedAt)
	if confirmed then self.learner:update(r.arm,r.features,math.tanh(net/1000/math.max(1,age/120)));self.state.stats.sells+=1 end
	table.insert(self.state.history,1,{ticker=r.draft.ticker,network=r.network,category=r.draft.category,net=net,learned=confirmed,reason=reason,at=s.now})
	if #self.state.history>30 then table.remove(self.state.history)end
	self.state.stats.completed+=1;self.state.round,self.state.pending=nil,nil;self.pumpMetrics=nil
	self:persist();self:status("ROUND COMPLETE",string.format("%s · observed balance change %.0f. Next launch follows cooldown.",reason,net))
end
function Engine:_reconcile(s)
	local p,r=self.state.pending,self.state.round
	if p.kind=="create"then
		for id,c in s.coins do if owns(c,s)and c.ticker==r.draft.ticker then self:_attached(id,s,nil);return end end
	elseif p.kind=="buy"and positionTokens(self.adapter:position(r.coinId))>(p.tokensBefore or 0)then self:_holding(s);return
	elseif p.kind=="sell"and positionTokens(self.adapter:position(r.coinId))<=1e-6 then
		if p.ack and s.now>=(p.settleAfter or p.at+1)and (s.account.balance~=p.balanceBefore or s.now-p.at>=5)then self:_finished(s,true,r.exitReason or "Position sold");return end
		if not p.ack then self:_finished(s,false,"Position closed; response unconfirmed");return end
		self:status("SETTLING","Waiting for the position and balance updates.");return
	end
	if p.ack and s.now-p.at<30 then self:status("SETTLING","Waiting for the game's trade update.");return end
	self:pause("The previous "..p.kind.." outcome is unconfirmed. It will not be submitted twice.")
end
function Engine:_create(s)
	if s.now<self.state.nextLaunchAt then self:status("COOLDOWN",string.format("Next launch in %.0fs",self.state.nextLaunchAt-s.now));return end
	local buy=self.config.BuyAmount*(1+s.tradeFee)
	local needed=s.cost+buy+self.config.ReserveBalance
	if s.account.balance<needed then self:status("WAITING FOR BALANCE",string.format("Have %.0f; need %.0f = launch %.0f + buy %.0f including fee + reserve %.0f.",s.account.balance,needed,s.cost,buy,self.config.ReserveBalance));return end
	local draft,arm=self:_draft(s)
	for n=1,40 do
		local duplicate=false
		for _,coin in s.coins do if coin.ticker==draft.ticker then duplicate=true;break end end
		if not duplicate and not table.find(self.state.artHistory,Art.signature(Art.draw(draft)))then break end
		self.state.serial+=1;draft=Art.draft(arm,self.state.serial+1,math.floor(s.now)+n*997,s.trend,{ArtSet=self.config.ArtSet,ArtTheme=self.config.ArtTheme});assert(n<40,"Draft allocation failed")
	end
	self.state.serial+=1
	self.state.round={draft=draft,arm=arm,features=table.clone(s.features),network=s.network,trend=s.trend,walletStart=s.account.balance,
		cost=s.cost,buyQuote=buy,startedAt=s.now,nextPostAt=s.now,nextChatAt=s.now+12,posts=0,chats=0,phase="create"}
	if not self:_intent("create",s)then self.state.round=nil;return end
	local payload=Art.payload(draft,s.network);payload.DevBuy=self.config.BuyAmount
	self:status("CREATING","Creating $"..draft.ticker.." · "..draft.category.." · "..s.network.." · 2,000 dev buy")
	local result=self.adapter:create(payload)
	if unknown(result)then self:pause("Launch outcome unconfirmed; checkpoint saved.");return end
	if result.ok then assert(result.coinId,"Missing created coin ID");self:_attached(result.coinId,s,result.devError)
	else self.state.round,self.state.pending=nil,nil;self.state.nextLaunchAt=s.now+math.max(15,s.cooldown);self:persist();self:status("LAUNCH DECLINED",tostring(result.error))end
end
function Engine:step()
	if not self.enabled or self.stopped then return end
	local s=self:refresh();if not s or not self.enabled or self.stopped then return end
	if self.state.pending then self:_reconcile(s);return end
	if not self.state.round then self:_create(s);return end
	local r=self.state.round;local c=s.coins[r.coinId]
	if not c then self:status("CONNECTING COIN","Waiting for the tracked coin in this server.");return end
	assert(owns(c,s)and c.ticker==r.draft.ticker,"Tracked coin ownership changed")
	local p=self.adapter:position(r.coinId)
	if c.phase=="Rugged"then self:_finished(s,false,"Coin was rugged");return end
	if r.phase=="entry"then
		if positionTokens(p)>0 and finite(p.cost)and p.cost>0 then self:_holding(s);return end
		if r.devFailed then
			if s.now<(r.retryAt or 0)then return end
			if s.account.balance<r.buyQuote then self:status("WAITING FOR BALANCE","Launch succeeded; 2,000 plus buy fee is still needed.");return end
			if not self:_intent("buy",s)then return end
			local result=self.adapter:buy(r.coinId,self.config.BuyAmount)
			if unknown(result)then self:pause("Buy outcome unconfirmed; it will not be repeated.");return end
			if result.ok then self.state.pending.ack=true;self:persist()
			else self.state.pending=nil;r.retryAt=s.now+15;self:persist();self:status("BUY DECLINED",tostring(result.error))end
		elseif s.now>r.confirmBy then self:pause("Launch returned, but the 2,000 position has not been confirmed. Check wallet updates.")
		else self:status("CONFIRMING BUY","Waiting for the dev-buy position update.")end
		return
	end
	if positionTokens(p)<=1e-6 then self:_finished(s,false,"Position closed outside this bot");return end
	if s.now<(r.retryAt or 0)then return end
	if self.adapter.watch then self.adapter:watch(r.coinId)end
	local observed=if self.adapter.takeObservations then self.adapter:takeObservations(r.coinId)else nil
	local value=self.adapter:value(r.coinId);assert(finite(value)and value>=0,"Invalid liquidation quote")
	local risk=ExitPolicy.evaluate(r,self.config,s.now,value,observed)
	local age,reason=risk.age,risk.reason
	self.pumpMetrics=string.format("Net %.0f · peak %.0f · trail %.0f%%",value,risk.peak,risk.trail*100)
	if reason then
		r.exitReason=reason
		if not self:_intent("sell",s)then return end
		self:status("SELLING",reason.." · selling the complete tracked position")
		local result=self.adapter:sell(r.coinId)
		if unknown(result)then self:pause("Sell outcome unconfirmed; it will not be repeated.");return end
		if result.ok then self.state.pending.ack=true;self.state.pending.settleAfter=s.now+1;self:persist()
		else self.state.pending=nil;r.retryAt=s.now+self.config.SellRetrySeconds;self:persist();self:status("SELL DECLINED",tostring(result.error))end
		return
	end
	if s.now>=(r.nextRiskSaveAt or 0)then r.nextRiskSaveAt=s.now+5;self:persist()end
	local function send(chat)
		local key=if chat then "chats"else "posts"
		local nextKey=if chat then "nextChatAt"else "nextPostAt"
		r[key]+=1;r[nextKey]=s.now+math.max(if chat then self.config.ChatEvery else self.config.PostEvery,(if chat then s.chatCooldown else s.postCooldown)+1)
		self:persist();if not self.enabled or self.stopped then return end
		local text=Art.message(r.draft,r[key],chat):sub(1,if chat then s.chatMax else s.postMax)
		local result=if chat then self.adapter:chat(text)else self.adapter:post(text)
		if type(result)=="table"and result.ok then self.state.stats[key]+=1;self:persist()
		else r[nextKey]=s.now+60;self.lastError=tostring(type(result)=="table"and result.error or "Message refused")end
	end
	if self.config.PostsEnabled and r.posts<self.config.MaxPostsPerCoin and s.now>=r.nextPostAt then send(false);return end
	if self.config.ChatEnabled and r.chats<self.config.MaxChatsPerCoin and s.now>=r.nextChatAt then send(true);return end
	self:status("WAITING FOR PUMP",string.format("$%s · %s · %.0fs · %s",c.ticker,r.network,age,self.pumpMetrics))
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
	local frame=make("Frame",{Name="Panel",Size=UDim2.fromOffset(460,550),Position=UDim2.new(0.5,-230,0.5,-275),BackgroundColor3=colors.bg,BorderSizePixel=0},self.gui)
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
	self.artSet=button(frame,"ArtSet","ART: All · NEXT COIN",20,414,420,30)
	self.start=button(frame,"Start","CONNECTING…",20,458,265,45)
	self.start.BackgroundColor3=colors.accent
	self.save=button(frame,"Save","SAVE",299,458,65,45)
	self.unload=button(frame,"Unload","UNLOAD",373,458,67,45)
	label(frame,"Footer","F6 start/pause · F7 unload · local learning saved to workspace",20,520,420,16,10,colors.muted)
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
		self.plan.Text=draft.category.." · "..(if arm>6 then "PATIENT" else "QUICK").."\n"..(engine.pumpMetrics or "2,000 entry · watch pump · sell")
	end
	self.metrics.Text=string.format("Rounds learned: %d  ·  Balance: %s",engine.learner.rounds,if s then string.format("%.0f",s.account.balance)else "connecting")
	local counts=engine.state.stats
	self.counts.Text=string.format("Launches %d · Buys %d · Sells %d · Posts %d",counts.launches,counts.buys or 0,counts.sells or 0,counts.posts)
	self.posts.Text="POSTS: "..(if engine.config.PostsEnabled then "YES" else "NO")
	self.chat.Text="CHAT: "..(if engine.config.ChatEnabled then "YES" else "NO")
	self.artSet.Text="ART: "..(engine.config.ArtTheme or engine.config.ArtSet or "All").." · NEXT COIN"
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

local Adapter=__modules["RemoteAdapter"]
local Engine=__modules["PumpEngine"]
local Storage=__modules["Storage"]
local UI=__modules["UI"]
local Art=__modules["Art"]
local VERSION="0.3.1"
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local Http=game:GetService("HttpService")
local environment=if type(getgenv)=="function"then getgenv()else getfenv()
local config=table.clone(environment.RugpullMLConfig or _G.RugpullMLConfig or {})
for key,value in environment.RugpullMLRuntimeDefaults or {}do if config[key]==nil then config[key]=value end end
local autoStartPending=config.StartEnabled==true
local player=assert(Players.LocalPlayer,"Run Rugpull ML on the client")
config.StateFile=config.StateFile or ("pump-learning-"..tostring(player.UserId)..".json")
local previous=environment.RugpullML or _G.RugpullML
if previous and not previous.PendingRequest and previous.Stop then previous:Stop()end
local oldIcon=UIS.MouseIconEnabled
UIS.MouseIconEnabled=true
local ui=UI.new(player,UIS,VERSION)
local connections={}
local engine,storage,adapter=nil,nil,nil
local stopped,busy,saveQueued=false,false,false
local token,nextStep=nil,0
local api={Version=VERSION,Ready=false,Enabled=false,PendingRequest=false,LastError=nil}
local function render()
	if not stopped and engine then ui:render(engine,storage.path)end
	api.Enabled=engine and engine.enabled or false
end
function api:SetEnabled(value)
	if not value then autoStartPending=false end
	if stopped or not engine or not engine.snapshot then return false end
	autoStartPending=false
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
	autoStartPending=false
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
	if adapter then adapter:destroy()end
	ui:destroy();UIS.MouseIconEnabled=oldIcon
end
function api:GetDiagnostics()
	return {version=VERSION,ready=api.Ready,enabled=api.Enabled,pending=api.PendingRequest,error=api.LastError,
		autoStartPending=autoStartPending,
		learningFile=storage and storage.path,learnedRounds=engine and engine.learner.rounds,
		status=engine and engine.code,detail=engine and engine.detail,
		coinId=engine and engine.state.round and engine.state.round.coinId,
		checkpoint=engine and engine.state.pending and engine.state.pending.kind,
		phase=engine and engine.state.round and engine.state.round.phase,
		network=engine and engine.state.round and engine.state.round.network,
		exitMode=engine and engine.config.ExitMode,
		artSet=engine and engine.config.ArtSet,
		peakSellValue=engine and engine.state.round and engine.state.round.peak,
		artTheme=engine and engine.state.round and engine.state.round.draft and engine.state.round.draft.name,
		trend=engine and engine.snapshot and engine.snapshot.trend}
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
table.insert(connections,ui.artSet.Activated:Connect(function()
	if engine then
		local index=table.find(Art.Sets,engine.config.ArtSet)or 1
		engine.config.ArtTheme=nil;engine.config.ArtSet=Art.Sets[1+index%#Art.Sets];render()
	end
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
local function tryAutoStart()
	if autoStartPending and not stopped and not api.LastError and engine and engine.snapshot then
		autoStartPending=false;engine:setEnabled(true);nextStep=math.min(nextStep,os.clock()+0.5)
	end
end
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
	adapter=Adapter.new(player,{storage=game:GetService("ReplicatedStorage"),chat=game:GetService("TextChatService"),
		profile=config.GameProfile,onChange=function()nextStep=math.min(nextStep,os.clock()+0.5)end,now=function()return workspace:GetServerTimeNow()end})
	engine=Engine.new({adapter=adapter,save=function(value)storage:save(value)end,saved=saved,config=config,userId=player.UserId})
	engine:refresh();engine:status(if engine.snapshot then "PAUSED" else "CONNECTING",if engine.snapshot then note..". Click Start Bot." else engine.detail)
	api.Ready=true
	tryAutoStart()
end)
table.insert(connections,RunService.Heartbeat:Connect(function()
	if stopped or not engine then return end
	local now=os.clock()
	if now<nextStep or busy then return end
	nextStep=now+(if engine.enabled then 0.5 else 2)
	work(function()
		if engine.enabled then engine:step()else engine:refresh();tryAutoStart()end
	end)
end))
return api
