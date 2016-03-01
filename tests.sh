# Every odd value should be the test suit and even values should be the test
# as understood by ./mach
#
# RROrangeHunter will pick a random test, execute with --repeat x --run-until-failure
# and then pick another test until a replay is produced.
HUNT_TESTS=(
   reftest layout/reftests/font-features/subsuper-fallback.html
   mochitest dom/media/tests/mochitest/test_peerConnection_trackDisabling.html
   mochitest toolkit/mozapps/extensions/test/xpinstall/browser_navigateaway3.js
   mochitest browser/base/content/test/general/browser_tabs_close_beforeunload.js
)

HUNT_TESTS_SIZE=$(expr ${#HUNT_TESTS[@]} / 2)
