//
//  MasterViewController.swift
//  OnAirLog813
//
//  Created by Atsushi Nagase on 10/2/14.
//
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

  @IBOutlet weak var filterTypeSegmentControl: UISegmentedControl!
  var detailViewController: DetailViewController? = nil
  private var scrollCache = [-CGFloat.max, -CGFloat.max]

  override func awakeFromNib() {
    super.awakeFromNib()
    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      self.clearsSelectionOnViewWillAppear = false
      self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }
    self.refreshControl = UIRefreshControl()
    self.refreshControl!.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.addSubview(self.refreshControl!)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
    }
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    var error: NSError?
    self.fetchedResultsController.performFetch(&error)
    self.tableView.reloadData()
    self.load()
  }

  // MARK: - Segues

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow() {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
        let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
        controller.detailItem = object
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    } else if segue.identifier == "showDatePicker" {
      // TODO: show date picker in half screen
    }
  }

  // MARK: - Scroll

  override func scrollViewDidScroll(scrollView: UIScrollView) {
    let contentHeight = scrollView.contentSize.height
    let height = scrollView.frame.size.height
    let top = scrollView.frame.origin.y
    let scrollTop = scrollView.contentOffset.y
    let diff = contentHeight - scrollTop - top
    if diff < height && !apiClient.isLoading && self.fetchedResultsController.sections?.count > 0 {
      let section = self.fetchedResultsController.sections?.last? as NSFetchedResultsSectionInfo
      let song = section.objects.last as Song
      self.load(sinceID: song.songID.integerValue - 1)
    }
    scrollCache[filterTypeSegmentControl.selectedSegmentIndex] = scrollView.contentOffset.y
  }

  // MARK: - Table View

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sections = self.fetchedResultsController.sections
    if sections?.count < section + 1 {
      return nil
    }
    let s = sections![section] as NSFetchedResultsSectionInfo
    let song = s.objects.first as Song
    return song.sectionTitle()
  }

  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return self.fetchedResultsController.sections?.count ?? 0
  }

  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
    return sectionInfo.numberOfObjects
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as SongTableViewCell
    self.configureCell(cell, atIndexPath: indexPath)
    return cell
  }

  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
  }

  func configureCell(cell: SongTableViewCell, atIndexPath indexPath: NSIndexPath) {
    let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as Song
    cell.configureSong(object)
  }

  // MARK: - Fetched results controller

  var fetchedResultsController: NSFetchedResultsController {
    if _fetchedResultsController == nil {
      _fetchedResultsController = Song.fetchAllSortedBy("songID", ascending: false, withPredicate: predicate(), groupBy: "sectionIdentifier", delegate: self)
      }
      return _fetchedResultsController!
  }
  var _fetchedResultsController: NSFetchedResultsController? = nil

  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    self.tableView.beginUpdates()
  }

  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    switch type {
    case .Insert:
      self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    case .Delete:
      self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
    default:
      return
    }
  }

  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath) {
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
    case .Delete:
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    case .Update:
      let cell = tableView.cellForRowAtIndexPath(newIndexPath)
      if cell != nil {
        self.configureCell(cell! as SongTableViewCell, atIndexPath: newIndexPath)
      }
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
    default:
      return
    }
  }
  @IBAction func filterTypeSegmentChange(sender: AnyObject) {
    if isTimeline() {
      self.tableView.addSubview(self.refreshControl!)
    } else {
      self.refreshControl?.removeFromSuperview()
    }
    self.fetchedResultsController.fetchRequest.predicate = predicate()
    self.fetchedResultsController.performFetch(nil)
    self.tableView.reloadData()
    let top = self.scrollCache[self.filterTypeSegmentControl.selectedSegmentIndex]
    if top > 0 {
      self.tableView.contentOffset = CGPointMake(0, top)
    }
  }

  func isTimeline() -> Bool {
    return filterTypeSegmentControl == nil || filterTypeSegmentControl.selectedSegmentIndex != 1
  }

  func predicate() -> NSPredicate? {
    if !isTimeline() {
      return NSPredicate(format: "favoritedAt != nil")
    }
    return nil
  }

  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    self.configureCell(self.tableView.cellForRowAtIndexPath(indexPath!)! as SongTableViewCell, atIndexPath: indexPath!)
  }

  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.endUpdates()
  }

  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if self.apiClient.isLoading || !isTimeline() { return }
    var row = indexPath.row
    var section = indexPath.section
    var sectionCount = self.numberOfSectionsInTableView(tableView)
    var rowCount = self.tableView(tableView, numberOfRowsInSection: section)
    if rowCount >= row + 1 {
      row = 0
      section++
    }
    let song1 = self.fetchedResultsController .objectAtIndexPath(indexPath) as Song
    let songID1 = song1.songID.integerValue
    var sinceID = 0
    if section >= sectionCount {
      sinceID = songID1 - 1
    } else {
      let indexPath2 = NSIndexPath(forRow: row, inSection: section)
      let song2 = self.fetchedResultsController .objectAtIndexPath(indexPath2) as Song
      let songID2 = song2.songID.integerValue
      if songID1 - songID2  > 10 {
        sinceID = songID1 - 1
      }
    }
    if sinceID > 0 {
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

  func refresh(sender :AnyObject?) {
    refreshControl?.beginRefreshing()
    self.load()
  }
  
}

