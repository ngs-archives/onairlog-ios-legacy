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

  override func awakeFromNib() {
    super.awakeFromNib()
    if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
      self.clearsSelectionOnViewWillAppear = false
      self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    var refreshControl = UIRefreshControl()
    refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
    self.tableView.addSubview(refreshControl)
    self.navigationItem.leftBarButtonItem = self.editButtonItem()
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
    }
    self.refresh(nil)
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
    }
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
    self.fetchedResultsController.fetchRequest.predicate = predicate()
    self.fetchedResultsController.performFetch(nil)
    self.tableView.reloadData()
  }

  func predicate() -> NSPredicate? {
    if filterTypeSegmentControl != nil && filterTypeSegmentControl.selectedSegmentIndex == 1 {
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

  // MARK: - Scroll

  override func scrollViewDidScroll(scrollView: UIScrollView) {
    let contentHeight = scrollView.contentSize.height
    let height = scrollView.frame.size.height
    let top = scrollView.frame.origin.y
    let scrollTop = scrollView.contentOffset.y
    let diff = contentHeight - scrollTop - top
    if diff < height {
      self.apiClient.load(true, success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        }, failure: { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
      })
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

  func refresh(sender :AnyObject?) {
    let refreshControl: UIRefreshControl? = sender as? UIRefreshControl
    refreshControl?.beginRefreshing()
    apiClient.load(false,
      success: { (task: NSURLSessionDataTask!, responseObject: AnyObject!) -> Void in
        if refreshControl != nil {
          refreshControl?.endRefreshing()
        }
      }) { (task: NSURLSessionDataTask!, error: NSError!) -> Void in
        if refreshControl != nil {
          refreshControl?.endRefreshing()
        }
    }
  }
  
}

