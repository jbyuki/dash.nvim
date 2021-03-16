##../dash
@add_tests+=
tests["lua"] = {
  str = [[
print("hello")
]],
  expected = { "hello" }
}
