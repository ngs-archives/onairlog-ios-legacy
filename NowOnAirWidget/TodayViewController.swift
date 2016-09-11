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
    //
    self.preferredContentSize = CGSize(width: 0, height: 130)
    self.updateSong()
  }

  func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)!) {
    let tracker = GAI.sharedInstance().defaultTracker
    tracker?.set(kGAIScreenName, value: "Today Widget")
    tracker?.send(GAIDictionaryBuilder.createScreenView().build() as [AnyHashable: Any])
    self.apiClient?.load(0,
      success: { (task: URLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.updateSong() {
          completionHandler(.newData)
          tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "widget", action: "new-data", label: self.song?.songID.stringValue, value: 1).build() as [AnyHashable: Any])
        } else {
          tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "widget", action: "no-data", label: self.song?.songID.stringValue, value: 1).build() as [AnyHashable: Any])
          completionHandler(.noData)
        }
      },
      failure: { (task: URLSessionDataTask!,  error: NSError!) -> Void in
        tracker.send(GAIDictionaryBuilder.createEvent(withCategory: "widget", action: "failed", label: self.song?.songID.stringValue, value: 1).build() as [AnyHashable: Any])
        completionHandler(.failed)
      }
    )
  }

  func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 30)
  }

  func updateSong() -> Bool {
    let newSong = Song.mr_findFirstOrdered(byAttribute: "songID", ascending: false)
    if newSong != nil {
      if (newSong?.isEqual(song))! {
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

  @IBAction func didViewTapped(_ sender: AnyObject) {
    if song?.songID != nil {
      let tracker = GAI.sharedInstance().defaultTracker
      tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "widget", action: "tapped", label: self.song?.songID., value: 1).build() as [AnyHashable: Any])
      let url = NSURL(scheme: kOnAirLogAppScheme, host: kOnAirLogAppHost, path: NSString(format: "/song/%@", song!.songID!) as String) as? URL
      self.extensionContext?.open(url!, completionHandler: { (success: Bool) -> Void in })
    }
  }
  
}
