import Toybox.Background;
import Toybox.Lang;
import Toybox.System;

// Runs every FETCH_INTERVAL_SEC via a temporal event. The HTTP request is
// proxied through the phone's Garmin Connect app over Bluetooth. The result
// is stored here, passed to UsageEvents, and handed to the running app via
// Background.exit.
(:background)
class TokenBurnServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        UsageStore.fetch(method(:onReceive));
    }

    function onReceive(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary) {
            UsageStore.save(data);
            UsageEvents.onSnapshot();
            Background.exit(data);
        } else {
            Background.exit(null);
        }
    }
}
