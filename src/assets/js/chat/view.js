/* Chat view — render messages (MVVM-style view layer) */
window.PortfolioChatView = (function () {
  'use strict';

  function cleanAiText(text) {
    var s = String(text || '');
    s = s.replace(/[\uE000-\uF8FF]/g, '');
    s = s.replace(/entity\[[^\]]*\]/gi, '');
    s = s.replace(/\[\s*"(?:organization|company|people)"[^\]]*\]/gi, '');
    s = s.replace(/<\|[^|>]*\|>/g, '');
    s = s.replace(/<\/?[a-z][^>]*>/gi, '');
    s = s.replace(/url[^|\n]*\|[^|\n]*\|[^|\n]*/gi, '');
    s = s.replace(/https?:\/\/www\.5bb\.com\.mm\/?/gi, '');
    s = s.replace(/Global Technology Group\s*\(\s*5BB\s*\)/gi, 'Global Technology Group (GTG)');
    s = s.replace(/Global Net Myanmar\s*[–-]\s*5BB/gi, 'Global Technology Group (GTG)');
    s = s.replace(/\b5BB\b/g, 'GTG');
    s = s.replace(/Software Applications Engineer(?:\s*\(SAE\))?/gi, 'Junior Engineer, Web Development (SAE)');
    s = s.replace(/Junior Web Developer/gi, 'Junior Engineer, Web Development (SAE)');
    s = s.replace(/\n+In a broader sense[\s\S]*$/i, '');
    s = s.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, '');
    s = s.replace(/\n{3,}/g, '\n\n');
    return s.trim();
  }

  function escapeHtml(t) {
    return String(t)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatInline(safe) {
    var html = safe;
    html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
    return html;
  }

  function renderMd(text) {
    text = cleanAiText(text);
    if (!text) return '';

    var lines = text.split('\n');
    var out = [];
    var inList = false;
    var i;
    var line;
    var bullet;
    var numbered;
    var heading;
    var item;
    var trimmed;

    for (i = 0; i < lines.length; i++) {
      line = lines[i];
      bullet = line.match(/^\s*[-*]\s+(.+)$/);
      numbered = line.match(/^\s*\d+\.\s+(.+)$/);
      heading = line.match(/^#{1,3}\s+(.+)$/);

      if (bullet || numbered) {
        item = (bullet || numbered)[1].trim();
        if (!inList) {
          out.push('<ul>');
          inList = true;
        }
        out.push('<li>' + formatInline(escapeHtml(item)) + '</li>');
      } else {
        if (inList) {
          out.push('</ul>');
          inList = false;
        }
        trimmed = line.trim();
        if (!trimmed) continue;
        if (heading) {
          out.push(
            '<p class="chat-md-heading">' +
              formatInline(escapeHtml(heading[1].trim())) +
              '</p>'
          );
        } else {
          out.push('<p>' + formatInline(escapeHtml(trimmed)) + '</p>');
        }
      }
    }

    if (inList) out.push('</ul>');
    return out.join('');
  }

  function scrollDown(messages) {
    messages.scrollTop = messages.scrollHeight;
  }

  function addMessage(messages, role, text, loading) {
    var row = document.createElement('div');
    row.className = 'chat-msg' + (role === 'user' ? ' is-user' : '');

    var av = document.createElement('div');
    av.className = 'chat-msg-avatar';
    av.textContent = role === 'user' ? 'You' : '\u2726';
    av.setAttribute('aria-label', role === 'user' ? 'You' : 'Assistant');

    var bubble = document.createElement('div');
    bubble.className = 'chat-bubble';
    if (loading) {
      bubble.innerHTML =
        '<div class="chat-typing"><span></span><span></span><span></span></div>';
    } else {
      bubble.innerHTML = renderMd(text);
    }

    row.appendChild(av);
    row.appendChild(bubble);
    messages.appendChild(row);
    scrollDown(messages);
    return bubble;
  }

  return {
    cleanAiText: cleanAiText,
    renderMd: renderMd,
    addMessage: addMessage,
    scrollDown: scrollDown
  };
})();
