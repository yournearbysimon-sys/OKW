(function () {
  const mount = document.getElementById("okw-health-ecg-mount");
  const canvas = document.getElementById("okw-ecg-canvas");
  const bpmEl = document.getElementById("okw-bpm");
  const hpEl = document.getElementById("okw-hp");

  if (!mount || !canvas || !bpmEl || !hpEl) return;
  const ctx = canvas.getContext("2d");
  if (!ctx) return;
  let healthPct = 100;
  let stripEnabled = false;

  window.addEventListener("message", function (ev) {
    const d = ev.data;
    if (!d || !d.action) return;

    if (d.action === "okwHealthEcgInit") {
      stripEnabled = !!d.data && !!d.data.enabled;
      mount.style.display = stripEnabled ? "block" : "none";
      if (!stripEnabled) return;
      const c = d.data || {};
      if (c.offsetLeft) document.documentElement.style.setProperty("--ecg-left", c.offsetLeft);
      if (c.offsetBottom) document.documentElement.style.setProperty("--ecg-bottom", c.offsetBottom);
      if (c.stripWidth) document.documentElement.style.setProperty("--ecg-width", c.stripWidth);
    }

    if (d.action === "okwHealthEcgVitals") {
      healthPct = Math.max(0, Math.min(100, Number(d.health) || 0));
    }
  });

  function lineColor() {
    if (healthPct > 55) return getComputedStyle(document.documentElement).getPropertyValue("--line-healthy").trim() || "#4ade80";
    if (healthPct > 25) return getComputedStyle(document.documentElement).getPropertyValue("--line-warn").trim() || "#fbbf24";
    return getComputedStyle(document.documentElement).getPropertyValue("--line-critical").trim() || "#f87171";
  }

  function targetBpm() {
    const stress = (100 - healthPct) * 0.65;
    return Math.round(68 + stress + (Math.random() - 0.5) * 4);
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

  function injectQrs(centerIdx, amplitude) {
    const a = amplitude;
    const sk = samples;
    const i0 = Math.max(0, centerIdx - 3);
    for (let k = 0; k < 8; k++) {
      const i = i0 + k;
      if (i >= sk.length) break;
      const t = k / 8;
      let bump = 0;
      if (t < 0.15) bump = -a * 0.15 * (t / 0.15);
      else if (t < 0.35) bump = a * (t - 0.15) / 0.2;
      else if (t < 0.5) bump = a * (1 - (t - 0.35) / 0.15) * 0.85;
      else if (t < 0.7) bump = -a * 0.35 * Math.sin(((t - 0.5) / 0.2) * Math.PI);
      sk[i] = (sk[i] || 0) + bump;
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
    displayBpm += (bpm - displayBpm) * 0.08;
    const beatMs = 60000 / Math.max(48, Math.min(165, displayBpm));

    const wander = (Math.sin(ts * 0.004) + Math.sin(ts * 0.0017)) * (1.2 + (100 - healthPct) * 0.04);
    const jitter = (Math.random() - 0.5) * (0.4 + (100 - healthPct) * 0.02);

    pushSample(mid + wander * 4 + jitter * 3);

    if (ts - lastBeat >= beatMs) {
      lastBeat = ts;
      const amp = (6 + (100 - healthPct) * 0.22) * (h / 88);
      injectQrs(samples.length - 1, amp);
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
    ctx.lineWidth = Math.max(1.4, h * 0.035);
    ctx.shadowColor = lineColor();
    ctx.shadowBlur = h * 0.08;

    ctx.beginPath();
    const stepX = (i) => ((i / (slice.length - 1)) * (w - 8)) + 4;
    for (let i = 0; i < slice.length; i++) {
      const x = stepX(i);
      const y = slice[i];
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.stroke();
    ctx.shadowBlur = 0;

    bpmEl.textContent = String(Math.round(displayBpm));
    hpEl.textContent = String(Math.round(healthPct));

    requestAnimationFrame(draw);
  }

  requestAnimationFrame(draw);
})();
