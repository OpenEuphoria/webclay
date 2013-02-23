include std/unittest.e
include std/datetime.e as dt
include ../webclay/webclay.e as wc

datetime testdate
testdate = dt:from_date({114,02,23,17,02,49,6,83})

test_equal("cookie expire time", "euweb_sessinfo=1234; path=/; expires=Sun, 23-Feb-2014 17:02:49 GMT", wc:create_cookie("euweb_sessinfo", "1234", "/", testdate))

test_report()
