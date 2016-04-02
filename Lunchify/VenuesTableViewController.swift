//
//  VenuesTableViewController.swift
//  Lunchify
//
//  Created by Sallar Kaboli on 11/22/15.
//  Copyright © 2015 Sallar Kaboli. All rights reserved.
//

import UIKit
import CoreLocation
import JGProgressHUD
import HEXColor
import DZNEmptyDataSet

class VenuesTableViewController: UITableViewController, CLLocationManagerDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var shouldEmptyStateBeShowed: Bool = false
    var venues: [Venue] = []
    var filteredVenues: [Venue] = []
    let venuesService = VenuesService()
    var resultSearchController: UISearchController?
    var location: CLLocation? {
        didSet {
            loadVenues()
        }
    }
    let locationManager = CLLocationManager()
    let HUD = JGProgressHUD(style: .Dark)

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
        
        // Location
        locationManager.delegate = self
        locationManager.distanceFilter = 500
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func configureView() {
        tableView.estimatedRowHeight = 64.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorColor = UIColor(rgba: "#F0F0F0")
        let image = UIImage(named: "logo")
        self.navigationItem.titleView = UIImageView(image: image)
        
        // Progress
        HUD.textLabel.text = NSLocalizedString("LOADING", comment: "Loading...")
        HUD.showInView(self.navigationController?.view)
        
        // Remove 1px border
        self.navigationController?.navigationBar.subviews[0].subviews[1].hidden = true
        
        // Search bar
        definesPresentationContext = true
        self.resultSearchController = ({
            let controller = UISearchController(searchResultsController: nil)
            controller.searchResultsUpdater = self
            controller.dimsBackgroundDuringPresentation = false
            controller.searchBar.searchBarStyle = .Minimal
            controller.searchBar.tintColor = UIColor(rgba: "#C2185B")
            controller.searchBar.sizeToFit()
            
            self.tableView.tableHeaderView = controller.searchBar
            return controller
        })()
        
        // Empty State
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        // Back button
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: nil, action: nil)
    }
    
    // MARK: - Load Venues
    
    func loadVenues() {
        // Get venues
        venuesService.getVenues(self.location!) { retrievedVenues in
            if let venues = retrievedVenues {
                
                // Go back to main process
                dispatch_async(dispatch_get_main_queue()) {
                    self.venues = venues.allVenues
                    self.filteredVenues = self.venues
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    self.HUD.dismiss()
                    self.shouldEmptyStateBeShowed = (venues.allVenues.count == 0)
                }
                
            } else {
                print("Fetch failed")
            }
        }
    }
    
    @IBAction func refreshVenues(sender: UIRefreshControl) {
        loadVenues()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredVenues.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("VenueCell", forIndexPath: indexPath) as! VenueTableViewCell
        let venue = self.filteredVenues[indexPath.row]

        // Configure the cell...
        cell.venueTitleLabel?.text = venue.name
        cell.venueAddressLabel?.text = venue.address
        
        if let location = self.location {
            cell.venueDistanceLabel?.text = venue.distanceFromLocation(location)
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowVenue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let venue = filteredVenues[indexPath.row]
                let controller = (segue.destinationViewController as! MenuViewController)
                controller.venue = venue
                controller.location = self.location
                controller.date = venuesService.getMenuDate("EEEE")
            }
        }
    }
    
    // MARK: - Location
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.location = locations.first
    }
    
    // MARK: - Search
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filteredVenues = searchText.isEmpty ? venues : venues.filter({(venue: Venue) -> Bool in
                return venue.name!.rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
            })
            
            tableView.reloadData()
        }
    }
    
    // MARK: - Empty View
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "no-venue")
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("NO_VENUES", comment: "No venues"))
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("NO_VENUES_DESC", comment: "Will add soon"))
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("RELOAD", comment: "Reload"))
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        HUD.showInView(self.navigationController?.view)
        loadVenues()
    }
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        return self.shouldEmptyStateBeShowed
    }
}
