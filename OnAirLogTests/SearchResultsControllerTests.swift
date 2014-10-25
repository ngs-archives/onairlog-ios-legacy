//
//  SearchResultsControllerTests.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/19/14.
//
//

import UIKit
import XCTest
import OnAirLog813

class SearchResultsControllerTests: XCTestCase {
  var _resultsController: SearchResultsController? = nil
  var resultsController: SearchResultsController {
    if _resultsController == nil {
      _resultsController = SearchResultsController()
      }
      return _resultsController!
  }

  override func tearDown() {
    _resultsController = nil
  }

  func testPredicate() {
    resultsController.searchItems = ["", "iphone", "", "", "ipad", ""]
    XCTAssert(
      resultsController.predicate()?.description ==
      "(title CONTAINS[c] \"iphone\" OR artist CONTAINS[c] \"iphone\") AND (title CONTAINS[c] \"ipad\" OR artist CONTAINS[c] \"ipad\")")
  }

}