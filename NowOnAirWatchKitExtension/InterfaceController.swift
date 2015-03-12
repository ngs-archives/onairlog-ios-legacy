//
//  InterfaceController.swift
//  OnAirLog813 WatchKit Extension
//
//  Created by Atsushi Nagase on 3/12/15.
//  Copyright (c) 2015 LittleApps Inc. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
  var song: Song? = nil
  var apiClient: SongAPIClient? = nil
  
  @IBOutlet weak var timestampLabel: WKInterfaceLabel!
  @IBOutlet weak var titleLabel: WKInterfaceLabel!
  @IBOutlet weak var artistLabel: WKInterfaceLabel!
  override func awakeWithContext(context: AnyObject?) {
    super.awakeWithContext(context)
    let dbURL = NSFileManager.defaultManager()
      .containerURLForSecurityApplicationGroupIdentifier(kOnAirLogDocumentContainerDomain)?
      .URLByAppendingPathComponent("OnAirLog.sqlite")
    MagicalRecord.setupCoreDataStackWithStoreAtURL(dbURL)
    self.apiClient = SongAPIClient()
    // Google Analytics
    let gai = GAI.sharedInstance()
    gai.trackUncaughtExceptions = true
    gai.dispatchInterval = 20
    gai.trackerWithTrackingId(kOnAirLogGATrackingId)
    self.updateSong()
  }
  
  override func willActivate() {
    super.willActivate()
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "Watch App")
    tracker.send(GAIDictionaryBuilder.createAppView().build())
    self.refresh()
  }
  
  @IBAction func refreshAction(sender: WKInterfaceButton) {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.send(GAIDictionaryBuilder.createEventWithCategory("watch", action: "refresh", label: self.song?.songID.stringValue, value: 1).build())
    self.refresh()
  }
  
  override func didDeactivate() {
    // This method is called when watch view controller is no longer visible
    super.didDeactivate()
  }
  
  func refresh() {
    let tracker = GAI.sharedInstance().defaultTracker
    self.apiClient?.load(0,
      success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.updateSong() {
          tracker.send(GAIDictionaryBuilder.createEventWithCategory("watch", action: "new-data", label: self.song?.songID.stringValue, value: 1).build())
        } else {
          tracker.send(GAIDictionaryBuilder.createEventWithCategory("watch", action: "no-data", label: self.song?.songID.stringValue, value: 1).build())
        }
      },
      failure: { (task: NSURLSessionDataTask!,  error: NSError!) -> Void in
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("watch", action: "failed", label: self.song?.songID.stringValue, value: 1).build())
      }
    )
  }
  
  func updateSong() -> Bool {
    let newSong = Song.MR_findFirstOrderedByAttribute("songID", ascending: false)
    if newSong != nil {
      if newSong.isEqual(song) {
        return false
      }
      song = newSong
      self.titleLabel.setText(song!.title)
      self.artistLabel.setText(song!.artist)
      self.timestampLabel.setText(song!.timeFormatted())
      return true
    }
    self.titleLabel.setText("")
    self.artistLabel.setText("")
    self.timestampLabel.setText("")
    return false
  }
  
}
