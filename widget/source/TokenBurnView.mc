import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.WatchUi;

// Full-screen app. Pages, cycled with up/down or select:
//   MORNING REPORT: yesterday's burn, burn status and what is left, per tool
//   BURN STATUS: a Body Battery-style gauge per tool on its headline window
//   one page per tool: its burn status, plan and credits, and every window
//   TODAY'S BURN: tokens burned and notional cost for the day
//   BURN HISTORY: the month's tokens and cost, the last week's bars, load and streak
class TokenBurnView extends WatchUi.View {

    var mPage = 0;

    function initialize() {
        View.initialize();
    }

    function onShow() {
        // Refresh in the foreground if the background snapshot is stale.
        var age = UsageStore.ageMinutes();
        if (age == null || age >= UsageStore.FETCH_INTERVAL_SEC / 60) {
            UsageStore.fetch(method(:onData));
        }
    }

    function onData(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200) {
            UsageStore.save(data);
        }
        WatchUi.requestUpdate();
    }

    // The tools the pages show: the snapshot already holds at most three.
    function shown() {
        var list = UsageStore.providers();
        return list.size() > 3 ? list.slice(0, 3) : list;
    }

    function pageCount() {
        return shown().size() + 4;
    }

    function nextPage() {
        mPage = (mPage + 1) % pageCount();
        WatchUi.requestUpdate();
    }

    function previousPage() {
        mPage = (mPage + pageCount() - 1) % pageCount();
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        var providers = shown();
        if (providers.size() == 0) {
            drawEmpty(dc);
            return;
        }

        var count = pageCount();
        mPage = mPage % count;
        if (mPage == 0) {
            drawMorningPage(dc, providers);
        } else if (mPage == 1) {
            drawOverviewPage(dc, providers);
        } else if (mPage <= providers.size() + 1) {
            drawProviderPage(dc, mPage - 2, providers[mPage - 2] as Dictionary);
        } else if (mPage == count - 2) {
            drawTodayPage(dc, withCost(providers));
        } else {
            drawHistoryPage(dc, withCost(providers));
        }
        drawPageDots(dc, count);
    }

    function drawEmpty(dc) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 30, Graphics.FONT_SMALL, "No data yet", Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 5, Graphics.FONT_XTINY, "Check phone connection", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + 30, Graphics.FONT_XTINY, "and the publisher", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // The tools with local token logs, for the burn pages.
    function withCost(providers) {
        var list = [];
        for (var i = 0; i < providers.size(); i++) {
            var p = providers[i] as Dictionary;
            if (p.get("last30_tokens") != null || p.get("today_tokens") != null) {
                list.add(p);
            }
        }
        return list;
    }

    // Like Garmin's morning report: per tool, yesterday's tokens and dollars
    // burned, then its burn status and how much of its headline window is left.
    function drawMorningPage(dc, providers) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var count = providers.size();
        var th = dc.getFontHeight(Graphics.FONT_TINY);
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var y = cy - (xh + count * (th + xh)) / 2;
        drawTitle(dc, cx, y, "MORNING REPORT");
        y += xh;

        for (var i = 0; i < count; i++) {
            var p = providers[i] as Dictionary;
            var tokens = UsageStore.num(p, "yesterday_tokens");
            var line = UsageRing.nameOf(p) + " ";
            line += tokens == null ? "" : UsageStore.formatTokens(tokens) + " · "
                + UsageStore.formatCost(UsageStore.num(p, "yesterday_cost_usd"));
            dc.setColor(UsageRing.colorFor(i, p), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY, line, Graphics.TEXT_JUSTIFY_CENTER);

            var status = UsageRing.burnStatus(p);
            var pct = UsageStore.headlinePct(p);
            drawTwoTone(dc, cx, y + th, Graphics.FONT_XTINY, UsageRing.STATUS_COLORS[status],
                UsageRing.STATUS_WORDS[status] + " · ", Graphics.COLOR_LT_GRAY,
                pct == null ? "--" : (100 - pct.toNumber()).toString() + "% left");
            y += th + xh;
        }

        drawFooter(dc, cx);
    }

    // A gauge per tool (outermost first) on its headline window, with a pace
    // tick, and the numbers stacked in the middle; the footer sits in the
    // gauges' gap.
    function drawOverviewPage(dc, providers) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var count = providers.size();
        var pen = count > 2 ? 7 : 8;

        for (var i = 0; i < count; i++) {
            var p = providers[i] as Dictionary;
            var window = UsageStore.headline(p);
            var pct = window == null ? null : UsageStore.num(window, "pct");
            UsageRing.drawGauge(dc, cx, cy, cx - 14 - i * (pen + 5), pen,
                UsageRing.zoneColor(pct, UsageStore.isAlert(p)), pct,
                window == null ? null : UsageStore.num(window, "pace_pct"));
        }

        // With two tools there is room for each one's burn status and time to
        // recover; with three, only the figures fit inside the gauges.
        var font = count > 2 ? Graphics.FONT_TINY : Graphics.FONT_MEDIUM;
        var fh = dc.getFontHeight(font);
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var detail = count <= 2;
        var y = cy - (xh + count * (fh + (detail ? xh : 0))) / 2;
        drawTitle(dc, cx, y, "BURN STATUS");
        y += xh;

        for (var i = 0; i < count; i++) {
            var p = providers[i] as Dictionary;
            var window = UsageStore.headline(p);
            var pct = window == null ? null : UsageStore.num(window, "pct");
            drawTwoTone(dc, cx, y, font, UsageRing.colorFor(i, p), UsageRing.nameOf(p) + " ",
                UsageRing.zoneColor(pct, UsageStore.isAlert(p)), UsageStore.formatPct(pct));
            if (detail) {
                var status = UsageRing.burnStatus(p);
                drawTwoTone(dc, cx, y + fh, Graphics.FONT_XTINY, UsageRing.STATUS_COLORS[status],
                    UsageRing.STATUS_WORDS[status] + " · ", Graphics.COLOR_LT_GRAY, recovery(window));
                y += xh;
            }
            y += fh;
        }

        drawFooter(dc, cx);
    }

    // Time until a window resets, which the watch calls recovery.
    function recovery(window) {
        return window == null ? "--" : UsageStore.formatDuration(UsageStore.num(window, "resets_min"));
    }

    // A label in one colour and a figure in another, centred as one line.
    function drawTwoTone(dc, cx, y, font, labelColor, label, valueColor, value) {
        var left = cx - dc.getTextWidthInPixels(label + value, font) / 2;
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, y, font, label, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left + dc.getTextWidthInPixels(label, font), y, font, value, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // One tool: its burn status, plan and credits, then a row per window with
    // its time to recover, the share used, and a bar with the pace tick.
    function drawProviderPage(dc, index, provider) {
        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var th = dc.getFontHeight(Graphics.FONT_TINY);
        var list = UsageStore.windows(provider);
        var rows = list.size() < 3 ? list.size() : 3;
        var rowHeight = th + 9;
        var error = provider.get("error");
        var bodyHeight = rows > 0 ? rows * rowHeight : 2 * xh;
        var y = cy - (3 * xh + 4 + bodyHeight) / 2;

        drawTitle(dc, cx, y, (UsageRing.nameOf(provider) as String).toUpper());
        y += xh;
        var burn = UsageRing.burnStatus(provider);
        dc.setColor(UsageRing.STATUS_COLORS[burn], Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, UsageRing.STATUS_WORDS[burn], Graphics.TEXT_JUSTIFY_CENTER);
        y += xh;
        var status = provider.get("status");
        dc.setColor(status instanceof String ? Graphics.COLOR_ORANGE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, status instanceof String ? status : subtitle(provider),
            Graphics.TEXT_JUSTIFY_CENTER);
        y += xh + 4;

        if (rows == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            var text = error instanceof String ? error : "No limits reported";
            var split = splitLine(text);
            dc.drawText(cx, y, Graphics.FONT_XTINY, split[0], Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, y + xh, Graphics.FONT_XTINY, split[1], Graphics.TEXT_JUSTIFY_CENTER);
        }

        var rowWidth = w * 3 / 4;
        var left = cx - rowWidth / 2;
        for (var i = 0; i < rows; i++) {
            var window = list[i] as Dictionary;
            var pct = UsageStore.num(window, "pct");
            var color = UsageRing.zoneColor(pct, false);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left, y + th - xh, Graphics.FONT_XTINY,
                window.get("label") + "  " + UsageStore.formatDuration(UsageStore.num(window, "resets_min")),
                Graphics.TEXT_JUSTIFY_LEFT);
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + rowWidth, y, Graphics.FONT_TINY, UsageStore.formatPct(pct), Graphics.TEXT_JUSTIFY_RIGHT);
            UsageRing.drawBar(dc, left, y + th + 1, rowWidth, 4, color, pct, UsageStore.num(window, "pace_pct"));
            y += rowHeight;
        }

        drawFooter(dc, cx);
    }

    function subtitle(provider) {
        var parts = [];
        if (provider.get("plan") instanceof String) {
            parts.add(provider.get("plan"));
        }
        if (provider.get("credits") instanceof String) {
            parts.add(provider.get("credits"));
        }
        if (parts.size() == 0) {
            return "";
        }
        return parts.size() == 1 ? parts[0] : parts[0] + " · " + parts[1];
    }

    // Two halves of a message, broken at the space nearest the middle.
    function splitLine(text as String) {
        var chars = text.toCharArray();
        var mid = chars.size() / 2;
        for (var d = 0; d < mid; d++) {
            if (chars[mid + d] == ' ') {
                return [text.substring(0, mid + d), text.substring(mid + d + 1, chars.size())];
            }
            if (chars[mid - d] == ' ') {
                return [text.substring(0, mid - d), text.substring(mid - d + 1, chars.size())];
            }
        }
        return [text, ""];
    }

    function drawTodayPage(dc, providers) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var count = providers.size();

        var font = count > 2 ? Graphics.FONT_TINY : Graphics.FONT_MEDIUM;
        var mh = dc.getFontHeight(font);
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var th = dc.getFontHeight(Graphics.FONT_TINY);
        var y = cy - (xh + count * (mh + xh) + th) / 2;
        drawTitle(dc, cx, y, "TODAY'S BURN");
        y += xh;

        var totalTokens = 0.0;
        for (var i = 0; i < count; i++) {
            var p = providers[i] as Dictionary;
            var tokens = UsageStore.num(p, "today_tokens");
            if (tokens != null) {
                totalTokens += tokens.toFloat();
            }
            dc.setColor(UsageRing.colorFor(i, p), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, font,
                UsageRing.nameOf(p) + " " + UsageStore.formatTokens(tokens),
                Graphics.TEXT_JUSTIFY_CENTER);
            // Cost reads like calories burned, with a badge on a record day.
            var cost = UsageStore.formatCost(UsageStore.num(p, "today_cost_usd")) + " burned";
            if (p.get("pr") == true) {
                drawTwoTone(dc, cx, y + mh, Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY, cost + " · ",
                    Graphics.COLOR_YELLOW, "PR");
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y + mh, Graphics.FONT_XTINY, cost, Graphics.TEXT_JUSTIFY_CENTER);
            }
            y += mh + xh;
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_TINY,
            UsageStore.formatTokens(totalTokens) + " tokens torched",
            Graphics.TEXT_JUSTIFY_CENTER);

        drawFooter(dc, cx);
    }

    // A line per tool for the month, then the last seven days as stacked bars
    // scaled to the busiest day, oldest on the left, with the burn load and
    // the longest streak beneath, and PR beside today on a record day.
    function drawHistoryPage(dc, providers) {
        var w = dc.getWidth();
        var cx = w / 2;
        var cy = dc.getHeight() / 2;

        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var th = dc.getFontHeight(Graphics.FONT_TINY);
        var chartHeight = 40;
        var count = providers.size();
        var y = cy - (xh + count * th + 6 + chartHeight + 2 + xh) / 2;
        drawTitle(dc, cx, y, "BURN HISTORY");
        y += xh;

        for (var i = 0; i < count; i++) {
            var p = providers[i] as Dictionary;
            dc.setColor(UsageRing.colorFor(i, p), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_TINY,
                UsageRing.nameOf(p) + " " + UsageStore.formatTokens(UsageStore.num(p, "last30_tokens"))
                    + "  " + UsageStore.formatCost(UsageStore.num(p, "last30_cost_usd")),
                Graphics.TEXT_JUSTIFY_CENTER);
            y += th;
        }
        y += 6;

        var days = 7;
        var gap = 4;
        var chartWidth = w * 3 / 5;
        var barWidth = (chartWidth - gap * (days - 1)) / days;
        var left = cx - chartWidth / 2;
        var base = y + chartHeight;

        var most = 0.0;
        var sum = 0.0;
        for (var d = 0; d < days; d++) {
            var total = 0.0;
            for (var i = 0; i < count; i++) {
                total += dayTokens(providers[i] as Dictionary, d);
            }
            sum += total;
            if (total > most) {
                most = total;
            }
        }
        var average = sum / days;

        for (var d = 0; d < days && most > 0; d++) {
            var x = left + d * (barWidth + gap);
            var top = base;
            for (var i = 0; i < count; i++) {
                var p = providers[i] as Dictionary;
                var h = (dayTokens(p, d) / most * chartHeight).toNumber();
                if (h > 0) {
                    top -= h;
                    dc.setColor(UsageRing.colorFor(i, p), Graphics.COLOR_TRANSPARENT);
                    dc.fillRectangle(x, top, barWidth, h);
                }
            }
        }
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left, base + 1, left + chartWidth, base + 1);

        // A dotted line at the daily average, like Garmin's history charts.
        if (most > 0) {
            var avgY = base - (average / most * chartHeight).toNumber();
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            for (var x = left; x < left + chartWidth; x += 4) {
                dc.fillRectangle(x, avgY, 2, 1);
            }
        }

        var streak = 0;
        var record = false;
        for (var i = 0; i < count; i++) {
            var p = providers[i] as Dictionary;
            var run = UsageStore.num(p, "streak");
            if (run != null && run > streak) {
                streak = run;
            }
            record = record || p.get("pr") == true;
        }
        if (record) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(left + days * (barWidth + gap), base - chartHeight,
                Graphics.FONT_XTINY, "PR", Graphics.TEXT_JUSTIFY_LEFT);
        }

        y = base + 2;
        var ratio = UsageStore.loadRatio(providers);
        var text = streak.toString() + "-day streak";
        if (ratio != null) {
            text = "Load " + UsageRing.loadWord(ratio) + " · " + text;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER);

        drawFooter(dc, cx);
    }

    function dayTokens(provider as Dictionary, index as Number) as Float {
        var week = provider["week_tokens"];
        if (week instanceof Array && index < week.size() && UsageStore.numeric(week[index]) != null) {
            return week[index].toFloat();
        }
        return 0.0;
    }

    // The page title with the flame to its left, like a Garmin metric icon.
    function drawTitle(dc, cx, y, title) {
        var xh = dc.getFontHeight(Graphics.FONT_XTINY);
        var size = xh / 3;
        var width = dc.getTextWidthInPixels(title, Graphics.FONT_XTINY);
        UsageRing.drawFlame(dc, cx - (width + size * 3) / 2 + size, y + xh / 2, size);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx + size * 3 / 2, y, Graphics.FONT_XTINY, title, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // The age of the snapshot, at the bottom where the gauges leave a gap.
    function drawFooter(dc, cx) {
        var age = UsageStore.ageMinutes();
        var text = age == null ? "" : UsageStore.formatDuration(age) + " ago";
        if (age != null && age >= UsageStore.STALE_AFTER_MIN) {
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            text = "stale · " + text;
        } else {
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        }
        var h = dc.getHeight();
        dc.drawText(cx, h - dc.getFontHeight(Graphics.FONT_XTINY) - h / 16, Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Garmin's page indicator: a dot per page on the left edge, the current
    // one white.
    function drawPageDots(dc, count) {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var radius = cx - 5;
        for (var i = 0; i < count; i++) {
            var angle = Math.toRadians(180 + (i - (count - 1) / 2.0) * 6);
            var x = cx + radius * Math.cos(angle);
            var y = cy - radius * Math.sin(angle);
            if (i == mPage) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, 3);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x, y, 2);
            }
        }
    }
}
