// ==UserScript==
// @name         OSA Video Fullscreen Zoom
// @namespace    osa.browser.zenBrowser
// @version      1.0.0
// @description  Grow HTML video players from their page position into fullscreen.
// @match        http://*/*
// @match        https://*/*
// @run-at       document-start
// @sandbox      raw
// @grant        GM_xmlhttpRequest
// @grant        unsafeWindow
// @connect      127.0.0.1
// ==/UserScript==

(() => {
  "use strict";

  const page = unsafeWindow;
  const requestFullscreen = page.Element.prototype.requestFullscreen;
  const duration = 260;
  let pending = null;
  let enabled = false;

  GM_xmlhttpRequest({
    method: "GET",
    url: "http://127.0.0.1:17837/enabled",
    timeout: 3000,
    onload: (response) => { enabled = response.status === 200 && response.responseText.trim() === "1"; },
  });

  page.Element.prototype.requestFullscreen = function (...args) {
    // Other fullscreen uses, such as slides and games, keep their own behavior.
    const video = enabled && (this instanceof page.HTMLVideoElement ? this : this.querySelector("video"));
    if (
      video &&
      this !== page.document.body &&
      this !== page.document.documentElement &&
      !page.document.fullscreenElement
    ) {
      const rect = this.getBoundingClientRect();
      const videoRect = video.getBoundingClientRect();
      if (rect.width > 0 && rect.height > 0 && videoRect.width > 0 && videoRect.height > 0) {
        pending = { element: this, rect };
      }
    }

    try {
      const result = Reflect.apply(requestFullscreen, this, args);
      if (pending?.element === this && result?.catch) {
        result.catch(() => {
          if (pending?.element === this) pending = null;
        });
      }
      return result;
    } catch (error) {
      if (pending?.element === this) pending = null;
      throw error;
    }
  };

  page.document.addEventListener("fullscreenchange", () => {
    const entry = pending;
    pending = null;
    if (!enabled || !entry || page.document.fullscreenElement !== entry.element) return;
    if (page.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const end = entry.element.getBoundingClientRect();
    if (!end.width || !end.height) return;

    const dx = entry.rect.left - end.left;
    const dy = entry.rect.top - end.top;
    const sx = entry.rect.width / end.width;
    const sy = entry.rect.height / end.height;
    if (![dx, dy, sx, sy].every(Number.isFinite)) return;

    // Individual transform properties leave the player's existing transform alone.
    entry.element.animate(
      [
        { transformOrigin: "top left", translate: `${dx}px ${dy}px`, scale: `${sx} ${sy}` },
        { transformOrigin: "top left", translate: "0px 0px", scale: "1 1" },
      ],
      { duration, easing: "cubic-bezier(0.22, 1, 0.36, 1)" },
    );
  }, true);
})();
