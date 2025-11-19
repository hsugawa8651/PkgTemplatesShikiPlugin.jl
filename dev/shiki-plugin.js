// Shiki Highlighter for Documenter.jl
(function() {
    'use strict';

    const SHIKI_CONFIG = {
        theme: 'github-light',
        darkTheme: 'github-dark',
        languages: ["julia", "javascript", "python", "bash", "json", "yaml", "toml"],
        themes: ["github-light", "github-dark"],
        cdnUrl: 'https://esm.sh'
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
                const shiki = await import(`${SHIKI_CONFIG.cdnUrl}/shiki@1.22.2`);
                const transformersModule = await import(`${SHIKI_CONFIG.cdnUrl}/@shikijs/transformers@1.22.2`);

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

        console.log(`🌓 Theme detection: isDark=${isDark}, classes=${htmlElement.className}`);

        // ダークテーマが選択されている場合はダークテーマを使用
        const selectedTheme = isDark ? SHIKI_CONFIG.darkTheme : SHIKI_CONFIG.theme;

        console.log(`🎨 Using theme: ${selectedTheme} (isDark=${isDark})`);

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
                        lines[lineIndex].classList.add(`highlight-level-${colorLevel}`);
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
                            console.log(`   🎨 Applied custom bgcolor "${bgcolor}" to line ${lineNum}`);
                        } else {
                            // デフォルトのレベル色を使用
                            const colorLevel = ((level - 1) % 4) + 1;
                            lines[lineIndex].classList.add(`highlight-level-${colorLevel}`);
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
        const lines = code.split('\n');
        let filteredLines = [];
        let highlightStack = []; // ネストレベルのスタック
        let lineOffset = 0;

        // 各行を処理
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];

            // @highlight: 1,3-4 形式
            if (i === 0 && line.match(/^\s*[#\/\/]\s*@highlight:\s*([\d,-]+)/)) {
                const match = line.match(/^\s*[#\/\/]\s*@highlight:\s*([\d,-]+)/);
                const ranges = parseHighlightRanges(match[1]);
                ranges.forEach(lineNum => {
                    customHighlightLines[lineNum] = 1;
                });
                console.log(`📌 Custom highlight detected: lines $${ranges.join(', ')}`);
                lineOffset++;
                continue; // この行をスキップ
            }

            // 行末の@highlight-endを先に処理
            if (line.match(/[#\/\/]\s*@highlight-end\s*$/)) {
                // 現在のハイライトレベルを適用（@highlight-endを処理する前）
                if (highlightStack.length > 0) {
                    const current = highlightStack[highlightStack.length - 1];
                    customHighlightLines[i - lineOffset + 1] = current;
                    console.log(`   📍 Line $${i - lineOffset + 1} will be highlighted with level $${current.level} (before end)`);
                }
                console.log(`🔚 Found @highlight-end at line $${i + 1}`);
                highlightStack.pop();
                // ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\s*[#\/\/]\s*@highlight-end\s*$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // 行頭の@highlight-auto-end（単独行）を先に処理
            if (line.match(/^\s*[#\/\/]\s*@highlight-auto-end\s*$/)) {
                console.log(`🔚 Found @highlight-auto-end (standalone) at line $${i + 1} - will be removed`);
                highlightStack.pop();
                lineOffset++;
                continue; // この行をスキップ（詰める）
            }

            // 行末の@highlight-auto-end
            if (line.match(/[#\/\/]\s*@highlight-auto-end\s*$/)) {
                // 現在のハイライトレベルを適用（@highlight-auto-endを処理する前）
                if (highlightStack.length > 0) {
                    const current = highlightStack[highlightStack.length - 1];
                    customHighlightLines[i - lineOffset + 1] = current;
                    console.log(`   📍 Line $${i - lineOffset + 1} will be highlighted with level $${current.level} (before auto-end)`);
                }
                console.log(`🔚 Found @highlight-auto-end at line $${i + 1}`);
                highlightStack.pop();
                // ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\s*[#\/\/]\s*@highlight-auto-end\s*$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // @highlight-start[level] 形式（行頭または行末）
            const startMatch = line.match(/^\s*[#\/\/]\s*@highlight-start(?:\[(\d+)\])?|[#\/\/]\s*@highlight-start(?:\[(\d+)\])?\s*$/);
            if (startMatch) {
                const level = startMatch[1] || startMatch[2] || 1;
                const levelNum = typeof level === 'string' ? parseInt(level) : 1;

                // レベルの検証
                if (levelNum < 1) {
                    console.error(`❌ ERROR at line $${i + 1}: @highlight-start level must be >= 1, got $${levelNum}`);
                    filteredLines.push(line);
                    continue;
                }

                // ネストの連続性を検証
                const expectedLevel = highlightStack.length + 1;
                if (levelNum !== expectedLevel) {
                    // 最初のレベルは1でなければならない
                    if (highlightStack.length === 0) {
                        console.error(`❌ ERROR at line $${i + 1}: First @highlight-start must be level 1, got $${levelNum}`);
                    } else {
                        console.error(`❌ ERROR at line $${i + 1}: @highlight-start[$${levelNum}] skips nesting levels. Expected level $${expectedLevel} (current stack: [$${highlightStack.join(', ')}])`);
                    }
                    // エラーでも処理は続行するが、警告を出す
                }

                console.log(`🔥 Found @highlight-start[$${levelNum}] at line $${i + 1}`);
                highlightStack.push({ level: levelNum, bgcolor: null });
                // 行頭の@highlight-startの場合は行全体をスキップ
                if (line.match(/^\s*[#\/\/]\s*@highlight-start/)) {
                    lineOffset++;
                    continue;
                }
                // 行末の@highlight-startの場合は、ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\s*[#\/\/]\s*@highlight-start(?:\[(\d+)\])?\s*$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // @highlight-auto-start 形式（自動ネスト、オプションで bgcolor 指定可能）
            const autoStartMatch = line.match(/^\s*[#\/\/]\s*@highlight-auto-start(?:,\s*bgcolor=([#\w]+))?|[#\/\/]\s*@highlight-auto-start(?:,\s*bgcolor=([#\w]+))?\s*$/);
            if (autoStartMatch) {
                // スタックサイズから自動的にレベルを決定（レベル番号は増え続け、色のみ1-4で循環）
                const autoLevel = highlightStack.length + 1;
                const bgcolor = autoStartMatch[1] || autoStartMatch[2] || null;

                if (bgcolor) {
                    console.log(`🔥 Found @highlight-auto-start,bgcolor=$${bgcolor} at line $${i + 1}, auto level: $${autoLevel}`);
                } else {
                    console.log(`🔥 Found @highlight-auto-start at line $${i + 1}, auto level: $${autoLevel}`);
                }

                // レベルと背景色をオブジェクトとして保存
                highlightStack.push({ level: autoLevel, bgcolor: bgcolor });

                // 行頭の場合は行全体をスキップ
                if (line.match(/^\s*[#\/\/]\s*@highlight-auto-start/)) {
                    lineOffset++;
                    continue;
                }
                // 行末の場合は、ディレクティブを削除して行を保持
                const cleanedLine = line.replace(/\s*[#\/\/]\s*@highlight-auto-start(?:,\s*bgcolor=[#\w]+)?\s*$/, '');
                filteredLines.push(cleanedLine);
                continue;
            }

            // 行頭の@highlight-end（単独行は詰める - ハイライト対象外）
            if (line.match(/^\s*[#\/\/]\s*@highlight-end\s*$/)) {
                console.log(`🔚 Found @highlight-end (standalone) at line $${i + 1} - will be removed`);
                highlightStack.pop();
                lineOffset++;
                continue; // この行をスキップ（詰める）
            }

            // 現在のハイライトレベルを適用
            if (highlightStack.length > 0) {
                // 最も深いレベル（最後の要素）を使用
                const current = highlightStack[highlightStack.length - 1];
                customHighlightLines[i - lineOffset + 1] = current;
                console.log(`   📍 Line $${i - lineOffset + 1} will be highlighted with level $${current.level}`);
            }

            filteredLines.push(line);
        }

        // フィルタリング後のコードを使用
        code = filteredLines.join('\n');

        // text言語の場合はShiki処理をスキップ（プレーンテキスト表示）
        if (lang === 'text') {
            console.log(`📝 Skipping Shiki for plain text block`);
            return;
        }

        // サポートされていない言語の場合はスキップ
        if (!SHIKI_CONFIG.languages.includes(lang)) {
            console.log(`⚠️  Skipping unsupported language: ${lang}`);
            return;
        }

        try {
            const highlighter = await loadShiki();
            if (!highlighter) {
                console.warn('⚠️  Highlighter not available, skipping...');
                return;
            }

            const theme = getCurrentTheme();
            console.log(`🎨 Highlighting ${lang} code with theme: ${theme}`);

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

            console.log(`🔍 Found ${codeBlocks.length} code blocks to highlight`);

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

            console.log(`🎉 Successfully highlighted ${codeBlocks.length} code blocks with Shiki`);
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
