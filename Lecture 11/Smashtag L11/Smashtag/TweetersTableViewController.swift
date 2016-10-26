//
//  TweetersTableViewController.swift
//  Smashtag
//
//  Created by CS193p Instructor.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
import CoreData

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


// используем CoreDataTableViewController в качестве superclass,
// так что все, что нам нужно сделать:
// 1. установить переменную fetchedResultsController и
// 2. реализовать tableView(cellForRowAtIndexPath:)

class TweetersTableViewController: CoreDataTableViewController
{
    var mention: String? { didSet { updateUI() } }
    var managedObjectContext: NSManagedObjectContext? { didSet { updateUI() } }

 //   var resultsController: NSFetchedResultsController<TwitterUser>!
    
       fileprivate func updateUI() {
        if let context = managedObjectContext , mention?.characters.count > 0 {
            let request: NSFetchRequest<TwitterUser> = TwitterUser.fetchRequest()
            request.predicate = NSPredicate(format: "any tweets.text contains[c] %@ and !screenName beginswith[c] %@", mention!, "darkside")
            request.sortDescriptors = [NSSortDescriptor(
                key: "screenName",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )]
            let resultsController:NSFetchedResultsController<TwitterUser>? = NSFetchedResultsController(fetchRequest: request,
                                                           managedObjectContext: context,
                                                           sectionNameKeyPath: nil,
                                                           cacheName: nil)
            fetchedResultsController =  resultsController as! NSFetchedResultsController<NSFetchRequestResult>?
        } else {
            fetchedResultsController = nil
        }
    }
    
    // это единственный метод UITableViewDataSource, который нужно реализовать,
    // если мы используем CoreDataTableViewController
    // очень важная часть - вызов fetchedResultsController?.objectAtIndexPath(indexPath)
    // (так мы получаем объект, который находится в той строке)
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TwitterUserCell", for: indexPath)

        if let twitterUser = fetchedResultsController?.object(at: indexPath) as? TwitterUser {
            var screenName: String?
            twitterUser.managedObjectContext?.performAndWait {
                // легко забыть, что это надо делать на нужной очереди (queue)
                screenName = twitterUser.screenName
                // мы не предполагаем, что context -это контекст на main queue
                // так что мы захватим screenName и вернем это значениена main queue
                // чтобы сделать установку типа cell.textLabel?.text
            }
            cell.textLabel?.text = screenName
            if let count = tweetCountWithMentionByTwitterUser(twitterUser) {
                cell.detailTextLabel?.text = (count == 1) ? "1 tweet" : "\(count) tweets"
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
    
        return cell
    }
    
    // private func, которая определяет сколько tweets, содержащих наш mention,
    // были посланы заданным пользователем
    
    fileprivate func tweetCountWithMentionByTwitterUser(_ user: TwitterUser) -> Int?
    {
        var count: Int?
        user.managedObjectContext?.performAndWait {
            let request = NSFetchRequest<Tweet>(entityName: "Tweet")
            request.predicate = NSPredicate(format: "text contains[c] %@ and tweeter = %@", self.mention!, user)
            count = try! user.managedObjectContext?.count(for: request)
        }
        return count
    }
}