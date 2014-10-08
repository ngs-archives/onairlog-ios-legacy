//
//  DetailViewController.swift
//  OnAirLog813
//
//  Created by Atsushi Nagase on 10/2/14.
//
//

import UIKit

class DetailViewController: UIViewController {

  var favoriteButtonItem: UIBarButtonItem?
  var shareButtonItem: UIBarButtonItem?
  var progressButtonItem: UIBarButtonItem?
  var shorteningInProgress = false
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var artistLabel: UILabel!
  @IBOutlet weak var timeStampLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.shareButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "share:")
    self.favoriteButtonItem = UIBarButtonItem(image: nil, style: UIBarButtonItemStyle.Plain, target: self, action: "toggleFavorite:")
    let av = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    av.startAnimating()
    self.progressButtonItem = UIBarButtonItem(customView: av)
    self.updateBarButtonItems()
  }

  var song: Song? {
    didSet {
      self.title = song?.title
      self.navigationItem.titleView = nil
      self.configureView()
    }
  }

  func configureView() {
    self.hidesBottomBarWhenPushed = false
    self.loadView()
    if let detail = self.song {
      self.timeStampLabel.text = detail.dateTimeFormatted()
      self.artistLabel.text = detail.artist
      self.titleLabel.text = detail.title
      self.titleLabel.sizeToFit()
    }
    self.updateFavoriteButton()
  }

  func updateBarButtonItems() {
    let item = self.shorteningInProgress ? self.progressButtonItem : self.shareButtonItem
    self.navigationItem.rightBarButtonItems = [
      item!,
      self.favoriteButtonItem!
    ]
  }

  func updateFavoriteButton() {
    let imgName = self.song?.isFavorited == true ? "726-star-toolbar-selected" : "726-star-toolbar"
    self.favoriteButtonItem?.image = UIImage(named: imgName)
  }

  func toggleFavorite(sender: AnyObject?) {
    if self.song == nil { return }
    let song = self.song!
    song.isFavorited = !song.isFavorited
    if song.managedObjectContext.save(nil) {
      self.updateFavoriteButton()
    }
  }

  func share(sender: AnyObject?) {
    if self.song == nil { return }
    let song = self.song!
    let url = song.iTunesSearchURL()
    let cacheHit = ShortenURL.findOrCreateByOriginalURL(song.iTunesSearchURL(),
      withAccessToken: BITLY_ACCESS_TOKEN) { (shortenURL: NSURL!) -> Void in
        let shareURL = shortenURL == nil ? song.iTunesSearchURL() : shortenURL
        let items = [shareURL, NSString(format: "%@ %@ %@", song.title, song.artist, song.dateTimeFormatted())]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.presentViewController(av, animated: true) {}
        self.shorteningInProgress = false
        self.updateBarButtonItems()
    }
    if !cacheHit {
      self.shorteningInProgress = true
      self.updateBarButtonItems()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.configureView()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  
}

