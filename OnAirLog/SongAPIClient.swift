//
//  SongAPIClient.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import Foundation

class SongAPIClient {
  var totalPages = -1
  var isLoading = false
  var sinceDate: Date? = nil

  func load(_ sinceID: Int, success: @escaping (URLSessionDataTask?, AnyObject?) -> Void, failure: @escaping (URLSessionDataTask?, NSError?) -> Void ) {
    if isLoading { return }
    let tracker = GAI.sharedInstance().defaultTracker
    let url = NSURL(scheme: "http", host: kOnAirLogAPIHost, path: "/") as? URL
    let manager = SongAPISessionManager(baseURL: url)
    isLoading = true
    let params = self.queryParams().mutableCopy() as! NSMutableDictionary
    if sinceID > 0 {
      params["s"] = sinceID
    }
    manager?.GET("/search.json", parameters: params,
      success: { (task: URLSessionDataTask!, responseObject: AnyObject!) -> Void in
        let serializer = manager.responseSerializer as! SongAPIResponseSerializer
        self.totalPages = serializer.totalPages
        let songs = serializer.songs
        MagicalRecord.saveWithBlock({ (context: NSManagedObjectContext!) -> Void in
          for var i = 0; i < songs?.count; i++ {
            let songDict = songs![i] as? NSDictionary
            Song.findOrCreateWithAttributes(songDict as! [AnyHashable: Any], inContext: context)
          }
          },
          completion: { (isSuccess: Bool, error: NSError?) -> Void in
            self.isLoading = false
            if error == nil {
              success(task, responseObject)
            } else {
              tracker.send(GAIDictionaryBuilder.createExceptionWithDescription(
                error!.localizedDescription, withFatal: false).build() as [AnyHashable: Any])
              failure(task, error)
            }
        })
      }) { (task: URLSessionDataTask!, error: NSError!) -> Void in
        self.isLoading = false
        tracker.send(GAIDictionaryBuilder.createExceptionWithDescription(
          error!.localizedDescription, withFatal: false).build() as [AnyHashable: Any])
        failure(task, error)
    }
  }

  func queryParams() -> NSDictionary {
    let params: NSMutableDictionary = NSMutableDictionary()
    if sinceDate != nil {
      let fmtd = DateFormatter()
      fmtd.dateFormat = "yyyyMMddHHmmss"
      params["d"] = fmtd.string(from: sinceDate!)
    }
    return params.copy() as! NSDictionary
  }

}
