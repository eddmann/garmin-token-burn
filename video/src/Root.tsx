import { Composition } from "remotion";
import { TokenBurn, TokenBurnStock, DURATION, FPS } from "./TokenBurn";

export const Root = () => (
  <>
    <Composition id="TokenBurn" component={TokenBurn} durationInFrames={DURATION} fps={FPS} width={1080} height={1080} />
    <Composition id="TokenBurnStock" component={TokenBurnStock} durationInFrames={DURATION} fps={FPS} width={1080} height={1080} />
  </>
);
