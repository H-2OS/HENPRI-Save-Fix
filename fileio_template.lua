----------------------------------------
-- file入出力 [PATCHED: HENPRI Save Fix V1.0]
-- - isSaveFile: saveg.dat消失時のDisk Fallback
-- - restore:    ロード時のメタデータ自動復旧 + お気に入りボイス復旧
-- - favodata:   音声コレクションの独立バックアップ管理
----------------------------------------
function store(e, p)
	message("通知", p.file, "をセーブしました")
	saveconv(true)
end
----------------------------------------
-- ■ ロード時に自動で呼ばれる
----------------------------------------
function restore(e, p)
	message("通知", p.file, "をロードしました")
	loadconv(true)

	-- [PATCHED] metadata auto-recovery: restore title & text & date from loaded scr
	local function __recover_metadata()
		local no = tonumber(tostring(p.file):match("save(%d+)"))
		if no and no < init.save_suspend then
			local t = sys.saveslot[no]
			if t then
				local need_save = false
				local ti = sv.getsavetitle()
				if ti and next(ti) ~= nil then t.title = ti; need_save = true end
				if scr.ip and scr.ip.save then
					local tx = scr.ip.save.text
					local dt = scr.ip.save.date
					if tx and tx ~= "" then
						if type(tx) ~= "string" or tx ~= "autosave" then
							t.text = tx; need_save = true
						end
					end
					if dt and type(dt) == "table" and #dt >= 6 then
						t.date = dt; need_save = true
					end
				end
				if need_save then asyssave() end
			end
		end
	end
	pcall(__recover_metadata)

	-- [PATCHED] favo recovery: attempt to restore voice favorites from favodata/
	if init.game_favovoice == "on" then
		pcall(function() favo_recover() end)
	end

	loadstart = true
	e:tag{"var", name="s.status.controlskip", data="0"}
	local uinm = scr.uifunc
	if scr.menu and uinm ~= 'menu' then sv.delpoint() end
	if uinm then local v = openui_table[uinm]; if v then _G[v[2]]({}) end end
	appex = nil; extra = nil; titlepage = nil
	scr.menu = nil; scr.uifunc = nil; scr.adv.memory = nil; scr.bgmfade = nil
	adv_flagreset(); allkeyon(); autoskip_init()
	sv.delpoint(); init_adv_btn()
	if temp_dialog then set_dlgparam(temp_dialog, 1); temp_dialog = nil; asyssave() end
	readScriptFile(scr.ip.file)
	if suspend_load then
		local file = e:var("s.savepath").."/"..sv.makefile(init.save_suspend)..".dat"
		tag{"file", command="delete", target=(file)}
	elseif scr.autosave then
		if scr.select then flg.autosave = true end
		scr.autosave = nil
	elseif scr.loadfunc then
		flg.ui = {}; setonpush_ui(); estag("init"); estag{ scr.loadfunc[1] }
		estag{"uitrans"}; estag{"eqwait"}; estag("stop"); return
	end
	conf_reload(); anime_reload(); checkAread(); set_caption()
	loading_off(); uimask_on(); tag{"lydel", id="zzlogn"}
	quickjumpui(#(log.stack or {}), "load")
end
----------------------------------------
function load_suspendcheck()
	if suspend_load and get_dlgparam("sus") == 0 then suspend_load = nil; dialog("oksus") end
end
function load_suspendcheck2() ResetStack(); quickjumpmsgmain() end
----------------------------------------
function save_system() fsave_pluto(init.save_system, sys) end
function save_global() fsave_pluto(init.save_global, gscr) end
function save_config() fsave_pluto(init.save_config, conf) end
function load_system() sys = fload_pluto(init.save_system) or {} end
function load_global() gscr = fload_pluto(init.save_global) or {} end
function load_config() conf = fload_pluto(init.save_config) or {} end
----------------------------------------
function saveconv(flag)
	save_playtime(); save_system(); save_global(); save_config()
	if flag then fsave_pluto("scr", scr); fsave_pluto("log", log); fsave_pluto("btn", btn) end
end
function loadconv(flag)
	save_playtime(); load_system(); load_global(); load_config()
	if flag then scr = fload_pluto("scr"); log = fload_pluto("log"); btn = fload_pluto("btn") end
end
function tags.syssave(e, param) syssave() return 1 end
function syssave() message("通知", "system dataをセーブしました"); saveconv(); eqtag{"save"} end
function asyssave() if not game.cs then syssave() end end
function pssyssave() if game.cs then tag{"call", file="system/ui.asb", label="pssyssave"} else syssave() end end
function save_playtime() local t = gscr.playtime or 0; t = t + e:now() - playtime; gscr.playtime = t; playtime = e:now() end
----------------------------------------
function fload(file, flag)
	local path = ""; if not flag then path = e:var("s.savepath")..'/' end
	local r = e:file(path..file); if r then r = pluto.unpersist({}, r) end
	return r
end
function fsave(file, tbl, flag)
	local path = ""; if not flag then path = e:var("s.savepath")..'/' end
	local fp = io.open((path..file), "wb")
	if fp then fp:write(pluto.persist({}, tbl)); io.close(fp) end
	return fp
end
function fload_pluto(name)
	local r = nil; local p = e:var(name or "t.dummy")
	if p ~= "0" then r = pluto.unpersist({}, p) end
	return r
end
function fsave_pluto(name, tbl) e:tag{"var", name=(name), data=(pluto.persist({}, tbl))} end
function deleteFile(path) e:tag{"file", command="delete", target=(path)} end
function readtable(file, name)
	local tbl = { ui=(game.path.ui) }; local path = (name and tbl[name] or "")..file
	if e:isFileExists(path) then e:include(path) else error_message(path.."はみつかりませんでした") end
end
function isFile(path) return path and e:isFileExists(path) end
----------------------------------------
-- ■ isSaveFile関数
-- [PATCHED] saveg.datのsaveslot消失時、ディスク上の
-- saveNNNN.dat実ファイルを確認して自動復旧。日付は_save_dates表から。
----------------------------------------
function isSaveFile(num, name)
	local ret = nil
	local no = tonumber(num) or 1
	if name == "quick" then no = no + game.qsavehead
	elseif name == "auto"  then no = no + game.asavehead end

	local file = nil; local mask = nil
	local s = sys.saveslot[no]

	if s then
		file = s.file; ret = s; mask = s.evmask
	else
		-- FALLBACK: saveslot消失時、ディスク上の実ファイルを確認
		local fname = (init.save_prefix or "save") .. string.format("%04d", no)
		if isFile(e:var("s.savepath") .. '/' .. fname .. ".dat") then
			file = fname
			ret = {
				text  = "",
				title = {},
				date  = (_save_dates[no] or get_unixtime()),
				file  = fname,
				evmask= nil,
			}
			sys.saveslot[no] = ret
		end
	end

	if not game.cs and file then
		if init.game_savemode == "new" then
			if mask then
				local ss = ":hev/"..mask
				if not isFile(ss..".png") and not isFile(ss..".jpg") and not isFile(ss..".jpeg") then ret = nil end
			elseif not isFile(e:var("s.savepath")..'/'..file..".png") then
				ret = nil
			end
		elseif not isFile(e:var("s.savepath")..'/'..file..".dat") then
			ret = nil
		end
	end
	return ret
end
----------------------------------------
-- DATE_TABLE_PLACEHOLDER --
----------------------------------------
function open_savepath()
	if game.trueos == "windows" then
		se_ok(); local fl = "explorer"
		e:callShellExecute{ file=(fl), option=(code_sjis(e:var("s.savepath"))) }
	end
end
----------------------------------------
function opensli(path, num)
	local ret = {}; local frq = num or init.voice_freq
	if not path:find(".ogg") then path = path..".ogg.sli" end
	if isFile(path) then
		for i, line in pairs(split(e:file(path), "\n")) do
			if string.sub(line, 0, 5) == "Label" then
				local s = line:gsub("[ ']", ""):gsub("=", ";")
				local ax = split(s, ";")
				table.insert(ret, math.floor(tonumber(ax[2] or 0) / frq))
			end
		end
	else ret = nil end
	return ret
end
----------------------------------------
-- ================================================================
-- [PATCHED] お気に入りボイス復旧 (favodata)
-- favodata/ に独立バックアップを作成し saveg.dat 破損時に復旧する
-- ================================================================
----------------------------------------
-- favodata パス取得
-- s.savepath = "D:/Games/HENPRI/savedata" → "D:/Games/HENPRI/favodata"
----------------------------------------
function favo_getpath()
	if not game.path.favodata then
		local sp = e:var("s.savepath")
		local fp = sp:gsub("[^/\\]+$", "favodata")
		if fp == sp then
			fp = sp .. "_favodata"
		end
		game.path.favodata = fp
	end
	return game.path.favodata
end
----------------------------------------
-- favog.dat : sys.favo 完全テーブルの読み書き
----------------------------------------
function favo_saveindex()
	local fp = favo_getpath()
	local file = fp .. "/favog.dat"
	pcall(function()
		local f = io.open(file, "wb")
		if f then
			f:write(pluto.persist({}, sys.favo or {}))
			io.close(f)
		end
	end)
end
----------------------------------------
function favo_loadindex()
	local fp = favo_getpath()
	local file = fp .. "/favog.dat"
	if not isFile(file) then return nil end
	local raw = e:file(file)
	if raw then
		local ok, data = pcall(pluto.unpersist, {}, raw)
		if ok and type(data) == "table" then return data end
	end
	return nil
end
----------------------------------------
-- favoNNNN.dat : エントリ単体の読み書き
----------------------------------------
function favo_savefile(no)
	local data = sys.favo[no]
	if not data then return end
	local fp = favo_getpath()
	local file = fp .. "/favo" .. string.format("%04d", no) .. ".dat"
	pcall(function()
		local f = io.open(file, "wb")
		if f then
			f:write(pluto.persist({}, data))
			io.close(f)
		end
	end)
end
----------------------------------------
function favo_deletefile(no)
	local fp = favo_getpath()
	local file = fp .. "/favo" .. string.format("%04d", no) .. ".dat"
	if isFile(file) then
		deleteFile(file)
	end
end
----------------------------------------
function favo_readfile(no)
	local fp = favo_getpath()
	local file = fp .. "/favo" .. string.format("%04d", no) .. ".dat"
	if not isFile(file) then return nil end
	local raw = e:file(file)
	if raw then
		local ok, data = pcall(pluto.unpersist, {}, raw)
		if ok and data and data.text then return data end
	end
	return nil
end
----------------------------------------
-- 復旧オーケストレーション
-- 第1層: favog.dat から全エントリ復旧
-- 第2層: favoNNNN.dat を走査してエントリを個別復旧
----------------------------------------
function favo_recover()
	-- sys.favo が既にデータを持っているか確認
	local has_data = false
	if sys.favo then
		for k, v in pairs(sys.favo) do
			if type(k) == "number" and v and v.text then
				has_data = true
				break
			end
		end
	end

	if has_data then return end
	if not sys.favo then sys.favo = {} end

	message("通知", "お気に入りボイスの復旧を試みます...")

	-- 第1層: favog.dat から一括復旧
	local loaded = favo_loadindex()
	if loaded then
		local count = 0
		for k, v in pairs(loaded) do
			if type(k) == "number" and v and v.text then
				sys.favo[k] = v
				count = count + 1
			end
		end
		if count > 0 then
			sys.favo.last = loaded.last
			sys.favo.page = loaded.page
			message("通知", "favog.dat から " .. count .. " 件のお気に入りボイスを復旧しました")
			asyssave()
			return
		end
	end

	-- 第2層: favoNNNN.dat 個別走査
	local maxno = (init.favo_page or 10) * (init.favo_column or 10)
	local count = 0
	local last = nil
	local latest_time = 0

	for no = 1, maxno do
		local data = favo_readfile(no)
		if data then
			sys.favo[no] = data
			count = count + 1
			local dt = data.date
			if dt then
				local t = type(dt) == "table" and
					(dt[1] or 0) * 10000000000 +
					(dt[2] or 0) * 100000000 +
					(dt[3] or 0) * 1000000 +
					(dt[4] or 0) * 10000 +
					(dt[5] or 0) * 100 +
					(dt[6] or 0)
					or 0
				if t > latest_time then
					latest_time = t
					last = no
				end
			end
		end
	end

	if count > 0 then
		sys.favo.last = last
		sys.favo.page = 1
		message("通知", "favoNNNN.dat から " .. count .. " 件のお気に入りボイスを復旧しました")
		favo_saveindex()
		asyssave()
	end
end
----------------------------------------
-- エクスポート: sys.favo の各エントリを favodata に書き出す
-- 既存ファイルはスキップし、欠けているものだけを補完する
-- 毎回起動時に呼ばれるが、実質的なI/Oは初回または favodata 欠損時のみ
----------------------------------------
function favo_exportall()
	if not sys.favo then return end

	-- 先にインデックスファイルの有無を確認
	local fp = favo_getpath()
	local has_index = isFile(fp .. "/favog.dat")

	local count = 0
	for no, data in pairs(sys.favo) do
		if type(no) == "number" and data and data.text then
			local file = fp .. "/favo" .. string.format("%04d", no) .. ".dat"
			if not isFile(file) then
				favo_savefile(no)
				count = count + 1
			end
		end
	end

	-- 新しいファイルができたか、インデックスが欠けている場合のみ書き直す
	if count > 0 or not has_index then
		favo_saveindex()
		message("通知", count .. " 件のお気に入りボイスを favodata に追加しました")
	end
end
----------------------------------------
