import Toybox.Application;
import Toybox.Complications;
import Toybox.Lang;
import Toybox.Notifications;

// Runs in the background after each fresh snapshot: publishes the busiest
// headline window as a complication, and posts a notification the first time
// a tool's alert or personal-record flag is set, again only after it clears.
(:background)
module UsageEvents {

    const KEY_ALERTED = "alerted";
    const KEY_RECORDED = "recorded";

    function onSnapshot() {
        var providers = UsageStore.providers();
        publishComplication(providers);
        notifyNewAlerts(providers);
    }

    function publishComplication(providers) {
        var top = null;
        var topPct = null;
        for (var i = 0; i < providers.size(); i++) {
            var p = providers[i] as Dictionary;
            var pct = UsageStore.headlinePct(p);
            if (pct != null && (topPct == null || pct > topPct)) {
                top = p;
                topPct = pct;
            }
        }
        if (top == null) {
            return;
        }
        var short = top.get("short");
        Complications.updateComplication(0, {
            :shortLabel => short instanceof String ? short : "BURN",
            :value => topPct.toNumber()
        });
    }

    // Once per crossing: a window over the alert threshold, then a record day.
    function notifyNewAlerts(providers) {
        var fresh = newlyFlagged(providers, KEY_ALERTED, "alert");
        if (fresh != null) {
            var window = UsageStore.headline(fresh);
            Notifications.showNotification("Overreaching",
                fresh.get("name") + " " + (window.get("label") as String).toLower() + " "
                    + UsageStore.formatPct(UsageStore.num(window, "pct")),
                {:dismissPrevious => false});
        }
        fresh = newlyFlagged(providers, KEY_RECORDED, "pr");
        if (fresh != null) {
            Notifications.showNotification("New PR!",
                fresh.get("name") + " " + UsageStore.formatTokens(UsageStore.num(fresh, "today_tokens"))
                    + " tokens torched",
                {:dismissPrevious => false});
        }
    }

    // The first provider whose flag has been set since the last snapshot;
    // `key` remembers which were set, so each fires again only after clearing.
    function newlyFlagged(providers, key, field) {
        var before = Application.Storage.getValue(key);
        if (!(before instanceof Array)) {
            before = [];
        }
        var now = [];
        var fresh = null;
        for (var i = 0; i < providers.size(); i++) {
            var p = providers[i] as Dictionary;
            var name = p.get("name");
            if (p.get(field) == true && name instanceof String) {
                now.add(name);
                if (fresh == null && before.indexOf(name) < 0) {
                    fresh = p;
                }
            }
        }
        Application.Storage.setValue(key, now);
        return fresh;
    }
}
