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
  var currentTrackID: AnyObject? = nil
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var artistLabel: UILabel!
  @IBOutlet weak var timeStampLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  var searchResults: Array<NSDictionary>? = nil

  override func awakeFromNib() {
    super.awakeFromNib()
    self.shareButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(DetailViewController.share(_:)))
    self.favoriteButtonItem = UIBarButtonItem(image: nil, style: UIBarButtonItemStyle.plain, target: self, action: #selector(DetailViewController.toggleFavorite(_:)))
    let av = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    av.startAnimating()
    self.progressButtonItem = UIBarButtonItem(customView: av)
    self.updateBarButtonItems()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.configureView()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if searchResults == nil && song != nil {
      // Screen tracking
      let tracker = GAI.sharedInstance().defaultTracker
      let songField = GAIFields.customDimension(for: 1)
      tracker?.set(kGAIScreenName, value: "Detail Screen")
      tracker?.set(songField, value: self.song!.songID.stringValue)
      tracker?.send(GAIDictionaryBuilder.createScreenView().set( forKey: "song").build() as [AnyHashable: Any])
      tracker?.send(GAIDictionaryBuilder.createEvent(withCategory: "detail", action: "view", label: song?.songID., value: 1).build() as [AnyHashable: Any])
      //
      let manager = AFHTTPSessionManager()
      manager.responseSerializer = AFJSONResponseSerializer(readingOptions: JSONSerialization.ReadingOptions.allowFragments)
      manager.requestSerializer = AFHTTPRequestSerializer()
      let url = NSString(format: "http://%@/song/%@.json", kOnAirLogAPIHost, song!.songID)
      manager.get(url as String, parameters: nil,
        success: { (task: URLSessionDataTask!, response: AnyObject!) -> Void in
          var json = response as? NSDictionary
          json = json == nil ? nil : json!["results"] as? NSDictionary
          json = json == nil ? nil : json!["song"] as? NSDictionary
          self.searchResults = (json == nil) ? [] : json!["itunes"] as! Array<NSDictionary>
          self.tableView.reloadData()
        },
        failure: { (task: URLSessionDataTask!, error: NSError!) -> Void in
          self.searchResults = []
          self.tableView.reloadData()
          tracker.send(GAIDictionaryBuilder.createException(
            withDescription: NSString(format: "%@: %@", url.description, error.description) as String, withFatal: false).build() as [AnyHashable: Any])
          return
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
    self.timeStampLabel.isHidden = b
    self.artistLabel.isHidden = b
    self.titleLabel.isHidden = b
    self.tableView.isHidden = b
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

  func toggleFavorite(_ sender: AnyObject?) {
    if self.song == nil { return }
    let song = self.song!
    var error: NSError? = nil
    song.isFavorited = !song.isFavorited
    if song.managedObjectContext!.save(&error) {
      self.updateFavoriteButton()
    }
    if error != nil {
      GAI.sharedInstance().defaultTracker.send(
        GAIDictionaryBuilder.createException(withDescription: error?., withFatal: true).build() as [AnyHashable: Any])
    }
  }

  func share(_ sender: AnyObject?) {
    if self.song == nil { return }
    let song = self.song!
    let url = song.iTunesSearchURL()
    let cacheHit = ShortenURL.findOrCreateByOriginalURL(song.iTunesSearchURL(),
      withAccessToken: BITLY_ACCESS_TOKEN) { (shortenURL: URL!) -> Void in
        let shareURL = shortenURL == nil ? song.iTunesSearchURL() : shortenURL
        let items = [NSString(format: "%@ %@ %@", song.title, song.artist, song.dateTimeFormatted()), shareURL]
        let av = UIActivityViewController(activityItems: items, applicationActivities: nil)
        self.presentViewController(av, animated: true) {}
        GAI.sharedInstance().defaultTracker.send(
          GAIDictionaryBuilder.createEventWithCategory("share",
            action: "show", label: song.songID.stringValue, value: 1).build() as [AnyHashable: Any])
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

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults == nil ? 1 : searchResults!.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if searchResults == nil {
      return tableView.dequeueReusableCell(withIdentifier: "ActivityCell") as! UITableViewCell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") as! UITableViewCell
    let item = searchResults![(indexPath as NSIndexPath).row]
    let imageURL = URL(string: item["artworkUrl100"] as! String)
    cell.imageView!.setImageWithURLRequest(URLRequest(URL: imageURL!),
      placeholderImage: nil,
      success: { (req: URLRequest!, res: HTTPURLResponse!, img: UIImage!) -> Void in
        cell.imageView!.image = img
        cell.setNeedsLayout()
      },
      failure: { (req: URLRequest!, res: HTTPURLResponse!, error: NSError!) -> Void in })
    cell.textLabel!.text = item["trackName"] as? String
    cell.detailTextLabel?.text = item["artistName"] as? String
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = SKStoreProductViewController()
    vc.delegate = self
    let item = (self.searchResults != nil) ? self.searchResults![(indexPath as NSIndexPath).row] as NSDictionary? : nil
    if item == nil || item!["trackId"] == nil { return }
    let trackID: AnyObject = item!["trackId"]! as AnyObject
    let params = [
      SKStoreProductParameterITunesItemIdentifier:trackID,
      SKStoreProductParameterAffiliateToken:"10l87J",
      SKStoreProductParameterCampaignToken:kOnAirLogCampaignToken
    ] as [String : Any]
    self.currentTrackID = trackID
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEvent(withCategory: "store-view",
        action: "show", label: trackID.stringValue, value: 1).build() as [AnyHashable: Any])
    vc.loadProduct(withParameters: params, completionBlock: nil)
    self.present(vc, animated: true, completion: nil)
  }
  func productViewControllerDidFinish(_ viewController: SKStoreProductViewController!) {
    viewController.dismiss(animated: true, completion: nil)
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEvent(withCategory: "store-view",
        action: "dismiss", label: self.currentTrackID?.stringValue, value: 1).build() as [AnyHashable: Any])
  }
  
  @IBAction func dismissViewController(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: { () -> Void in })
  }
}

