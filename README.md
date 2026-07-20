<p align="center">
  <b>简体中文</b> &nbsp;|&nbsp;
  <a href="#聲明">繁體中文</a> &nbsp;|&nbsp;
  <a href="#Disclaimer">English</a>
</p>

---

### 声明

本补丁为非官方第三方补丁，仅供学习交流使用，禁止商用。原游戏《HENPRI》（HENTAI PRISON）的全部代码、剧情、美术、音频等内容，版权归原版权方 Qruppo 所有。

本补丁中的 Lua 脚本（`fileio_template.lua`、`fsave.lua`、`favo.lua`、`init.lua`）系使用解包工具（GARbro）对合法获取的游戏文件进行互操作性分析后，基于原游戏引擎（Artemis Engine）代码修改而成——原始引擎代码版权归 Qruppo 所有，原作者仅对修改和新增部分主张权利。其中存档恢复部分继承自 [NUKITASHI Save Fix V1.1](https://github.com/H-2OS/NUKITASHI-Save-Fix)。`install.ps1` 与 `install.bat` 为完全原创代码。

本项目与 NUKITASHI Save Fix 采用相同的自定义许可证发布，详见 [LICENSE.txt](./LICENSE.txt)。若版权所有者提出异议，本项目将立即下架。

### 简介

这是一个个人制作的 **HENPRI（Steam 版）存档修复 + 语音收藏备份补丁**，基于 [NUKITASHI Save Fix V1.1](https://github.com/H-2OS/NUKITASHI-Save-Fix) 的思路设计，本补丁旨在无损、便捷地恢复原存档的可用性，以及为易丢失的语音收藏生成备份。如果它对你有帮助，欢迎点亮⭐️支持本项目！

**本补丁的两个功能：**

1. **saveg.dat损坏导致的存档丢失修复**：Steam Cloud 同步覆盖 `saveg.dat` → Load 界面空白。实际上 `saveNNNN.dat` 文件完整无损，补丁可从磁盘恢复。
2. **saveg.dat完好时的语音收藏备份**：`sys.favo` 仅存在于 `saveg.dat` 中，没有独立备份。补丁创建 `favodata/` 目录进行冗余存储，解决 Steam Cloud 覆盖或未知原因导致的语音收藏丢失问题。
 注：saveg.dat损坏时（表现为存档不显示）无法导出语音收藏生成备份，因为其已丢失。

### 要求

- Windows 8+（使用自带 PowerShell 3.0）
- HENPRI（Steam 版，Artemis Engine）

### 使用方法

**安装补丁：**

1. 双击 `install.bat`
2. 按屏幕提示完成操作
   （HENPRI Save Fix 文件夹中的文件是补丁辅助安装程序，补丁成功后即可删除此文件夹）
3. 启动游戏
4. 进入 Load 页面，将看到拥有正确日期但章节和角色语句空白的存档
5. 对任一存档进行读档操作（无需存档），完成读档后返回 Load 页面，空白部分将显示章节及角色语句

注：语音收藏的导出无需任何操作。所有流程均为自动——备份导出在游戏启动时自动完成（游戏正常结束后可在游戏目录下找到favodata文件夹以及其中的语音收藏存档）。损坏恢复在加载存档时自动触发，日常新增/删除/移动的同步在后台静默执行

**卸载补丁：**

删除游戏文件夹下的四个文件即可：
- `system/init.lua`
- `system/adv/fileio.lua`
- `system/adv/fsave.lua`
- `system/ui/favo.lua`

`favodata/` 目录是你的语音收藏备份，可保留或删除。PFS 封包内的原始游戏文件从未被修改，无须担心。

### 文件

| 文件 | 作用 |
|------|------|
| `install.bat` | 双击运行，绕过 PowerShell 执行策略 |
| `install.ps1` | 扫描 `saveXXXX.png` 修改时间 → 生成 `_save_dates` 表 → 组装 `fileio.lua` → 部署全部四个文件 → 创建 `favodata/` |
| `fileio_template.lua` | 补丁模板，`-- DATE_TABLE_PLACEHOLDER --` 由脚本替换。包含存档磁盘回退、全部 favodata 基础设施函数、语音收藏恢复逻辑 |
| `fsave.lua` | 预修补版（两处改动：嵌入日期到 BOWS + HENPRI 语言修复） |
| `favo.lua` | 预修补版（语音收藏 favodata 实时同步 + 恢复入口） |
| `init.lua` | 预修补版（游戏启动时自动调用 `favo_exportall()` 完成存量导出） |

### 补丁工作原理

游戏使用 Artemis Engine。存档系统依赖 `savedata/saveg.dat` 中的 Lua 表 `sys.saveslot` 来索引槽位，语音收藏依赖同文件中的 `sys.favo` 表。当该文件因 Steam 云同步或未知原因被覆写时，`sys.saveslot` 和 `sys.favo` 同时丢失。

补丁通过**修改四个 Lua 脚本**（引擎优先读取文件系统中的 `.lua` 文件，覆盖 PFS 封包内的原脚本）实现恢复。

部署后游戏目录结构：

```
HENPRI/
├── HENPRI.exe
├── HENPRI.pfs                     ← 原始 Lua 脚本在此档案内
├── system/
│   ├── init.lua                   ← ★ 补丁版（启动时自动导出）
│   ├── adv/
│   │   ├── fileio.lua             ← ★ 补丁版（存档磁盘回退 + 语音收藏恢复）
│   │   └── fsave.lua              ← ★ 补丁版（日期嵌入 + 语言修复）
│   └── ui/
│       └── favo.lua               ← ★ 补丁版（favodata 实时同步）
├── savedata/                      ← 引擎管理（受 Steam Cloud 影响）
│   ├── saveg.dat                  ← sys 表（saveslot + favo 索引）
│   ├── save0001.dat ~ ...
│   └── save0001.png ~ ...
└── favodata/                      ← ★ 补丁创建的语音收藏存档文件夹（独立于引擎，不受 Steam Cloud 影响）
    ├── favog.dat                  ← sys.favo 完整表备份
    └── favo0001.dat ~ ...         ← 每条语音收藏的独立备份
```

---

#### 第一部分：存档恢复（继承自 NUKITASHI Save Fix）

**阶段 1：打开 Load 菜单 — `isSaveFile()` 磁盘回退**

`save.lua` 遍历槽位，对每个槽位调用 `isSaveFile(no)`。原版函数在 `sys.saveslot[no]` 为 nil 时直接放弃。补丁增加了 else 分支：

```lua
function isSaveFile(num, name)
    ...
    if s then
        file = s.file; ret = s; mask = s.evmask
    else
        -- FALLBACK: 磁盘回退
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
            sys.saveslot[no] = ret    -- 索引修复
        end
    end
    ...
end
```

`isFile()` 确认 `saveNNNN.dat` 在磁盘上真实存在后，用 `_save_dates` 表（`install.ps1` 从该机器的 `saveXXXX.png` 缩略图时间一次性生成）获取接近原始的存档日期，创建最小条目。

**此时**：所有存档在 Load 界面可见，日期就位。标题和对话文本为空白。

**阶段 2：加载存档 — `restore()` 元数据恢复**

用户加载存档后，Artemis Engine 将 `saveNNNN.dat` 解压反序列化，`scr` 表完整恢复到内存中。引擎随后调用 `restore()`，补丁在此处注入元数据恢复逻辑：

```lua
function restore(e, p)
    loadconv(true)
    -- metadata auto-recovery
    local function __recover_metadata()
        local no = tonumber(tostring(p.file):match("save(%d+)"))
        if no and no < init.save_suspend then
            local t = sys.saveslot[no]
            if t then
                local need_save = false
                -- 章节标题: scr.adv.title
                local ti = sv.getsavetitle()
                if ti and next(ti) ~= nil then t.title = ti; need_save = true end
                -- 对话文本: scr.ip.save.text
                -- 存档日期: scr.ip.save.date
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
                if need_save then asyssave() end  -- 持久化到 saveg.dat
            end
        end
    end
    pcall(__recover_metadata)
    ...
end
```

数据来源追踪：

| 恢复项 | 内存来源 | 写入来源 | 说明 |
|--------|----------|----------|------|
| 章节标题 | `scr.adv.title` | 游戏脚本 `sv.savetitle()` | 每次进新章节时设定 |
| 对话文本 | `scr.ip.save.text` | `sv.save()` → `getTextBlockText()` | 存档时捕获的当前文本 |
| 存档日期 | `scr.ip.save.date` | `sv.save()` → `get_unixtime()` | 存档时的精确时间 |

**此时**：标题、对话文本、日期三项全部恢复，`asyssave()` 将完整条目持久化到 `saveg.dat`。再次打开 Load 界面时，`sys.saveslot` 已完整——不需要再走回退。

**阶段 3（无感知）：存档时嵌入日期 — `fsave.lua`**

为使补丁后新创建的存档自带精确日期，`fsave.lua` 做了一行改动：

```lua
-- 原版:
scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc) }

-- 补丁版:
scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc), date=get_unixtime() }
```

存档时将当前时间嵌入 BOWS 文件内部。第二阶段 `restore()` 读取的 `scr.ip.save.date` 即来源于此。补丁前的旧存档无此字段，日期由 `_save_dates` 表兜底。

---

#### 第二部分：语音收藏备份与恢复（HENPRI Save Fix 新引入的功能）

**问题根因**：`sys.favo` 仅存在于 `saveg.dat` 中，没有独立文件备份。存档有 `saveg.dat`（索引）+ `saveNNNN.dat`（数据）双层存储，语音收藏只有单层。若`saveg.dat` 损坏，语音收藏将彻底丢失。

**解决方案**：创建 `favodata/` 独立目录，完全仿照存档的"索引 + 独立条目文件"结构。

---

##### 流程 A：已有语音收藏导出（每次启动自动执行）

玩家无需任何操作。游戏启动完成后 `system_starting()` 自动调用 `favo_exportall()`：

```
favo_exportall()
  │
  ├─ sys.favo 为空？→ return（无数据，静默退出）
  │
  ├─ 遍历 sys.favo 中每条有效收藏：
  │    isFile("favodata/favoNNNN.dat")？
  │      ├─ 是 → 跳过（文件已存在，无需重写）
  │      └─ 否 → favo_savefile(no) → 写入缺失文件
  │
  └─ 有新文件写入 或 favog.dat 缺失？
       └─ 是 → favo_saveindex() → 更新/重建索引
```

设计要点：
- **无标记机制**：不依赖持久化标记判断是否已导出，每次遍历时直接检查文件是否存在
- **按文件粒度跳过**：已存在的文件无需覆盖写入，缺失的文件自动补全
- **favodata/ 被删自动重建**：所有文件缺失 → 全部补写；部分缺失 → 仅补缺失

各场景的 I/O 表现：

| 场景 | 启动时 I/O |
|------|-----------|
| 首次安装 | 全部文件缺失 → 全量写入 |
| 后续正常启动 | 全部文件已存在 → 零写入 |
| `favodata/` 被手动删除 | 全部文件缺失 → 全量重建 |
| 游戏中途新增了收藏 | `favoclick()` 已实时同步 → 文件已存在 → 跳过 |

---

##### 流程 B：日常增量同步（每次收藏操作触发）

```
favoclick()（新增收藏）
  ├→ sys.favo[no] = {...}        ← 写入内存
  ├→ favo_savefile(no)            ← 写 favodata/favoNNNN.dat
  ├→ favo_saveindex()             ← 更新 favodata/favog.dat
  └→ asyssave()                   ← 持久化到 saveg.dat

favodelete()（删除收藏）
  ├→ sys.favo[no] = nil           ← 从内存移除
  ├→ favo_deletefile(no)          ← 删 favodata/favoNNNN.dat
  ├→ favo_saveindex()             ← 更新 favodata/favog.dat
  └→ asyssave()                   ← 持久化到 saveg.dat

favomove()（移动/交换收藏）
  ├→ 内存中完成 swap/move
  ├→ 更新两个受影响槽位的 favoNNNN.dat（写或删）
  ├→ favo_saveindex()             ← 更新 favodata/favog.dat
  └→ asyssave()                   ← 持久化到 saveg.dat
```

一份数据，三处落盘：`saveg.dat` + `favog.dat` + `favoNNNN.dat`。

---

##### 流程 C：损坏恢复（以saveg.dat 被 Steam Cloud 覆盖为例）

-玩家启动游戏

```
restore()
  │
  ├─ __recover_metadata()         ← 存档元数据恢复
  │    scr.adv.title  → saveslot.title
  │    scr.ip.save.text → saveslot.text
  │    scr.ip.save.date → saveslot.date
  │    asyssave() → 写回 saveg.dat
  │
  └─ favo_recover()               ← 语音收藏恢复
       │
       │  sys.favo 为空 → 继续
       │
       ├─ 第1层: favo_loadindex()
       │    favodata/favog.dat 存在？
       │    └─ 是 → Pluto 反序列化 → sys.favo 整表恢复
       │         → asyssave() → 写回 saveg.dat
       │
       └─ 第2层: favog.dat 也坏了？
            └─ 扫描 favodata/favoNNNN.dat
                逐条 Pluto 反序列化 → sys.favo 逐条重建
                → 重建 favog.dat 索引
                → asyssave() → 写回 saveg.dat
```

---

##### 函数依赖关系

`fileio.lua` 先于 `favo.lua` 加载，`init.lua` 中的回调在所有脚本加载完成后才被引擎调用：

```
fileio_template.lua（定义）
  ├─ favo_getpath()
  ├─ favo_savefile(no)          ←──┐
  ├─ favo_deletefile(no)        ←──┤
  ├─ favo_saveindex()           ←──┤ favo.lua、init.lua 调用
  ├─ favo_loadindex()           ←──┤
  ├─ favo_readfile(no)          ←──┤
  ├─ favo_recover()             ←──┤
  └─ favo_exportall()           ←──┘
```

---

### 与 NUKITASHI Save Fix 的差异

| 维度 | NUKITASHI Save Fix V1.1 | HENPRI Save Fix V1.0 |
|------|------------------------|----------------------|
| 存档恢复 | ✅ | ✅（完全移植） |
| 语音收藏备份 | 无此功能 | favodata/ 双轨冗余 |
| 部署文件 | fileio.lua + fsave.lua | fileio.lua + fsave.lua + favo.lua + init.lua |
| 导出触发 | 无此功能 | 启动时自动，每次运行补缺 |
| 恢复触发 | restore() | restore() + favo_init() 双重兜底 |
| 游戏检测 | NUKITASHI.exe | HENPRI.exe |

---

### 聲明

本修補程式為非官方第三方修補程式，僅供學習交流使用，禁止商用。原遊戲《HENPRI》（HENTAI PRISON）的全部程式碼、劇情、美術、音訊等內容，版權歸原版權方 Qruppo 所有。

本修補程式中的 Lua 指令碼（`fileio_template.lua`、`fsave.lua`、`favo.lua`、`init.lua`）係使用解包工具（GARbro）對合法取得的遊戲檔案進行互操作性分析後，基於原遊戲引擎（Artemis Engine）程式碼修改而成——原始引擎程式碼版權歸 Qruppo 所有，原作者僅對修改和新增部分主張權利。其中存檔復原部分繼承自 [NUKITASHI Save Fix V1.1](https://github.com/H-2OS/NUKITASHI-Save-Fix)。`install.ps1` 與 `install.bat` 為完全原創程式碼。

本專案與 NUKITASHI Save Fix 採用相同的自訂授權條款發布，詳見 [LICENSE.txt](./LICENSE.txt)。若著作權所有者提出異議，本專案將立即下架。

### 簡介

這是一個個人製作的 **HENPRI（Steam 版）存檔復原 + 語音收藏備份修補程式**，基於 [NUKITASHI Save Fix V1.1](https://github.com/H-2OS/NUKITASHI-Save-Fix) 的思路設計，本修補程式旨在無損、便捷地復原原存檔的可用性，以及為易遺失的語音收藏生成備份。如果它對你有幫助，歡迎點亮⭐️支持本專案！

**本修補程式的兩個功能：**

1. **saveg.dat損壞導致的存檔遺失修復**：Steam Cloud 同步覆蓋 `saveg.dat` → Load 介面空白。實際上 `saveNNNN.dat` 檔案完整無損，修補程式可從磁碟復原。
2. **saveg.dat完好時的語音收藏備份**：`sys.favo` 僅存在於 `saveg.dat` 中，沒有獨立備份。修補程式建立 `favodata/` 目錄進行冗餘儲存，解決 Steam Cloud 覆蓋或未知原因導致的語音收藏遺失問題。
 註：saveg.dat損壞時（表現為存檔不顯示）無法匯出語音收藏生成備份，因為其已遺失。

### 要求

- Windows 8+（使用內建 PowerShell 3.0）
- HENPRI（Steam 版，Artemis Engine）

### 使用方法

**安裝修補程式：**

1. 雙擊 `install.bat`
2. 按螢幕提示完成操作
   （HENPRI Save Fix 資料夾中的檔案是修補程式輔助安裝程式，修補成功後即可刪除此資料夾）
3. 啟動遊戲
4. 進入 Load 頁面，將看到擁有正確日期但章節和角色語句空白的存檔
5. 對任一存檔進行讀檔操作（無需存檔），完成讀檔後返回 Load 頁面，空白部分將顯示章節及角色語句
 
 註：語音收藏的匯出無需任何操作。所有流程均為自動——備份匯出在遊戲啟動時自動完成（遊戲正常結束後可在遊戲目錄下找到favodata資料夾以及其中的語音收藏存檔）。損壞恢復在載入存檔時自動觸發，日常新增/刪除/移動的同步在背景靜默執行

**解除安裝修補程式：**

刪除遊戲資料夾下的四個檔案即可：
- `system/init.lua`
- `system/adv/fileio.lua`
- `system/adv/fsave.lua`
- `system/ui/favo.lua`

`favodata/` 目錄是你的語音收藏備份，可保留或刪除。PFS 封包內的原始遊戲檔案從未被修改，無須擔心。

### 檔案

| 檔案 | 作用 |
|------|------|
| `install.bat` | 雙擊執行，繞過 PowerShell 執行策略 |
| `install.ps1` | 掃描 `saveXXXX.png` 修改時間 → 生成 `_save_dates` 表 → 組裝 `fileio.lua` → 部署全部四個檔案 → 建立 `favodata/` |
| `fileio_template.lua` | 修補範本，`-- DATE_TABLE_PLACEHOLDER --` 由指令碼替換。包含存檔磁碟回退、全部 favodata 基礎設施函式、語音收藏復原邏輯 |
| `fsave.lua` | 預修補版（兩處改動：嵌入日期到 BOWS + HENPRI 語言修復） |
| `favo.lua` | 預修補版（語音收藏 favodata 即時同步 + 復原入口） |
| `init.lua` | 預修補版（遊戲啟動時自動呼叫 `favo_exportall()` 完成存量匯出） |

### 修補程式工作原理

遊戲使用 Artemis Engine。存檔系統依賴 `savedata/saveg.dat` 中的 Lua 表 `sys.saveslot` 來索引欄位，語音收藏依賴同檔案中的 `sys.favo` 表。當該檔案因 Steam 雲端同步或未知原因被覆寫時，`sys.saveslot` 和 `sys.favo` 同時遺失。

修補程式透過**修改四個 Lua 腳本**（引擎優先讀取檔案系統中的 `.lua` 檔案，覆蓋 PFS 封包內的原腳本）實現復原。

部署後遊戲目錄結構：

```
HENPRI/
├── HENPRI.exe
├── HENPRI.pfs                     ← 原始 Lua 腳本在此封包內
├── system/
│   ├── init.lua                   ← ★ 修補版（啟動時自動匯出）
│   ├── adv/
│   │   ├── fileio.lua             ← ★ 修補版（存檔磁碟回退 + 語音收藏復原）
│   │   └── fsave.lua              ← ★ 修補版（日期嵌入 + 語言修復）
│   └── ui/
│       └── favo.lua               ← ★ 修補版（favodata 即時同步）
├── savedata/                      ← 引擎管理（受 Steam Cloud 影響）
│   ├── saveg.dat                  ← sys 表（saveslot + favo 索引）
│   ├── save0001.dat ~ ...
│   └── save0001.png ~ ...
└── favodata/                      ← ★ 修補程式建立的語音收藏存檔資料夾（獨立於引擎，不受 Steam Cloud 影響）
    ├── favog.dat                  ← sys.favo 完整表備份
    └── favo0001.dat ~ ...         ← 每條語音收藏的獨立備份
```

---

#### 第一部分：存檔復原（繼承自 NUKITASHI Save Fix）

**階段 1：開啟 Load 介面 — `isSaveFile()` 磁碟回退**

`save.lua` 走訪欄位，對每個欄位呼叫 `isSaveFile(no)`。原版函式在 `sys.saveslot[no]` 為 nil 時直接放棄。修補程式增加了 else 分支：

```lua
function isSaveFile(num, name)
    ...
    if s then
        file = s.file; ret = s; mask = s.evmask
    else
        -- FALLBACK: 磁碟回退
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
            sys.saveslot[no] = ret    -- 索引修復
        end
    end
    ...
end
```

`isFile()` 確認 `saveNNNN.dat` 在磁碟上真實存在後，用 `_save_dates` 表（`install.ps1` 從該機器的 `saveXXXX.png` 縮圖時間一次性生成）獲取接近原始的存檔日期，建立最小條目。

**此時**：所有存檔在 Load 介面可見，日期就位。標題和對話文字為空白。

**階段 2：載入存檔 — `restore()` 元資料復原**

使用者載入存檔後，Artemis Engine 將 `saveNNNN.dat` 解壓反序列化，`scr` 表完整復原到記憶體中。引擎隨後呼叫 `restore()`，修補程式在此處注入元資料復原邏輯：

```lua
function restore(e, p)
    loadconv(true)
    -- metadata auto-recovery
    local function __recover_metadata()
        local no = tonumber(tostring(p.file):match("save(%d+)"))
        if no and no < init.save_suspend then
            local t = sys.saveslot[no]
            if t then
                local need_save = false
                -- 章節標題: scr.adv.title
                local ti = sv.getsavetitle()
                if ti and next(ti) ~= nil then t.title = ti; need_save = true end
                -- 對話文字: scr.ip.save.text
                -- 存檔日期: scr.ip.save.date
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
                if need_save then asyssave() end  -- 持久化到 saveg.dat
            end
        end
    end
    pcall(__recover_metadata)
    ...
end
```

資料來源追蹤：

| 復原項 | 記憶體來源 | 寫入來源 | 說明 |
|--------|----------|----------|------|
| 章節標題 | `scr.adv.title` | 遊戲腳本 `sv.savetitle()` | 每次進入新章節時設定 |
| 對話文字 | `scr.ip.save.text` | `sv.save()` → `getTextBlockText()` | 存檔時捕獲的目前文字 |
| 存檔日期 | `scr.ip.save.date` | `sv.save()` → `get_unixtime()` | 存檔時的精確時間 |

**此時**：標題、對話文字、日期三項全部復原，`asyssave()` 將完整條目持久化到 `saveg.dat`。再次開啟 Load 介面時，`sys.saveslot` 已完整——不需要再走回退。

**階段 3（無感知）：存檔時嵌入日期 — `fsave.lua`**

為使修補後新建立的存檔自帶精確日期，`fsave.lua` 做了一行改動：

```lua
-- 原版:
scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc) }

-- 修補版:
scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc), date=get_unixtime() }
```

存檔時將目前時間嵌入 BOWS 檔案內部。第二階段 `restore()` 讀取的 `scr.ip.save.date` 即來源於此。修補前的舊存檔無此欄位，日期由 `_save_dates` 表兜底。

---

#### 第二部分：語音收藏備份與復原（HENPRI Save Fix 新引入的功能）

**問題根因**：`sys.favo` 僅存在於 `saveg.dat` 中，沒有獨立檔案備份。存檔有 `saveg.dat`（索引）+ `saveNNNN.dat`（資料）雙層儲存，語音收藏只有單層。若`saveg.dat` 損壞，語音收藏將徹底遺失。

**解決方案**：建立 `favodata/` 獨立目錄，完全仿照存檔的"索引 + 獨立條目檔案"結構。

---

##### 流程 A：已有語音收藏匯出（每次啟動自動執行）

玩家無需任何操作。遊戲啟動完成後 `system_starting()` 自動呼叫 `favo_exportall()`：

```
favo_exportall()
  │
  ├─ sys.favo 為空？→ return（無資料，靜默退出）
  │
  ├─ 走訪 sys.favo 中每條有效收藏：
  │    isFile("favodata/favoNNNN.dat")？
  │      ├─ 是 → 跳過（檔案已存在，無需重寫）
  │      └─ 否 → favo_savefile(no) → 寫入缺失檔案
  │
  └─ 有新檔案寫入 或 favog.dat 缺失？
       └─ 是 → favo_saveindex() → 更新/重建索引
```

設計要點：
- **無標記機制**：每次走訪時直接檢查檔案是否存在
- **按檔案粒度跳過**：已存在的檔案無需覆蓋寫入，缺失的檔案自動補全
- **favodata/ 被刪自動重建**：所有檔案缺失 → 全部補寫；部分缺失 → 僅補缺失

各場景的 I/O 表現：

| 場景 | 啟動時 I/O |
|------|-----------|
| 首次安裝 | 全部檔案缺失 → 全量寫入 |
| 後續正常啟動 | 全部檔案已存在 → 零寫入 |
| `favodata/` 被手動刪除 | 全部檔案缺失 → 全量重建 |
| 遊戲中途新增了收藏 | `favoclick()` 已即時同步 → 檔案已存在 → 跳過 |

---

##### 流程 B：日常增量同步（每次收藏操作觸發）

```
favoclick()（新增收藏）
  ├→ sys.favo[no] = {...}        ← 寫入記憶體
  ├→ favo_savefile(no)            ← 寫 favodata/favoNNNN.dat
  ├→ favo_saveindex()             ← 更新 favodata/favog.dat
  └→ asyssave()                   ← 持久化到 saveg.dat

favodelete()（刪除收藏）
  ├→ sys.favo[no] = nil           ← 從記憶體移除
  ├→ favo_deletefile(no)          ← 刪 favodata/favoNNNN.dat
  ├→ favo_saveindex()             ← 更新 favodata/favog.dat
  └→ asyssave()                   ← 持久化到 saveg.dat

favomove()（移動/交換收藏）
  ├→ 記憶體中完成 swap/move
  ├→ 更新兩個受影響欄位的 favoNNNN.dat（寫或刪）
  ├→ favo_saveindex()             ← 更新 favodata/favog.dat
  └→ asyssave()                   ← 持久化到 saveg.dat
```

一份資料，三處落盤：`saveg.dat` + `favog.dat` + `favoNNNN.dat`。

---

##### 流程 C：損壞恢復（以saveg.dat 被 Steam Cloud 覆蓋為例）

-玩家啟動遊戲

```
restore()
  │
  ├─ __recover_metadata()         ← 存檔元資料復原
  │    scr.adv.title  → saveslot.title
  │    scr.ip.save.text → saveslot.text
  │    scr.ip.save.date → saveslot.date
  │    asyssave() → 寫回 saveg.dat
  │
  └─ favo_recover()               ← 語音收藏復原
       │
       │  sys.favo 為空 → 繼續
       │
       ├─ 第1層: favo_loadindex()
       │    favodata/favog.dat 存在？
       │    └─ 是 → Pluto 反序列化 → sys.favo 整表復原
       │         → asyssave() → 寫回 saveg.dat
       │
       └─ 第2層: favog.dat 也壞了？
            └─ 掃描 favodata/favoNNNN.dat
                逐條 Pluto 反序列化 → sys.favo 逐條重建
                → 重建 favog.dat 索引
                → asyssave() → 寫回 saveg.dat
```

---

##### 函式依賴關係

`fileio.lua` 先於 `favo.lua` 載入，`init.lua` 中的回呼在所有腳本載入完成後才被引擎呼叫：

```
fileio_template.lua（定義）
  ├─ favo_getpath()
  ├─ favo_savefile(no)          ←──┐
  ├─ favo_deletefile(no)        ←──┤
  ├─ favo_saveindex()           ←──┤ favo.lua、init.lua 呼叫
  ├─ favo_loadindex()           ←──┤
  ├─ favo_readfile(no)          ←──┤
  ├─ favo_recover()             ←──┤
  └─ favo_exportall()           ←──┘
```

---

### 與 NUKITASHI Save Fix 的差異

| 維度 | NUKITASHI Save Fix V1.1 | HENPRI Save Fix V1.0 |
|------|------------------------|----------------------|
| 存檔復原 | ✅ | ✅（完全移植） |
| 語音收藏備份 | 無此功能 | favodata/ 雙軌冗餘 |
| 部署檔案 | fileio.lua + fsave.lua | fileio.lua + fsave.lua + favo.lua + init.lua |
| 匯出觸發 | 無此功能 | 啟動時自動，每次執行補缺 |
| 復原觸發 | restore() | restore() + favo_init() 雙重兜底 |
| 遊戲偵測 | NUKITASHI.exe | HENPRI.exe |

---

### Disclaimer

This patch is an unofficial third-party patch, for educational and personal use only; commercial use is prohibited. All original game code, story, art, audio, and other content of HENPRI (HENTAI PRISON) are the property of the original rights holder, Qruppo.

The Lua scripts in this patch (`fileio_template.lua`, `fsave.lua`, `favo.lua`, `init.lua`) were created by using extraction tools (GARbro) to perform interoperability analysis on lawfully obtained game files, and modifying the original game engine (Artemis Engine) code — the original engine code is copyrighted by Qruppo; the Author claims rights only over the modifications and additions. The save recovery portions are inherited from [NUKITASHI Save Fix V1.1](https://github.com/H-2OS/NUKITASHI-Save-Fix). `install.ps1` and `install.bat` are entirely original code.

This project is released under the same custom license as NUKITASHI Save Fix. See [LICENSE.txt](./LICENSE.txt). Should the copyright holders object, this project will be taken down immediately.

### About

A personal **save recovery + voice favorite backup patch** for HENPRI (Steam edition), based on the design approach of [NUKITASHI Save Fix V1.1](https://github.com/H-2OS/NUKITASHI-Save-Fix). This patch aims to losslessly and conveniently restore save readability, and generate backups for vulnerable voice favorites. If it helps you, a ⭐️ would be appreciated!

**The two functions of this patch:**

1. **Save loss recovery when saveg.dat is corrupted**: Steam Cloud sync overwrites `saveg.dat` → Load menu becomes empty. The `saveNNNN.dat` files are actually fully intact — the patch recovers them from disk.
2. **Voice favorite backup when saveg.dat is intact**: `sys.favo` exists only in `saveg.dat` with no independent backup. The patch creates a `favodata/` directory for redundant storage, solving voice favorite loss caused by Steam Cloud overwrites or unknown reasons.
 
 Note: When saveg.dat is corrupted (indicated by saves not appearing), voice favorites cannot be exported for backup because they are already lost.

### Requirements

- Windows 8+ (uses built-in PowerShell 3.0)
- HENPRI (Steam edition, Artemis Engine)

### Usage

**Install the patch:**

1. Double-click `install.bat`
2. Follow the on-screen prompts to complete the setup
   (The files in the HENPRI Save Fix folder are helper installers; you may delete this folder after the patch is successfully applied)
3. Launch the game
4. Open the Load page — saves will appear with correct dates but blank chapter titles and dialogue text
5. Load any of the above saves (no need to re-save); upon returning to the Load page, the previously blank fields will display chapter titles and dialogue text
 Note: Voice favorite export requires no action. All processes are automatic — backup export runs at game startup (after normal game exit, you can find the favodata folder and voice favorite saves in the game directory). Disaster recovery triggers on save load, and day-to-day sync of new/deleted/moved favorites happens silently in the background

**Uninstall the patch:**

Delete these four files from your game folder:
- `system/init.lua`
- `system/adv/fileio.lua`
- `system/adv/fsave.lua`
- `system/ui/favo.lua`

The `favodata/` directory is your voice favorite backup — you may keep or delete it. The original game files inside the PFS archive are never modified.

### Files

| File | Purpose |
|------|---------|
| `install.bat` | Double-click launcher (bypasses PowerShell execution policy) |
| `install.ps1` | Scans `saveXXXX.png` timestamps → generates `_save_dates` table → assembles `fileio.lua` → deploys all four files → creates `favodata/` |
| `fileio_template.lua` | Patch template; `-- DATE_TABLE_PLACEHOLDER --` replaced by the script. Contains save disk fallback, all favodata infrastructure functions, and voice favorite recovery logic |
| `fsave.lua` | Pre-patched (two changes: embed date into BOWS + HENPRI language fix) |
| `favo.lua` | Pre-patched (voice favorite favodata real-time sync + recovery entry point) |
| `init.lua` | Pre-patched (automatically calls `favo_exportall()` at game startup) |

### How the Patch Works

The game uses the Artemis Engine. Its save system relies on the Lua table `sys.saveslot` inside `savedata/saveg.dat` to index all slots, and its voice favorite system relies on `sys.favo` in the same file. When this file is overwritten by Steam Cloud sync or unknown reasons, both `sys.saveslot` and `sys.favo` are lost.

This patch works by **modifying four of the game's Lua scripts** (the engine loads loose `.lua` files from the filesystem in preference to those packed inside the PFS archive).

After deployment, the game directory looks like:

```
HENPRI/
├── HENPRI.exe
├── HENPRI.pfs                     ← original Lua scripts inside
├── system/
│   ├── init.lua                   ← ★ patched (auto-export at startup)
│   ├── adv/
│   │   ├── fileio.lua             ← ★ patched (save disk fallback + favo recovery)
│   │   └── fsave.lua              ← ★ patched (date embedding + language fix)
│   └── ui/
│       └── favo.lua               ← ★ patched (favodata real-time sync)
├── savedata/                      ← managed by engine (affected by Steam Cloud)
│   ├── saveg.dat                  ← sys table (saveslot + favo index)
│   ├── save0001.dat ~ ...
│   └── save0001.png ~ ...
└── favodata/                      ← ★ voice favorite save folder created by patch (independent of engine, immune to Steam Cloud)
    ├── favog.dat                  ← full sys.favo table backup
    └── favo0001.dat ~ ...         ← per-entry independent voice favorite backups
```

---

#### Part 1: Save Recovery (inherited from NUKITASHI Save Fix)

**Phase 1: Opening the Load Menu — `isSaveFile()` Disk Fallback**

`save.lua` iterates slots, calling `isSaveFile(no)` for each. The original function gives up when `sys.saveslot[no]` is nil. The patch adds an else branch:

```lua
function isSaveFile(num, name)
    ...
    if s then
        file = s.file; ret = s; mask = s.evmask
    else
        -- FALLBACK: disk fallback
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
            sys.saveslot[no] = ret    -- index repaired
        end
    end
    ...
end
```

After `isFile()` confirms that `saveNNNN.dat` physically exists on disk, the `_save_dates` table — generated once by `install.ps1` from the `saveXXXX.png` thumbnail timestamps on the player's own machine — provides a date close to the original save time, and a minimal entry is created.

**Result**: All saves visible in the Load menu. Dates are correct. Chapter titles and dialogue text are blank.

**Phase 2: Loading a Save — `restore()` Metadata Recovery**

When the player loads a save, the Artemis Engine decompresses and deserializes `saveNNNN.dat`, restoring the entire `scr` table into memory. The engine then calls `restore()`, where the patch injects metadata recovery logic:

```lua
function restore(e, p)
    loadconv(true)
    -- metadata auto-recovery
    local function __recover_metadata()
        local no = tonumber(tostring(p.file):match("save(%d+)"))
        if no and no < init.save_suspend then
            local t = sys.saveslot[no]
            if t then
                local need_save = false
                -- Chapter title: scr.adv.title
                local ti = sv.getsavetitle()
                if ti and next(ti) ~= nil then t.title = ti; need_save = true end
                -- Dialogue text: scr.ip.save.text
                -- Save date:     scr.ip.save.date
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
                if need_save then asyssave() end  -- persist to saveg.dat
            end
        end
    end
    pcall(__recover_metadata)
    ...
end
```

Where each piece of data comes from:

| Recovered Item | Memory Source | Written By | Notes |
|---------------|--------------|------------|-------|
| Chapter title | `scr.adv.title` | Game script `sv.savetitle()` | Set each time a new chapter begins |
| Dialogue text | `scr.ip.save.text` | `sv.save()` → `getTextBlockText()` | The text captured at save time |
| Save date | `scr.ip.save.date` | `sv.save()` → `get_unixtime()` | The exact timestamp when saved |

**Result**: Title, dialogue text, and date are all recovered. `asyssave()` persists the complete entry to `saveg.dat`. The next time the Load menu opens, `sys.saveslot` is fully populated — the fallback is no longer needed.

**Phase 3 (Transparent): Embedding Dates at Save Time — `fsave.lua`**

To ensure saves created after the patch carry their own exact date, a single line in `fsave.lua` is changed:

```lua
-- Original:
scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc) }

-- Patched:
scr.ip.save = { text=(tx), txno=(ax.lang), crc=(ax.crc), date=get_unixtime() }
```

The current time is embedded into the BOWS file at save time. Phase 2 reads `scr.ip.save.date` from here. Old saves created before the patch lack this field — the `_save_dates` table serves as the fallback.

---

#### Part 2: Voice Favorite Backup & Recovery (new feature introduced by HENPRI Save Fix)

**Root Cause**: `sys.favo` exists only in `saveg.dat` with no independent file backup. Saves have a two-tier storage of `saveg.dat` (index) + `saveNNNN.dat` (data), but voice favorites have only one tier. If `saveg.dat` is corrupted, voice favorites are permanently lost.

**Solution**: Create a `favodata/` independent directory, mirroring the save system's "index + per-entry file" architecture.

---

##### Flow A: Export Existing Voice Favorites (runs automatically at every startup)

No player action required. `system_starting()` automatically calls `favo_exportall()` after game initialization:

```
favo_exportall()
  │
  ├─ sys.favo nil/empty? → return (no data, silent exit)
  │
  ├─ Iterate each valid entry in sys.favo:
  │    isFile("favodata/favoNNNN.dat")?
  │      ├─ Yes → skip (file already exists)
  │      └─ No  → favo_savefile(no) → write missing file
  │
  └─ New files written or favog.dat missing?
       └─ Yes → favo_saveindex() → update/rebuild index
```

Design highlights:
- **No flag mechanism**: checks file existence directly on each run
- **Per-file granularity**: existing files are skipped; only missing ones are written
- **Auto-rebuild on favodata/ deletion**: all missing → full rewrite; partially missing → fill only gaps

I/O behavior by scenario:

| Scenario | Startup I/O |
|----------|------------|
| First install | All files missing → full write |
| Subsequent normal startup | All files exist → zero I/O |
| `favodata/` manually deleted | All files missing → full rebuild |
| New favorite added during play | `favoclick()` already synced → file exists → skip |

---

##### Flow B: Incremental Sync (triggered by each favorite operation)

```
favoclick() (add favorite)
  ├→ sys.favo[no] = {...}        ← write to memory
  ├→ favo_savefile(no)            ← write favodata/favoNNNN.dat
  ├→ favo_saveindex()             ← update favodata/favog.dat
  └→ asyssave()                   ← persist to saveg.dat

favodelete() (delete favorite)
  ├→ sys.favo[no] = nil           ← remove from memory
  ├→ favo_deletefile(no)          ← delete favodata/favoNNNN.dat
  ├→ favo_saveindex()             ← update favodata/favog.dat
  └→ asyssave()                   ← persist to saveg.dat

favomove() (move/swap favorites)
  ├→ complete swap/move in memory
  ├→ update favoNNNN.dat for both affected slots (write or delete)
  ├→ favo_saveindex()             ← update favodata/favog.dat
  └→ asyssave()                   ← persist to saveg.dat
```

One piece of data, three places on disk: `saveg.dat` + `favog.dat` + `favoNNNN.dat`.

---

##### Flow C: Corruption Recovery (example: saveg.dat overwritten by Steam Cloud)

-Player launches the game

```
restore()
  │
  ├─ __recover_metadata()         ← save metadata recovery
  │    scr.adv.title  → saveslot.title
  │    scr.ip.save.text → saveslot.text
  │    scr.ip.save.date → saveslot.date
  │    asyssave() → write back to saveg.dat
  │
  └─ favo_recover()               ← voice favorite recovery
       │
       │  sys.favo empty → continue
       │
       ├─ Tier 1: favo_loadindex()
       │    favodata/favog.dat exists?
       │    └─ Yes → Pluto deserialize → sys.favo full table restore
       │          → asyssave() → write back to saveg.dat
       │
       └─ Tier 2: favog.dat also corrupted?
            └─ Scan favodata/favoNNNN.dat
                Deserialize each → rebuild sys.favo entry by entry
                → rebuild favog.dat index
                → asyssave() → write back to saveg.dat
```

---

##### Function Dependency Graph

`fileio.lua` loads before `favo.lua`; the callback in `init.lua` is invoked by the engine only after all scripts have loaded:

```
fileio_template.lua (defines)
  ├─ favo_getpath()
  ├─ favo_savefile(no)          ←──┐
  ├─ favo_deletefile(no)        ←──┤
  ├─ favo_saveindex()           ←──┤ called by favo.lua, init.lua
  ├─ favo_loadindex()           ←──┤
  ├─ favo_readfile(no)          ←──┤
  ├─ favo_recover()             ←──┤
  └─ favo_exportall()           ←──┘
```

---

### Differences from NUKITASHI Save Fix

| Aspect | NUKITASHI Save Fix V1.1 | HENPRI Save Fix V1.0 |
|--------|------------------------|----------------------|
| Save recovery | ✅ | ✅ (fully ported) |
| Voice favorite backup | Not supported | favodata/ dual-track redundancy |
| Deployed files | fileio.lua + fsave.lua | fileio.lua + fsave.lua + favo.lua + init.lua |
| Export trigger | Not supported | Auto at startup, fills gaps each run |
| Recovery trigger | restore() | restore() + favo_init() dual fallback |
| Game detection | NUKITASHI.exe | HENPRI.exe |

---

<br>
<p align="center">© 2026 H-2OS (自宅警備員). Some rights reserved.&nbsp;|&nbsp; <a href="./LICENSE.txt">LICENSE</a></p>
