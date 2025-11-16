module ShikiHighlighter

using Documenter

export shiki_html, add_shiki_assets

"""
    shiki_html(; theme="github-light", dark_theme="github-dark", languages=[...], kwargs...)

Shikiハイライト機能付きのDocumenter.HTML()を返します。
すべてのDocumenter.HTML()オプションをサポートします。

# Shiki固有のオプション
- `theme::String="github-light"`: デフォルトテーマ
- `dark_theme::String="github-dark"`: ダークモード用テーマ
- `languages::Vector{String}`: サポートする言語のリスト
- `cdn_url::String="https://esm.sh"`: ShikiライブラリのCDN URL
- `load_themes::Vector{String}=String[]`: ロードするテーマのリスト

# Documenter.HTMLオプション
その他のキーワード引数はすべてDocumenter.HTML()に渡されます。
"""
function shiki_html(;
    # Shiki固有オプション
    theme="github-light",
    dark_theme="github-dark",
    languages=["julia", "javascript", "python", "bash", "json", "yaml", "toml"],
    cdn_url="https://esm.sh",
    load_themes=String[],
    # Documenter.HTMLの基本オプション
    prettyurls=true,
    disable_git=false,
    edit_link=nothing,
    canonical=nothing,
    assets=String[],
    analytics="",
    collapselevel=2,
    sidebar_sitename=true,
    mathengine=Documenter.KaTeX(),
    footer=nothing,
    ansicolor=false,
    warn_outdated=true,
    prerender=true,  # highlight.jsの読み込みをスキップ
    highlights=String[],  # 追加の言語なし
    kwargs... # その他のDocumenter.HTMLオプション
)
    # load_themesが空の場合、themeとdark_themeを使用
    if isempty(load_themes)
        load_themes = unique([theme, dark_theme])
    end

    # Shiki用アセットを追加（ルートディレクトリから読み込む）
    shiki_assets = copy(assets)
    push!(shiki_assets, "shiki-plugin.css")
    push!(shiki_assets, "shiki-plugin.js")

    # グローバルにShiki設定を保存（アセット生成で使用）
    global SHIKI_CONFIG = (
        theme=theme,
        dark_theme=dark_theme,
        languages=languages,
        cdn_url=cdn_url,
        load_themes=load_themes
    )

    # 標準のDocumenter.HTML()を返す
    return Documenter.HTML(;
        prettyurls=prettyurls,
        disable_git=disable_git,
        edit_link=edit_link,
        canonical=canonical,
        assets=shiki_assets,
        analytics=analytics,
        collapselevel=collapselevel,
        sidebar_sitename=sidebar_sitename,
        mathengine=mathengine,
        footer=footer,
        ansicolor=ansicolor,
        warn_outdated=warn_outdated,
        prerender=prerender,
        highlights=highlights,
        kwargs...
    )
end

# グローバル設定変数
SHIKI_CONFIG = nothing

"""
    add_shiki_assets(build_dir::String)

指定したビルドディレクトリにShikiのCSSとJavaScriptアセットを追加します。
makedocs()の後に呼び出してください。

# 使用例
```julia
makedocs(
    sitename="My Documentation",
    format=shiki_html(theme="github-dark"),
    pages=["Home" => "index.md"]
)
add_shiki_assets("docs/build")  # ビルド後にアセットを追加
```
"""
function add_shiki_assets(build_dir::String)
    if SHIKI_CONFIG === nothing
        @warn "Shiki configuration not found. Please use shiki_html() function first."
        return
    end

    # ビルドディレクトリのルートにファイルを作成（Documenterの期待する場所）
    mkpath(build_dir)

    # CSS ファイルを作成
    css_content = generate_shiki_css()
    css_path = joinpath(build_dir, "shiki-plugin.css")
    write(css_path, css_content)

    # JavaScript ファイルを作成
    js_content = generate_shiki_javascript(SHIKI_CONFIG)
    js_path = joinpath(build_dir, "shiki-plugin.js")
    write(js_path, js_content)

    @info "📦 Created Shiki assets: $(css_path), $(js_path)"
end

"""
    generate_shiki_css()

Shiki用のCSSスタイルを生成します。
"""
function generate_shiki_css()
    return """
/* Shiki Highlighter Plugin Styles */

/* デフォルトのコードブロックスタイル（Shiki適用前） */
pre code {
    color: inherit !important;
    background: transparent !important;
}

html.theme--dark pre code,
html.theme--documenter-dark pre code {
    color: #c9d1d9 !important;
}

.shiki-loading {
    position: relative;
    background: #f6f8fa;
    border-radius: 6px;
    padding: 16px;
    font-family: 'JetBrains Mono', 'Fira Code', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
    font-size: 14px;
    line-height: 1.5;
    border: 1px solid #e1e4e8;
    margin: 1em 0;
}

.shiki-loading::after {
    content: "⚡ Loading syntax highlighting...";
    color: #666;
    font-style: italic;
    opacity: 0.7;
    animation: pulse 1.5s ease-in-out infinite alternate;
}

@keyframes pulse {
    from { opacity: 0.4; }
    to { opacity: 0.8; }
}

.shiki {
    background-color: transparent !important;
    border-radius: 6px;
    padding: 16px;
    overflow-x: auto;
    font-family: 'JetBrains Mono', 'Fira Code', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
    font-size: 14px;
    line-height: 1.5;
    border: 1px solid #e1e4e8;
    margin: 1em 0;
    position: relative;
}

.shiki code {
    background: none !important;
    padding: 0 !important;
    border-radius: 0 !important;
    font-weight: inherit;
    color: inherit;
    font-size: inherit;
}

.shiki pre {
    margin: 0;
    padding: 0;
    background: transparent;
    overflow: visible;
    font-size: inherit;
}

/* ダークモード対応 */
@media (prefers-color-scheme: dark) {
    .shiki-loading {
        background: #0d1117;
        border-color: #30363d;
        color: #c9d1d9;
    }

    .shiki {
        border-color: #30363d;
    }
}

/* Documenterテーマとの統合 */
html.theme--dark .shiki-loading,
html.theme--documenter-dark .shiki-loading {
    background: #0d1117;
    border-color: #30363d;
    color: #c9d1d9;
}

html.theme--dark .shiki,
html.theme--documenter-dark .shiki {
    border-color: #30363d;
}

/* Shikiのテーマが提供する色をそのまま使用 - キーワードと数字はそのまま */
/* 変数名（i, j等の通常の識別子）のみを上書き */

/* ライトテーマ: 変数名を黒にする */
html.theme--light .shiki span[style*="color:#383A42"],
html.theme--light .shiki span[style*="color:#383a42"] {
    color: #000000 !important;
}

/* ダークテーマ: 変数名を白にする */
html.theme--dark .shiki span[style*="color:#383A42"],
html.theme--dark .shiki span[style*="color:#383a42"],
html.theme--documenter-dark .shiki span[style*="color:#383A42"],
html.theme--documenter-dark .shiki span[style*="color:#383a42"] {
    color: #ffffff !important;
}

/* ライトテーマで薄いテキストを濃くする */
html.theme--light .shiki span[style*="color:#6F42C1"],
html.theme--light .shiki span[style*="color:#6f42c1"] {
    color: #5a32a3 !important;  /* より濃い紫 */
}

html.theme--light .shiki span[style*="color:#032F62"],
html.theme--light .shiki span[style*="color:#032f62"] {
    color: #022543 !important;  /* より濃い青 */
}

/* ライトテーマのコメントを濃くする */
html.theme--light .shiki span[style*="color:#A0A1A7"],
html.theme--light .shiki span[style*="color:#a0a1a7"],
html.theme--light .shiki span[style*="color:#969896"],
html.theme--light .shiki span[style*="color:#8E908C"] {
    color: #5a5d62 !important;  /* より濃いグレー */
}

/* ライトテーマの薄いグレーテキストを濃くする */
html.theme--light .shiki span[style*="color:#383A42"],
html.theme--light .shiki span[style*="color:#383a42"] {
    color: #000000 !important;  /* 完全な黒 */
}

/* ライトテーマの識別子（灰色のテキスト）をコメントと同じ濃さにする */
html.theme--light .shiki span[style*="color:#959DA5"],
html.theme--light .shiki span[style*="color:#959da5"],
html.theme--light .shiki span[style*="color:#6A737D"],
html.theme--light .shiki span[style*="color:#6a737d"] {
    color: #5a5d62 !important;  /* コメントと同じ濃いグレー */
}

/* ライトテーマのデフォルト色の識別子も濃くする */
html.theme--light .shiki span[style*="color:#24292E"],
html.theme--light .shiki span[style*="color:#24292e"] {
    color: #000000 !important;  /* 完全な黒 */
}

/* ライトテーマの変数名・関数名を濃くする */
html.theme--light .shiki span[style*="color:#E45649"],
html.theme--light .shiki span[style*="color:#e45649"] {
    color: #d73a49 !important;  /* より濃い赤 */
}

html.theme--light .shiki span[style*="color:#4078F2"],
html.theme--light .shiki span[style*="color:#4078f2"] {
    color: #0366d6 !important;  /* より濃い青 */
}

/* ライトテーマの薄いピンク色を濃くする */
html.theme--light .shiki span[style*="color:#F97583"],
html.theme--light .shiki span[style*="color:#f97583"] {
    color: #000000 !important;  /* 完全な黒（識別子） */
}

/* ライトテーマの薄い青を濃くする */
html.theme--light .shiki span[style*="color:#79B8FF"],
html.theme--light .shiki span[style*="color:#79b8ff"],
html.theme--light .shiki span[style*="color:#79B8ff"] {
    color: #000000 !important;  /* 完全な黒（識別子） */
}

/* ライトテーマの薄いグレーを濃くする */
html.theme--light .shiki span[style*="color:#E1E4E8"],
html.theme--light .shiki span[style*="color:#e1e4e8"],
html.theme--light .shiki span[style*="color:#E1E4e8"] {
    color: #000000 !important;  /* 完全な黒 */
}

/* ライトテーマの薄い緑を濃くする */
html.theme--light .shiki span[style*="color:#85E89D"],
html.theme--light .shiki span[style*="color:#85e89d"] {
    color: #22863a !important;  /* 濃い緑 */
}

/* ライトテーマの薄い紫を濃くする（one-lightテーマ） */
html.theme--light .shiki span[style*="color:#B392F0"],
html.theme--light .shiki span[style*="color:#b392f0"] {
    color: #6f42c1 !important;  /* 濃い紫 */
}

/* 行番号サポート */
.shiki .line {
    min-height: 1.5em;
}

/* スクロールバーのスタイリング */
.shiki::-webkit-scrollbar {
    height: 8px;
}

.shiki::-webkit-scrollbar-track {
    background: transparent;
}

.shiki::-webkit-scrollbar-thumb {
    background: rgba(0,0,0,0.2);
    border-radius: 4px;
}

.shiki::-webkit-scrollbar-thumb:hover {
    background: rgba(0,0,0,0.3);
}

/* コピーボタン */
.shiki .copy-button {
    position: absolute;
    top: 8px;
    right: 8px;
    opacity: 0;
    transition: opacity 0.2s;
    background: rgba(255,255,255,0.9);
    border: 1px solid #e1e4e8;
    border-radius: 4px;
    padding: 4px 8px;
    font-size: 12px;
    cursor: pointer;
    font-family: inherit;
    z-index: 10;
}

.shiki:hover .copy-button {
    opacity: 1;
}

.shiki .copy-button:hover {
    background: rgba(255,255,255,1);
}

html.theme--dark .shiki .copy-button ,
html.theme--documenter-dark .shiki .copy-button {
    background: rgba(13,17,23,0.9);
    border-color: #30363d;
    color: #c9d1d9;
}

html.theme--dark .shiki .copy-button:hover ,
html.theme--documenter-dark .shiki .copy-button:hover {
    background: rgba(13,17,23,1);
}

/* ハイライト行のスタイル - レベル1 (黄色) */
.shiki .highlighted,
.shiki .line.highlighted,
.shiki .highlight-level-1 {
    background-color: rgba(255, 255, 0, 0.1);
    display: inline-block;
    width: 100%;
    position: relative;
}

.shiki .highlighted::before,
.shiki .line.highlighted::before,
.shiki .highlight-level-1::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(255, 255, 0, 0.1);
    z-index: -1;
}

/* レベル2 (赤色) */
.shiki .highlight-level-2 {
    background-color: rgba(255, 100, 100, 0.15);
    display: inline-block;
    width: 100%;
    position: relative;
}

/* ハイライト行でも通常の文字色ルールを適用 */

.shiki .highlight-level-2::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(255, 100, 100, 0.15);
    z-index: -1;
}

/* レベル3 (緑色) */
.shiki .highlight-level-3 {
    background-color: rgba(100, 255, 100, 0.15);
    display: inline-block;
    width: 100%;
    position: relative;
}

.shiki .highlight-level-3::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(100, 255, 100, 0.15);
    z-index: -1;
}

/* レベル4 (青色) */
.shiki .highlight-level-4 {
    background-color: rgba(100, 150, 255, 0.15);
    display: inline-block;
    width: 100%;
    position: relative;
}

.shiki .highlight-level-4::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(100, 150, 255, 0.15);
    z-index: -1;
}

/* ダークモードでのハイライト - 行全体の背景色変更 */
html.theme--dark .shiki .highlighted,
html.theme--dark .shiki .line.highlighted,
html.theme--dark .shiki .highlight-level-1 ,
html.theme--documenter-dark .shiki .highlight-level-1 {
    /* レベル1: 黄色系 - 行全体に薄い背景色 */
    background-color: rgba(255, 234, 0, 0.1);
    display: inline-block;
    width: 100%;
    position: relative;
}

html.theme--dark .shiki .highlighted::before,
html.theme--dark .shiki .line.highlighted::before,
html.theme--dark .shiki .highlight-level-1::before ,
html.theme--documenter-dark .shiki .highlight-level-1::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(255, 234, 0, 0.1);
    z-index: -1;
}

/* ハイライト行でも通常の色ルールを使用（フィルタなし） */

html.theme--dark .shiki .highlight-level-2 ,
html.theme--documenter-dark .shiki .highlight-level-2 {
    /* レベル2: 赤系 - 行全体に薄い背景色 */
    background-color: rgba(255, 95, 109, 0.1);
    display: inline-block;
    width: 100%;
    position: relative;
}

html.theme--dark .shiki .highlight-level-2::before ,
html.theme--documenter-dark .shiki .highlight-level-2::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(255, 95, 109, 0.1);
    z-index: -1;
}


html.theme--dark .shiki .highlight-level-3 ,
html.theme--documenter-dark .shiki .highlight-level-3 {
    /* レベル3: 緑系 - 行全体に薄い背景色 */
    background-color: rgba(95, 255, 135, 0.1);
    display: inline-block;
    width: 100%;
    position: relative;
}

html.theme--dark .shiki .highlight-level-3::before ,
html.theme--documenter-dark .shiki .highlight-level-3::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(95, 255, 135, 0.1);
    z-index: -1;
}


html.theme--dark .shiki .highlight-level-4 ,
html.theme--documenter-dark .shiki .highlight-level-4 {
    /* レベル4: 青系 - 行全体に薄い背景色 */
    background-color: rgba(100, 181, 255, 0.1);
    display: inline-block;
    width: 100%;
    position: relative;
}

html.theme--dark .shiki .highlight-level-4::before ,
html.theme--documenter-dark .shiki .highlight-level-4::before {
    content: '';
    position: absolute;
    left: -16px;
    right: -16px;
    top: 0;
    bottom: 0;
    background-color: rgba(100, 181, 255, 0.1);
    z-index: -1;
}


/* 差分表示のスタイル（オプション） */
.shiki .diff.add {
    background-color: rgba(46, 160, 67, 0.15);
}

.shiki .diff.remove {
    background-color: rgba(248, 81, 73, 0.15);
}

html.theme--dark .shiki .diff.add ,
html.theme--documenter-dark .shiki .diff.add {
    background-color: rgba(46, 160, 67, 0.2);
}

html.theme--dark .shiki .diff.remove ,
html.theme--documenter-dark .shiki .diff.remove {
    background-color: rgba(248, 81, 73, 0.2);
}

/* Catppuccinテーマを設定メニューから隠す */
#documenter-themepicker option[value="catppuccin-latte"],
#documenter-themepicker option[value="catppuccin-frappe"],
#documenter-themepicker option[value="catppuccin-macchiato"],
#documenter-themepicker option[value="catppuccin-mocha"] {
    display: none;
}
"""
end

"""
    generate_shiki_javascript(config)

Shiki用のJavaScriptコードを生成します。
"""
function generate_shiki_javascript(config)
    themes_json = join(["\"$theme\"" for theme in config.load_themes], ", ")
    languages_json = join(["\"$lang\"" for lang in config.languages], ", ")

    return """
// Shiki Highlighter for Documenter.jl
(function() {
    'use strict';

    const SHIKI_CONFIG = {
        theme: '$(config.theme)',
        darkTheme: '$(config.dark_theme)',
        languages: [$(languages_json)],
        themes: [$(themes_json)],
        cdnUrl: '$(config.cdn_url)'
    };

    let shikiHighlighter = null;
    let isLoading = false;
    let loadingPromise = null;

    console.log('🎨 ShikiHighlighter initialized');
    console.log('📋 Config:', SHIKI_CONFIG);

    // Transformersを格納する変数
    let shikiTransformers = null;

    // Shikiの動的インポート
    async function loadShiki() {
        if (shikiHighlighter) return shikiHighlighter;
        if (isLoading) return loadingPromise;

        isLoading = true;

        loadingPromise = (async () => {
            try {
                console.log('📦 Loading Shiki highlighter and transformers...');

                // ES Modules形式でShikiとTransformersをロード
                const shiki = await import(`\${SHIKI_CONFIG.cdnUrl}/shiki@1.22.2`);
                const transformersModule = await import(`\${SHIKI_CONFIG.cdnUrl}/@shikijs/transformers@1.22.2`);

                // Transformersを保存
                shikiTransformers = transformersModule;

                shikiHighlighter = await shiki.createHighlighter({
                    themes: SHIKI_CONFIG.themes,
                    langs: SHIKI_CONFIG.languages
                });

                console.log('✅ Shiki highlighter and transformers loaded successfully');
                return shikiHighlighter;

            } catch (error) {
                console.error('❌ Failed to load Shiki:', error);
                return null;
            } finally {
                isLoading = false;
            }
        })();

        return loadingPromise;
    }

    // テーマ検出
    function getCurrentTheme() {
        // Documenterのテーマをチェック
        const htmlElement = document.documentElement;

        // 複数のダークテーマクラスをチェック
        const isDark = htmlElement.classList.contains('theme--dark') ||
                      htmlElement.classList.contains('theme--documenter-dark') ||
                      htmlElement.classList.contains('documenter-dark') ||
                      htmlElement.getAttribute('data-theme') === 'dark' ||
                      htmlElement.getAttribute('data-theme') === 'documenter-dark';

        console.log(`🌓 Theme detection: isDark=\${isDark}, classes=\${htmlElement.className}`);

        // ダークテーマが選択されている場合はダークテーマを使用
        const selectedTheme = isDark ? SHIKI_CONFIG.darkTheme : SHIKI_CONFIG.theme;

        console.log(`🎨 Using theme: \${selectedTheme} (isDark=\${isDark})`);

        return selectedTheme;
    }

    // 範囲文字列をパース: "1,3-4" -> [1, 3, 4]
    function parseHighlightRanges(rangeStr) {
        const ranges = [];
        rangeStr.split(',').forEach(part => {
            part = part.trim();
            if (part.includes('-')) {
                const [start, end] = part.split('-').map(s => parseInt(s.trim()));
                for (let i = start; i <= end; i++) {
                    ranges.push(i);
                }
            } else {
                const num = parseInt(part);
                if (!isNaN(num)) {
                    ranges.push(num);
                }
            }
        });
        return ranges;
    }

    // 特定の行にハイライトクラスを追加（レベル対応）
    function addHighlightToLines(preElement, lineHighlights) {
        const codeElement = preElement.querySelector('code');
        if (!codeElement) return;

        // Shikiが生成する各行の<span>を取得
        const lines = codeElement.querySelectorAll('.line');

        // lineHighlightsが配列の場合（後方互換性）
        if (Array.isArray(lineHighlights)) {
            lineHighlights.forEach(lineNum => {
                const lineIndex = lineNum - 1;
                if (lines[lineIndex]) {
                    lines[lineIndex].classList.add('highlighted');
                }
            });
        }
        // lineHighlightsがオブジェクトの場合（レベル付き、bgcolor対応）
        else if (typeof lineHighlights === 'object') {
            Object.entries(lineHighlights).forEach(([lineNum, info]) => {
                const lineIndex = parseInt(lineNum) - 1;
                if (lines[lineIndex]) {
                    // info が数値の場合（後方互換性）
                    if (typeof info === 'number') {
                        const colorLevel = ((info - 1) % 4) + 1;
                        lines[lineIndex].classList.add(`highlight-level-\${colorLevel}`);
                    }
                    // info がオブジェクトの場合（レベル + bgcolor）
                    else if (typeof info === 'object') {
                        const level = info.level;
                        const bgcolor = info.bgcolor;

                        if (bgcolor) {
                            // カスタム背景色を指定
                            lines[lineIndex].style.backgroundColor = bgcolor;
                            lines[lineIndex].style.display = 'inline-block';
                            lines[lineIndex].style.width = '100%';
                            lines[lineIndex].style.position = 'relative';
                            console.log(`   🎨 Applied custom bgcolor "\${bgcolor}" to line \${lineNum}`);
                        } else {
                            // デフォルトのレベル色を使用
                            const colorLevel = ((level - 1) % 4) + 1;
                            lines[lineIndex].classList.add(`highlight-level-\${colorLevel}`);
                        }
                    }
                }
            });
        }
    }

    // コードブロックのハイライト
    async function highlightCodeBlock(codeBlock) {
        const pre = codeBlock.parentElement;

        // 元のコードを保存（data属性に保存されていればそれを使用）
        let code = pre.dataset.originalCode || codeBlock.textContent;

        // 初回レンダリング時は元のコードと言語を保存
        if (!pre.dataset.originalCode) {
            pre.dataset.originalCode = code;
            const langClass = Array.from(codeBlock.classList).find(cls => cls.startsWith('language-'));
            if (langClass) {
                pre.dataset.originalLang = langClass;
            }
        }

        const langClass = Array.from(codeBlock.classList).find(cls => cls.startsWith('language-'));
        let lang = langClass ? langClass.replace('language-', '') : 'text';

        // nohighlight- で始まる言語はShiki処理をスキップ
        if (lang.startsWith('nohighlight-') || lang === 'nohighlight') {
            console.log(`🚫 Skipping Shiki for nohighlight block`);
            return;
        }

        // julia-repl を julia として扱う
        if (lang === 'julia-repl') {
            lang = 'julia';
        }

        // @highlight: 形式の検出
        let customHighlightLines = {};
        const lines = code.split('\\n');
        let filteredLines = [];
        let highlightStack = []; // ネストレベルのスタック
        let lineOffset = 0;

        // 各行を処理
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // @highlight: 1,3-4 形式
            if (i === 0 && line.match(/^\\s*[#\\/\\/]\\s*@highlight:\\s*([\\d,-]+)/)) {
                const match = line.match(/^\\s*[#\\/\\/]\\s*@highlight:\\s*([\\d,-]+)/);
                const ranges = parseHighlightRanges(match[1]);
                ranges.forEach(lineNum => {
                    customHighlightLines[lineNum] = 1;
                });
                console.log(`📌 Custom highlight detected: lines \$\${ranges.join(', ')}`);
                lineOffset++;
                continue; // この行をスキップ
            }

            // 行末の@highlight-endを先に処理
            if (line.match(/[#\\/\\/]\\s*@highlight-end\\s*\$/)) {
                // 現在のハイライトレベルを適用（@highlight-endを処理する前）
                if (highlightStack.length > 0) {
                    const current = highlightStack[highlightStack.length - 1];
                    customHighlightLines[i - lineOffset + 1] = current;
                    console.log(`   📍 Line \$\${i - lineOffset + 1} will be highlighted with level \$\${current.level} (before end)`);
                }
                console.log(`🔚 Found @highlight-end at line \$\${i + 1}`);
                highlightStack.pop();
                // ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\\s*[#\\/\\/]\\s*@highlight-end\\s*\$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // 行頭の@highlight-auto-end（単独行）を先に処理
            if (line.match(/^\\s*[#\\/\\/]\\s*@highlight-auto-end\\s*\$/)) {
                console.log(`🔚 Found @highlight-auto-end (standalone) at line \$\${i + 1} - will be removed`);
                highlightStack.pop();
                lineOffset++;
                continue; // この行をスキップ（詰める）
            }

            // 行末の@highlight-auto-end
            if (line.match(/[#\\/\\/]\\s*@highlight-auto-end\\s*\$/)) {
                // 現在のハイライトレベルを適用（@highlight-auto-endを処理する前）
                if (highlightStack.length > 0) {
                    const current = highlightStack[highlightStack.length - 1];
                    customHighlightLines[i - lineOffset + 1] = current;
                    console.log(`   📍 Line \$\${i - lineOffset + 1} will be highlighted with level \$\${current.level} (before auto-end)`);
                }
                console.log(`🔚 Found @highlight-auto-end at line \$\${i + 1}`);
                highlightStack.pop();
                // ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\\s*[#\\/\\/]\\s*@highlight-auto-end\\s*\$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // @highlight-start[level] 形式（行頭または行末）
            const startMatch = line.match(/^\\s*[#\\/\\/]\\s*@highlight-start(?:\\[(\\d+)\\])?|[#\\/\\/]\\s*@highlight-start(?:\\[(\\d+)\\])?\\s*\$/);
            if (startMatch) {
                const level = startMatch[1] || startMatch[2] || 1;
                const levelNum = typeof level === 'string' ? parseInt(level) : 1;

                // レベルの検証
                if (levelNum < 1) {
                    console.error(`❌ ERROR at line \$\${i + 1}: @highlight-start level must be >= 1, got \$\${levelNum}`);
                    filteredLines.push(line);
                    continue;
                }

                // ネストの連続性を検証
                const expectedLevel = highlightStack.length + 1;
                if (levelNum !== expectedLevel) {
                    // 最初のレベルは1でなければならない
                    if (highlightStack.length === 0) {
                        console.error(`❌ ERROR at line \$\${i + 1}: First @highlight-start must be level 1, got \$\${levelNum}`);
                    } else {
                        console.error(`❌ ERROR at line \$\${i + 1}: @highlight-start[\$\${levelNum}] skips nesting levels. Expected level \$\${expectedLevel} (current stack: [\$\${highlightStack.join(', ')}])`);
                    }
                    // エラーでも処理は続行するが、警告を出す
                }

                console.log(`🔥 Found @highlight-start[\$\${levelNum}] at line \$\${i + 1}`);
                highlightStack.push({ level: levelNum, bgcolor: null });
                // 行頭の@highlight-startの場合は行全体をスキップ
                if (line.match(/^\\s*[#\\/\\/]\\s*@highlight-start/)) {
                    lineOffset++;
                    continue;
                }
                // 行末の@highlight-startの場合は、ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\\s*[#\\/\\/]\\s*@highlight-start(?:\\[(\\d+)\\])?\\s*\$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // @highlight-auto-start 形式（自動ネスト、オプションで bgcolor 指定可能）
            const autoStartMatch = line.match(/^\\s*[#\\/\\/]\\s*@highlight-auto-start(?:,\\s*bgcolor=([#\\w]+))?|[#\\/\\/]\\s*@highlight-auto-start(?:,\\s*bgcolor=([#\\w]+))?\\s*\$/);
            if (autoStartMatch) {
                // スタックサイズから自動的にレベルを決定（レベル番号は増え続け、色のみ1-4で循環）
                const autoLevel = highlightStack.length + 1;
                const bgcolor = autoStartMatch[1] || autoStartMatch[2] || null;

                if (bgcolor) {
                    console.log(`🔥 Found @highlight-auto-start,bgcolor=\$\${bgcolor} at line \$\${i + 1}, auto level: \$\${autoLevel}`);
                } else {
                    console.log(`🔥 Found @highlight-auto-start at line \$\${i + 1}, auto level: \$\${autoLevel}`);
                }

                // レベルと背景色をオブジェクトとして保存
                highlightStack.push({ level: autoLevel, bgcolor: bgcolor });

                // 行頭の場合は行全体をスキップ
                if (line.match(/^\\s*[#\\/\\/]\\s*@highlight-auto-start/)) {
                    lineOffset++;
                    continue;
                }
                // 行末の場合は、ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\\s*[#\\/\\/]\\s*@highlight-auto-start(?:,\\s*bgcolor=[#\\w]+)?\\s*\$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // 行頭の@highlight-end（単独行は詰める - ハイライト対象外）
            if (line.match(/^\\s*[#\\/\\/]\\s*@highlight-end\\s*\$/)) {
                console.log(`🔚 Found @highlight-end (standalone) at line \$\${i + 1} - will be removed`);
                highlightStack.pop();
                lineOffset++;
                continue; // この行をスキップ（詰める）
            }

            // 現在のハイライトレベルを適用
            if (highlightStack.length > 0) {
                // 最も深いレベル（最後の要素）を使用
                const current = highlightStack[highlightStack.length - 1];
                customHighlightLines[i - lineOffset + 1] = current;
                console.log(`   📍 Line \$\${i - lineOffset + 1} will be highlighted with level \$\${current.level}`);
            }

            filteredLines.push(line);
        }

        // フィルタリング後のコードを使用
        code = filteredLines.join('\\n');

        // text言語の場合はShiki処理をスキップ（プレーンテキスト表示）
        if (lang === 'text') {
            console.log(`📝 Skipping Shiki for plain text block`);
            return;
        }

        // サポートされていない言語の場合はスキップ
        if (!SHIKI_CONFIG.languages.includes(lang)) {
            console.log(`⚠️  Skipping unsupported language: \${lang}`);
            return;
        }

        try {
            const highlighter = await loadShiki();
            if (!highlighter) {
                console.warn('⚠️  Highlighter not available, skipping...');
                return;
            }

            const theme = getCurrentTheme();
            console.log(`🎨 Highlighting \${lang} code with theme: \${theme}`);

            // Transformersを使用してハイライト
            const transformers = [];
            if (shikiTransformers) {
                // メタデータによるハイライト {1,3-4} 形式
                if (shikiTransformers.transformerMetaHighlight) {
                    transformers.push(shikiTransformers.transformerMetaHighlight());
                }
                // コメント記法によるハイライト [!code highlight]
                if (shikiTransformers.transformerNotationHighlight) {
                    transformers.push(shikiTransformers.transformerNotationHighlight({
                        matchAlgorithm: 'v3'  // コメント行の次の行からカウント
                    }));
                }
                // 差分表示用のtransformer（オプション）
                if (shikiTransformers.transformerNotationDiff) {
                    transformers.push(shikiTransformers.transformerNotationDiff({
                        matchAlgorithm: 'v3'
                    }));
                }
            }

            const html = highlighter.codeToHtml(code, {
                lang,
                theme,
                transformers: transformers
            });

            // 新しいShiki要素を作成
            const tempDiv = document.createElement('div');
            tempDiv.innerHTML = html;
            const shikiPre = tempDiv.querySelector('pre');

            if (shikiPre) {
                // カスタムハイライト行がある場合は適用
                if (Object.keys(customHighlightLines).length > 0) {
                    console.log(`✨ Applying highlights:`, customHighlightLines);
                    addHighlightToLines(shikiPre, customHighlightLines);
                }

                // コピーボタンを追加
                const copyButton = document.createElement('button');
                copyButton.className = 'copy-button';
                copyButton.textContent = 'Copy';
                copyButton.onclick = (e) => {
                    e.preventDefault();
                    navigator.clipboard.writeText(code).then(() => {
                        copyButton.textContent = 'Copied!';
                        setTimeout(() => copyButton.textContent = 'Copy', 2000);
                    }).catch(() => {
                        // フォールバック: テキストエリアを使用
                        const textarea = document.createElement('textarea');
                        textarea.value = code;
                        document.body.appendChild(textarea);
                        textarea.select();
                        document.execCommand('copy');
                        document.body.removeChild(textarea);
                        copyButton.textContent = 'Copied!';
                        setTimeout(() => copyButton.textContent = 'Copy', 2000);
                    });
                };
                shikiPre.appendChild(copyButton);

                // 元の要素を置き換え
                const parentPre = codeBlock.closest('pre');
                if (parentPre) {
                    parentPre.parentNode.replaceChild(shikiPre, parentPre);
                } else {
                    codeBlock.parentNode.replaceChild(shikiPre, codeBlock);
                }
            }

        } catch (error) {
            console.error('❌ Error highlighting code:', error);
        }
    }

    // 全てのコードブロックを処理
    async function highlightAllCodeBlocks() {
        // 既に処理中の場合はスキップ
        if (highlightAllCodeBlocks.isRunning) {
            console.log('⏳ Highlight already in progress, skipping...');
            return;
        }
        highlightAllCodeBlocks.isRunning = true;

        try {
            // highlight.jsのクラスも含めて、全てのコードブロックを選択
            // hljs クラスが付いていても処理する
            const codeBlocks = document.querySelectorAll('pre:not(.shiki) code[class*="language-"], pre:not(.shiki) code.hljs, pre:not(.shiki) code:not([class])');

            if (codeBlocks.length === 0) {
                console.log('📄 No unprocessed code blocks found');
                return;
            }

            console.log(`🔍 Found \${codeBlocks.length} code blocks to highlight`);

            // ローディング状態を表示
            codeBlocks.forEach(block => {
                const pre = block.closest('pre');
                if (pre && !pre.classList.contains('shiki')) {
                    pre.classList.add('shiki-loading');
                }
            });

            // バッチ処理で同時実行数を制限
            const BATCH_SIZE = 5;
            const codeBlocksArray = Array.from(codeBlocks);

            for (let i = 0; i < codeBlocksArray.length; i += BATCH_SIZE) {
                const batch = codeBlocksArray.slice(i, i + BATCH_SIZE);
                await Promise.all(batch.map(highlightCodeBlock));
            }

            // ローディング状態を削除
            document.querySelectorAll('.shiki-loading').forEach(el => {
                el.classList.remove('shiki-loading');
            });

            console.log(`🎉 Successfully highlighted \${codeBlocks.length} code blocks with Shiki`);
        } finally {
            highlightAllCodeBlocks.isRunning = false;
        }
    }

    // テーマ変更の監視
    function observeThemeChanges() {
        const observer = new MutationObserver(async (mutations) => {
            for (const mutation of mutations) {
                if (mutation.type === 'attributes' &&
                    (mutation.attributeName === 'class' || mutation.attributeName === 'data-theme')) {
                    console.log('🎨 Theme changed, re-highlighting...');

                    // Highlighterインスタンスをリセット
                    highlighterInstance = null;

                    // 既存のShikiブロックを元の状態に戻す
                    const blocks = document.querySelectorAll('pre.shiki');
                    for (const pre of blocks) {
                        const codeElement = pre.querySelector('code');
                        if (codeElement && pre.dataset.originalCode) {
                            // 元のコードを復元
                            codeElement.textContent = pre.dataset.originalCode;
                            // Shikiクラスを削除して再処理可能にする
                            pre.classList.remove('shiki');
                            // 元のクラスを維持
                            const langClass = pre.dataset.originalLang;
                            if (langClass && !codeElement.classList.contains(langClass)) {
                                codeElement.classList.add(langClass);
                            }
                        }
                    }

                    // 少し待ってから再ハイライト
                    await new Promise(resolve => setTimeout(resolve, 200));
                    await highlightAllCodeBlocks();
                    break;
                }
            }
        });

        observer.observe(document.documentElement, {
            attributes: true,
            attributeFilter: ['class', 'data-theme']
        });

        // prefers-color-schemeの変更も監視
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', async () => {
            console.log('🌙 System theme changed, re-highlighting...');

            // Highlighterインスタンスをリセット
            highlighterInstance = null;

            // 既存のShikiブロックを元の状態に戻す
            const blocks = document.querySelectorAll('pre.shiki');
            for (const pre of blocks) {
                const codeElement = pre.querySelector('code');
                if (codeElement && pre.dataset.originalCode) {
                    // 元のコードを復元
                    codeElement.textContent = pre.dataset.originalCode;
                    // Shikiクラスを削除して再処理可能にする
                    pre.classList.remove('shiki');
                    // 元のクラスを維持
                    const langClass = pre.dataset.originalLang;
                    if (langClass && !codeElement.classList.contains(langClass)) {
                        codeElement.classList.add(langClass);
                    }
                }
            }

            // 少し待ってから再ハイライト
            await new Promise(resolve => setTimeout(resolve, 200));
            await highlightAllCodeBlocks();
        });
    }

    // DOM準備完了時に実行
    function initialize() {
        // テーマ変更の監視を先に開始
        observeThemeChanges();

        // 複数のタイミングでハイライトを試行
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', () => {
                highlightAllCodeBlocks();
            });
        } else {
            // 即座に実行
            highlightAllCodeBlocks();
        }

        // Documenterの初期化完了を待つ
        setTimeout(() => {
            highlightAllCodeBlocks();
        }, 250);

        // さらに遅延させて再実行（フォールバック）
        setTimeout(() => {
            highlightAllCodeBlocks();
        }, 1000);
    }

    // 初期化実行
    initialize();

    // ページ全体の読み込み完了後も実行
    window.addEventListener('load', () => {
        setTimeout(highlightAllCodeBlocks, 100);
    });

    // グローバルに公開（デバッグ用）
    window.ShikiHighlighter = {
        rehighlight: highlightAllCodeBlocks,
        config: SHIKI_CONFIG,
        getCurrentTheme: getCurrentTheme
    };

})();
"""
end

end # module
