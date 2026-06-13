# Wuthering Waves Gacha Link Extractor

[中文](#中文) | [English](#english)

---

## 中文

### 项目简介

这是一个基于 PowerShell 的鸣潮抽卡链接提取脚本。  
它会从运行中的 `KRWebView.exe` 主进程命令行参数中提取 Base64 编码数据，解码后解析出抽卡记录页面链接及相关参数。

在 `3.4` 之前，社区常见做法是直接从 `client.log` 中提取抽卡链接。  
但在 `3.4` 之后，库洛对该文件进行了加密或二进制化处理，已经无法继续通过原来的方式直接提取，因此才改用当前这套方案。

脚本文件：

- `Get-WuwaGachaLink.ps1`

### 工作原理

当游戏内打开抽卡记录页面时，鸣潮会启动或复用 `KRWebView.exe`。
该进程的主命令行参数中包含一段编码后的 JSON 数据，其中包括：

- 抽卡记录页面 URL
- `player_id`
- `gacha_id`
- `gacha_type`
- `record_id`
- `svr_id`
- `userId`

脚本会自动：

- 过滤掉 `--type=renderer`、`--type=gpu-process` 等子进程
- 定位主 `KRWebView.exe` 进程
- 提取编码参数
- 自动处理参数尾部 `..` 到标准 Base64 `==` 的兼容问题
- 解码并输出抽卡记录链接

### 环境要求

- Windows
- PowerShell 5.x 或 PowerShell 7
- 游戏运行中
- 已打开或即将打开抽卡记录页面

### 使用方法

以下命令基于 GitHub Raw 链接远程调用脚本，无需手动下载到本地：

#### 1. 单次抓取

```powershell
powershell -NoExit -Command "iex (irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1')"
```

#### 2. 输出 JSON

适合其他程序调用：

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -AsJson"
```

#### 3. 持续监听

适合先运行脚本，再进入游戏打开抽卡记录页：

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -Watch"
```

#### 4. 自动复制链接

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -Copy"
```

#### 5. 输出 AccessToken

默认不输出敏感字段，如需输出：

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -AsJson -IncludeAccessToken"
```

#### 6. 自定义监听间隔

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -Watch -IntervalSeconds 2"
```

### 参数说明

- `-Watch`
  持续监听 `KRWebView.exe`，直到抓到新链接。

- `-IntervalSeconds`
  监听模式轮询间隔，默认 `1` 秒。

- `-Copy`
  抓到结果后自动复制 URL 到剪贴板。

- `-AsJson`
  以 JSON 格式输出，适合脚本或程序二次调用。

- `-IncludeAccessToken`
  额外输出 `accessToken`。此参数涉及敏感信息，请谨慎使用。

### 输出示例

```json
{
  "Source": "process_cmdline",
  "ProcessId": 36500,
  "ParentProcessId": 16908,
  "Url": "https://aki-gm-resources.aki-game.com/aki/gacha/index.html#/record?...",
  "PlayerId": "117631947",
  "GachaId": "100070",
  "GachaType": "1",
  "RecordId": "f481280443e6e9b8b3acc36d515fc4a9",
  "ServerId": "76402e5b20be2c39f095a152090afddc",
  "ServerArea": "cn",
  "Language": "zh-Hans",
  "Platform": "PC",
  "UserId": "537671067",
  "Uuid": "566a4441-3fb4-420d-b811-9d6d45afc0e8",
  "CapturedAt": "2026-06-13T14:39:19"
}
```

### 常见问题

#### 没有输出结果

请检查：

- 游戏是否正在运行
- 是否已经打开抽卡记录页面
- 是否使用了 `-Watch` 模式等待页面打开

### 安全说明

- 抽卡链接和 `accessToken` 都属于敏感信息
- 不建议将原始链接直接公开分享
- 不建议默认保存到磁盘
- 上传截图或日志前请先脱敏

### License

如需发布到 GitHub，建议你自行补充许可证，例如 `MIT License`。

---

## English

### Overview

This is a PowerShell-based Wuthering Waves gacha link extractor.
It reads the encoded startup argument from the main `KRWebView.exe` process, decodes it, and extracts the gacha record page URL and related parameters.

Before version `3.4`, the common community approach was to extract the gacha link directly from `client.log`.
After `3.4`, Kuro encrypted or converted that file into a non-plain-text format, so the old method no longer works reliably.
This script uses a different approach based on the `KRWebView.exe` process command line.

Script file:

- `Get-WuwaGachaLink.ps1`

### How It Works

When the in-game gacha record page is opened, Wuthering Waves launches or reuses `KRWebView.exe`.
The main process command line contains a Base64-like JSON payload with data such as:

- gacha record page URL
- `player_id`
- `gacha_id`
- `gacha_type`
- `record_id`
- `svr_id`
- `userId`

The script automatically:

- filters out subprocesses such as `--type=renderer` and `--type=gpu-process`
- locates the main `KRWebView.exe` process
- extracts the encoded argument
- converts the trailing `..` back to standard Base64 `==`
- decodes the payload and outputs the gacha record link

### Requirements

- Windows
- PowerShell 5.x or PowerShell 7
- The game must be running
- The gacha record page must be open or about to be opened

### Usage

The following commands execute the script directly from the GitHub Raw URL, without downloading the file manually:

#### 1. One-time capture

```powershell
powershell -NoExit -Command "iex (irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1')"
```

#### 2. Output as JSON

Recommended for programmatic usage:

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -AsJson"
```

#### 3. Watch mode

Run the script first, then open the gacha record page in-game:

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -Watch"
```

#### 4. Copy the URL automatically

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -Copy"
```

#### 5. Include AccessToken

Sensitive fields are hidden by default. To include `accessToken`:

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -AsJson -IncludeAccessToken"
```

#### 6. Custom polling interval

```powershell
powershell -NoExit -Command "& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/jcx515250418qq/WuwaGachaLinkExtractor/main/Get-WuwaGachaLink.ps1'))) -Watch -IntervalSeconds 2"
```

### Parameters

- `-Watch`
  Continuously monitors `KRWebView.exe` and prints newly captured links.

- `-IntervalSeconds`
  Polling interval in watch mode. Default is `1`.

- `-Copy`
  Copies the extracted URL to the clipboard.

- `-AsJson`
  Outputs JSON for scripts or external programs.

- `-IncludeAccessToken`
  Includes `accessToken` in the output. Use with caution.

### Example Output

```json
{
  "Source": "process_cmdline",
  "ProcessId": 36500,
  "ParentProcessId": 16908,
  "Url": "https://aki-gm-resources.aki-game.com/aki/gacha/index.html#/record?...",
  "PlayerId": "117631947",
  "GachaId": "100070",
  "GachaType": "1",
  "RecordId": "f481280443e6e9b8b3acc36d515fc4a9",
  "ServerId": "76402e5b20be2c39f095a152090afddc",
  "ServerArea": "cn",
  "Language": "zh-Hans",
  "Platform": "PC",
  "UserId": "537671067",
  "Uuid": "566a4441-3fb4-420d-b811-9d6d45afc0e8",
  "CapturedAt": "2026-06-13T14:39:19"
}
```

### FAQ

#### No output is returned

Please check:

- the game is running
- the gacha record page has been opened
- you are using `-Watch` mode if the page will be opened later

### Security Notes

- Gacha links and `accessToken` are sensitive
- Do not publish raw links without masking
- Do not store sensitive output by default unless necessary
- Remove or mask private values before sharing screenshots or logs

### License

If you publish this project on GitHub, consider adding a license such as `MIT`.
