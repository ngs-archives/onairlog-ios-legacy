//
//  DatePickerViewController.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/7/14.
//
//

import UIKit

class DatePickerViewController: UIViewController {
  override func viewDidLoad() {
    let h = self.datePicker.frame.origin.y + self.datePicker.frame.size.height
    self.preferredContentSize = CGSizeMake(320.0, h)
  }
  @IBOutlet weak var navigationBar: UINavigationBar!
  @IBOutlet weak var datePicker: UIDatePicker!
  @IBAction func cancelButtonTapped(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: {})
  }
}
