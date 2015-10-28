import Spectre
import PathKit
import Ploughman


describe("Feature") {
  let fixtures = Path(__FILE__) + ".." + ".." + "PloughmanSpec" + "fixtures"
  let exampleFeature = fixtures + "example.feature"

  $0.it("can be parsed from a file") {
    let features = try Feature.parse([exampleFeature])

    try expect(features.count) == 1
    try expect(features[0].name) == "Showing build output in simple format"
    try expect(features[0].scenarios.count) == 2
    let scenarios = features[0].scenarios
    try expect(scenarios[0].name) == "Showing file compilation"
    try expect(scenarios[0].line) == 3
    try expect(scenarios[0].steps.count) == 3
    try expect(scenarios[1].name) == "Showing xib compilation"
    try expect(scenarios[1].line) == 8
    try expect(scenarios[1].steps.count) == 3
  }
}
