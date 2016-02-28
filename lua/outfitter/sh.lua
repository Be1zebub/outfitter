local Tag='outfitter' 

module(Tag,package.seeall)


function HasMDL(mdl)
	mdl = mdl:gsub("%.mdl$","")
	return file.Exists(mdl..'.mdl','GAME')
end

net.Receive(Tag,function(...) OnReceive(...) end)

local cache = {}
function FlushCache()
	cache = {}
end

function FileExistsCached(fpath)
	local ret = cache[fpath]
	if ret == nil then
		ret = HasMDL(fpath)
		cache[fpath] = ret
	end
	return ret
end

function SanityCheckNData(mdl,wsid)
	
	if not mdl then return false end
	if not wsid then return false end
	if mdl=="" or #mdl>2048*2 then return false end
	if mdl:find("  ",1,true) or mdl:find("..",1,true) or mdl:find("\t",1,true) or mdl:find("\n",1,true) then return false end
	if wsid<=0 then return false end
end


function findpl(uid)
	for _,pl in next,player.GetAll() do 
		if pl:UserID()==uid then
			return pl
		end
	end
end	


--TODO: hex encoding at least
function EncodeOW(o,w)
	return w..','..o
end

function DecodeOW(str)
	local w,o = str:match'^(%d-),(.*)$'
	w = tonumber(w)
	return o,w
end

function CanPlayerModel(f)
	local mdl,err = mdlinspect.Open(f)
	if not mdl then
		return nil,err
	end
	
	if mdl.version~=44 and mdl.version~=48 then
		return nil,"version"
	end
	
	local ok ,err = mdl:ParseHeader()
	if not ok then 
		return nil,err or "hdr" 
	end

	local valid = mdl:Validate()
	if not valid then 
		return nil,"valid" 
	end
	
	local found = false
	for k,v in next,mdl:IncludedModels() do
		v=v[2]
		if v:find"%.mdl$" and ( v:find("anim",1,true) or v:find('/m_',1,true) or v:find('/f_',1,true) ) then
			found = true
			break
		end
	end
	if not found then 
		return nil,"includemdls" 
	end
	
	local bname = mdl:BoneNames() [1]
	if bname~= "ValveBiped.Bip01_Pelvis" then
		return nil,"bones"
	end
	
	
	return true
end

local fp ="models/player/"
local flist = file.Find(fp..'*.mdl','GAME')
-- flist = {'matress.mdl'}

for _,fn in next,flist do

	local fpath = fp..fn
	local f = file.Open(fpath,'rb','GAME')
	print(('%50s'):format(fn),CanPlayerModel(f))
	f:Close()
	
end

function GrepModels(l)
	local t={}
	for k,v in next,l do
		if v:find"%.mdl$" then
			t[#t+1] = v
		end
	end
	return t
end
