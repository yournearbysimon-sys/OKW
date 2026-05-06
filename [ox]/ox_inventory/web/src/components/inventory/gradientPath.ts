export class Point {
  x: number;
  y: number;
  progress: number;

  constructor({ x, y, progress }: { x: number; y: number; progress: number }) {
    this.x = x;
    this.y = y;
    this.progress = progress;
  }
}

class Sample {
  samples: Point[];
  progress: number;

  constructor({ samples }: { samples: Point[] }) {
    this.samples = samples;
    this.progress = samples.length > 0 ? samples[Math.floor(samples.length / 2)].progress : 0;
  }
}

const PRECISION = 2;

function getData({
  path,
  segments,
  samples,
  precision = PRECISION,
}: {
  path: SVGPathElement;
  segments: number;
  samples: number;
  precision?: number;
}) {
  const totalLength = path.getTotalLength();
  const totalPoints = segments * samples;
  const rawPoints: Point[] = [];
  const resultSamples: Sample[] = [];

  for (let i = 0; i <= totalPoints; i++) {
    const progress = i / totalPoints;
    const point = path.getPointAtLength(progress * totalLength);
    let x = point.x;
    let y = point.y;

    if (precision) {
      x = +x.toFixed(precision);
      y = +y.toFixed(precision);
    }

    rawPoints.push(new Point({ x, y, progress }));
  }

  for (let i = 0; i < segments; i++) {
    const start = i * samples;
    const end = start + samples;
    const chunk: Point[] = [];

    for (let j = 0; j < samples; j++) {
      chunk.push(rawPoints[start + j]);
    }
    chunk.push(rawPoints[end]);

    resultSamples.push(new Sample({ samples: chunk }));
  }

  return resultSamples;
}

function getStroke(data: Sample[], width: number, precision: number, closed: boolean) {
  const halfWidth = width / 2;
  const result: Sample[] = [];

  const getOffsetPoints = (angle: number, dist: number, prec: number | undefined, refPoint: Point) => {
    const p1 = new Point({
      x: Math.sin(angle) * dist + refPoint.x,
      y: -Math.cos(angle) * dist + refPoint.y,
      progress: refPoint.progress,
    });
    const p2 = new Point({
      x: -Math.sin(angle) * dist + refPoint.x,
      y: Math.cos(angle) * dist + refPoint.y,
      progress: refPoint.progress,
    });

    if (prec) {
      p1.x = +p1.x.toFixed(prec);
      p1.y = +p1.y.toFixed(prec);
      p2.x = +p2.x.toFixed(prec);
      p2.y = +p2.y.toFixed(prec);
    }
    return [p1, p2];
  };

  const formattedData = data.map((s) => ({
    samples: s.samples.map((p) => new Point(p)),
  }));

  for (let i = 0; i < formattedData.length; i++) {
    const segment = formattedData[i];
    const segmentPoints: Point[] = [];

    for (let j = 0; j < segment.samples.length - 1; j++) {
      const pCurrent = segment.samples[j];
      const pNext = segment.samples[j + 1];
      const angle = Math.atan2(pNext.y - pCurrent.y, pNext.x - pCurrent.x);

      const [off1, off2] = getOffsetPoints(angle, halfWidth, precision, pCurrent);
      const [off3, off4] = getOffsetPoints(angle, halfWidth, precision, pNext);

      if (j === 0) {
        segmentPoints.push(off1);
        segmentPoints.push(off2);
      }
      segmentPoints.push(off3);
      segmentPoints.push(off4);
    }

    const topSide = segmentPoints.filter((_, idx) => idx % 2 === 0);
    const bottomSide = segmentPoints.filter((_, idx) => idx % 2 === 1).reverse();

    result.push(new Sample({ samples: [...topSide, ...bottomSide] }));
  }

  for (let i = 0; i < result.length; i++) {
    const current = result[i];
    const next = i < result.length - 1 ? result[i + 1] : closed ? result[0] : null;

    if (next) {
      const len = current.samples.length;
      const mid = len / 2;

      const p1 = current.samples[mid - 1];
      const p2 = next.samples[0];

      const avgX = (p1.x + p2.x) / 2;
      const avgY = (p1.y + p2.y) / 2;

      p1.x = p2.x = avgX;
      p1.y = p2.y = avgY;

      const p3 = current.samples[mid];
      const p4 = next.samples[next.samples.length - 1];

      const avgX2 = (p3.x + p4.x) / 2;
      const avgY2 = (p3.y + p4.y) / 2;

      p3.x = p4.x = avgX2;
      p3.y = p4.y = avgY2;
    }
  }

  return result;
}

function pointsToPath(points: Point[]) {
  let d = '';
  for (let i = 0; i < points.length; i++) {
    const p = points[i];
    if (i === 0) {
      d += `M${p.x},${p.y}`;
    } else {
      d += `L${p.x},${p.y}`;
    }
  }
  d += 'Z';
  return d;
}

export interface ColorStop {
  color: string;
  pos: number;
  name?: string;
  r?: number;
  g?: number;
  b?: number;
}

function parseColor(color: string) {
  const ctx = document.createElement('canvas').getContext('2d');
  if (!ctx) return { r: 0, g: 0, b: 0 };
  ctx.fillStyle = color;
  const hex = ctx.fillStyle;
  if (hex.startsWith('#')) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return { r, g, b };
  }
  return { r: 0, g: 0, b: 0 };
}

function interpolateColor(c1: ColorStop, c2: ColorStop, factor: number) {
  const r1 = c1.r ?? 0;
  const g1 = c1.g ?? 0;
  const b1 = c1.b ?? 0;
  const r2 = c2.r ?? 0;
  const g2 = c2.g ?? 0;
  const b2 = c2.b ?? 0;

  const r = Math.round(r1 + (r2 - r1) * factor);
  const g = Math.round(g1 + (g2 - g1) * factor);
  const b = Math.round(b1 + (b2 - b1) * factor);

  return `rgb(${r}, ${g}, ${b})`;
}

function getColorAt(stops: ColorStop[], progress: number) {
  let start = stops[0];
  let end = stops[stops.length - 1];

  for (let i = 0; i < stops.length - 1; i++) {
    if (progress >= stops[i].pos && progress <= stops[i + 1].pos) {
      start = stops[i];
      end = stops[i + 1];
      break;
    }
  }

  if (start.r === undefined) Object.assign(start, parseColor(start.color));
  if (end.r === undefined) Object.assign(end, parseColor(end.color));

  const range = end.pos - start.pos;
  const factor = range === 0 ? 0 : (progress - start.pos) / range;

  return interpolateColor(start, end, factor);
}

export class GradientPath {
  path: SVGPathElement;
  segments: number;
  samples: number;
  precision: number;
  data: Sample[];
  svg: SVGSVGElement | null;
  group: SVGGElement;

  constructor({
    path,
    segments,
    samples,
    precision = PRECISION,
  }: {
    path: SVGPathElement;
    segments: number;
    samples: number;
    precision?: number;
  }) {
    this.path = path;
    this.segments = segments;
    this.samples = samples;
    this.precision = precision;

    this.svg = path.closest('svg');
    this.group = document.createElementNS('http://www.w3.org/2000/svg', 'g');
    this.group.classList.add('gradient-path');

    if (this.path.parentNode) {
      this.path.parentNode.insertBefore(this.group, this.path.nextSibling);
    }

    this.data = getData({ path, segments, samples, precision });

    this.path.style.display = 'none';
  }

  render({ fill, width }: { fill: ColorStop[]; width: number }) {
    while (this.group.firstChild) {
      this.group.removeChild(this.group.firstChild);
    }

    const pathData = getStroke(
      this.data,
      width,
      this.precision,
      this.path.getAttribute('d')?.match(/z/gi) ? true : false
    );

    for (const sample of pathData) {
      const p = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      p.setAttribute('d', pointsToPath(sample.samples));

      const color = getColorAt(fill, sample.progress);
      p.setAttribute('fill', color);
      p.setAttribute('stroke', 'none');

      this.group.appendChild(p);
    }
  }
}
