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
    self.datePicker.maximumDate = Date()
    self.datePicker.date = Date(timeIntervalSinceNow: -3600)
    self.preferredContentSize = CGSize(width: 320.0, height: self.datePicker.frame.size.height)
    self.progressOverlayView.isHidden = true
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    let tracker = GAI.sharedInstance().defaultTracker
    tracker?.set(kGAIScreenName, value: "Date Picker Screen")
    tracker?.send(GAIDictionaryBuilder.createScreenView().build() as [AnyHashable: Any])
  }
  @IBOutlet weak var datePicker: UIDatePicker!
  @IBAction func cancelButtonTapped(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: {})
  }
  @IBAction func doneButtonTapped(_ sender: AnyObject) {
    let tracker = GAI.sharedInstance().defaultTracker
    let dateFrom = self.datePicker.date
    let dateTo = dateFrom.addingTimeInterval(3600)
    let pred = NSPredicate(format: "timeStamp <= %@ AND timeStamp >= %@", dateTo as CVarArg, dateFrom as CVarArg)
    tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "filter", action: "date_picked", label: dateFrom.description, value: 1).build() as [AnyHashable: Any])
    let song: Song? = Song.findFirst(with: pred, sortedBy: "songID", ascending: false)
    if song != nil {
      self.masterViewController?.scrollToSong(song)
      self.cancelButtonTapped(sender)
      return
    }
    let apiClient = SongAPIClient()
    self.doneButtonItem.isEnabled = false
    self.progressOverlayView.isHidden = false
    self.progressOverlayView.alpha = 0.0
    UIView.animate(withDuration: 0.3, animations: {
      self.progressOverlayView.alpha = 1.0
    })
    apiClient.sinceDate = dateTo
    apiClient.load(0,
      success: { (task: URLSessionDataTask!, res: AnyObject!) -> Void in
        let song: Song? = Song.findFirst(with: pred, sortedBy: "songID", ascending: false)
        self.masterViewController?.scrollToSong(song)
        self.cancelButtonTapped(sender)
      }) { (task: URLSessionDataTask!, error: NSError!) -> Void in
        self.doneButtonItem.isEnabled = true
        UIView.animate(withDuration: 0.3,
          animations: { () -> Void in
            self.progressOverlayView.alpha = 0.0
          },
          completion: { (finished: Bool) -> Void in
            if finished {
              self.progressOverlayView.isHidden = true
            }
        })
    }
  }
}
