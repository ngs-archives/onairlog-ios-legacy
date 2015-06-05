//
//  MasterViewController.swift
//  OnAirLog813
//
//  Created by Atsushi Nagase on 10/2/14.
//
//

import UIKit

class MasterViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate {

  @IBOutlet weak var filterTypeSegmentControl: UISegmentedControl!
  private var scrollCache = [-CGFloat.max, -CGFloat.max]
  var searchController: UISearchController!
  var resultsTableController: SearchResultsController!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.refreshControl = UIRefreshControl()
    self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.addSubview(self.refreshControl!)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.definesPresentationContext = true
    resultsTableController = self.storyboard?.instantiateViewControllerWithIdentifier("searchResultsController") as! SearchResultsController
    resultsTableController.masterViewController = self
    searchController = UISearchController(searchResultsController: resultsTableController)
    searchController.searchResultsUpdater = resultsTableController
    searchController.searchBar.sizeToFit()
    tableView.tableHeaderView = searchController.searchBar
    searchController.delegate = self
    searchController.dimsBackgroundDuringPresentation = false
    searchController.searchBar.delegate = self
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
    }
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    self.load()
    var error: NSError?
    self.fetchedResultsController.performFetch(&error)
    self.tableView.reloadData()
  }

  // MARK: - Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      var song: Song? = nil
      if sender?.isKindOfClass(Song) == true {
        song = sender as? Song
      } else if let indexPath = self.tableView.indexPathForSelectedRow() {
        song = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Song
      }
      if song != nil {
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
        controller.song = song
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    } else if segue.identifier == "showDatePicker" {
      let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DatePickerViewController
      controller.masterViewController = self
    }
  }

  // MARK: - Scroll

  private var isScrolling = false

  override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
    self.isScrolling = true
  }

  override func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    self.isScrolling = false
  }

  override func scrollViewDidScroll(scrollView: UIScrollView) {
    let contentHeight = scrollView.contentSize.height
    let height = scrollView.frame.size.height
    let top = scrollView.frame.origin.y
    let scrollTop = scrollView.contentOffset.y
    let diff = contentHeight - scrollTop - top
    if self.shouldAutoLoad() && diff < height && self.fetchedResultsController.sections?.count > 0 {
      let section = self.fetchedResultsController.sections?.last as! NSFetchedResultsSectionInfo
      let song = section.objects.last as! Song
      self.load(sinceID: song.songID.integerValue - 1)
    }
    scrollCache[filterTypeSegmentControl.selectedSegmentIndex] = scrollView.contentOffset.y
  }

  @IBAction func filterTypeSegmentChange(sender: AnyObject) {
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEventWithCategory("timeline",
        action: "segment-change", label: isTimeline() ? "timeline" : "favorites" ,
        value: 1).build() as [NSObject : AnyObject])
    if isTimeline() {
      self.tableView.addSubview(self.refreshControl!)
    } else {
      self.refreshControl?.removeFromSuperview()
    }
    updatePredicate()
    let top = self.scrollCache[self.filterTypeSegmentControl.selectedSegmentIndex]
    if top > 0 {
      self.tableView.contentOffset = CGPointMake(0, top)
    }
  }

  func isTimeline() -> Bool {
    return filterTypeSegmentControl == nil || filterTypeSegmentControl.selectedSegmentIndex != 1
  }

  override func predicate() -> NSPredicate? {
    if !isTimeline() {
      return NSPredicate(format: "favoritedAt != nil")
    }
    return nil
  }

  func shouldAutoLoad() -> Bool {
    return !self.apiClient.isLoading && isTimeline() && !self.isScrolling && self.isViewLoaded() && self.view.window != nil
  }

  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if !shouldAutoLoad() { return }
    var row = indexPath.row
    var section = indexPath.section
    var sectionCount = self.numberOfSectionsInTableView(tableView)
    var rowCount = self.tableView(tableView, numberOfRowsInSection: section)
    if rowCount >= row + 1 {
      row = 0
      section++
    }
    let song1 = self.fetchedResultsController .objectAtIndexPath(indexPath) as! Song
    let songID1 = song1.songID.integerValue
    var sinceID = 0
    if section >= sectionCount {
      sinceID = songID1 - 1
    } else {
      let indexPath2 = NSIndexPath(forRow: row, inSection: section)
      let song2 = self.fetchedResultsController .objectAtIndexPath(indexPath2)as! Song
      let songID2 = song2.songID.integerValue
      if songID1 - songID2  > 10 {
        sinceID = songID1 - 1
      }
    }
    if sinceID > 0  {
      GAI.sharedInstance().defaultTracker.send(
        GAIDictionaryBuilder.createEventWithCategory("timeline",
          action: "load-more", label: NSString(format: "since = %@", sinceID.description) as String,
          value: 1).build() as [NSObject : AnyObject])
      self.load(sinceID: sinceID)
    }
  }

  // MARK: - API

  var apiClient: SongAPIClient {
    if _apiClient == nil {
      _apiClient = SongAPIClient()
      }
      return _apiClient!
  }

  var _apiClient: SongAPIClient? = nil

  func load(sinceID: Int = 0) {
    apiClient.load(sinceID,
      success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.refreshControl != nil {
          self.refreshControl?.endRefreshing()
        }
      }) { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
        if self.refreshControl != nil {
          self.refreshControl?.endRefreshing()
        }
    }
  }

  func scrollToSong(song :Song?) {
    let indexPath = song == nil ? nil : self.fetchedResultsController.indexPathForObject(song!)
    if indexPath != nil {
      self.isScrolling = true
      // lock loading more for 3.sec
      let time = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC * 3))
      dispatch_after(time, dispatch_get_main_queue(), {
        self.isScrolling = false
      })
      self.tableView.scrollToRowAtIndexPath(indexPath!,
        atScrollPosition: UITableViewScrollPosition.Top, animated: true)
    }
  }

  func refresh(sender :AnyObject?) {
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEventWithCategory("timeline",
        action: "refresh", label: nil, value: 1).build() as [NSObject : AnyObject])
    refreshControl?.beginRefreshing()
    self.load()
  }

  // MARK: - UISearchBarDelegate

  func searchBarSearchButtonClicked(searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  // MARK: - UISearchControllerDelegate

  func presentSearchController(searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func willPresentSearchController(searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func didPresentSearchController(searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func willDismissSearchController(searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func didDismissSearchController(searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

}

