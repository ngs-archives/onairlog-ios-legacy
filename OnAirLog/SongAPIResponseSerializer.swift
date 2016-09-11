//
//  SongAPIResponseSerializer.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import Foundation

class SongAPIResponseSerializer: AFJSONResponseSerializer {
  var currentPage = 0
  var totalPages = 0
  var songs: NSArray?
  override func responseObjectForResponse(_ response: URLResponse!, data: Data!, error: NSErrorPointer) -> AnyObject! {
    var json = super.responseObjectForResponse(response, data: data, error: error) as? NSDictionary
    if json == nil { return nil }
    json = json!["results"] as? NSDictionary
    if json == nil { return nil }
    self.songs = json!["songs"] as? NSArray
    var page = json!["page"] as? NSDictionary
    if page != nil && page?["total_pages"] != nil {
      self.totalPages = page!["total_pages"]!.integerValue
    }
    return json
  }

}
