(function () {
  'use strict';

  /* Theme */
  var themeBtn = document.getElementById('themeToggle');
  if (themeBtn) {
    var saved = localStorage.getItem('theme') || 'dark';
    if (saved === 'light') {
      document.documentElement.setAttribute('data-theme', 'light');
      themeBtn.textContent = '\u2600\uFE0F';
    }
    themeBtn.addEventListener('click', function () {
      var isLight = document.documentElement.getAttribute('data-theme') === 'light';
      if (isLight) {
        document.documentElement.removeAttribute('data-theme');
        themeBtn.textContent = '\uD83C\uDF19';
        localStorage.setItem('theme', 'dark');
      } else {
        document.documentElement.setAttribute('data-theme', 'light');
        themeBtn.textContent = '\u2600\uFE0F';
        localStorage.setItem('theme', 'light');
      }
    });
  }

  /* Mobile nav */
  var navToggle = document.getElementById('navToggle');
  var navPanel = document.getElementById('navPanel');
  if (navToggle && navPanel) {
    navToggle.addEventListener('click', function () {
      var open = navPanel.classList.toggle('is-open');
      navToggle.setAttribute('aria-expanded', open ? 'true' : 'false');
      navToggle.textContent = open ? '\u2715' : '\u2630';
    });
    navPanel.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        navPanel.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.textContent = '\u2630';
      });
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        navPanel.classList.remove('is-open');
        navToggle.setAttribute('aria-expanded', 'false');
        navToggle.textContent = '\u2630';
      }
    });
  }

  /* Typewriter */
  var tw = document.getElementById('tw');
  var siteCfg = window.PortfolioSiteConfig || {};
  if (tw) {
    var phrases = siteCfg.typewriterPhrases || [
      'Full Stack Developer',
      'AI & NLP Engineer',
      'Open Source Contributor'
    ];
    var pi = 0;
    var ci = 0;
    var del = false;
    function type() {
      var p = phrases[pi];
      tw.textContent = del ? p.slice(0, ci--) : p.slice(0, ci++);
      if (!del && ci > p.length) {
        del = true;
        setTimeout(type, 1500);
        return;
      }
      if (del && ci < 0) {
        del = false;
        pi = (pi + 1) % phrases.length;
        ci = 0;
        setTimeout(type, 400);
        return;
      }
      setTimeout(type, del ? 40 : 80);
    }
    type();
  }

  /* Hero canvas */
  var canvas = document.getElementById('heroCanvas');
  var hero = document.getElementById('hero');
  if (!canvas || !hero) return;

  var ctx = canvas.getContext('2d');
  var mouse = { x: -999, y: -999 };
  var N = 70;
  var pts = [];

  function init() {
    canvas.width = hero.offsetWidth || 900;
    canvas.height = hero.offsetHeight || 420;
    pts.length = 0;
    for (var i = 0; i < N; i++) {
      pts.push({
        x: Math.random() * canvas.width,
        y: Math.random() * canvas.height,
        vx: (Math.random() - 0.5) * 0.6,
        vy: (Math.random() - 0.5) * 0.6,
        r: Math.random() * 2 + 1.5
      });
    }
  }

  hero.addEventListener(
    'mousemove',
    function (e) {
      var r = hero.getBoundingClientRect();
      mouse.x = e.clientX - r.left;
      mouse.y = e.clientY - r.top;
    },
    { passive: true }
  );
  hero.addEventListener('mouseleave', function () {
    mouse.x = -999;
    mouse.y = -999;
  });

  function getColors() {
    var light = document.documentElement.getAttribute('data-theme') === 'light';
    return {
      dot: light ? 'rgba(40,52,196,0.8)' : 'rgba(0,245,255,0.8)',
      line: light ? 'rgba(124,58,237,' : 'rgba(191,0,255,'
    };
  }

  function draw() {
    requestAnimationFrame(draw);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    var c = getColors();
    var W = canvas.width;
    var H = canvas.height;
    var i;
    var j;
    var p;
    var dx;
    var dy;
    var d2;
    var d;
    var DIST = 120;

    for (i = 0; i < N; i++) {
      p = pts[i];
      dx = mouse.x - p.x;
      dy = mouse.y - p.y;
      d2 = dx * dx + dy * dy;
      if (d2 < 8000) {
        p.vx += dx * 0.003;
        p.vy += dy * 0.003;
      }
      p.vx *= 0.97;
      p.vy *= 0.97;
      p.x += p.vx;
      p.y += p.vy;
      if (p.x < 0) {
        p.x = 0;
        p.vx *= -1;
      }
      if (p.x > W) {
        p.x = W;
        p.vx *= -1;
      }
      if (p.y < 0) {
        p.y = 0;
        p.vy *= -1;
      }
      if (p.y > H) {
        p.y = H;
        p.vy *= -1;
      }
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
      ctx.fillStyle = c.dot;
      ctx.fill();
    }

    for (i = 0; i < N; i++) {
      for (j = i + 1; j < N; j++) {
        dx = pts[i].x - pts[j].x;
        dy = pts[i].y - pts[j].y;
        d = Math.sqrt(dx * dx + dy * dy);
        if (d < DIST) {
          ctx.beginPath();
          ctx.moveTo(pts[i].x, pts[i].y);
          ctx.lineTo(pts[j].x, pts[j].y);
          ctx.strokeStyle = c.line + (1 - d / DIST).toFixed(2) + ')';
          ctx.lineWidth = 0.5;
          ctx.stroke();
        }
      }
    }
  }

  init();
  window.addEventListener('resize', init, { passive: true });
  draw();
})();
