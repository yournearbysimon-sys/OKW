(function () {
  const mount = document.getElementById("okw-health-ecg-mount");
  const canvas = document.getElementById("okw-ecg-canvas");
  const bpmEl = document.getElementById("okw-bpm");
  const hpEl = document.getElementById("okw-hp");
  const rootStyle = document.documentElement.style;

  if (!mount || !canvas || !bpmEl || !hpEl) return;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;

  let staminaPct = 100;
  let faintActive = false;
  let stripEnabled = false;

  function applyLayout(data) {
    if (!data) return;
    if (data.enabled === false || data.hidden === true) {
      stripEnabled = false;
      mount.style.display = "none";
      return;
    }
    stripEnabled = true;
    mount.style.display = "block";

    if (data.offsetLeft) {
      rootStyle.setProperty("--ecg-left", data.offsetLeft);
      rootStyle.setProperty("--ecg-right", "auto");
    } else if (data.offsetRight) {
      rootStyle.setProperty("--ecg-right", data.offsetRight);
      rootStyle.setProperty("--ecg-left", "auto");
    }

    if (data.offsetBottom) {
      rootStyle.setProperty("--ecg-bottom", data.offsetBottom);
      rootStyle.setProperty("--ecg-top", "auto");
    } else if (data.offsetTop) {
      rootStyle.setProperty("--ecg-top", data.offsetTop);
      rootStyle.setProperty("--ecg-bottom", "auto");
    }

    if (data.stripWidth) rootStyle.setProperty("--ecg-width", data.stripWidth);

    rootStyle.setProperty("--ecg-tx", data.translateX || "0px");
    rootStyle.setProperty("--ecg-ty", data.translateY || "0px");
  }

  window.addEventListener("message", function (ev) {
    const d = ev.data;
    if (!d || !d.action) return;

    if (d.action === "okwHealthEcgInit") {
      const c = d.data || {};
      applyLayout({
        enabled: !!c.enabled,
        hidden: !c.enabled,
        offsetLeft: c.offsetLeft,
        offsetBottom: c.offsetBottom,
        stripWidth: c.stripWidth,
        translateX: "0px",
        translateY: "0px",
      });
    }

    if (d.action === "okwHealthEcgLayout") {
      applyLayout(d.data || {});
    }

    if (d.action === "okwHealthEcgVitals") {
      if (typeof d.stamina === "number") staminaPct = Math.max(0, Math.min(100, d.stamina));
      else if (typeof d.health === "number") staminaPct = Math.max(0, Math.min(100, d.health));
      faintActive = !!d.faint;
    }
  });

  function lineColor() {
    if (faintActive) return getComputedStyle(document.documentElement).getPropertyValue("--text-dim").trim() || "#9ca3af";
    if (staminaPct > 50) return getComputedStyle(document.documentElement).getPropertyValue("--line-healthy").trim() || "#4ade80";
    if (staminaPct > 20) return getComputedStyle(document.documentElement).getPropertyValue("--line-warn").trim() || "#fbbf24";
    return getComputedStyle(document.documentElement).getPropertyValue("--line-critical").trim() || "#f87171";
  }

  /** Target BPM: full stamina = slow & smooth; ~half = faster; empty = fastest. */
  function targetBpm() {
    const s = staminaPct;
    if (faintActive) return 42 + (Math.random() - 0.5) * 3;
    if (s > 50) return 56 + (100 - s) * 0.12 + (Math.random() - 0.5) * 2;
    if (s > 20) return 74 + (50 - s) * 0.55 + (Math.random() - 0.5) * 3;
    return 102 + (20 - s) * 1.85 + (Math.random() - 0.5) * 5;
  }

  /** Smoothing: more responsive when stamina is low (faster visual pulse). */
  function bpmSmoothAlpha() {
    if (faintActive) return 0.04;
    if (staminaPct > 50) return 0.06;
    if (staminaPct > 20) return 0.095;
    return 0.14;
  }

  let displayBpm = 72;
  const samples = [];
  const maxSamples = 480;

  function resize() {
    const rect = canvas.getBoundingClientRect();
    const dpr = Math.min(2, window.devicePixelRatio || 1);
    const w = Math.max(200, Math.floor(rect.width * dpr));
    const h = Math.max(44, Math.floor(rect.height * dpr));
    if (canvas.width !== w || canvas.height !== h) {
      canvas.width = w;
      canvas.height = h;
    }
  }

  function pushSample(y) {
    samples.push(y);
    if (samples.length > maxSamples) samples.shift();
  }

  /** Classic strip: isoelectric, rounded P, Q-down, tall R, deep S, ST, rounded T, small U. */
  function ecgBeatDeltaY(u, a) {
    if (u < 0.18) return 0;
    if (u < 0.27) return a * 0.12 * Math.sin(((u - 0.18) / 0.09) * Math.PI);
    if (u < 0.34) return 0;
    if (u < 0.37) return -a * 0.22 * ((u - 0.34) / 0.03);
    if (u < 0.405) return -a * 0.22 + a * 1.52 * ((u - 0.37) / 0.035);
    if (u < 0.438)
      return a * 1.3 - a * 1.78 * ((u - 0.405) / 0.033);
    if (u < 0.485) return -a * 0.48 * (1 - (u - 0.438) / 0.047);
    if (u < 0.53) return 0;
    if (u < 0.76) return a * 0.29 * Math.sin(((u - 0.53) / 0.23) * Math.PI);
    if (u < 0.84) return a * 0.07 * Math.sin(((u - 0.76) / 0.08) * Math.PI);
    return 0;
  }

  function injectEcgBeat(endIdx, amplitude) {
    const a = amplitude;
    const len = 56;
    const i0 = Math.max(0, endIdx - (len - 1));
    const sk = samples;
    for (let k = 0; k < len; k++) {
      const i = i0 + k;
      if (i >= sk.length) break;
      const u = len > 1 ? k / (len - 1) : 0;
      sk[i] = (sk[i] || 0) + ecgBeatDeltaY(u, a);
    }
  }

  let lastBeat = 0;

  function draw(ts) {
    if (!stripEnabled) {
      requestAnimationFrame(draw);
      return;
    }

    resize();
    const w = canvas.width;
    const h = canvas.height;
    const mid = h * 0.55;

    const bpm = targetBpm();
    displayBpm += (bpm - displayBpm) * bpmSmoothAlpha();
    const beatMs = 60000 / Math.max(42, Math.min(175, displayBpm));

    const stress = (100 - staminaPct) * 0.03;
    const wanderSlow = Math.sin(ts * 0.0011) * (0.32 + stress);
    const wanderFast = Math.sin(ts * 0.0038) * (0.11 + stress * 0.4);
    const jitter = (Math.random() - 0.5) * (0.11 + stress * 0.32);

    if (faintActive) {
      pushSample(mid + Math.sin(ts * 0.002) * 2);
    } else {
      pushSample(mid + wanderSlow * 2.8 + wanderFast * 1.8 + jitter * 2);
    }

    if (!faintActive && ts - lastBeat >= beatMs) {
      lastBeat = ts;
      const ampBase = (9.2 + (100 - staminaPct) * 0.3) * (h / 88);
      injectEcgBeat(samples.length - 1, ampBase);
    }

    ctx.clearRect(0, 0, w, h);

    const slice = samples.slice(-Math.floor(w / 2));
    if (slice.length < 2) {
      requestAnimationFrame(draw);
      return;
    }

    ctx.lineJoin = "round";
    ctx.lineCap = "round";
    ctx.strokeStyle = lineColor();
    ctx.lineWidth = Math.max(1.65, h * 0.042);
    ctx.shadowColor = lineColor();
    ctx.shadowBlur = h * 0.08;

    ctx.beginPath();
    const stepX = (i) => (i / (slice.length - 1)) * (w - 8) + 4;
    for (let i = 0; i < slice.length; i++) {
      const x = stepX(i);
      const y = slice[i];
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    bpmEl.textContent = String(Math.round(displayBpm));
    hpEl.textContent = String(Math.round(staminaPct));

    requestAnimationFrame(draw);
  }

  requestAnimationFrame(draw);
})();
