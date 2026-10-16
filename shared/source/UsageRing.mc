import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// Drawing helpers shared by the glance, the app and the watch face. Usage is
// drawn as a 270-degree gauge open at the bottom, like Body Battery, filling
// clockwise from the lower left with the share of a window used.
(:glance)
module UsageRing {

    const PROVIDER_COLORS = [Graphics.COLOR_ORANGE, Graphics.COLOR_BLUE];
    const GAUGE_START = 225;
    const GAUGE_SWEEP = 270;

    // A dark track, the share used in `color`, and a white tick where an even
    // pace through the window would be.
    function drawGauge(dc, cx, cy, radius, penWidth, color, pct, pacePct) {
        dc.setPenWidth(penWidth);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, GAUGE_START, GAUGE_START - GAUGE_SWEEP);
        if (pct != null) {
            var sweep = (GAUGE_SWEEP * fraction(pct)).toNumber();
            if (sweep > 0) {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, GAUGE_START, GAUGE_START - sweep);
            }
        }
        if (pacePct != null) {
            var angle = Math.toRadians(GAUGE_START - GAUGE_SWEEP * fraction(pacePct));
            var inner = radius - penWidth / 2 - 2;
            var outer = radius + penWidth / 2 + 2;
            dc.setPenWidth(2);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cx + inner * Math.cos(angle), cy - inner * Math.sin(angle),
                cx + outer * Math.cos(angle), cy - outer * Math.sin(angle));
        }
        dc.setPenWidth(1);
    }

    // A horizontal bar: a dark track, the share used, and the pace tick.
    function drawBar(dc, x, y, width, height, color, pct, pacePct) {
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, width, height);
        if (pct != null) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x, y, (width * fraction(pct)).toNumber(), height);
        }
        if (pacePct != null) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + (width * fraction(pacePct)).toNumber() - 1, y - 2, 2, height + 4);
        }
    }

    function fraction(pct) {
        var f = pct.toFloat() / 100.0;
        return f < 0.0 ? 0.0 : (f > 1.0 ? 1.0 : f);
    }

    // Status colour for a share used, like Garmin's stress and load zones.
    function zoneColor(pct, alert) {
        if (alert || (pct != null && pct >= 90)) {
            return Graphics.COLOR_RED;
        }
        if (pct == null || pct < 50) {
            return Graphics.COLOR_GREEN;
        }
        return pct < 75 ? Graphics.COLOR_YELLOW : Graphics.COLOR_ORANGE;
    }

    const STATUS_WORDS = ["Productive", "Maintaining", "Recovering", "Overreaching", "Detraining"];
    const STATUS_COLORS = [Graphics.COLOR_GREEN, Graphics.COLOR_YELLOW, Graphics.COLOR_BLUE,
        Graphics.COLOR_ORANGE, Graphics.COLOR_LT_GRAY];

    // Burn status, like Garmin's training status, as an index into
    // STATUS_WORDS: Detraining with no tokens in seven days; Overreaching
    // when any window is more than 10 points ahead of an even pace; then by
    // load, Productive when high, Recovering when low, Maintaining otherwise;
    // without token logs, Recovering when every window is more than 25 points
    // behind pace, else Maintaining.
    function burnStatus(provider) {
        var ratio = UsageStore.loadRatio([provider]);
        if (ratio != null && ratio == 0) {
            return 4;
        }
        var ahead = null;
        var list = UsageStore.windows(provider);
        for (var i = 0; i < list.size(); i++) {
            var pct = UsageStore.num(list[i] as Dictionary, "pct");
            var pace = UsageStore.num(list[i] as Dictionary, "pace_pct");
            if (pct != null && pace != null && (ahead == null || pct - pace > ahead)) {
                ahead = pct - pace;
            }
        }
        if (ahead != null && ahead > 10) {
            return 3;
        }
        if (ratio != null) {
            return ratio > 1.3 ? 0 : (ratio < 0.8 ? 2 : 1);
        }
        return ahead != null && ahead < -25 ? 2 : 1;
    }

    function loadWord(ratio) {
        return ratio > 1.3 ? "High" : (ratio < 0.8 ? "Low" : "Optimal");
    }

    // Identity colour for a tool, from the snapshot, red while its alert
    // flag is set.
    function colorFor(index, provider) {
        if (UsageStore.isAlert(provider)) {
            return Graphics.COLOR_RED;
        }
        var color = provider.get("color");
        return color instanceof Number ? color : PROVIDER_COLORS[index % PROVIDER_COLORS.size()];
    }

    // The full name for the app's pages, where there is room for it.
    function nameOf(provider) {
        var name = provider.get("name");
        return name instanceof String ? name : shortOf(provider);
    }

    // The short label for the glance, the face and the complication.
    function shortOf(provider) {
        var short = provider.get("short");
        return short instanceof String ? short : "???";
    }

    // The Token Burn flame, centred on (x, y), about 2 * size tall.
    function drawFlame(dc, x, y, size) {
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x, y - size], [x - size * 0.6, y + size * 0.3], [x + size * 0.6, y + size * 0.3]]);
        dc.fillCircle(x, y + size * 0.35, size * 0.6);
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x, y], [x - size * 0.3, y + size * 0.5], [x + size * 0.3, y + size * 0.5]]);
        dc.fillCircle(x, y + size * 0.55, size * 0.3);
    }
}
