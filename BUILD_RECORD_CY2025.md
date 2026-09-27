# OpenRV カスタムビルド記録 — CY2025（依存関係更新版）

- **日付**: 2026-08-29 00:55
- **ソース**: `v4.0.2` + カスタムコミット（CY2025依存関係調整）
- **ブランチ**: `custom/win-cy2025`
- **VFX Platform**: CY2025
- **ホスト環境**: Windows, MSVC v143 14.40.33807, CMake generator "Visual Studio 17 2022" x64

> 公式の標準ビルドではありません。公式タグ `v4.0.2` の上にWindows環境向けの修正とCY2026相当への依存関係更新を適用しています。なお、`rv.exe` 起動時に `Version 4.0.0` と表示されますが、これは上流の `CMakeLists.txt` における `RV_REVISION_NUMBER` が `0` に固定されているためです。実際の識別情報は起動バナー内のコミットハッシュとなります。

## 採用された依存関係バージョン

`bin/` に実際に配置されたDLLを検証済み：

| 依存関係 | バージョン | 備考 |
|---|---|---|
| Qt | 6.5.3 | CY2025 デフォルト（変更なし） |
| Python | 3.11.9 | CY2025 デフォルト（変更なし） |
| PySide | 6.5.3 | CY2025 デフォルト（変更なし） |
| **OCIO** | **2.5.0** | 2.4.2 から更新（`OpenColorIO_2_5.dll`） |
| **Boost** | **1.88.0** | 1.85.0 から更新（`boost_*-1_88.dll`） |
| **Imath** | **3.2.2** | 3.1.12 から更新（`Imath-3_2.dll`） |
| **OpenEXR** | **3.4.3** | 3.3.6 から更新（`OpenEXR-3_4.dll`） |
| NumPy | 1.26.4 | **意図的に据え置き**（詳細は後述） |
| OpenSSL | 3.6.2 | CY2025 デフォルト（CY2026の3.6.0より新しい） |

上記4つの更新により、Qt 6.5.3の変更を伴わない範囲で、CY2025の依存関係をCY2026の固定バージョンまで引き上げています。

- **NumPy を 1.26.4 に据え置いた理由**：CY2026は 2.3.0 を指定していますが、PySide6 6.5.3 の `build_scripts/utils.py:get_numpy_location()` は `numpy/core/include` をハードコードしています。NumPy 2.0 ではこのパスが `numpy/_core/include` へ変更されたため、shiboken6 で `fatal error C1083: Cannot open include file: 'numpy/arrayobject.h'` が発生します。PySide が 6.5.3 に留まる限り、NumPy 2.x への更新は回避する必要があります。
- **Qt / PySide / Python を据え置いた理由**：Qt 6.8.3 では MuQt6 が破損します。Qt 6.8 で比較演算子がクラス外へ移動されたためです。これには単なるバージョン変更ではなく、本格的なソースコードの移植が必要となります。

## コーデックに関する設定

個人の検証・制作環境における利用を前提とし、以下のオプションを明示的に指定してビルドを行っています。これらはデフォルト設定ではありません：

```
-DRV_FFMPEG_NON_FREE_DECODERS_TO_ENABLE="prores;hevc"
-DRV_FFMPEG_NON_FREE_ENCODERS_TO_ENABLE="prores"
```

- **ProRes**：OpenRV では ProRes は「non-free」としてデフォルト無効になっています。公式ドキュメントでは Windows/Linux で ProRes デコードを有効にするには Apple 社からライセンス許諾と SDK を取得することが求められています。本ビルドでは FFmpeg ネイティブの `prores`/`prores_ks` 実装を使用しています。
- **HEVC**：ProRes とは独立して、`src/lib/image/mio_ffmpeg/init.cpp` のアプリケーション層にランタイムの許可リストが存在します。FFmpeg 内にデコーダをコンパイルするだけでなく、`RV_FFMPEG_NON_FREE_DECODERS_TO_ENABLE` に `hevc` を渡す必要があります。

## v4.0.2 に対するソースコード変更点

| 項目 | 変更内容 |
|---|---|
| `.gitignore` | VFX Platform ごとのビルド生成物を除外 |
| `cmake/dependencies/ffmpeg.cmake` | Windows 上で pkg-config が OpenSSL ビルドツリーを参照するよう修正（`--enable-openssl` 時に `openssl >= 1.0.1k not found` となる上流バグの修正） |
| `src/build/requirements.txt.in` | cryptography 42.0.5→44.0.2、pydantic 2.7.1→2.10.6（Python 3.13 / PyO3 互換性向上） |
| `cmake/defaults/CY2025.cmake` | 上記4つの依存関係バージョン引き上げ |
| `.github/workflows/conan.yml` | repository-owner ガードの復元（上流でコメントアウトされており、fork 先で nightly cron が誤実行される問題の防止） |
| `cmake/globals/rv_git.cmake` | キャッシュされた Git ハッシュとブランチに `FORCE` を追加（上流バグ修正、詳細は後述） |

### 出典情報（Git Hash）に関するバグの修正

`rv_git.cmake` は configure 実行ごとに `git rev-parse` を呼び出しますが、結果を `SET(... CACHE STRING ...)` で保存しており `FORCE` がありませんでした。CMake キャッシュは未定義時のみ書き込まれるため、ビルドディレクトリを最初に configure した時点のハッシュとブランチ名が固定されてしまいます。
`rv_git.cmake` の該当箇所に `FORCE` を付与することで、常に正確なコミットハッシュがバイナリ起動バナーに反映されるよう修正しました。

## 動作検証

`avcodec-62.dll` に対する `avcodec_find_decoder_by_name` / `avcodec_find_encoder_by_name` を用いた直接検証：

```
decoder h264: FOUND    decoder hevc: FOUND    decoder prores: FOUND
encoder prores: FOUND  encoder prores_ks: FOUND
```

実際のメディアファイルを `rv.exe` で開き、`%APPDATA%\ASWF\OpenRV\OpenRV.log` を確認：

| ファイル形式 | 検証結果 |
|---|---|
| H.264 `.mov` | エラーログなし |
| HEVC `.mov` | エラーログなし |
| ProRes 422 HQ `.mov` | エラーログなし |
| OpenEXR `.exr` | 正常確認（`Read image info from test_exr.exr`） |

`Unallowed codec` や `Unsupported codec`、`[error]` は出力されず、クラッシュダンプも生成されませんでした。

**注意事項**：上記はエラーやクラッシュが発生しないことをログレベルで確認したものです。また、OCIO についてはリンクレベルの確認となっており、実案件で使用する際は事前に `$OCIO` 環境変数を適切な config に向けて動作確認を行ってください。

## ビルド時の注意点

`--parallel 8` で実行した際、空きメモリが約 7.4 GB の状態で `RvDocument.cpp` のコンパイル中に `error C1060: compiler is out of heap space` が発生しました。`--parallel 4` に制限することで安定してビルドが完了します。
