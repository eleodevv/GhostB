// GhostB Landing — Scroll Reveal

document.addEventListener('DOMContentLoaded', function() {
  // ─── Auto-detect OS for download button ────────────────────────────────
  var btn = document.getElementById('auto-download');
  var label = document.getElementById('download-label');
  var ua = navigator.userAgent.toLowerCase();

  if (ua.indexOf('win') !== -1) {
    btn.href = 'https://github.com/eleodevv/GhostB/releases/latest/download/GhostB-1.0.0-windows.zip';
    label.textContent = 'Descargar para Windows';
  } else if (ua.indexOf('mac') !== -1) {
    btn.href = 'https://github.com/eleodevv/GhostB/releases/latest/download/GhostB-1.0.0.dmg';
    label.textContent = 'Descargar para macOS';
  } else if (ua.indexOf('linux') !== -1) {
    btn.href = 'https://github.com/eleodevv/GhostB/releases/latest/download/ghostb_1.0.0_amd64.deb';
    label.textContent = 'Descargar para Linux';
  } else {
    btn.href = 'https://github.com/eleodevv/GhostB/releases';
    label.textContent = 'Descargar';
  }

  // ─── Scroll reveal ─────────────────────────────────────────────────────
  var elements = document.querySelectorAll('.reveal');

  // Mostrar elementos que ya están en viewport al cargar
  elements.forEach(function(el) {
    var rect = el.getBoundingClientRect();
    if (rect.top < window.innerHeight) {
      el.classList.add('visible');
    }
  });

  // Observer para los que aparecen al hacer scroll
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function(entries) {
      entries.forEach(function(entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.1 });

    elements.forEach(function(el) {
      if (!el.classList.contains('visible')) {
        observer.observe(el);
      }
    });
  } else {
    // Fallback: mostrar todo si no hay IntersectionObserver
    elements.forEach(function(el) {
      el.classList.add('visible');
    });
  }
});
