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
  var song: Song?

  @IBAction func toggleFavorite(sender: AnyObject) {
    if self.song != nil {
      self.song?.isFavorited = !self.song!.isFavorited
      self.song?.managedObjectContext?.saveToPersistentStoreAndWait()
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let imgName = self.song?.isFavorited == true ? "726-star-toolbar-selected" : "726-star-toolbar"
    let img = UIImage(named: imgName)?.imageWithRenderingMode(.AlwaysTemplate)
    self.favoriteButton.setImage(img, forState: .Normal)
  }

  func configureSong(song: Song) {
    self.song = song
    self.titleLabel.text = song.title
    self.subtitleLabel.text = song.artist
    self.timeStampLabel.text = song.timeFormatted()
    self.setNeedsUpdateConstraints()
    self.updateConstraints()
    self.setNeedsLayout()
    self.favoriteButton.selected = song.isFavorited
  }
  
}
