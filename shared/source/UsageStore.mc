import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;

// Storage access and formatting helpers, shared by the glance, the app and
// the background service (hence the dual annotation).
(:background, :glance)
module UsageStore {

    const KEY_DATA = "usage";
    const KEY_FETCHED_AT = "fetchedAt";
    const FETCH_INTERVAL_SEC = 300;
    const STALE_AFTER_MIN = 20;

    const DEFAULT_URL = "https://raw.githubusercontent.com/eddmann/garmin-token-burn/main/data/usage.json";

    function dataUrl() {
        var url = Application.Properties.getValue("dataUrl");
        if (url instanceof String && url.length() > 0) {
            return url;
        }
        return DEFAULT_URL;
    }

    // Asks the phone's Garmin Connect app to fetch the snapshot, bypassing caches.
    function fetch(callback) {
        Communications.makeWebRequest(dataUrl(), null, {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => {"Cache-Control" => "no-cache"}
        }, callback);
    }

    function save(data) {
        if (data instanceof Dictionary) {
            Application.Storage.setValue(KEY_DATA, data);
            Application.Storage.setValue(KEY_FETCHED_AT, Time.now().value());
        }
    }

    function providers() {
        var data = Application.Storage.getValue(KEY_DATA);
        if (data instanceof Dictionary) {
            var list = data.get("providers");
            if (list instanceof Array) {
                return list;
            }
        }
        return [];
    }

    // The tools the face, glance and complication show: the snapshot's face
    // pair, or the first two.
    function facePair() {
        var list = providers();
        var data = Application.Storage.getValue(KEY_DATA) as Dictionary;
        var face = data != null ? data.get("face") : null;
        var pair = [];
        if (face instanceof Array) {
            for (var i = 0; i < face.size() && pair.size() < 2; i++) {
                if (face[i] instanceof Number && face[i] < list.size()) {
                    pair.add(list[face[i]]);
                }
            }
        }
        if (pair.size() == 0) {
            pair = list.size() > 2 ? list.slice(0, 2) : list;
        }
        return pair;
    }

    function windows(provider) {
        var list = provider.get("windows");
        return list instanceof Array ? list : [];
    }

    // A tool's headline: the window closest to its limit.
    function headline(provider) {
        var best = null;
        var list = windows(provider);
        for (var i = 0; i < list.size(); i++) {
            var pct = num(list[i] as Dictionary, "pct");
            if (pct != null && (best == null || pct > num(best, "pct"))) {
                best = list[i] as Dictionary;
            }
        }
        return best;
    }

    function headlinePct(provider) {
        var window = headline(provider);
        return window == null ? null : num(window, "pct");
    }

    // Burn load, like Garmin's training load: the last seven days' tokens
    // against an average week of the last 30, or null without token logs.
    function loadRatio(list) {
        var week = 0.0;
        var month = 0.0;
        for (var i = 0; i < list.size(); i++) {
            var p = list[i] as Dictionary;
            var last30 = num(p, "last30_tokens");
            var days = p.get("week_tokens");
            if (last30 == null || !(days instanceof Array)) {
                continue;
            }
            month += last30.toFloat();
            for (var d = 0; d < days.size(); d++) {
                if (numeric(days[d]) != null) {
                    week += days[d].toFloat();
                }
            }
        }
        return month > 0 ? week / (month * 7.0 / 30.0) : null;
    }

    function ageMinutes() {
        var fetched = Application.Storage.getValue(KEY_FETCHED_AT);
        if (fetched instanceof Number) {
            var age = Time.now().value() - fetched;
            if (age < 0) {
                age = 0;
            }
            return age / 60;
        }
        return null;
    }

    function num(dict, key) {
        return numeric(dict.get(key));
    }

    // Counts above about 2.1 billion, such as a heavy month of tokens, arrive
    // from the JSON as a Long.
    function numeric(value) {
        if (value instanceof Number || value instanceof Long || value instanceof Float || value instanceof Double) {
            return value;
        }
        return null;
    }

    function isAlert(provider) {
        return provider.get("alert") == true;
    }

    function formatPct(value) {
        if (value == null) {
            return "--%";
        }
        return value.toNumber().toString() + "%";
    }

    function formatTokens(count) {
        if (count == null) {
            return "--";
        }
        var n = count.toFloat();
        if (n >= 1000000000) {
            return (n / 1000000000).format("%.1f") + "B";
        }
        if (n >= 1000000) {
            // Above 100M the decimal no longer fits the round screen.
            return (n / 1000000).format(n >= 100000000 ? "%.0f" : "%.1f") + "M";
        }
        if (n >= 1000) {
            return (n / 1000).format("%.1f") + "K";
        }
        return count.toNumber().toString();
    }

    function formatDuration(mins) {
        if (mins == null) {
            return "--";
        }
        var m = mins.toNumber();
        if (m >= 1440) {
            return (m / 1440).toString() + "d " + ((m % 1440) / 60).toString() + "h";
        }
        if (m >= 60) {
            return (m / 60).toString() + "h " + (m % 60).toString() + "m";
        }
        return m.toString() + "m";
    }

    function formatCost(cost) {
        if (cost == null) {
            return "$--";
        }
        if (cost >= 100) {
            return "$" + cost.toNumber().toString();
        }
        return "$" + cost.toFloat().format("%.2f");
    }
}
