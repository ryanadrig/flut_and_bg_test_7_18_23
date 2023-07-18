# and_bg_fetch_test


# Reference
logs with:::
    $ adb logcat *:S flutter:V, TSBackgroundFetch:V

Simulate a background-fetch event on a device
(insert <your.application.id>) (only works for sdk 21+:::
    $ adb shell cmd jobscheduler run -f <your.application.id> 999

For devices with sdk <21, simulate a "Headless" event with
(insert <your.application.id>):::
    $ adb shell am broadcast -a <your.application.id>.event.BACKGROUND_FETCH
