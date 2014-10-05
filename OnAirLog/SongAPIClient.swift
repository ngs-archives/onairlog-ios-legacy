//
//  SongAPIClient.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import Foundation

class SongAPIClient {
  var currentPage = 1
  var totalPages = 0
  var sinceDate: NSDate? = nil
  var songManager: SongManager? = nil

  func hasMore() -> Bool {
    return currentPage < totalPages
  }

  func load(more: Bool, success: (NSURLSessionDataTask!, AnyObject!) -> Void, failure: (NSURLSessionDataTask!, NSError!) -> Void ) {
    if more {
      if !hasMore() { return }
      currentPage++
    } else {
      currentPage = 1
      totalPages = -1
    }
    let url = NSURL(scheme: "http", host: "813.liap.us", path: "/")
    let manager = SongAPISessionManager(baseURL: url)
    manager.GET("/search.json", parameters: queryParams(),
      success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        let serializer = manager.responseSerializer as SongAPIResponseSerializer
        self.currentPage = serializer.currentPage
        self.totalPages = serializer.totalPages
        success(task, responseObject)
      }, failure: failure)
  }

  func queryParams() -> NSDictionary {
    var params: NSMutableDictionary = NSMutableDictionary()
    params["p"] = currentPage
    if sinceDate != nil {
      let fmtd = NSDateFormatter()
      fmtd.dateFormat = "yyyyMMddHHmmss"
      params["d"] = fmtd.stringFromDate(sinceDate!)
    }
    return params.copy() as NSDictionary
  }
  
}