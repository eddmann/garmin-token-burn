import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class TokenBurnGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    // Like Garmin's own glances: a title, each face tool's headline window,
    // and a thin bar under each figure.
    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var providers = UsageStore.facePair();
        var alert = false;
        var line = providers.size() == 0 ? "no data yet" : "";
        for (var i = 0; i < providers.size(); i++) {
            var p = providers[i] as Dictionary;
            var pct = UsageStore.headlinePct(p);
            if (i > 0) {
                line += "  ";
            }
            line += UsageRing.shortOf(p) + " " + UsageStore.formatPct(pct);
            alert = alert || UsageStore.isAlert(p);

            var left = i * w / 2;
            var width = w / 2 - 8;
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left, h - 5, width, 4);
            if (pct != null) {
                dc.setColor(UsageRing.zoneColor(pct, UsageStore.isAlert(p)), Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(left, h - 5, (width * UsageRing.fraction(pct)).toNumber(), 4);
            }
        }

        dc.setColor(alert ? Graphics.COLOR_RED : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h * 2 / 9, Graphics.FONT_GLANCE, alert ? "TOKEN BURN !" : "TOKEN BURN",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h * 5 / 9, Graphics.FONT_GLANCE, line,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
