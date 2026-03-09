// ---------------------------------------------------------------------------
// Qt-specific markdown renderer using markdown-it
// ---------------------------------------------------------------------------

function markdownToHtml(text, colors) {
  if (!text) return '';

  var c = colors || {
    codeBg: '#20FFFFFF',
    inlineCodeBg: '#30FFFFFF',
    blockquoteBg: 'transparent',
    blockquoteBorder: '#808080',
  };

  // Use markdown-it to render
  var html = _md.render(text);

  // Post-process: add copy buttons to code blocks
  html = html.replace(
    /<pre><code([^>]*)>([\s\S]*?)<\/code><\/pre>/g,
    function (match, attrs, code) {
      var lang = '';
      var langMatch = attrs.match(/class="language-(\w+)"/);
      if (langMatch) {
        lang = langMatch[1];
      }

      // Decode HTML entities for btoa
      var decoded = code
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&amp;/g, '&');

      var b64 = Qt.btoa(decoded);

      return (
        '<table width="100%" border="0" cellspacing="0" cellpadding="0"' +
        ' style="background-color: ' +
        c.codeBg +
        '; margin: 8px 0; table-layout: fixed;">' +
        '<tr><td style="padding: 4px 10px 0 10px;">' +
        '<table width="100%" border="0" cellspacing="0" cellpadding="0"' +
        ' style="margin: 0; table-layout: fixed;"><tr>' +
        '<td align="left"  style="padding: 0;"><font size="1" color="#808080">' +
        lang +
        '</font></td>' +
        '<td align="right" style="padding: 0; width: 35px;">' +
        '<a href="copy://' +
        b64 +
        '" style="text-decoration: none;">' +
        '<font size="1">[Copy]</font></a></td>' +
        '</tr></table>' +
        '</td></tr>' +
        '<tr><td style="padding: 0 10px 10px 10px;">' +
        '<pre style="margin: 0; padding: 0; white-space: pre-wrap;"><code>' +
        code +
        '</code></pre>' +
        '</td></tr>' +
        '</table>'
      );
    }
  );

  // Post-process: style blockquotes
  html = html.replace(
    /<blockquote>/g,
    '<blockquote style="background-color: ' +
      c.blockquoteBg +
      '; ' +
      'border-left: 3px solid ' +
      c.blockquoteBorder +
      '; ' +
      'margin: 8px 0; padding: 4px 10px;">'
  );

  // Post-process: style inline code
  html = html.replace(
    /<code>/g,
    '<code style="background-color: ' +
      c.inlineCodeBg +
      '; ' +
      'padding: 2px 4px; border-radius: 3px;">'
  );

  return html;
}
