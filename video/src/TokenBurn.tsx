import { AbsoluteFill, Img, Sequence, continueRender, delayRender, interpolate, random, spring, staticFile, useCurrentFrame, useVideoConfig } from "remotion";
import { Audio } from "@remotion/media";
import { CAPTIONS } from "./captions";

// Barlow Condensed (OFL), bundled in public/fonts: a condensed sports-advert face.
const FONT = "Barlow Condensed";
const fontsReady = delayRender("Loading Barlow Condensed");
Promise.all([
  new FontFace(FONT, `url(${staticFile("fonts/BarlowCondensed-800Italic.woff2")})`, { weight: "800", style: "italic" }).load(),
  new FontFace(FONT, `url(${staticFile("fonts/BarlowCondensed-600.woff2")})`, { weight: "600", style: "normal" }).load(),
]).then((faces) => {
  faces.forEach((face) => document.fonts.add(face));
  continueRender(fontsReady);
});

export const FPS = 30;
export const DURATION = 40 * FPS;
const s = (seconds: number) => Math.round(seconds * FPS);

// Where each generated wrist shot's blank watch screen sits, in its 1024px image.
const SCREENS = {
  "wrist-dawn": { x: 498, y: 480, r: 153 },
  "wrist-finish": { x: 500, y: 534, r: 159 },
  "wrist-beach": { x: 493.5, y: 517.5, r: 139 },
} as const;

// Camera shake that starts at `at` and settles within half a second.
const shake = (frame: number, at: number | undefined, strength = 14) => {
  if (at === undefined || frame < at) return { x: 0, y: 0 };
  const decay = interpolate(frame - at, [0, 15], [1, 0], { extrapolateRight: "clamp" });
  return { x: Math.sin((frame - at) * 2.7) * strength * decay, y: Math.cos((frame - at) * 3.3) * strength * 0.6 * decay };
};

// A still that slowly pushes in and drifts sideways, like a Ken Burns move.
const Still: React.FC<{ src: string; from?: number; to?: number; drift?: number; shakeAt?: number; children?: React.ReactNode; dim?: number }> = ({ src, from = 1.04, to = 1.14, drift = 0, shakeAt, children, dim = 0 }) => {
  const frame = useCurrentFrame();
  const { durationInFrames } = useVideoConfig();
  const scale = interpolate(frame, [0, durationInFrames], [from, to]);
  const x = interpolate(frame, [0, durationInFrames], [-drift / 2, drift / 2]);
  const jolt = shake(frame, shakeAt);
  return (
    <AbsoluteFill style={{ overflow: "hidden", backgroundColor: "black" }}>
      <AbsoluteFill style={{ transform: `translate(${x + jolt.x}px, ${jolt.y}px) scale(${scale})` }}>
        <Img src={staticFile(`gen/${src}.jpg`)} style={{ width: 1080, height: 1080 }} />
        {children}
      </AbsoluteFill>
      {dim > 0 && <AbsoluteFill style={{ backgroundColor: `rgba(0,0,0,${dim})` }} />}
    </AbsoluteFill>
  );
};

// A watch screen capture clipped to a circle, with a little glass glare.
const Screen: React.FC<{ watch: string; size: number; shake?: boolean }> = ({ watch, size, shake }) => {
  const frame = useCurrentFrame();
  const dx = shake ? Math.sin(frame * 2.2) * interpolate(frame, [0, 18], [6, 0], { extrapolateRight: "clamp" }) : 0;
  return (
    <div style={{ width: size, height: size, borderRadius: "50%", overflow: "hidden", position: "relative", transform: `translateX(${dx}px)`, backgroundColor: "black" }}>
      <Img src={staticFile(`watch/${watch}.png`)} style={{ width: size, height: size }} />
      <div style={{ position: "absolute", inset: 0, borderRadius: "50%", background: "linear-gradient(135deg, rgba(255,255,255,0.10) 0%, rgba(255,255,255,0) 45%)" }} />
      <Sweep />
    </div>
  );
};

// A band of light that crosses the watch glass every couple of seconds.
const Sweep = () => {
  const frame = useCurrentFrame();
  const pos = interpolate((frame + 20) % 75, [0, 30], [-60, 160], { extrapolateRight: "clamp" });
  return <div style={{ position: "absolute", inset: 0, background: `linear-gradient(115deg, rgba(255,255,255,0) ${pos - 12}%, rgba(255,255,255,0.16) ${pos}%, rgba(255,255,255,0) ${pos + 12}%)` }} />;
};

// Drifting particles: dust in the light, falling confetti or rising embers.
const Particles: React.FC<{ kind: "dust" | "confetti" | "embers"; count: number; seed: string }> = ({ kind, count, seed }) => {
  const frame = useCurrentFrame();
  const colours = ["#ff5a1f", "#ffd23f", "#3fa7ff", "#ffffff", "#ff3f7f"];
  return (
    <AbsoluteFill style={{ pointerEvents: "none" }}>
      {Array.from({ length: count }, (_, i) => {
        const r = (k: string) => random(`${seed}-${i}-${k}`);
        const speed = kind === "dust" ? 0.3 + r("s") * 0.5 : 3 + r("s") * 5;
        const size = kind === "confetti" ? 10 + r("z") * 12 : kind === "embers" ? 3 + r("z") * 5 : 2 + r("z") * 4;
        const x = r("x") * 1080 + Math.sin(frame / (12 + r("w") * 20) + r("p") * 6) * (kind === "dust" ? 20 : 40);
        const travel = (r("y") * 1300 + frame * speed) % 1300 - 110;
        const y = kind === "embers" || kind === "dust" ? 1080 - travel : travel;
        const style: React.CSSProperties = kind === "confetti"
          ? { width: size, height: size * 0.45, background: colours[i % colours.length], transform: `rotate(${frame * (4 + r("r") * 8)}deg)` }
          : { width: size, height: size, borderRadius: "50%", background: kind === "embers" ? "#ff8a2a" : "rgba(255,240,210,0.55)", boxShadow: kind === "embers" ? "0 0 10px #ff6a00" : "none", opacity: kind === "dust" ? 0.35 + r("o") * 0.4 : 0.9 };
        return <div key={i} style={{ position: "absolute", left: x, top: y, ...style }} />;
      })}
    </AbsoluteFill>
  );
};

// Our screen dropped onto a generated wrist shot's blank watch face.
const OnWrist: React.FC<{ shot: keyof typeof SCREENS; watch: string; shake?: boolean }> = ({ shot, watch, shake }) => {
  const k = 1080 / 1024;
  const { x, y, r } = SCREENS[shot];
  return (
    <div style={{ position: "absolute", left: (x - r) * k, top: (y - r) * k }}>
      <Screen watch={watch} size={2 * r * k} shake={shake} />
    </div>
  );
};

// A plain round watch, for scenes without a wrist in shot.
const Watch: React.FC<{ watch: string; size?: number; x?: number; y?: number }> = ({ watch, size = 440, x = 560, y = 330 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame, fps, config: { damping: 14 } });
  const bezel = 34;
  // Drifts against the background for a little parallax, with a slow bob.
  const dx = -frame * 0.35;
  const dy = Math.sin(frame / 18) * 6;
  return (
    <div style={{ position: "absolute", left: x, top: y, transform: `translate(${dx}px, ${dy}px) scale(${0.85 + 0.15 * pop}) rotate(${Math.sin(frame / 30) * 1.5}deg)`, opacity: pop }}>
      <div style={{ width: size + 2 * bezel, height: size + 2 * bezel, borderRadius: "50%", background: "radial-gradient(circle at 35% 30%, #4a4a4a, #141414 70%)", boxShadow: "0 30px 80px rgba(0,0,0,0.7)", display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Screen watch={watch} size={size} />
      </div>
    </div>
  );
};

// A caption laid out in full from the start, each word fading up as the narrator says it.
const Caption: React.FC<{ vo: string }> = ({ vo }) => {
  const frame = useCurrentFrame();
  return (
    <AbsoluteFill style={{ justifyContent: "flex-end", alignItems: "center", paddingBottom: 80 }}>
      <div style={{ fontFamily: FONT, fontWeight: 800, fontStyle: "italic", fontSize: 72, color: "white", textAlign: "center", maxWidth: 900, lineHeight: 1.0, textShadow: "0 4px 22px rgba(0,0,0,0.9)", textTransform: "uppercase", letterSpacing: -0.5 }}>
        {CAPTIONS[vo].map((line, i) => (
          <div key={i}>
            {line.map(([word, at], j) => {
              const shown = interpolate(frame, [s(at), s(at) + 4], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
              return (
                <span key={j} style={{ display: "inline-block", opacity: shown, transform: `translateY(${(1 - shown) * 6}px)`, marginRight: j < line.length - 1 ? "0.22em" : 0 }}>
                  {word}
                </span>
              );
            })}
          </div>
        ))}
      </div>
    </AbsoluteFill>
  );
};

const Line: React.FC<{ at: number; vo: string; until: number }> = ({ at, vo, until }) => (
  <Sequence from={s(at)} durationInFrames={s(until - at)} premountFor={FPS}>
    <Audio src={staticFile(`vo/${vo}.wav`)} />
    {CAPTIONS[vo] && <Caption vo={vo} />}
  </Sequence>
);

const Scene: React.FC<{ at: number; to: number; children: React.ReactNode }> = ({ at, to, children }) => (
  <Sequence from={s(at)} durationInFrames={s(to - at)} premountFor={FPS}>
    {children}
  </Sequence>
);

const EndCard = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const pop = spring({ frame, fps, config: { damping: 12 } });
  const later = interpolate(frame, [s(1.2), s(1.8)], [0, 1], { extrapolateLeft: "clamp", extrapolateRight: "clamp" });
  return (
    <AbsoluteFill>
      <Still src="embers" dim={0.35} from={1.0} to={1.08} />
      <Particles kind="embers" count={60} seed="end" />
      <AbsoluteFill style={{ justifyContent: "center", alignItems: "center", fontFamily: FONT, color: "white", textAlign: "center" }}>
        <div style={{ transform: `scale(${0.8 + 0.2 * pop})`, opacity: pop, fontSize: 170, fontWeight: 800, fontStyle: "italic", letterSpacing: -2, textTransform: "uppercase", lineHeight: 1 }}>Token Burn 🔥</div>
        <div style={{ opacity: later, fontSize: 64, fontWeight: 800, fontStyle: "italic", textTransform: "uppercase", marginTop: 12 }}>Feel the Token Burn.</div>
        <div style={{ opacity: later, fontSize: 36, fontWeight: 600, marginTop: 80, color: "#ddd" }}>github.com/eddmann/garmin-token-burn</div>
        <div style={{ opacity: later, fontSize: 28, fontWeight: 600, marginTop: 14, color: "#aaa" }}>Unofficial. CodexBar on a Garmin, because why not.</div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// When each voice line plays, in seconds, so the music can duck under it.
// When each voice line plays and how long it lasts, in seconds, and when its shot ends (so its caption holds).
const VOICE: [string, number, number, number][] = [
  ["l1", 0.5, 4.96, 5.8],
  ["l2", 6.6, 3.09, 10],
  ["l3", 10.3, 2.46, 15.2],
  ["l4", 15.6, 3.53, 21.2],
  ["l5", 21.6, 2.71, 24.6],
  ["l6", 25.0, 3.71, 29.2],
  ["l7", 31.0, 2.4, 33.6],
  ["l8", 34.4, 3.59, 40],
];

const musicVolume = (f: number) => {
  const t = f / FPS;
  const duck = Math.max(0, ...VOICE.map(([, at, length]) =>
    interpolate(t, [at - 0.2, at, at + length, at + length + 0.3], [0, 1, 1, 0], { extrapolateLeft: "clamp", extrapolateRight: "clamp" })));
  return interpolate(duck, [0, 1], [0.9, 0.2]);
};

export const TokenBurn = () => (
  <AbsoluteFill style={{ backgroundColor: "black" }}>
    <Audio src={staticFile("music/track.wav")} volume={musicVolume} />

    <Scene at={0} to={5.8}><Still src="runner-dawn" drift={50} /><Particles kind="dust" count={40} seed="dawn" /></Scene>
    <Scene at={5.8} to={10}>
      <Still src="wrist-dawn" from={1.0} to={1.08} drift={30} shakeAt={s(1)}>
        <Sequence durationInFrames={s(1)} layout="none"><OnWrist shot="wrist-dawn" watch="face" /></Sequence>
        <Sequence from={s(1)} layout="none"><OnWrist shot="wrist-dawn" watch="notif-overreaching" shake /></Sequence>
      </Still>
    </Scene>
    <Scene at={10} to={15.2}>
      <Still src="typing" dim={0.25} drift={-70} />
      <Sequence from={s(0.8)} layout="none"><Watch watch="status" x={500} y={230} /></Sequence>
    </Scene>
    <Scene at={15.2} to={17.4}><Still src="finish-line" from={1.12} to={1.0} drift={40} /><Particles kind="confetti" count={70} seed="finish" /></Scene>
    <Scene at={17.4} to={21.2}>
      <Still src="wrist-finish" from={1.0} to={1.06} drift={-30} shakeAt={0}>
        <Sequence durationInFrames={s(1.5)} layout="none"><OnWrist shot="wrist-finish" watch="notif-pr" shake /></Sequence>
        <Sequence from={s(1.5)} layout="none"><OnWrist shot="wrist-finish" watch="today" /></Sequence>
      </Still>
      <Particles kind="confetti" count={45} seed="pr" />
    </Scene>
    <Scene at={21.2} to={24.6}>
      <Still src="sofa" dim={0.2} drift={50} />
      <Particles kind="dust" count={30} seed="sofa" />
      <Sequence from={s(0.6)} layout="none"><Watch watch="claude" x={60} y={250} /></Sequence>
    </Scene>
    <Scene at={24.6} to={29.2}>
      <Still src="coach" dim={0.2} drift={-60} />
      <Sequence from={s(0.6)} layout="none"><Watch watch="history" x={500} y={230} /></Sequence>
    </Scene>
    <Scene at={29.2} to={30.6}><Still src="beach" drift={60} /></Scene>
    <Scene at={30.6} to={33.6}>
      <Still src="wrist-beach" from={1.0} to={1.1} drift={20}><OnWrist shot="wrist-beach" watch="detraining" /></Still>
    </Scene>
    <Scene at={33.6} to={40}><EndCard /></Scene>

    {VOICE.map(([vo, at, , until]) => <Line key={vo} at={at} vo={vo} until={until} />)}
  </AbsoluteFill>
);
