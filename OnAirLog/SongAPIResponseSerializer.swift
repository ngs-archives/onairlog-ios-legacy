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
  override func responseObjectForResponse(response: NSURLResponse!, data: NSData!, error: NSErrorPointer) -> AnyObject! {
    var json = super.responseObjectForResponse(response, data: data, error: error) as? NSDictionary
    if json == nil { return nil }
    json = json!["results"] as? NSDictionary
    if json == nil { return nil }
    var songs = json!["songs"] as? NSArray
    if songs == nil { return nil }
    MagicalRecord.saveUsingCurrentThreadContextWithBlockAndWait { (context: NSManagedObjectContext!) -> Void in
      for var i = 0; i < songs?.count; i++ {
        let songDict = songs![i] as? NSDictionary
        Song.findOrCreateWithAttributes(songDict, inContext: context)
      }
    }
    var page = json!["page"] as? NSDictionary
    if page != nil && page?["total_pages"] != nil {
      self.totalPages = page!["total_pages"]!.integerValue
    }
    return json
  }

}