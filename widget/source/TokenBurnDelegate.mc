import Toybox.Lang;
import Toybox.WatchUi;

class TokenBurnDelegate extends WatchUi.BehaviorDelegate {

    var mView;

    function initialize(view) {
        BehaviorDelegate.initialize();
        mView = view;
    }

    function onNextPage() {
        mView.nextPage();
        return true;
    }

    function onPreviousPage() {
        mView.previousPage();
        return true;
    }

    function onSelect() {
        mView.nextPage();
        return true;
    }
}
