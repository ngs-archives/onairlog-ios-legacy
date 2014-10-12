//
//  SongAPISessionManager.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import Foundation

class SongAPISessionManager: AFHTTPSessionManager {
  override init(baseURL url: NSURL!) {
    super.init(baseURL: url)
    setup()
  }

  override init(baseURL url: NSURL!, sessionConfiguration configuration: NSURLSessionConfiguration!) {
    super.init(baseURL: url, sessionConfiguration: configuration)
    setup()
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  func setup() {
    requestSerializer = AFHTTPRequestSerializer()
    responseSerializer = SongAPIResponseSerializer()
  }
}