//
//  SearchResultsController.swift
//  OnAirLog
//
//  Created by Atsushi Nagase on 10/19/14.
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


open class SearchResultsController: BaseTableViewController, UISearchResultsUpdating {

  open var searchItems: [String]?
  var masterViewController: MasterViewController?

  open func updateSearchResults(for searchController: UISearchController) {
    let whitespaceCharacterSet = CharacterSet.whitespaces
    let strippedString = searchController.searchBar.text.stringByTrimmingCharactersInSet(whitespaceCharacterSet)
    searchItems = strippedString.componentsSeparatedByString(" ") as [String]
    updatePredicate()
  }

  override open func predicate() -> NSPredicate? {
    var andMatchPredicates = [NSPredicate]()
    if searchItems == nil || !(searchItems?.count > 0) {
      return nil
    }
    for searchString in searchItems! {
      if searchString == "" { continue }
      var searchItemsPredicate = [NSPredicate]()
      for key in ["title", "artist"] {
        let lhs = NSExpression(forKeyPath: key)
        let rhs = NSExpression(forConstantValue: searchString)
        let finalPredicate = NSComparisonPredicate(leftExpression: lhs, rightExpression: rhs, modifier: .direct, type: .contains, options: .caseInsensitive)
        searchItemsPredicate.append(finalPredicate)
      }
      let orMatchPredicates = NSCompoundPredicate.orPredicate(withSubpredicates: searchItemsPredicate)
      andMatchPredicates.append(orMatchPredicates)
    }
    let masterPred = self.masterViewController?.predicate()
    if masterPred != nil {
      andMatchPredicates.append(masterPred!)
    }
    return NSCompoundPredicate.andPredicate(withSubpredicates: andMatchPredicates)
  }

  override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let song: Song! = self.fetchedResultsController.object(at: indexPath) as! Song
    self.masterViewController?.performSegue(withIdentifier: "showDetail", sender: song)
  }

  override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {

  }

}
