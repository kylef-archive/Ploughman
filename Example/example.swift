#!/usr/bin/env swift -I .conche/modules -L .conche/lib -lPloughman -lSpectre

import Ploughman
import Spectre

var array: [Int] = []

given("^I have an empty array$") { match in
  array = []
}

given("^I have an array with the numbers (\\d) though (\\d)$") { match in
  let start = match.groups[1]
  let end = match.groups[2]

  array = Array(Int(start)! ..< Int(end)!)
}

when("^I add (\\d) to the array$") { match in
  let number = Int(match.groups[1])!
  array.append(number)
}

when("^I filter the array for even numbers$") { match in
  array = array.filter { $0 % 2 == 0 }
}

then("^I should have (\\d) items? in the array$") { match in
  let count = Int(match.groups[1])!
  try expect(array.count) == count
}

ploughman.run()
