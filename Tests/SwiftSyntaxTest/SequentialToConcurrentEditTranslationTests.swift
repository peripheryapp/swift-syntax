//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import SwiftSyntax
import _SwiftSyntaxTestSupport

let longString = """
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwxyz\
  1234567890abcdefghijklmnopqrstuvwzyz
  """

/// Verifies that
///  1. translation of the `sequential` edits results in the
///     `expectedConcurrent` edits
///  2. applying the `sequential` and concurrent edits to `testString` results
///     in the same post-edit string
func verifySequentialToConcurrentTranslation(
  _ sequential: [SourceEdit],
  _ expectedConcurrent: [SourceEdit],
  testString: String = longString
) {
  let concurrent = ConcurrentEdits(fromSequential: sequential)
  XCTAssertEqual(concurrent.edits, expectedConcurrent)
  XCTAssertEqual(
    applyEdits(sequential, concurrent: false, to: testString),
    applyEdits(concurrent.edits, concurrent: true, to: testString)
  )
}

final class TranslateSequentialToConcurrentEditsTests: XCTestCase {
  func testEmpty() {
    verifySequentialToConcurrentTranslation([], [])
  }

  func testCreatingConcurrentFailsIfEditsDoNotSatisfyConcurrentRequirements() {
    XCTAssertThrowsError(
      try {
        try ConcurrentEdits(concurrent: [
          SourceEdit(offset: 5, length: 1, replacementLength: 0),
          SourceEdit(offset: 5, length: 1, replacementLength: 0),
        ])
      }()
    )
  }

  func testSingleEdit1() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 0)
      ],
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 0)
      ]
    )
  }

  func testSingleEdit2() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 1)
      ],
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 1)
      ]
    )
  }

  func testTwoNonOverlappingDeletesInFrontToBackOrder() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 0),
        SourceEdit(offset: 10, length: 2, replacementLength: 0),
      ],
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 0),
        SourceEdit(offset: 11, length: 2, replacementLength: 0),
      ]
    )
  }

  func testTwoNonOverlappingDeletesInBackToFrontOrder() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 10, length: 2, replacementLength: 0),
        SourceEdit(offset: 5, length: 1, replacementLength: 0),
      ],
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 0),
        SourceEdit(offset: 10, length: 2, replacementLength: 0),
      ]
    )
  }

  func testTwoNonOverlappingInsertionsInFrontToBackOrder() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 2),
        SourceEdit(offset: 10, length: 0, replacementLength: 3),
      ],
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 2),
        SourceEdit(offset: 8, length: 0, replacementLength: 3),
      ]
    )
  }

  func testTwoNonOverlappingInsertionsInBackToFrontOrder() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 10, length: 0, replacementLength: 3),
        SourceEdit(offset: 5, length: 0, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 2),
        SourceEdit(offset: 10, length: 0, replacementLength: 3),
      ]
    )
  }

  func testTwoNonOverlappingReplacementsInFrontToBackOrder() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 4, replacementLength: 2),
        SourceEdit(offset: 20, length: 5, replacementLength: 3),
      ],
      [
        SourceEdit(offset: 5, length: 4, replacementLength: 2),
        SourceEdit(offset: 22, length: 5, replacementLength: 3),
      ]
    )
  }

  func testTwoNonOverlappingReplacementsInBackToFrontOrder() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 20, length: 5, replacementLength: 3),
        SourceEdit(offset: 5, length: 4, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 5, length: 4, replacementLength: 2),
        SourceEdit(offset: 20, length: 5, replacementLength: 3),
      ]
    )
  }

  func testMultipleNonOverlappingEdits() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 0, length: 6, replacementLength: 0),
        SourceEdit(offset: 15, length: 7, replacementLength: 9),
        SourceEdit(offset: 10, length: 0, replacementLength: 3),
        SourceEdit(offset: 30, length: 2, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 0, length: 6, replacementLength: 0),
        SourceEdit(offset: 16, length: 0, replacementLength: 3),
        SourceEdit(offset: 21, length: 7, replacementLength: 9),
        SourceEdit(offset: 31, length: 2, replacementLength: 2),
      ]
    )
  }

  func testTwoAdjacentEditsInBackToFrontOrder() {
    //                 [--- edit1 ----]
    // [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 10, length: 1, replacementLength: 3),
        SourceEdit(offset: 5, length: 5, replacementLength: 1),
      ],
      [
        SourceEdit(offset: 5, length: 6, replacementLength: 4)
      ]
    )
  }

  func testAdjacentReplaceAndDeleteInBackToFrontOrder() {
    //                 [--- edit1 ----]
    // [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 10, length: 1, replacementLength: 3),
        SourceEdit(offset: 5, length: 5, replacementLength: 0),
      ],
      [
        SourceEdit(offset: 5, length: 6, replacementLength: 3)
      ]
    )
  }

  func testOverlappingBefore() {
    //            [--- edit1 ----]
    // [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 3, replacementLength: 1),
        SourceEdit(offset: 4, length: 2, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 4, length: 4, replacementLength: 2)
      ]
    )
  }

  func testEnclosing() {
    //      [--- edit1 ----]
    // [------- edit2 --------]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 3, replacementLength: 1),
        SourceEdit(offset: 4, length: 4, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 4, length: 6, replacementLength: 2)
      ]
    )
  }

  func testTwoInsertionsAtSameLocation() {
    // [--- edit1 (length 0) ----]
    // [--- edit2 (length 0) ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 1),
        SourceEdit(offset: 5, length: 0, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 3)
      ]
    )
  }

  func testTwoReplacementsAtSameLocation() {
    // [--- edit1 ----]
    // [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 2),
        SourceEdit(offset: 5, length: 1, replacementLength: 3),
      ],
      [
        SourceEdit(offset: 5, length: 1, replacementLength: 4)
      ]
    )
  }

  func testTwoInsertionsAtSameLocationDifferentLength() {
    // [----- edit1 ------]
    // [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 2, replacementLength: 2),
        SourceEdit(offset: 5, length: 1, replacementLength: 3),
      ],
      [
        SourceEdit(offset: 5, length: 2, replacementLength: 4)
      ]
    )
  }

  func testEnclosed() {
    // [-------- edit1 --------]
    //        [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 5, replacementLength: 2),
        SourceEdit(offset: 6, length: 1, replacementLength: 0),
      ],
      [
        SourceEdit(offset: 5, length: 5, replacementLength: 1)
      ]
    )
  }

  func testOverlappingAfter() {
    // [---- edit1 ----]
    //        [--- edit2 ----]
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 3, length: 3, replacementLength: 2),
        SourceEdit(offset: 4, length: 3, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 3, length: 5, replacementLength: 3)
      ]
    )
  }

  func testTwoOverlappingInsertions() {
    verifySequentialToConcurrentTranslation(
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 3),
        SourceEdit(offset: 6, length: 0, replacementLength: 2),
      ],
      [
        SourceEdit(offset: 5, length: 0, replacementLength: 5)
      ]
    )
  }

  /// Enable and run this test to randomly generate edit arrays and verify that
  /// translating them to sequential edits results in the same post-edit string.
  func disabledTestFuzz() {
    var i = 0
    while true {
      i += 1
      var edits: [SourceEdit] = []
      let numEdits = Int.random(in: 1..<10)
      for _ in 0..<numEdits {
        edits.append(
          SourceEdit(
            offset: Int.random(in: 0..<32),
            length: Int.random(in: 0..<32),
            replacementLength: Int.random(in: 0..<32)
          )
        )
      }
      print(edits)
      let normalizedEdits = ConcurrentEdits(fromSequential: edits)
      if applyEdits(edits, concurrent: false, to: longString) != applyEdits(normalizedEdits.edits, concurrent: true, to: longString) {
        print("failed \(i)")
        fatalError()
      } else {
        print("passed \(i)")
      }
    }
  }
}
