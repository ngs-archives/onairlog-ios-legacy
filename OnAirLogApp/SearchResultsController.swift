//
//  SearchResultsController.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/19/14.
//
//

import UIKit

public class SearchResultsController: BaseTableViewController, UISearchResultsUpdating {

  public var searchItems: [String]?
  var masterViewController: MasterViewController?

  public func updateSearchResultsForSearchController(searchController: UISearchController) {
    let whitespaceCharacterSet = NSCharacterSet.whitespaceCharacterSet()
    let strippedString = searchController.searchBar.text.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
    searchItems = strippedString.componentsSeparatedByString(" ") as [String]
    updatePredicate()
  }

  override public func predicate() -> NSPredicate? {
    var andMatchPredicates = [NSPredicate]()
    if searchItems == nil || !(searchItems?.count > 0) {
      return nil
    }
    for searchString in searchItems! {
      if searchString == "" { continue }
      var searchItemsPredicate = [NSPredicate]()
      for key in ["title", "artist"] {
        var lhs = NSExpression(forKeyPath: key)
        var rhs = NSExpression(forConstantValue: searchString)
        var finalPredicate = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .DirectPredicateModifier, type: .ContainsPredicateOperatorType, options: .CaseInsensitivePredicateOption)
        searchItemsPredicate.append(finalPredicate)
      }
      let orMatchPredicates = NSCompoundPredicate.orPredicateWithSubpredicates(searchItemsPredicate)
      andMatchPredicates.append(orMatchPredicates)
    }
    let masterPred = self.masterViewController?.predicate()
    if masterPred != nil {
      andMatchPredicates.append(masterPred!)
    }
    return NSCompoundPredicate.andPredicateWithSubpredicates(andMatchPredicates)
  }

  override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let song: Song! = self.fetchedResultsController.objectAtIndexPath(indexPath) as Song
    self.masterViewController?.performSegueWithIdentifier("showDetail", sender: song)
  }

  override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

  }

}
