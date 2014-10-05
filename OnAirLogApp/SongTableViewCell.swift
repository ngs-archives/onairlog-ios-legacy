//
//  SongTableViewCell.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/3/14.
//
//

import UIKit
import CoreData

class SongTableViewCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var timeStampLabel: UILabel!
  @IBOutlet weak var favoriteButton: UIButton!
  @IBAction func toggleFavorite(sender: AnyObject) {
    NSLog("%@", self)
  }
  func configureSong(song: Song) {
    self.titleLabel.text = song.timeStamp.description
    self.titleLabel.sizeToFit()
    self.setNeedsUpdateConstraints()
    self.updateConstraints()
  }
}
