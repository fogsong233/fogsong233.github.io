'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const defaultConfig = {
  command: 'typst',
  features: ['html'],
  extraArgs: [],
  inlineMathSvg: true,
  copyableMathSvg: true
};

const inlineMathFramePrelude = `
#show math.equation.where(block: false): it => html.elem(
  "span",
  attrs: (class: "typst-inline-math-frame"),
  html.frame(it),
)
`;

function readLocalCommand(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8').split(/\r?\n/, 1)[0].trim();
  } catch (error) {
    if (error && error.code === 'ENOENT') return '';
    throw error;
  }
}

function resolveTypstCommand(config, root) {
  if (config.command && config.command !== 'typst') return config.command;

  const envCommand = process.env.TYPST_COMMAND || '';
  if (envCommand) return envCommand;

  const localCommand = readLocalCommand(path.join(root, '.typst-command'));
  if (localCommand) return localCommand;

  const localNightly = '/tmp/typst-main-target/release/typst';
  if (fs.existsSync(localNightly)) return localNightly;

  return config.command || 'typst';
}

function firstExistingPath(paths) {
  return paths.find(candidate => candidate && fs.existsSync(candidate));
}

function resolveSourcePath(hexo, dataPath) {
  if (!dataPath) return null;

  const candidates = path.isAbsolute(dataPath)
    ? [dataPath]
    : [
        path.resolve(hexo.base_dir, dataPath),
        path.resolve(hexo.source_dir, dataPath)
      ];

  return firstExistingPath(candidates) || candidates[0];
}

function htmlParts(html) {
  const headMatch = html.match(/<head[^>]*>([\s\S]*?)<\/head>/i);
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  const styles = headMatch
    ? Array.from(headMatch[1].matchAll(/<style\b[^>]*>[\s\S]*?<\/style>/gi))
        .map(match => match[0].trim())
        .join('\n')
    : '';
  const body = (bodyMatch ? bodyMatch[1] : html).trim();
  return { styles, body };
}

function frontMatter(text) {
  const match = text.match(/^\uFEFF?---\r?\n([\s\S]*?)\r?\n---\r?\n?/);
  return match ? match[1] : '';
}

function frontMatterValue(text, key) {
  const pattern = new RegExp(`^${key}:\\s*(.+?)\\s*$`, 'm');
  const match = frontMatter(text).match(pattern);
  return match ? match[1].replace(/^['"]|['"]$/g, '') : '';
}

function stripFrontMatter(text) {
  return text.replace(/^\uFEFF?---\r?\n[\s\S]*?\r?\n---\r?\n?/, '');
}

function readSource(data, sourcePath) {
  if (sourcePath && fs.existsSync(sourcePath)) {
    return fs.readFileSync(sourcePath, 'utf8');
  }

  if (typeof data.text === 'string') return data.text;

  if (Buffer.isBuffer(data.text)) {
    return data.text.toString('utf8');
  }

  return '';
}

function renderMode(source, userConfig) {
  const mode = frontMatterValue(source, 'typst_render') || userConfig.render || 'html';
  return mode.toLowerCase();
}

function createTemporaryInput(sourceDir, sourcePath, input) {
  const baseName = sourcePath ? path.basename(sourcePath, path.extname(sourcePath)) : 'input';
  const safeName = baseName.replace(/[^a-zA-Z0-9_.-]/g, '_').slice(0, 80);
  const suffix = `${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const tempPath = path.join(sourceDir, `.hexo-typst-${safeName}-${suffix}.typ`);

  fs.writeFileSync(tempPath, input);
  return tempPath;
}

function featureArgs(config) {
  const features = Array.isArray(config.features) ? config.features : [];
  return features.length > 0 ? ['--features', features.join(',')] : [];
}

function svgPages(outputDir) {
  return fs.readdirSync(outputDir)
    .filter(file => file.endsWith('.svg'))
    .sort()
    .map(file => fs.readFileSync(path.join(outputDir, file), 'utf8'));
}

function svgBody(svg, index) {
  return `<figure class="typst-page" style="margin:1.5rem auto;max-width:100%;overflow-x:auto" aria-label="Typst page ${index + 1}">${svg}</figure>`;
}

function runTypst(config, args, sourceDir, dataPath) {
  const result = spawnSync(config.command, args, {
    cwd: sourceDir,
    encoding: 'utf8',
    maxBuffer: 1024 * 1024 * 32
  });

  if (result.error && result.status === null) {
    throw new Error(
      `Failed to run "${config.command}": ${result.error.message}. Install Typst and make sure it is available on PATH.`
    );
  }

  if (result.status !== 0) {
    const location = dataPath ? ` while rendering ${dataPath}` : '';
    const message = result.stderr || result.stdout || `Typst exited with status ${result.status}`;
    throw new Error(`Typst failed${location}:\n${message.trim()}`);
  }

  return result.stdout;
}

function compileHtml(config, root, sourceDir, tempPath, dataPath) {
  const extraArgs = Array.isArray(config.extraArgs) ? config.extraArgs : [];
  const args = [
    'compile',
    '--format',
    'html',
    '--root',
    root,
    ...featureArgs(config),
    ...extraArgs,
    tempPath,
    '-'
  ];

  return runTypst(config, args, sourceDir, dataPath);
}

function renderSvg(config, root, sourceDir, tempPath, dataPath) {
  const outputDir = path.join(sourceDir, `.hexo-typst-svg-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`);
  fs.mkdirSync(outputDir);

  const output = path.join(outputDir, 'page-{0p}.svg');
  const extraArgs = Array.isArray(config.svgExtraArgs) ? config.svgExtraArgs : [];
  const args = [
    'compile',
    '--format',
    'svg',
    '--root',
    root,
    ...featureArgs(config),
    ...extraArgs,
    tempPath,
    output
  ];

  try {
    runTypst(config, args, sourceDir, dataPath);
    return svgPages(outputDir).map(svgBody).join('\n');
  } finally {
    fs.rmSync(outputDir, { recursive: true, force: true });
  }
}

function decodeEntities(text) {
  const named = {
    amp: '&',
    lt: '<',
    gt: '>',
    quot: '"',
    apos: "'",
    nbsp: ' '
  };

  return text.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (entity, body) => {
    if (body[0] === '#') {
      const value = body[1].toLowerCase() === 'x'
        ? Number.parseInt(body.slice(2), 16)
        : Number.parseInt(body.slice(1), 10);
      return Number.isFinite(value) ? String.fromCodePoint(value) : entity;
    }
    return Object.prototype.hasOwnProperty.call(named, body) ? named[body] : entity;
  });
}

function htmlToText(html) {
  return decodeEntities(html
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/(p|div|section|article|h[1-6]|li|ul|ol|tr|table|math|figure)>/gi, '\n')
    .replace(/<[^>]+>/g, '')
    .replace(/[ \t]+\n/g, '\n')
    .replace(/\n[ \t]+/g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim());
}

function escapeAttribute(value) {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/"/g, '&quot;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function inlineMathElements(html) {
  return Array.from(html.matchAll(/<math\b(?![^>]*\bdisplay\s*=\s*["']block["'])[^>]*>[\s\S]*?<\/math>/gi))
    .map(match => match[0]);
}

function mathFrameAssets() {
  return `<style>
.typst-inline-math-frame {
  display: inline-block;
  position: relative;
  vertical-align: -0.15em;
}
.typst-inline-math-frame > svg {
  display: inline-block !important;
  vertical-align: middle;
}
.typst-inline-math-copy {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  pointer-events: none;
}
</style>
<script>
(function () {
  if (window.__typstInlineMathCopyInstalled) return;
  window.__typstInlineMathCopyInstalled = true;

  document.addEventListener('copy', function (event) {
    var selection = window.getSelection();
    if (!selection || selection.rangeCount === 0 || !event.clipboardData) return;

    var fragment = selection.getRangeAt(0).cloneContents();
    if (!fragment.querySelectorAll) return;

    var changed = false;
    fragment.querySelectorAll('.typst-inline-math-frame').forEach(function (frame) {
      var copy = frame.querySelector('.typst-inline-math-copy');
      if (!copy) return;
      frame.replaceWith(copy.cloneNode(true));
      changed = true;
    });

    if (!changed) return;

    var container = document.createElement('div');
    container.appendChild(fragment);
    event.clipboardData.setData('text/html', container.innerHTML);
    event.clipboardData.setData('text/plain', container.textContent);
    event.preventDefault();
  });
})();
</script>`;
}

function addCopyableMathFrames(framedBody, semanticBody) {
  const inlineMath = inlineMathElements(semanticBody);
  let index = 0;

  return framedBody.replace(
    /<span class="typst-inline-math-frame">(<svg\b[\s\S]*?<\/svg>)<\/span>/gi,
    (match, svg) => {
      const math = inlineMath[index];
      index += 1;

      if (!math) return match;

      return [
        `<span class="typst-inline-math-frame" data-copy-text="${escapeAttribute(htmlToText(math))}">`,
        svg,
        `<span class="typst-inline-math-copy" aria-hidden="true">${math}</span>`,
        `</span>`
      ].join('');
    }
  );
}

function renderHtml(config, root, sourceDir, sourcePath, input, dataPath) {
  const useInlineMathSvg = config.inlineMathSvg !== false;
  const copyableMathSvg = config.copyableMathSvg !== false;
  const framedInput = useInlineMathSvg ? `${inlineMathFramePrelude}\n${input}` : input;
  const framedTempPath = createTemporaryInput(sourceDir, sourcePath, framedInput);
  let semanticTempPath = null;

  try {
    const framed = compileHtml(config, root, sourceDir, framedTempPath, dataPath);
    const framedParts = htmlParts(framed);

    if (!useInlineMathSvg || !copyableMathSvg) {
      return [framedParts.styles, framedParts.body].filter(Boolean).join('\n');
    }

    semanticTempPath = createTemporaryInput(sourceDir, sourcePath, input);
    const semantic = compileHtml(config, root, sourceDir, semanticTempPath, dataPath);
    const semanticParts = htmlParts(semantic);
    const body = addCopyableMathFrames(framedParts.body, semanticParts.body);

    return [framedParts.styles, mathFrameAssets(), body].filter(Boolean).join('\n');
  } finally {
    fs.rmSync(framedTempPath, { force: true });
    if (semanticTempPath) fs.rmSync(semanticTempPath, { force: true });
  }
}

hexo.extend.renderer.register('typ', 'html', function typstRenderer(data) {
  const userConfig = hexo.config.typst || {};
  const config = Object.assign({}, defaultConfig, userConfig);
  const sourcePath = resolveSourcePath(hexo, data.path);
  const sourceDir = sourcePath ? path.dirname(sourcePath) : hexo.source_dir;
  const root = path.resolve(hexo.base_dir, config.root || '.');
  config.command = resolveTypstCommand(config, root);
  const source = readSource(data, sourcePath);
  const input = stripFrontMatter(source);
  const mode = renderMode(source, userConfig);

  if (mode === 'html') {
    return renderHtml(config, root, sourceDir, sourcePath, input, data.path);
  }

  const tempPath = createTemporaryInput(sourceDir, sourcePath, input);
  try {
    if (mode === 'svg') return renderSvg(config, root, sourceDir, tempPath, data.path);
    return renderHtml(config, root, sourceDir, sourcePath, input, data.path);
  } finally {
    fs.rmSync(tempPath, { force: true });
  }
});
