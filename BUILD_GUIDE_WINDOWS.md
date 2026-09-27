# OpenRV Windows ビルド知見ノート

> **本ドキュメントについて**：単に「手順通りに実行すればビルドできる」マニュアルにとどまらず、実際の運用と検証から得られた**実践的な知見とトラブルシューティングの記録**です。
> 実際に行ったフルビルド（CY2024、CY2025）、試行したCY2026での課題、個別依存関係のバージョン引き上げ、上流リリース追従（v4.0.1 → v4.0.2）、およびリポジトリ運用までの一連のプロセスを網羅しています。
> 遭遇した落とし穴、ソースコード調査、ライセンス上の留意点などを記録し、再検証時の手戻りを防ぐことを目的としています。
>
> **AI エージェントへの指示**：Part 3 は順次実行可能なビルド手順です。各フェーズの検証ポイントを確認し、問題発生時は Part 4 のトラブルシューティングを参照してください。Part 1 のコーデック（ProRes, HEVC）に関する判断は、利用環境や目的に応じて各自で適切に確認・判断してください。

---

## 現状の構成サマリー

**適用バージョン**：上流タグ `v4.0.2` ＋ Windows向け修正、VFX Platform **CY2025**、Qt 6.5.3 / Python 3.11.9。一部の主要依存関係をCY2026相当へ引き上げ済み。

対象ブランチ：`custom/win-cy2025`

| 依存関係 | 採用バージョン | 状況 |
|---|---|---|
| Qt / PySide | 6.5.3 | CY2025 デフォルト、**維持**（1.1 参照） |
| Python | 3.11.9 | CY2025 デフォルト |
| OCIO | **2.5.0** | CY2026 相当へ引き上げ |
| Boost | **1.88.0** | 同上 |
| Imath | **3.2.2** | 同上 |
| OpenEXR | **3.4.3** | 同上 |
| NumPy | 1.26.4 | **意図的に維持**（1.6 参照） |

各 VFX Platform の公式標準構成：

| VFX Platform | Qt | Python | OCIO | 状態 |
|---|---|---|---|---|
| CY2024 | 6.5.3 | 3.11.9 | 2.3.2 | フルビルド検証完了 |
| **CY2025** | 6.5.3 | 3.11.9 | 2.4.2 | **実運用（依存関係引き上げ済み）** |
| CY2026 | 6.8.3 | 3.13.9 | 2.5.0 | MuQt6 の Qt 6.8 API 非互換により保留（1.1 参照） |

---

## Part 1 — 設計判断と技術的背景

### 1.1 VFX Platform の選定経緯

1. 当初は **CY2024**（v4.0.1 の公式 CI デフォルト）を採用し、OCIO 2.3.2 にてフルビルドを完了。
2. より新しい OCIO 2.5.0 の利用を検討し、`cmake/defaults/CY2026.cmake` を確認。しかし CY2026 では Qt 6.8.3、Python 3.13.9 を含む全体が大幅に刷新され、上流 CI でのテストマトリクスも存在しない実験的ステータスでした。
3. CY2026 のビルド試行時、`MuQt6`（Mu スクリプト言語の Qt バインディング層）において、Qt 6.8 API の比較演算子仕様変更（クラスメンバから非メンバ/hidden friendへの移行）に起因する**大量のコンパイルエラー**が発生。これを解消するには `src/lib/mu/MuQt6/` 配下の広範なソースコード修正が必要となり、環境設定の範疇を超えるため保留としました。
4. **CY2025 への回帰**：Qt/Python は実績のある 6.5.3 / 3.11.9 を維持しつつ、OCIO を含む主要ライブラリのみを個別に引き上げる構成を採用し、安定したビルドを実現しました。

### 1.2 ProRes に関する留意事項

OpenRV では、ProRes は「non-free」コーデックとしてデフォルト無効化されています。公式ドキュメントでは Windows/Linux 環境でデコードを有効にするには Apple 社からライセンス許諾と SDK を取得することが求められています。
FFmpeg ネイティブの `prores`/`prores_ks` 実装を有効化してビルドする場合、以下のフラグを使用します（ライセンス責任は各利用者に帰属します）：

```
-DRV_FFMPEG_NON_FREE_DECODERS_TO_ENABLE="prores"
-DRV_FFMPEG_NON_FREE_ENCODERS_TO_ENABLE="prores"
```

正規の SDK を使用する場合は `-DRV_DEPS_APPLE_PRORES_SDK_ZIP_PATH` を指定します。

### 1.3 HEVC に関する留意事項

FFmpeg の HEVC デコーダ自体はビルドされていても、`src/lib/image/mio_ffmpeg/init.cpp` に独立したアプリケーション層のランタイム許可リストが存在します：

```cpp
static const char* disallowedCodecsArray[] = {
    "ac3", "hevc", "mpeg2video", "prores", "prores_ks", "prores_aw",
    "prores_lgpl", "svq1", "svq3", 0};
```

HEVC を有効化するには、ProRes と同様に変数へ追加指定する必要があります：

```
-DRV_FFMPEG_NON_FREE_DECODERS_TO_ENABLE="prores;hevc"
```

コーデックの有効化を確認する際は、FFmpeg のビルドフラグだけでなく、アプリ層のログで `Unallowed codec` が出力されていないかを実機ログで確認することが必須です。

### 1.4 ポータビリティとランタイム

ビルド生成物を別マシンへ展開する場合、Visual C++ 再頒布可能パッケージ（`vc_redist.x64.exe`）の事前インストールが必要です。

### 1.5 依存関係の個別引き上げ

`cmake/defaults/CY2025.cmake` 内の各依存関係は個別のバージョンとハッシュ定義を持っているため、特定ライブラリのみを更新可能です：

| 依存関係 | 変更内容 | 結果 |
|---|---|---|
| OCIO | 2.4.2 → **2.5.0** | 成功（Imath >= 3.1.1 必須） |
| Boost | 1.85.0 → **1.88.0** | 成功 |
| Imath | 3.1.12 → **3.2.2** | 成功 |
| OpenEXR | 3.3.6 → **3.4.3** | 成功 |
| NumPy | 1.26.4 → 2.3.0 | **失敗（PySide6 6.5.3 依存のため据え置き）** |

- **NumPy 2.x の制約**：PySide6 6.5.3 のビルドスクリプトが `numpy/core/include` を直接参照しており、NumPy 2.0 で変更されたディレクトリ構造（`numpy/_core/include`）と衝突してコンパイルエラーとなります。

### 1.6 出典情報（Git Hash）に関するバグの修正

`cmake/globals/rv_git.cmake` はビルド時に `git rev-parse` を実行しますが、結果を `SET(... CACHE STRING ...)` で保存しており `FORCE` がありませんでした。そのため、ビルドディレクトリを作成した初回のコミットハッシュが固定化されてしまい、ソースコードを更新してもバイナリ起動時のコミット表示が更新されない問題がありました。両箇所に `FORCE` を付与して修正しています。

---

## Part 2 — 環境要件

| ツール | 推奨バージョン | 備考 |
|---|---|---|
| Visual Studio | 2022 (17.x), **MSVC v143 14.40.x** | "C++によるデスクトップ開発" が必須 |
| Windows SDK | 10.0.20348 以降 | VS インストーラ同梱 |
| Qt | **6.5.3** (`win64_msvc2019_64`) | `aqtinstall` で導入 |
| Python | **3.11.x** (ホスト側) | ビルド用 venv の作成に使用 |
| Rust | 1.92+ | cryptography 等のコンパイルに必要 |
| CMake | 3.27 以降 | CMake 4.x の場合は後述のポリシー設定が必要 |
| MSYS2 | 最新版 | bash, nasm, meson 等を提供。`mingw64\bin` も PATH に追加 |
| Strawberry Perl | 5.32+ | OpenSSL ビルドに必要 |
| Git | 最新版 | Git LFS を含む |

**注意点**：Windows のパス長制限（260文字）を回避するため、リポジトリはドライブ直下に近い短いパス（例：`D:\dev\OpenRV`）に配置し、OS の `LongPathsEnabled` を有効にしてください。また、`vcpkg` などのグローバルパッケージマネージャが PATH に存在すると意図しないライブラリが混入するため、ビルド時は環境変数から除外してください。

---

## Part 3 — ビルド手順

### Phase 0：環境確認

PowerShell にて必要なツール類のバージョンと空きディスク容量を確認します（ビルドには 60GB 以上の空き容量を推奨）：

```powershell
$checks = @("git", "cmake", "python", "perl", "rustc", "cargo")
foreach ($cmd in $checks) { Get-Command $cmd -ErrorAction SilentlyContinue | Select-Object Name, Source }
Get-PSDrive -PSProvider FileSystem | Select-Object Name, @{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}}
```

### Phase 1：ツールのインストール

Qt 6.5.3 の導入：

```powershell
pip install aqtinstall
aqt install-qt windows desktop 6.5.3 win64_msvc2019_64 -O C:\Qt `
  -m qtwebengine qtwebsockets qtmultimedia qtpositioning qtwebchannel
```

MSYS2 パッケージの導入（MINGW64 シェル内）：

```bash
pacman -Syu --noconfirm
pacman -S --needed --noconfirm \
  mingw-w64-x86_64-autotools mingw-w64-x86_64-glew mingw-w64-x86_64-libarchive \
  mingw-w64-x86_64-make mingw-w64-x86_64-meson mingw-w64-x86_64-toolchain \
  autoconf automake bison flex git libtool nasm p7zip patch unzip zip
```

### Phase 2：リポジトリの準備

```powershell
$SRC = "D:\dev\OpenRV"
git clone --recursive https://github.com/mathilda-ximo/OpenRV.git $SRC
cd $SRC
git checkout custom/win-cy2025
```

### Phase 3：Python 仮想環境の構築

```powershell
cd $SRC
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt

# Windows 環境向け python3.exe のエイリアス作成
$PY_DIR = (Split-Path (Get-Command python).Source)
if (-not (Test-Path "$PY_DIR\python3.exe")) {
    Copy-Item "$PY_DIR\python.exe" "$PY_DIR\python3.exe"
}
```

### Phase 4：ビルド環境変数の設定

```powershell
$vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vs -DevCmdArguments "-arch=x64 -host_arch=x64" -SkipAutomaticLocation

.\.venv\Scripts\Activate.ps1

# vcpkg の汚染防止
$env:VCPKG_ROOT = $null
$env:PATH = (($env:PATH -split ";") | Where-Object { $_ -notlike "*vcpkg*" }) -join ";"

# PATH の優先順序設定（VSツールチェーンを最優先にする）
$env:PATH = "$env:PATH;C:\Program Files\CMake\bin;C:\msys64\usr\bin;C:\msys64\mingw64\bin;C:\Strawberry\perl\bin;$env:USERPROFILE\.cargo\bin"

$env:QT_HOME = "C:\Qt\6.5.3\msvc2019_64"
$env:CMAKE_POLICY_VERSION_MINIMUM = "3.5"
```

### Phase 5：Configure および Build

Configure 実行（インストール先パスは必ずスラッシュ `/` を使用）：

```powershell
cmake -B _build -G "Visual Studio 17 2022" -A x64 `
  -DCMAKE_BUILD_TYPE=Release `
  -DRV_DEPS_QT_LOCATION="$env:QT_HOME" `
  -DRV_DEPS_WIN_PERL_ROOT="C:\Strawberry\perl\bin" `
  -DRV_VFX_PLATFORM=CY2025 `
  -DRV_FFMPEG_NON_FREE_DECODERS_TO_ENABLE="prores;hevc" `
  -DRV_FFMPEG_NON_FREE_ENCODERS_TO_ENABLE="prores" `
  -DCMAKE_INSTALL_PREFIX="D:/dev/OpenRV/_install"
```

依存関係のビルド（数時間程度を要します）：

```powershell
cmake --build _build --config Release --target dependencies --parallel 8
```

本体のビルドおよびインストール：

```powershell
cmake --build _build --config Release --target main_executable --parallel 4
cmake --install _build --prefix "D:/dev/OpenRV/_install" --config Release
```

### Phase 6：検証

Python `ctypes` による DLL 内コーデックのシンボル確認：

```python
import ctypes, os
bin_dir = r"D:\dev\OpenRV\_install\bin"
os.add_dll_directory(bin_dir)
avcodec = ctypes.CDLL(os.path.join(bin_dir, "avcodec-62.dll"))
avcodec.avcodec_find_decoder_by_name.restype = ctypes.c_void_p
avcodec.avcodec_find_decoder_by_name.argtypes = [ctypes.c_char_p]

for name in ["h264", "hevc", "prores"]:
    found = avcodec.avcodec_find_decoder_by_name(name.encode())
    print(f"decoder {name}: {'FOUND' if found else 'MISSING'}")
```

テスト動画を再生し、`%APPDATA%\ASWF\OpenRV\OpenRV.log` に `Unallowed codec` 等のエラーがないことを確認します。

---

## Part 4 — トラブルシューティング知識ベース

| 症状 | 原因 | 対処方法 |
|---|---|---|
| `openssl >= 1.0.1k not found using pkg-config` (FFmpeg) | Windows 版 OpenSSL の install に `.pc` が含まれない | `cmake/dependencies/ffmpeg.cmake` でビルドツリーの pkgconfig を追加参照 |
| `ERROR: Found GNU link.exe instead of MSVC link.exe` | MSYS2 の PATH が VS より前にある | VS DevShell のパスを PATH の最優先に配置 |
| `error C1060: compiler is out of heap space` | 並列コンパイルによるメモリ不足 | `--parallel 4` に制限してビルド |
| `rv.exe` の起動バナーの日時・コミットが更新されない | `rv_git.cmake` の CMake キャッシュに `FORCE` がない | `SET(... CACHE STRING ... FORCE)` を追加 |
| CMake 4.x でのポリシーエラー | 過去バージョン互換性の削除 | `CMAKE_POLICY_VERSION_MINIMUM=3.5` を指定 |

---

## Part 5 — GitHub Fork リポジトリ運用の注意点

### GitHub Actions の意図しない実行防止

上流の `.github/workflows/conan.yml` ではリポジトリ所有者ガードが外れている箇所があり、fork 先で毎日スケジュール実行されてアクション時間を過剰に消費するリスクがあります。
本ブランチではガード条件（`if: github.repository_owner == 'AcademySoftwareFoundation'`）を復元しています。また、不要な場合は GitHub のリポジトリ設定（Actions 権限）を無効化しておくことを推奨します。
