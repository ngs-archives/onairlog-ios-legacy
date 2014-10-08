//
//  DetailViewController.swift
//  OnAirLog813
//
//  Created by Atsushi Nagase on 10/2/14.
//
//

import UIKit

class DetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SKStoreProductViewControllerDelegate {

  var favoriteButtonItem: UIBarButtonItem?
  var shareButtonItem: UIBarButtonItem?
  var progressButtonItem: UIBarButtonItem?
  var shorteningInProgress = false
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var artistLabel: UILabel!
  @IBOutlet weak var timeStampLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  var searchResults: Array<NSDictionary>? = nil

  override func awakeFromNib() {
    super.awakeFromNib()
    self.shareButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "share:")
    self.favoriteButtonItem = UIBarButtonItem(image: nil, style: UIBarButtonItemStyle.Plain, target: self, action: "toggleFavorite:")
    let av = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    av.startAnimating()
    self.progressButtonItem = UIBarButtonItem(customView: av)
    self.updateBarButtonItems()
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    self.configureView()
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    if searchResults == nil && song != nil {
      let manager = AFHTTPSessionManager()
      manager.responseSerializer = AFJSONResponseSerializer()
      manager.requestSerializer = AFHTTPRequestSerializer()
      let url = NSString(format: "http://%@/song/%@.json", kOnAirLogAPIHost, song!.songID)
      manager.GET(url, parameters: nil,
        success: { (task: NSURLSessionDataTask!, response: AnyObject!) -> Void in
          var json = response as? NSDictionary
          json = json == nil ? nil : json!["results"] as? NSDictionary
          json = json == nil ? nil : json!["song"] as? NSDictionary
          self.searchResults = (json == nil) ? [] : json!["itunes"] as Array<NSDictionary>
          self.tableView.reloadData()
        },
        failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
          self.searchResults = []
          self.tableView.reloadData()
        }
      )
    }
  }

  var song: Song? {
    didSet {
      self.title = song?.title
      self.configureView()
      self.searchResults = nil
    }
  }

  func configureView() {
    if self.titleLabel == nil { return }
    let b = self.song == nil
    self.timeStampLabel.hidden = b
    self.artistLabel.hidden = b
    self.titleLabel.hidden = b
    self.tableView.hidden = b
    if !b {
      self.timeStampLabel.text = self.song!.dateTimeFormatted()
      self.artistLabel.text = self.song!.artist
      self.titleLabel.text = self.song!.title
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
        let items = [NSString(format: "%@ %@ %@", song.title, song.artist, song.dateTimeFormatted()), shareURL]
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

  // MARK: - TableView

  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults == nil ? 1 : searchResults!.count
  }

  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if searchResults == nil {
      return tableView.dequeueReusableCellWithIdentifier("ActivityCell") as UITableViewCell
    }
    let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell") as UITableViewCell
    let item = searchResults![indexPath.row]
    let imageURL = NSURL(string: item["artworkUrl100"] as String)
    cell.imageView?.setImageWithURLRequest(NSURLRequest(URL: imageURL),
      placeholderImage: nil,
      success: { (req: NSURLRequest!, res: NSHTTPURLResponse!, img: UIImage!) -> Void in
        cell.imageView?.image = img
        cell.setNeedsLayout()
      },
      failure: { (req: NSURLRequest!, res: NSHTTPURLResponse!, error: NSError!) -> Void in })
    cell.textLabel?.text = item["trackName"] as? String
    cell.detailTextLabel?.text = item["artistName"] as? String
    return cell
  }

  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
    let vc = SKStoreProductViewController()
    vc.delegate = self
    let item = (self.searchResults != nil) ? self.searchResults![indexPath.row] as NSDictionary? : nil
    if item == nil || item!["trackId"] == nil { return }
    let trackID: AnyObject = item!["trackId"]!
    let params = [
      SKStoreProductParameterITunesItemIdentifier:trackID,
      SKStoreProductParameterAffiliateToken:"10l87J",
      SKStoreProductParameterCampaignToken:kOnAirLogCampaignToken
    ]
    vc.loadProductWithParameters(params, completionBlock: nil)
    self.presentViewController(vc, animated: true, completion: nil)
  }
  func productViewControllerDidFinish(viewController: SKStoreProductViewController!) {
    viewController.dismissViewControllerAnimated(true, completion: nil)
  }
  
}

