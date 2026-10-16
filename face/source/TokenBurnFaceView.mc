import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Watch face: the time in the middle, framed by a thin gauge per tool showing
// how much of its headline window, the one closest to its limit, is used, with the flame at 12 and
// the percentages below; a tool turns red while its alert flag is set.
class TokenBurnFaceView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    function onUpdate(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        var providers = UsageStore.facePair();
        for (var i = 0; i < 2; i++) {
            var color = UsageRing.PROVIDER_COLORS[i];
            var pct = null;
            if (i < providers.size()) {
                var p = providers[i] as Dictionary;
                color = UsageRing.colorFor(i, p);
                pct = UsageStore.headlinePct(p);
            }
            UsageRing.drawGauge(dc, cx, cy, cx - 4 - (i * 8), 4, color, pct, null);
        }
        UsageRing.drawFlame(dc, cx, cx / 5 + 9, cx / 14);

        var timeFont = Graphics.FONT_NUMBER_HOT;
        var timeHeight = dc.getFontHeight(timeFont);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, timeFont, timeText(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var smallHeight = dc.getFontHeight(Graphics.FONT_TINY);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - timeHeight / 2 - smallHeight, Graphics.FONT_TINY, dateText(),
            Graphics.TEXT_JUSTIFY_CENTER);

        var y = cy + timeHeight / 2;
        if (providers.size() == 0) {
            dc.drawText(cx, y, Graphics.FONT_TINY, "no data yet", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }
        for (var i = 0; i < providers.size(); i++) {
            var p = providers[i] as Dictionary;
            var text = UsageRing.shortOf(p) + " " + UsageStore.formatPct(UsageStore.headlinePct(p));
            dc.setColor(UsageRing.colorFor(i, p), Graphics.COLOR_TRANSPARENT);
            if (providers.size() == 1) {
                dc.drawText(cx, y, Graphics.FONT_TINY, text, Graphics.TEXT_JUSTIFY_CENTER);
            } else if (i == 0) {
                dc.drawText(cx - 6, y, Graphics.FONT_TINY, text, Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(cx + 6, y, Graphics.FONT_TINY, text, Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        var age = UsageStore.ageMinutes();
        if (age != null && age >= UsageStore.STALE_AFTER_MIN) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + smallHeight, Graphics.FONT_XTINY,
                "stale · " + UsageStore.formatDuration(age) + " ago", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function timeText() {
        var clock = System.getClockTime();
        var hour = clock.hour;
        if (!System.getDeviceSettings().is24Hour) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
            return hour.toString() + ":" + clock.min.format("%02d");
        }
        return hour.format("%02d") + ":" + clock.min.format("%02d");
    }

    function dateText() {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return (info.day_of_week as String).toUpper() + " " + (info.day as Number).toString();
    }
}
