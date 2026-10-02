// ==UserScript==
// @name         OSA Video Fullscreen Zoom
// @namespace    osa.browser.zenBrowser
// @version      2.0.0
// @description  Grow HTML video players before entering fullscreen.
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
  let enabled = false;
  let pending = null;

  GM_xmlhttpRequest({
    method: "GET",
    url: "http://127.0.0.1:17837/enabled",
    timeout: 3000,
    // Each revision uses a new token so old imported scripts become inert.
    onload: (response) => { enabled = response.status === 200 && response.responseText.trim() === "2"; },
  });

  function restore(entry) {
    if (entry.restored) return;
    entry.restored = true;
    if (pending === entry) pending = null;
    entry.animation.cancel();
    page.removeEventListener("resize", entry.onResize);
    page.document.removeEventListener("fullscreenchange", entry.onFullscreenChange, true);
    for (const [property, value, priority] of entry.styles) {
      if (value) entry.element.style.setProperty(property, value, priority);
      else entry.element.style.removeProperty(property);
    }
  }

  page.Element.prototype.requestFullscreen = function (...args) {
    if (!enabled || page.document.fullscreenElement || page.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      return Reflect.apply(requestFullscreen, this, args);
    }
    if (pending) return pending.element === this ? pending.promise : Reflect.apply(requestFullscreen, this, args);

    const video = this instanceof page.HTMLVideoElement ? this : this.querySelector("video");
    if (!video || this === page.document.body || this === page.document.documentElement) {
      return Reflect.apply(requestFullscreen, this, args);
    }

    const rect = this.getBoundingClientRect();
    const videoRect = video.getBoundingClientRect();
    const width = page.innerWidth;
    const height = page.innerHeight;
    if (!rect.width || !rect.height || !videoRect.width || !videoRect.height || !width || !height) {
      return Reflect.apply(requestFullscreen, this, args);
    }

    const sx = width / rect.width;
    const sy = height / rect.height;
    if (![sx, sy, rect.left, rect.top].every(Number.isFinite)) {
      return Reflect.apply(requestFullscreen, this, args);
    }

    const styles = ["position", "z-index"].map((property) => [
      property,
      this.style.getPropertyValue(property),
      this.style.getPropertyPriority(property),
    ]);
    if (page.getComputedStyle(this).position === "static") this.style.setProperty("position", "relative", "important");
    this.style.setProperty("z-index", "2147483647", "important");

    let animation;
    try {
      animation = this.animate(
        [
          { transformOrigin: "top left", translate: "0px 0px", scale: "1 1" },
          { transformOrigin: "top left", translate: `${-rect.left}px ${-rect.top}px`, scale: `${sx} ${sy}` },
        ],
        { duration, easing: "cubic-bezier(0.22, 1, 0.36, 1)", fill: "forwards" },
      );
    } catch (error) {
      for (const [property, value, priority] of styles) {
        if (value) this.style.setProperty(property, value, priority);
        else this.style.removeProperty(property);
      }
      return Reflect.apply(requestFullscreen, this, args);
    }

    const entry = {
      element: this,
      animation,
      styles,
      requested: false,
      restored: false,
      onResize: () => { if (entry.requested) restore(entry); },
      onFullscreenChange: () => { if (page.document.fullscreenElement === this) restore(entry); },
    };
    pending = entry;
    page.addEventListener("resize", entry.onResize);
    page.document.addEventListener("fullscreenchange", entry.onFullscreenChange, true);

    entry.promise = animation.finished.then(() => {
      entry.requested = true;
      return Reflect.apply(requestFullscreen, this, args);
    }).finally(() => restore(entry));
    return entry.promise;
  };
})();
