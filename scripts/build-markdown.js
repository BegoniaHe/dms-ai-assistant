#!/usr/bin/env node
/**
 * Build script for markdown2html.mjs
 * Bundles markdown-it with Qt-compatible settings and custom renderer
 */

const fs = require('fs');
const esbuild = require('esbuild');

const isWatch = process.argv.includes('--watch');

async function build() {
  try {
    console.log('Building markdown2html.mjs for Qt QML V4 engine...');

    // Create a temporary entry file that imports markdown-it
    const entryContent = `
import MarkdownIt from 'markdown-it';

// Create markdown-it instance
const md = new MarkdownIt({
  html: false,
  breaks: false,
  linkify: false
});

// Export as _md for compatibility
export const _md = md;
`;

    fs.writeFileSync('_temp_entry.js', entryContent);

    // Bundle with esbuild
    const result = await esbuild.build({
      entryPoints: ['_temp_entry.js'],
      bundle: true,
      format: 'esm',
      target: 'es2016', // ES7 for Qt V4
      write: false,
      minify: false,
    });

    // Clean up temp file
    fs.unlinkSync('_temp_entry.js');

    // Get bundled code
    let bundled = result.outputFiles[0].text;

    // Read custom Qt renderer
    const qtRenderer = fs.readFileSync('src/qt-renderer.js', 'utf8');

    // Combine: bundled markdown-it + Qt renderer + export
    const final = bundled + '\n\n' + qtRenderer + '\n\nexport { _md, markdownToHtml };\n';

    // Write final output
    fs.writeFileSync('markdown2html.mjs', final, 'utf8');

    console.log('✓ Built markdown2html.mjs successfully');
    console.log(`  Size: ${(final.length / 1024).toFixed(2)} KB`);
  } catch (error) {
    console.error('Build failed:', error);
    process.exit(1);
  }
}

if (isWatch) {
  console.log('Watching for changes...');

  // Watch source files
  const watchPaths = ['src/qt-renderer.js'];

  watchPaths.forEach((filePath) => {
    fs.watch(filePath, (eventType) => {
      if (eventType === 'change') {
        console.log(`\n${filePath} changed, rebuilding...`);
        build();
      }
    });
  });

  // Initial build
  build();
} else {
  build();
}
