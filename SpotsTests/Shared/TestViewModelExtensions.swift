@testable import Spots
import Foundation
import XCTest
import Brick

class ItemExtensionsTests : XCTestCase {

  func testEvaluateChanges() {
    /*
     Check .New and .Removed
     */

    var oldJSON: [[String : AnyObject]] = [
      ["title" : "foo"],
      ["title" : "bar"],
    ]

    var newJSON: [[String : AnyObject]] = [
      ["title" : "foo"],
      ["title" : "bar"],
      ["title" : "baz"]
    ]

    var newModels = newJSON.map { Item($0) }
    var oldModels = oldJSON.map { Item($0) }
    XCTAssertEqual(newModels.count, 3)
    XCTAssertEqual(oldModels.count, 2)

    var changes = Item.evaluate(newModels, oldModels: oldModels)
    XCTAssertEqual(changes![0], ItemDiff.None)
    XCTAssertEqual(changes![1], ItemDiff.None)
    XCTAssertEqual(changes![2], ItemDiff.New)

    var processedChanges = Item.processChanges(changes!)
    XCTAssertEqual(processedChanges.insertions.count, 1)
    XCTAssertEqual(processedChanges.updates.count, 0)
    XCTAssertEqual(processedChanges.reloads.count, 0)
    XCTAssertEqual(processedChanges.deletions.count, 0)

    changes = Item.evaluate(oldModels, oldModels: newModels)
    XCTAssertEqual(changes![0], ItemDiff.None)
    XCTAssertEqual(changes![1], ItemDiff.None)
    XCTAssertEqual(changes![2], ItemDiff.Removed)

    processedChanges = Item.processChanges(changes!)
    XCTAssertEqual(processedChanges.insertions.count, 0)
    XCTAssertEqual(processedChanges.updates.count, 0)
    XCTAssertEqual(processedChanges.reloads.count, 0)
    XCTAssertEqual(processedChanges.deletions.count, 1)

    /*
     Check that kind takes precedence over title
     */

    oldJSON = [
      ["title" : "foo", "kind" : "course-item"],
      ["title" : "bar", "kind" : "list-item"],
    ]
    newJSON = [
      ["title" : "foo1", "kind" : "course-item"],
      ["title" : "bar1", "kind" : "grid-item"],
    ]

    newModels = newJSON.map { Item($0) }
    oldModels = oldJSON.map { Item($0) }

    changes = Item.evaluate(oldModels, oldModels: newModels)
    XCTAssertEqual(changes![0], ItemDiff.Title)
    XCTAssertEqual(changes![1], ItemDiff.Kind)

    processedChanges = Item.processChanges(changes!)
    XCTAssertEqual(processedChanges.insertions.count, 0)
    XCTAssertEqual(processedChanges.updates.count, 1)
    XCTAssertEqual(processedChanges.reloads.count, 1)
    XCTAssertEqual(processedChanges.deletions.count, 0)
  }
}
