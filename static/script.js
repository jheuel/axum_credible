(function () {
  "use strict";

  var location = window.location;
  var document = window.document;
  var currentScript = document.currentScript;
  var apiEndpoint = currentScript.getAttribute("data-api") ||
    new URL(currentScript.src).origin + "/stats/event";
  var domain = currentScript.getAttribute("data-domain");

  function handleIgnoredEvent(reason, callback) {
    if (reason) {
      console.warn("Ignoring Event: " + reason);
    }
    if (callback && callback.callback) {
      callback.callback();
    }
  }

  function sendEvent(eventName, options) {
    if (
      /^localhost$|^127(\.[0-9]+){0,2}\.[0-9]+$|^\[::1?\]$/.test(
        location.hostname,
      ) || location.protocol === "file:"
    ) {
      return handleIgnoredEvent("localhost", options);
    }

    if (
      window._phantom || window.__nightmare || window.navigator.webdriver ||
      window.Cypress
    ) {
      return handleIgnoredEvent(null, options);
    }

    try {
      if (window.localStorage.analytics_ignore === "true") {
        return handleIgnoredEvent("localStorage flag", options);
      }
    } catch (e) {}

    var payload = {
      n: eventName,
      u: location.href,
      d: domain,
      r: document.referrer || null,
    };

    if (options && options.meta) {
      payload.m = JSON.stringify(options.meta);
    }

    if (options && options.props) {
      payload.p = options.props;
    }

    var xhr = new XMLHttpRequest();
    xhr.open("POST", apiEndpoint, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.send(JSON.stringify(payload));

    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4 && options && options.callback) {
        options.callback({ status: xhr.status });
      }
    };
  }

  var queuedEvents = window.analytics && window.analytics.q || [];
  window.analytics = sendEvent;

  for (var i = 0; i < queuedEvents.length; i++) {
    sendEvent.apply(this, queuedEvents[i]);
  }

  var lastPathname;
  function trackPageview() {
    if (lastPathname !== location.pathname) {
      lastPathname = location.pathname;
      sendEvent("pageview");
    }
  }

  function onNavigation() {
    trackPageview();
  }

  var history = window.history;
  if (history.pushState) {
    var originalPushState = history.pushState;
    history.pushState = function (state, unused, url) {
      originalPushState.apply(history, [state, unused, url]);
      onNavigation();
    };
    window.addEventListener("popstate", onNavigation);
  }

  if (document.visibilityState === "prerender") {
    document.addEventListener("visibilitychange", function () {
      if (!lastPathname && document.visibilityState === "visible") {
        trackPageview();
      }
    });
  }
  if (!(document.visibilityState === "prerender")) {
    trackPageview();
  }
})();
