//
//  MasterViewController.swift
//  OnAirLog813
//
//  Created by Atsushi Nagase on 10/2/14.
//
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class MasterViewController: BaseTableViewController, UISearchControllerDelegate, UISearchBarDelegate {

  @IBOutlet weak var filterTypeSegmentControl: UISegmentedControl!
  fileprivate var scrollCache = [-CGFloat.greatestFiniteMagnitude, -CGFloat.greatestFiniteMagnitude]
  var searchController: UISearchController!
  var resultsTableController: SearchResultsController!

  override func awakeFromNib() {
    super.awakeFromNib()
    self.refreshControl = UIRefreshControl()
    self.refreshControl!.addTarget(self, action: #selector(MasterViewController.refresh(_:)), for: UIControlEvents.valueChanged)
    self.tableView.addSubview(self.refreshControl!)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.definesPresentationContext = true
    resultsTableController = self.storyboard?.instantiateViewController(withIdentifier: "searchResultsController") as! SearchResultsController
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

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.load()
    var error: NSError?
    self.fetchedResultsController.performFetch(&error)
    self.tableView.reloadData()
  }

  // MARK: - Segues

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "showDetail" {
      var song: Song? = nil
      if (sender as AnyObject).isKind(of: Song) == true {
        song = sender as? Song
      } else if let indexPath = self.tableView.indexPathForSelectedRow {
        song = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Song
      }
      if song != nil {
        let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
        controller.song = song
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    } else if segue.identifier == "showDatePicker" {
      let controller = (segue.destination as! UINavigationController).topViewController as! DatePickerViewController
      controller.masterViewController = self
    }
  }

  // MARK: - Scroll

  fileprivate var isScrolling = false

  override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.isScrolling = true
  }

  override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    self.isScrolling = false
  }

  override func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

  @IBAction func filterTypeSegmentChange(_ sender: AnyObject) {
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEvent(withCategory: "timeline",
        action: "segment-change", label: isTimeline() ? "timeline" : "favorites" ,
        value: 1).build() as [AnyHashable: Any])
    if isTimeline() {
      self.tableView.addSubview(self.refreshControl!)
    } else {
      self.refreshControl?.removeFromSuperview()
    }
    updatePredicate()
    let top = self.scrollCache[self.filterTypeSegmentControl.selectedSegmentIndex]
    if top > 0 {
      self.tableView.contentOffset = CGPoint(x: 0, y: top)
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
    return !self.apiClient.isLoading && isTimeline() && !self.isScrolling && self.isViewLoaded && self.view.window != nil
  }

  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if !shouldAutoLoad() { return }
    var row = (indexPath as NSIndexPath).row
    var section = (indexPath as NSIndexPath).section
    var sectionCount = self.numberOfSections(in: tableView)
    var rowCount = self.tableView(tableView, numberOfRowsInSection: section)
    if rowCount >= row + 1 {
      row = 0
      section += 1
    }
    let song1 = self.fetchedResultsController .object(at: indexPath) as! Song
    let songID1 = song1.songID.intValue
    var sinceID = 0
    if section >= sectionCount {
      sinceID = songID1 - 1
    } else {
      let indexPath2 = IndexPath(row: row, section: section)
      let song2 = self.fetchedResultsController .object(at: indexPath2)as! Song
      let songID2 = song2.songID.intValue
      if songID1 - songID2  > 10 {
        sinceID = songID1 - 1
      }
    }
    if sinceID > 0  {
      GAI.sharedInstance().defaultTracker.send(
        GAIDictionaryBuilder.createEvent(withCategory: "timeline",
          action: "load-more", label: NSString(format: "since = %@", sinceID.description) as String,
          value: 1).build() as [AnyHashable: Any])
      self.load(sinceID)
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

  func load(_ sinceID: Int = 0) {
    apiClient.load(sinceID,
      success: { (task: URLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if self.refreshControl != nil {
          self.refreshControl?.endRefreshing()
        }
      }) { (task: URLSessionDataTask!, error: NSError!) -> Void in
        if self.refreshControl != nil {
          self.refreshControl?.endRefreshing()
        }
    }
  }

  func scrollToSong(_ song :Song?) {
    let indexPath = song == nil ? nil : self.fetchedResultsController.indexPath(forObject: song!)
    if indexPath != nil {
      self.isScrolling = true
      // lock loading more for 3.sec
      let time = DispatchTime.now() + Double(Int64(NSEC_PER_SEC * 3)) / Double(NSEC_PER_SEC)
      DispatchQueue.main.asyncAfter(deadline: time, execute: {
        self.isScrolling = false
      })
      self.tableView.scrollToRow(at: indexPath!,
        at: UITableViewScrollPosition.top, animated: true)
    }
  }

  func refresh(_ sender :AnyObject?) {
    GAI.sharedInstance().defaultTracker.send(
      GAIDictionaryBuilder.createEvent(withCategory: "timeline",
        action: "refresh", label: nil, value: 1).build() as [AnyHashable: Any])
    refreshControl?.beginRefreshing()
    self.load()
  }

  // MARK: - UISearchBarDelegate

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  // MARK: - UISearchControllerDelegate

  func presentSearchController(_ searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func willPresentSearchController(_ searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func didPresentSearchController(_ searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func willDismissSearchController(_ searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

  func didDismissSearchController(_ searchController: UISearchController) {
    //NSLog(__FUNCTION__)
  }

}

