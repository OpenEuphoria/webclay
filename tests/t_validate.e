include std/unittest.e
include ../webclay/validate.e as v


test_equal("not_empty #1", 0, v:not_empty(""))
test_equal("not_empty #2", 1, v:not_empty("John Doe"))

test_equal("size_within #1", 0, v:size_within("John", 10, 50))
test_equal("size_within #2", 0, v:size_within("Johne", 1, 3))
test_equal("size_within #3", 1, v:size_within("John", 1, 5))
test_equal("size_within #4", 1, v:size_within("John", 1, 4))
test_equal("size_within #5", 1, v:size_within("John", 4, 10))

test_equal("size_equal #1", 0, v:size_equal("John", 10))
test_equal("size_equal #2", 1, v:size_equal("John", 4))

test_report()
