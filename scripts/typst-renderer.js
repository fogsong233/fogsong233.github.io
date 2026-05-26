'use strict';

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const defaultConfig = {
  command: 'typst',
  features: ['html'],
  extraArgs: []
};

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

function htmlBodyFragment(html) {
  const headMatch = html.match(/<head[^>]*>([\s\S]*?)<\/head>/i);
  const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  const styles = headMatch
    ? Array.from(headMatch[1].matchAll(/<style\b[^>]*>[\s\S]*?<\/style>/gi))
        .map(match => match[0].trim())
        .join('\n')
    : '';
  const body = (bodyMatch ? bodyMatch[1] : html).trim();
  return [styles, body].filter(Boolean).join('\n');
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

function svgPages(outputDir) {
  return fs.readdirSync(outputDir)
    .filter(file => file.endsWith('.svg'))
    .sort()
    .map(file => fs.readFileSync(path.join(outputDir, file), 'utf8'));
}

function svgBody(svg, index) {
  return `<figure class="typst-page" style="margin:1.5rem auto;max-width:100%;overflow-x:auto" aria-label="Typst page ${index + 1}">${svg}</figure>`;
}

function renderSvg(config, root, sourceDir, tempPath, dataPath) {
  const outputDir = path.join(sourceDir, `.hexo-typst-svg-${process.pid}-${Date.now()}-${Math.random().toString(16).slice(2)}`);
  fs.mkdirSync(outputDir);

  const output = path.join(outputDir, 'page-{0p}.svg');
  const extraArgs = Array.isArray(config.svgExtraArgs) ? config.svgExtraArgs : [];
  const args = ['compile', '--format', 'svg', '--root', root, ...extraArgs, tempPath, output];

  let result;
  try {
    result = spawnSync(config.command, args, {
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

    return svgPages(outputDir).map(svgBody).join('\n');
  } finally {
    fs.rmSync(outputDir, { recursive: true, force: true });
  }
}

function renderHtml(config, root, sourceDir, tempPath, dataPath) {
  const args = ['compile', '--format', 'html', '--root', root];

  const features = Array.isArray(config.features) ? config.features : [];
  if (features.length > 0) {
    args.push('--features', features.join(','));
  }

  const extraArgs = Array.isArray(config.extraArgs) ? config.extraArgs : [];
  args.push(...extraArgs, tempPath, '-');

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

  return htmlBodyFragment(result.stdout);
}

hexo.extend.renderer.register('typ', 'html', function typstRenderer(data) {
  const userConfig = hexo.config.typst || {};
  const config = Object.assign({}, defaultConfig, userConfig);
  const sourcePath = resolveSourcePath(hexo, data.path);
  const sourceDir = sourcePath ? path.dirname(sourcePath) : hexo.source_dir;
  const root = path.resolve(hexo.base_dir, config.root || '.');
  const source = readSource(data, sourcePath);
  const input = stripFrontMatter(source);
  const mode = renderMode(source, userConfig);

  const tempPath = createTemporaryInput(sourceDir, sourcePath, input);
  try {
    if (mode === 'svg') return renderSvg(config, root, sourceDir, tempPath, data.path);
    return renderHtml(config, root, sourceDir, tempPath, data.path);
  } finally {
    fs.rmSync(tempPath, { force: true });
  }
});
