import sharp from "../netlify/node_modules/sharp/lib/index.js";

const [sourcePath, outputPath, proofPath] = process.argv.slice(2);

if (!sourcePath || !outputPath || !proofPath) {
  throw new Error(
    "usage: node scripts/build-bark-avatar.mjs <source> <output.png> <proof.png>",
  );
}

const clamp = (value, minimum, maximum) =>
  Math.min(maximum, Math.max(minimum, value));

const smoothstep = (edge0, edge1, value) => {
  const normalized = clamp((value - edge0) / (edge1 - edge0), 0, 1);
  return normalized * normalized * (3 - 2 * normalized);
};

const { data, info } = await sharp(sourcePath)
  .extract({ left: 250, top: 170, width: 720, height: 880 })
  .removeAlpha()
  .raw()
  .toBuffer({ resolveWithObject: true });

const cutout = Buffer.alloc(info.width * info.height * 4);
const backdrop = 252;

for (let pixel = 0; pixel < info.width * info.height; pixel += 1) {
  const inputOffset = pixel * info.channels;
  const outputOffset = pixel * 4;
  const red = data[inputOffset];
  const green = data[inputOffset + 1];
  const blue = data[inputOffset + 2];
  const luminance = red * 0.2126 + green * 0.7152 + blue * 0.0722;
  const chroma = Math.max(red, green, blue) - Math.min(red, green, blue);

  // The generator baked a 247–255 gray checkerboard into the image. Pixels
  // that differ only by that small neutral variation are background. Dark or
  // violet pixels belong to the approved smoke-glass ribbon.
  const foregroundSignal = Math.max(0, backdrop - luminance - 7) + chroma * 0.7;
  const alpha = smoothstep(4, 150, foregroundSignal);

  if (alpha < 0.015) {
    cutout[outputOffset + 3] = 0;
    continue;
  }

  const recoveredAlpha = Math.max(alpha, 0.08);
  for (let channel = 0; channel < 3; channel += 1) {
    const composite = data[inputOffset + channel];
    const recovered =
      (composite - (1 - recoveredAlpha) * backdrop) / recoveredAlpha;
    cutout[outputOffset + channel] = Math.round(clamp(recovered, 0, 255));
  }
  cutout[outputOffset + 3] = Math.round(alpha * 255);
}

const ribbon = await sharp(cutout, {
  raw: {
    width: info.width,
    height: info.height,
    channels: 4,
  },
})
  .trim({ background: { r: 0, g: 0, b: 0, alpha: 0 }, threshold: 2 })
  .resize({ width: 520, height: 690, fit: "inside" })
  .png()
  .toBuffer();

const lens = Buffer.from(`
  <svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="rim" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#ffffff" stop-opacity="0.62" />
        <stop offset="0.42" stop-color="#ffffff" stop-opacity="0.18" />
        <stop offset="0.73" stop-color="#6c537b" stop-opacity="0.15" />
        <stop offset="1" stop-color="#ffffff" stop-opacity="0.48" />
      </linearGradient>
      <radialGradient id="pane" cx="34%" cy="24%" r="86%">
        <stop offset="0" stop-color="#ffffff" stop-opacity="0.09" />
        <stop offset="0.58" stop-color="#ffffff" stop-opacity="0.035" />
        <stop offset="1" stop-color="#5d466d" stop-opacity="0.045" />
      </radialGradient>
    </defs>
    <circle cx="512" cy="512" r="438" fill="url(#pane)" stroke="url(#rim)" stroke-width="4" />
    <circle cx="512" cy="512" r="432" fill="none" stroke="#ffffff" stroke-opacity="0.13" stroke-width="2" />
    <path d="M 210 273 A 405 405 0 0 1 655 106" fill="none" stroke="#ffffff" stroke-opacity="0.48" stroke-width="5" stroke-linecap="round" />
  </svg>
`);

await sharp({
  create: {
    width: 1024,
    height: 1024,
    channels: 4,
    background: { r: 0, g: 0, b: 0, alpha: 0 },
  },
})
  .composite([
    { input: lens, left: 0, top: 0 },
    { input: ribbon, left: 246, top: 156 },
  ])
  .png()
  .toFile(outputPath);

const lightProof = await sharp({
  create: {
    width: 1024,
    height: 1024,
    channels: 3,
    background: "#eee8e2",
  },
})
  .composite([
    {
      input: Buffer.from(`
        <svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
          <defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
            <stop stop-color="#f4d7c6"/><stop offset="0.48" stop-color="#d9d2ce"/><stop offset="1" stop-color="#d8c7e3"/>
          </linearGradient></defs>
          <rect width="1024" height="1024" fill="url(#g)"/>
        </svg>
      `),
    },
    { input: outputPath },
  ])
  .png()
  .toBuffer();

const darkProof = await sharp({
  create: {
    width: 1024,
    height: 1024,
    channels: 3,
    background: "#17141d",
  },
})
  .composite([
    {
      input: Buffer.from(`
        <svg width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
          <defs><radialGradient id="g" cx="28%" cy="24%" r="92%">
            <stop stop-color="#514559"/><stop offset="0.55" stop-color="#28222f"/><stop offset="1" stop-color="#151219"/>
          </radialGradient></defs>
          <rect width="1024" height="1024" fill="url(#g)"/>
        </svg>
      `),
    },
    { input: outputPath },
  ])
  .png()
  .toBuffer();

await sharp({
  create: {
    width: 2048,
    height: 1024,
    channels: 3,
    background: "#ffffff",
  },
})
  .composite([
    { input: lightProof, left: 0, top: 0 },
    { input: darkProof, left: 1024, top: 0 },
  ])
  .png()
  .toFile(proofPath);

const metadata = await sharp(outputPath).metadata();
console.log(
  JSON.stringify({
    outputPath,
    proofPath,
    width: metadata.width,
    height: metadata.height,
    channels: metadata.channels,
    hasAlpha: metadata.hasAlpha,
  }),
);
