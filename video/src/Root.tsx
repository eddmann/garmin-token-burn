import { Composition } from "remotion";
import { TokenBurn, DURATION, FPS } from "./TokenBurn";

export const Root = () => (
  <Composition id="TokenBurn" component={TokenBurn} durationInFrames={DURATION} fps={FPS} width={1080} height={1080} />
);
