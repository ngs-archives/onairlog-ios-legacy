//
//  InterfaceController.swift
//  OnAirLog813 WatchKit Extension
//
//  Created by Atsushi Nagase on 3/12/15.
//  Copyright (c) 2015 LittleApps Inc. All rights reserved.
//

import WatchKit
import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class InterfaceController: WKInterfaceController {
  var song: Song? = nil
  var apiClient: SongAPIClient? = nil
  var refreshIntervalTimer: Timer? = nil

  @IBOutlet weak var artworkImage: WKInterfaceImage!
  @IBOutlet weak var timestampLabel: WKInterfaceLabel?
  @IBOutlet weak var titleLabel: WKInterfaceLabel!
  @IBOutlet weak var artistLabel: WKInterfaceLabel!
  override func awake(withContext context: Any?) {
    super.awake(withContext: context)
    let dbURL = FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: kOnAirLogDocumentContainerDomain)?
      .appendingPathComponent("OnAirLog.sqlite")
    MagicalRecord.enableShorthandMethods()
    MagicalRecord.setupCoreDataStackWithStore(at: dbURL)
    self.apiClient = SongAPIClient()
    // Google Analytics
    let gai = GAI.sharedInstance()
    gai?.trackUncaughtExceptions = true
    gai?.dispatchInterval = 20
    gai?.tracker(withTrackingId: kOnAirLogGATrackingId)
    self.updateSong()
  }

  override func willActivate() {
    super.willActivate()
    let tracker = GAI.sharedInstance().defaultTracker
    tracker?.set(kGAIScreenName, value: "Watch App")
    tracker?.send(GAIDictionaryBuilder.createScreenView().build() as [AnyHashable: Any])
    self.refresh()
  }

  @IBAction func viewMenuAction() {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "watch", action: "view-song", label: self.song?.songID., value: 1).build() as [AnyHashable: Any])
    let opened = WKInterfaceController.openParentApplication(["songID": NSString(format: "%@", self.song!.songID)],
      reply: { (reply, error) in
    })
  }

  func startRefreshInterval() {
    if(refreshIntervalTimer == nil) {
      refreshIntervalTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(InterfaceController.refresh), userInfo: nil, repeats: false)
    }
  }

  func stopRefreshInterval() {
    refreshIntervalTimer?.invalidate()
    refreshIntervalTimer = nil
  }

  @IBAction func favoriteMenuAction() {
    if self.song != nil && self.song?.isFavorited != true {
      self.song?.isFavorited = true
      var error: NSError? = nil
      self.song?.managedObjectContext?.save(&error)
    }
  }

  override func didDeactivate() {
    self.stopRefreshInterval()
    super.didDeactivate()
  }

  func refresh() {
    refreshIntervalTimer = nil
    let tracker = GAI.sharedInstance().defaultTracker
    self.apiClient?.load(0,
      success: { (task: URLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.updateSong() {
          tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "watch", action: "new-data", label: self.song?.songID.stringValue, value: 1).build() as [AnyHashable: Any])
        } else {
          tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "watch", action: "no-data", label: self.song?.songID.stringValue, value: 1).build() as [AnyHashable: Any])
        }
        self.startRefreshInterval()
      },
      failure: { (task: URLSessionDataTask!,  error: NSError!) -> Void in
        tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "watch", action: "failed", label: self.song?.songID.stringValue, value: 1).build() as [AnyHashable: Any])
        self.startRefreshInterval()
      }

    )
  }

  func updateSong() -> Bool {
    let newSong = Song.mr_findFirstOrdered(byAttribute: "songID", ascending: false)
    if newSong != nil {
      if (newSong?.isEqual(song))! {
        return false
      }
      song = newSong
      self.titleLabel.setText(song!.title)
      self.artistLabel.setText(song!.artist)
      if self.timestampLabel != nil {
        self.timestampLabel!.setText(song!.timeFormatted())
      }
      self.artworkImage.setImageNamed("Artwork")
      self.updateImage()
      return true
    }
    self.titleLabel.setText("")
    self.artistLabel.setText("")
    if self.timestampLabel != nil {
      self.timestampLabel!.setText("")
    }
    return false
  }

  func updateImage() {
    let tracker = GAI.sharedInstance().defaultTracker
    let manager = AFHTTPSessionManager()
    manager.responseSerializer = AFJSONResponseSerializer(readingOptions: JSONSerialization.ReadingOptions.allowFragments)
    manager.requestSerializer = AFHTTPRequestSerializer()
    let url = NSString(format: "http://%@/song/%@.json", kOnAirLogAPIHost, song!.songID)
    manager.get(url as String, parameters: nil,
      success: { (task: URLSessionDataTask!, response: AnyObject!) -> Void in
        var json = response as? NSDictionary
        json = json == nil ? nil : json!["results"] as? NSDictionary
        json = json == nil ? nil : json!["song"] as? NSDictionary
        let itunes = json == nil ? nil : json!["itunes"] as? Array<AnyObject>
        if itunes?.count > 0 {
          let item = itunes?.first as! NSDictionary!
          let artwork = item["artworkUrl100"] as? NSString
          if artwork != nil {
            self.cacheImage(artwork!)
          } else {
            WKInterfaceDevice.current().removeCachedImage(withName: "Artwork")
            self.artworkImage.setImageNamed("Artwork")
          }
        }
      }) { (task: URLSessionDataTask!, error: NSError!) -> Void in
        tracker.send(GAIDictionaryBuilder.createException(
          withDescription: NSString(format: "%@: %@", url.description, error.description) as String, withFatal: false).build() as [AnyHashable: Any])
        return
    }
  }

  func cacheImage(_ url: NSString) {
    let tracker = GAI.sharedInstance().defaultTracker
    let manager = AFHTTPSessionManager()
    manager.responseSerializer = AFImageResponseSerializer() as AFImageResponseSerializer
    manager.requestSerializer = AFHTTPRequestSerializer()
    manager.get(url as String, parameters: nil,
      success: { (task: URLSessionDataTask!, response: AnyObject!) -> Void in
        let image = response as? UIImage
        if image != nil {
          WKInterfaceDevice.current().addCachedImage(image!, name: "Artwork")
          self.artworkImage.setImageNamed("Artwork")
        } else {
          WKInterfaceDevice.current().removeCachedImage(withName: "Artwork")
          self.artworkImage.setImageNamed("Artwork")
        }
      },
      failure: { (task: URLSessionDataTask!, error: NSError!) -> Void in
        tracker.send(GAIDictionaryBuilder.createException(
          withDescription: NSString(format: "%@: %@", url.description, error.description) as String, withFatal: false).build() as [AnyHashable: Any])
        return
      }
    )
  }
}
