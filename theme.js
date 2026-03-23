/**
 * Pterodactyl Panel — AvenoxTheme
 * Theme injector: loads the End CSS into the panel
 */
(function () {
  'use strict';

  const THEME_ID   = 'avenox-theme';
  const THEME_PATH = '/themes/avenox/avenox.css';

  function injectTheme() {
    if (document.getElementById(THEME_ID)) return;

    const link    = document.createElement('link');
    link.id       = THEME_ID;
    link.rel      = 'stylesheet';
    link.type     = 'text/css';
    link.href     = THEME_PATH + '?v=' + Date.now();
    link.media    = 'all';

    document.head.appendChild(link);
    console.log('[AvenoxTheme] Loaded — welcome to The End.');
  }

  // Inject as soon as possible
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectTheme);
  } else {
    injectTheme();
  }

  // Re-apply after React SPA route changes
  const _pushState = history.pushState.bind(history);
  history.pushState = function (...args) {
    _pushState(...args);
    setTimeout(injectTheme, 100);
  };

  window.addEventListener('popstate', () => setTimeout(injectTheme, 100));

})();
