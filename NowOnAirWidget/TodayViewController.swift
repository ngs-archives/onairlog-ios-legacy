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
    let dbURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(kOnAirLogDocumentContainerDomain)?.URLByAppendingPathComponent("OnAirLog.sqlite")
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
    self.apiClient?.load(0,
      success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.updateSong() {
          completionHandler(.NewData)
        } else {
          completionHandler(.NoData)
        }
      },
      failure: { (task: NSURLSessionDataTask!,  error: NSError!) -> Void in
        completionHandler(.Failed)
      }
    )
  }

  func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
    return UIEdgeInsets(top: 0, left: 45, bottom: 0, right: 20)
  }

  var titleAttributes: NSDictionary {
    if nil == _titleAttributes {
      let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as NSMutableParagraphStyle
      para.lineSpacing = 8
      _titleAttributes = [
        NSParagraphStyleAttributeName: para,
        NSFontAttributeName: UIFont(name: "HiraKakuProN-W3", size: 30.0),
        NSForegroundColorAttributeName: UIColor(white: 1.0, alpha: 1.0)
      ]
      }
      return _titleAttributes!
  }
  private var _titleAttributes: NSDictionary?

  var subtitleAttributes: NSDictionary {
    if nil == _subtitleAttributes {
      let para = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as NSMutableParagraphStyle
      para.lineSpacing = 5
      _subtitleAttributes = [
        NSParagraphStyleAttributeName: para,
        NSFontAttributeName: UIFont(name: "HiraKakuProN-W3", size: 18.0),
        NSForegroundColorAttributeName: UIColor(white: 1.0, alpha: 0.6)
      ]
      }
      return _subtitleAttributes!
  }
  private var _subtitleAttributes: NSDictionary?

  func updateSong() -> Bool {
    let newSong = Song.MR_findFirstOrderedByAttribute("songID", ascending: false)
    if newSong != nil {
      if newSong.isEqual(song) {
        return false
      }
      song = newSong
      let titleString = NSAttributedString(string: song!.title!, attributes: titleAttributes)
      self.titleLabel.attributedText = titleString
      let subtitle = NSString(format: "%@ %@", song!.artist!, song!.timeStampFormatted())
      let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
      self.subtitleLabel.attributedText = subtitleString
      return true
    }
    self.titleLabel.attributedText = nil
    self.subtitleLabel.attributedText = nil
    return false
  }

  @IBAction func didViewTapped(sender: AnyObject) {
    if song?.songID != nil {
      let url = NSURL(scheme: kOnAirLogAppScheme, host: kOnAirLogAppHost, path: NSString(format: "/song/%@", song!.songID!))
      self.extensionContext?.openURL(url, completionHandler: { (success: Bool) -> Void in

      })
    }
  }
  
}
