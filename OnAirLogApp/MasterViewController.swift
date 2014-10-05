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

  var detailViewController: DetailViewController? = nil
  var songManager: SongManager? = nil


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
    self.tableView.addSubview(refreshControl)
    self.navigationItem.leftBarButtonItem = self.editButtonItem()
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
    }
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
    // Return false if you do not want the specified item to be editable.
    return true
  }

  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      let context = self.fetchedResultsController.managedObjectContext
      context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject)

      var error: NSError? = nil
      if !context.save(&error) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        //println("Unresolved error \(error), \(error.userInfo)")
        abort()
      }
    }
  }

  func configureCell(cell: SongTableViewCell, atIndexPath indexPath: NSIndexPath) {
    let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as Song
    cell.configureSong(object)
  }

  // MARK: - Fetched results controller

  var fetchedResultsController: NSFetchedResultsController {
    if _fetchedResultsController == nil {
      _fetchedResultsController = self.songManager?.fetchedResultsControllerWithPredicate(nil, delegate: self)
      }
      return _fetchedResultsController!
  }
  var _fetchedResultsController: NSFetchedResultsController? = nil

  var favoritesFetchedResultsController: NSFetchedResultsController {
    if _favoritesFetchedResultsController == nil {
      let predicate: NSPredicate = NSPredicate(format: "favoritedTimeStamp IS NOT NULL")
      _favoritesFetchedResultsController = self.songManager?.fetchedResultsControllerWithPredicate(predicate, delegate: self)
      }
      return _favoritesFetchedResultsController!
  }
  var _favoritesFetchedResultsController: NSFetchedResultsController? = nil

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
      self.configureCell(tableView.cellForRowAtIndexPath(indexPath)! as SongTableViewCell, atIndexPath: indexPath)
    case .Move:
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
    default:
      return
    }
  }

  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    self.tableView.endUpdates()
  }
  
}

