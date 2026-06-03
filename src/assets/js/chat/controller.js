/* Chat controller — model/API + UI wiring */
(function () {
  'use strict';

  var C = window.PortfolioChatConfig || {};
  var V = window.PortfolioChatView;
  if (!V || !C.prompts) return;

  var SYSTEM =
    'You are the public portfolio assistant for Peter Pau Sian Lian only.\n\nFacts:\n' +
    C.facts +
    '\n\nRules:\n' +
    (C.rules || []).map(function (r) { return '- ' + r; }).join('\n');

  var panel = document.getElementById('chatPanel');
  var backdrop = document.getElementById('chatBackdrop');
  var fab = document.getElementById('chatFab');
  var btnClose = document.getElementById('chatClose');
  var btnOpen = document.getElementById('chatOpenInline');
  var messages = document.getElementById('chatMessages');
  var input = document.getElementById('chatInput');
  var btnSend = document.getElementById('chatSend');
  var promptsEl = document.getElementById('chatPrompts');
  var statusEl = document.getElementById('chatStatus');

  if (!panel || !messages || !fab) return;

  var storageKey = C.storageKey || 'portfolioChatId_v3';
  var chatId = sessionStorage.getItem(storageKey) || null;
  var visitorId = sessionStorage.getItem('portfolioVisitorId');
  if (!visitorId) {
    visitorId =
      'pv_' +
      Date.now().toString(36) +
      '_' +
      Math.random().toString(36).slice(2, 10);
    sessionStorage.setItem('portfolioVisitorId', visitorId);
  }
  var busy = false;
  var isOpen = false;
  var host = location.hostname.replace(/^www\./, '');
  var isLive = host === 'peterlianpi.site';

  function hasConversation() {
    return messages.querySelector('.chat-msg.is-user') !== null;
  }

  function updatePrompts() {
    if (!promptsEl) return;
    var hide = hasConversation() || busy;
    promptsEl.classList.toggle('is-hidden', hide);
    promptsEl.setAttribute('aria-hidden', hide ? 'true' : 'false');
  }

  function setStatus(online, text) {
    if (!statusEl) return;
    statusEl.textContent = text || (online ? 'Online' : 'Preview');
    statusEl.className = 'chat-status' + (online ? '' : ' is-offline');
  }

  function openChat() {
    isOpen = true;
    panel.classList.add('is-open');
    panel.setAttribute('aria-hidden', 'false');
    if (backdrop) {
      backdrop.classList.add('is-open');
      backdrop.setAttribute('aria-hidden', 'false');
    }
    fab.classList.add('is-open');
    fab.setAttribute('aria-expanded', 'true');
    fab.setAttribute('aria-label', 'Close chat');
    document.body.classList.add('chat-is-open');
    updatePrompts();
    setTimeout(function () {
      if (input) input.focus();
    }, 50);
  }

  function closeChat() {
    isOpen = false;
    panel.classList.remove('is-open');
    panel.setAttribute('aria-hidden', 'true');
    if (backdrop) {
      backdrop.classList.remove('is-open');
      backdrop.setAttribute('aria-hidden', 'true');
    }
    fab.classList.remove('is-open');
    fab.setAttribute('aria-expanded', 'false');
    fab.setAttribute('aria-label', 'Open chat');
    document.body.classList.remove('chat-is-open');
    updatePrompts();
  }

  function toggleChat() {
    if (isOpen) closeChat();
    else openChat();
  }

  function chatHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-Portfolio-Visitor': visitorId,
      'X-Portfolio-Source': 'peterlianpi.site'
    };
  }

  function buildPayload(userText) {
    var trimmed = (userText || '').trim();
    var msg = trimmed;
    if (!chatId) {
      msg = SYSTEM + '\n\nQuestion: ' + trimmed;
    }
    return {
      message: msg,
      user_message: trimmed,
      chat_id: chatId,
      temporary: false
    };
  }

  function parseSSE(buffer, onData) {
    var lines = buffer.split('\n');
    var rest = lines.pop() || '';
    var i;
    for (i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (line.indexOf('data: ') !== 0) continue;
      try {
        onData(JSON.parse(line.slice(6)));
      } catch (e) { /* skip */ }
    }
    return rest;
  }

  function streamChat(payload, bubble, done) {
    fetch('/api/chat/stream', {
      method: 'POST',
      headers: chatHeaders(),
      body: JSON.stringify(payload)
    })
      .then(function (res) {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        if (!res.body || !res.body.getReader) throw new Error('No stream');
        var reader = res.body.getReader();
        var decoder = new TextDecoder();
        var buf = '';
        var full = '';

        function handleData(data) {
          if (data.error) throw new Error(data.error);
          if (data.delta) {
            full += data.delta;
            bubble.innerHTML = V.renderMd(full);
            V.scrollDown(messages);
          }
          var id = data.chat_id || data.conversation_id;
          if (id) {
            chatId = id;
            sessionStorage.setItem(storageKey, chatId);
          }
        }

        function pump() {
          return reader.read().then(function (chunk) {
            if (chunk.done) {
              buf = parseSSE(buf + '\n', handleData);
              done(null, full);
              return;
            }
            buf += decoder.decode(chunk.value, { stream: true });
            buf = parseSSE(buf, handleData);
            return pump();
          });
        }

        return pump();
      })
      .catch(done);
  }

  function fallbackChat(payload, done) {
    fetch('/api/chat', {
      method: 'POST',
      headers: chatHeaders(),
      body: JSON.stringify(payload)
    })
      .then(function (res) {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        return res.json();
      })
      .then(function (data) {
        var id = data.chat_id || data.conversation_id;
        if (id) {
          chatId = id;
          sessionStorage.setItem(storageKey, chatId);
        }
        done(null, data.text || '');
      })
      .catch(done);
  }

  function sendMessage(text) {
    var trimmed = (text || '').trim();
    if (!trimmed || busy) return;

    if (!isOpen) openChat();

    busy = true;
    btnSend.disabled = true;
    updatePrompts();
    V.addMessage(messages, 'user', trimmed);
    input.value = '';
    input.style.height = 'auto';

    var bubble = V.addMessage(messages, 'assistant', '', true);
    var payload = buildPayload(trimmed);

    function finish(err, full) {
      busy = false;
      btnSend.disabled = false;
      updatePrompts();
      if (err) {
        setStatus(false, isLive ? 'Error' : 'Preview');
        bubble.innerHTML = isLive
          ? '<p>Could not reach the assistant. Try again.</p>'
          : '<p>Chat works on <strong>peterlianpi.site</strong>.</p>';
      } else {
        setStatus(true, 'Online');
        if (!full || !V.cleanAiText(full)) {
          bubble.innerHTML = '<p>No response. Please try again.</p>';
        }
      }
      if (input) input.focus();
    }

    if (!isLive) {
      finish(new Error('preview'), '');
      return;
    }

    streamChat(payload, bubble, function (err, full) {
      if (!err && full) {
        finish(null, full);
        return;
      }
      fallbackChat(payload, function (err2, full2) {
        if (!err2 && full2) {
          bubble.innerHTML = V.renderMd(full2);
          V.scrollDown(messages);
        }
        finish(err2 || err, full2 || full);
      });
    });
  }

  var i;
  for (i = 0; i < C.prompts.length; i++) {
    (function (label) {
      var b = document.createElement('button');
      b.type = 'button';
      b.className = 'chat-prompt';
      b.textContent = label;
      b.addEventListener('click', function () {
        sendMessage(label);
      });
      promptsEl.appendChild(b);
    })(C.prompts[i]);
  }

  fab.addEventListener('click', function (e) {
    e.preventDefault();
    e.stopPropagation();
    toggleChat();
  });

  if (btnClose) {
    btnClose.addEventListener('click', function (e) {
      e.stopPropagation();
      closeChat();
    });
  }

  if (backdrop) {
    backdrop.addEventListener('click', closeChat);
  }

  if (btnOpen) {
    btnOpen.addEventListener('click', function (e) {
      e.preventDefault();
      openChat();
    });
  }

  btnSend.addEventListener('click', function () {
    sendMessage(input.value);
  });

  input.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage(input.value);
    }
  });

  input.addEventListener('input', function () {
    input.style.height = 'auto';
    input.style.height = Math.min(input.scrollHeight, 110) + 'px';
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && isOpen) closeChat();
  });

  var navChat = document.querySelector('a[href="#chat"]');
  if (navChat) {
    navChat.addEventListener('click', function (e) {
      e.preventDefault();
      openChat();
    });
  }

  V.addMessage(messages, 'assistant', C.welcome || "Hi! Ask about Peter's work.");
  setStatus(isLive, isLive ? 'Online' : 'Preview');
  updatePrompts();
})();
