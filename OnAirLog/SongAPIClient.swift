//
//  SongAPIClient.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import Foundation

class SongAPIClient {
  var currentPage = 0
  var totalPages = 0
  var sinceDate: NSDate? = nil

  func hasMore() -> Bool {
    return false
  }

}