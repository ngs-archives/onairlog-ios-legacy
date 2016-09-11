//
//  SongAPISessionManager.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/5/14.
//
//

import Foundation

class SongAPISessionManager: AFHTTPSessionManager {
  init(baseURL url: URL!) {
    super.init(baseURL: url, sessionConfiguration: nil)
    setup()
  }

  override init(baseURL url: URL!, sessionConfiguration configuration: URLSessionConfiguration!) {
    super.init(baseURL: url, sessionConfiguration: configuration)
    setup()
  }

  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  func setup() {
    requestSerializer = AFHTTPRequestSerializer()
    responseSerializer = SongAPIResponseSerializer(readingOptions: JSONSerialization.ReadingOptions.allowFragments)
  }
}
