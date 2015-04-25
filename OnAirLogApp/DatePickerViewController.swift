//
//  DatePickerViewController.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/7/14.
//
//

import UIKit

class DatePickerViewController: UIViewController {
  var masterViewController: MasterViewController? = nil

  @IBOutlet weak var progressOverlayView: UIView!
  @IBOutlet weak var cancelButtonItem: UIBarButtonItem!
  @IBOutlet weak var doneButtonItem: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.datePicker.maximumDate = NSDate()
    self.datePicker.date = NSDate(timeIntervalSinceNow: -3600)
    self.preferredContentSize = CGSizeMake(320.0, self.datePicker.frame.size.height)
    self.progressOverlayView.hidden = true
  }
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    let tracker = GAI.sharedInstance().defaultTracker
    tracker.set(kGAIScreenName, value: "Date Picker Screen")
    tracker.send(GAIDictionaryBuilder.createAppView().build() as [NSObject : AnyObject])
  }
  @IBOutlet weak var datePicker: UIDatePicker!
  @IBAction func cancelButtonTapped(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: {})
  }
  @IBAction func doneButtonTapped(sender: AnyObject) {
    let tracker = GAI.sharedInstance().defaultTracker
    let dateFrom = self.datePicker.date
    let dateTo = dateFrom.dateByAddingTimeInterval(3600)
    let pred = NSPredicate(format: "timeStamp <= %@ AND timeStamp >= %@", dateTo, dateFrom)
    tracker.send(GAIDictionaryBuilder.createEventWithCategory("filter", action: "date_picked", label: dateFrom.description, value: 1).build() as [NSObject : AnyObject])
    let song: Song? = Song.findFirstWithPredicate(pred, sortedBy: "songID", ascending: false)
    if song != nil {
      self.masterViewController?.scrollToSong(song)
      self.cancelButtonTapped(sender)
      return
    }
    let apiClient = SongAPIClient()
    self.doneButtonItem.enabled = false
    self.progressOverlayView.hidden = false
    self.progressOverlayView.alpha = 0.0
    UIView.animateWithDuration(0.3, animations: {
      self.progressOverlayView.alpha = 1.0
    })
    apiClient.sinceDate = dateTo
    apiClient.load(0,
      success: { (task: NSURLSessionDataTask!, res: AnyObject!) -> Void in
        let song: Song? = Song.findFirstWithPredicate(pred, sortedBy: "songID", ascending: false)
        self.masterViewController?.scrollToSong(song)
        self.cancelButtonTapped(sender)
      }) { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
        self.doneButtonItem.enabled = true
        UIView.animateWithDuration(0.3,
          animations: { () -> Void in
            self.progressOverlayView.alpha = 0.0
          },
          completion: { (finished: Bool) -> Void in
            if finished {
              self.progressOverlayView.hidden = true
            }
        })
    }
  }
}
