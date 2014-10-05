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
    var json: AnyObject = super.responseObjectForResponse(response, data: data, error: error)
    return json
  }

}