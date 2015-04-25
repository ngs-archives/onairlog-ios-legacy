//
//  TodayViewController.swift
//  NowOnAirWidget813
//
//  Created by Atsushi Nagase on 10/3/14.
//
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
  var song: Song? = nil
  var apiClient: SongAPIClient? = nil

  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  override func viewDidLoad() {
    super.viewDidLoad()
    // Magical Record
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
    //
    self.preferredContentSize = CGSizeMake(0, 130)
    self.updateSong()
  }

  func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "Today Widget")
    tracker.send(GAIDictionaryBuilder.createAppView().build() as [NSObject : AnyObject])
    self.apiClient?.load(0,
      success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.updateSong() {
          completionHandler(.NewData)
          tracker.send(GAIDictionaryBuilder.createEventWithCategory("widget", action: "new-data", label: self.song?.songID.stringValue, value: 1).build() as [NSObject : AnyObject])
        } else {
          tracker.send(GAIDictionaryBuilder.createEventWithCategory("widget", action: "no-data", label: self.song?.songID.stringValue, value: 1).build() as [NSObject : AnyObject])
          completionHandler(.NoData)
        }
      },
      failure: { (task: NSURLSessionDataTask!,  error: NSError!) -> Void in
        tracker.send(GAIDictionaryBuilder.createEventWithCategory("widget", action: "failed", label: self.song?.songID.stringValue, value: 1).build() as [NSObject : AnyObject])
        completionHandler(.Failed)
      }
    )
  }

  func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 30)
  }

  func updateSong() -> Bool {
    let newSong = Song.MR_findFirstOrderedByAttribute("songID", ascending: false)
    if newSong != nil {
      if newSong.isEqual(song) {
        return false
      }
      song = newSong
      self.titleLabel.text = song?.title
      self.titleLabel.sizeToFit()
      let subtitle = NSString(format: "%@ %@", song!.artist!, song!.timeFormatted())
      self.subtitleLabel.text = subtitle as String
      self.subtitleLabel.sizeToFit()
      return true
    }
    self.titleLabel.text = nil
    self.subtitleLabel.text = nil
    return false
  }

  @IBAction func didViewTapped(sender: AnyObject) {
    if song?.songID != nil {
      let tracker = GAI.sharedInstance().defaultTracker
      tracker.send(GAIDictionaryBuilder.createEventWithCategory("widget", action: "tapped", label: self.song?.songID.stringValue, value: 1).build() as [NSObject : AnyObject])
      let url = NSURL(scheme: kOnAirLogAppScheme, host: kOnAirLogAppHost, path: NSString(format: "/song/%@", song!.songID!) as String)
      self.extensionContext?.openURL(url!, completionHandler: { (success: Bool) -> Void in })
    }
  }
  
}
