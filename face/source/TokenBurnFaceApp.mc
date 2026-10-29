import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

(:background)
class TokenBurnFaceApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        // Idempotent: the system throttles temporal events to one per 5 minutes.
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(UsageStore.FETCH_INTERVAL_SEC));
        }
    }

    function onStop(state) {
    }

    function getInitialView() {
        return [new TokenBurnFaceView()];
    }

    function getServiceDelegate() {
        return [new TokenBurnServiceDelegate()];
    }

    function onBackgroundData(data) {
        // The background service has already stored the snapshot.
        WatchUi.requestUpdate();
    }
}
