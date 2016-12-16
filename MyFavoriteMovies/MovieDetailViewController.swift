//
//  MovieDetailViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - MovieDetailViewController: UIViewController

class MovieDetailViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var isFavorite = false
    var movie: Movie?
    
    // MARK: Outlets
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var favoriteButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the app delegate
        appDelegate = UIApplication.shared.delegate as! AppDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if let movie = movie {
            
            // setting some defaults...
            posterImageView.image = UIImage(named: "film342.png")
            titleLabel.text = movie.title
            
            /* TASK A: Get favorite movies, then update the favorite buttons */
            /* 1A. Set the parameters */
            let methodParameters = [
                Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
                Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
            ]
            
            /* 2/3. Build the URL, Configure the request */
            let request = NSMutableURLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String:AnyObject], withPathExtension: "/account/\(appDelegate.userID!)/favorite/movies"))
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            /* 4A. Make the request */
            let task = appDelegate.sharedSession.dataTask(with: request as URLRequest) { (data, response, error) in
                
                /* GUARD: Was there an error? */
                guard (error == nil) else {
                    print("There was an error with your request: \(error)")
                    return
                }
                
                /* GUARD: Did we get a successful 2XX response? */
                guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                    print("Your request returned a status code other than 2xx!")
                    return
                }
                
                /* GUARD: Was there any data returned? */
                guard let data = data else {
                    print("No data was returned by the request!")
                    return
                }
                
                /* 5A. Parse the data */
                let parsedResult: [String:AnyObject]!
                do {
                    parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
                } catch {
                    print("Could not parse the data as JSON: '\(data)'")
                    return
                }
                
                /* GUARD: Did TheMovieDB return an error? */
                if let _ = parsedResult[Constants.TMDBResponseKeys.StatusCode] as? Int {
                    print("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedResult)")
                    return
                }
                
                /* GUARD: Is the "results" key in parsedResult? */
                guard let results = parsedResult[Constants.TMDBResponseKeys.Results] as? [[String:AnyObject]] else {
                    print("Cannot find key '\(Constants.TMDBResponseKeys.Results)' in \(parsedResult)")
                    return
                }
                
                /* 6A. Use the data! */
                let movies = Movie.moviesFromResults(results) // helper func to get movies list
                self.isFavorite = false
                
                for movie in movies {
                    if movie.id == self.movie!.id {
                        self.isFavorite = true
                    }
                }
                
                performUIUpdatesOnMain {
                    self.favoriteButton.tintColor = (self.isFavorite) ? nil : .black
                }
            }
            
            /* 7A. Start the request */
            task.resume()
            
            /* TASK B: Get the poster image, then populate the image view */
            if let posterPath = movie.posterPath {
                
                /* 1B. Set the parameters */
                // There are none...
                
                /* 2B. Build the URL */
                let baseURL = URL(string: appDelegate.config.baseImageURLString)!
                let url = baseURL.appendingPathComponent("w342").appendingPathComponent(posterPath)
                
                /* 3B. Configure the request */
                let request = URLRequest(url: url)
                
                /* 4B. Make the request */
                let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
                    
                    /* GUARD: Was there an error? */
                    guard (error == nil) else {
                        print("There was an error with your request: \(error)")
                        return
                    }
                    
                    /* GUARD: Did we get a successful 2XX response? */
                    guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                        print("Your request returned a status code other than 2xx!")
                        return
                    }
                    
                    /* GUARD: Was there any data returned? */
                    guard let data = data else {
                        print("No data was returned by the request!")
                        return
                    }
                    
                    /* 5B. Parse the data */
                    // No need, the data is already raw image data.
                    
                    /* 6B. Use the data! */
                    if let image = UIImage(data: data) {
                        performUIUpdatesOnMain {
                            self.posterImageView!.image = image
                        }
                    } else {
                        print("Could not create image from \(data)")
                    }
                }
                
                /* 7B. Start the request */
                task.resume()
            }
        }
    }
    
    // MARK: Favorite Actions
    
    @IBAction func toggleFavorite(_ sender: AnyObject) {
        
         let shouldFavorite = !isFavorite  // if already fav, by clicking heart -> change its state to false
        
        
        /* 1. Set the parameters */
        let headers = [Constants.TMDBHeaderParameterKeys.contentType: Constants.TMDBHeaderParameterValue.contentType]
        let bodyParameters = [
            Constants.TMDBBodyParameterKeys.mediaType: Constants.TMDBBodyParameterValue.mediaType,
            Constants.TMDBBodyParameterKeys.mediaID: movie!.id,
            Constants.TMDBBodyParameterKeys.favorite: shouldFavorite
        ] as [String : Any]
        
        // convert swift dict to json
        let postData = try? JSONSerialization.data(withJSONObject: bodyParameters, options: .prettyPrinted)
       
       
        // url parameters - will become your query Items - required items from API call 
        // NOthing change!
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID!
        ]
        
        /* 2/3. Build the URL, Configure the request */ // withPathExtension: passing anything after 3/
        var request = NSMutableURLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String: AnyObject], withPathExtension: "account/\(appDelegate.userID!)/favorite)"))
        
        print("request BEFORE adding header/ body is ...\(request)")
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        print("request AFTER adding header/ body is ...\(request)")
        print("Request's body is ....\(request.httpBody as AnyObject)")
   
        /* 4. Make the request */ // NOthing change!
        let task = appDelegate.sharedSession.dataTask(with: request as URLRequest) { (data, response, error) in
            /* 5. Parse the data */
            // check error, response, data
            guard (error == nil) else {
                print("There was an error with your request \(error)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your requset returned a statusCode other than 2xx - \((response as? HTTPURLResponse)?.statusCode), failed @ toggleFavorite")
                return
            }
            
            guard let data = data else {
                print("There is no data returned")
                return
            }
            
            let parsedData: [String: AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                print("The data cannot be jsonated")
                return
            }
  
            /* 6. Use the data! */
            // check statuscode
            guard let tmdbStatusCode = parsedData[Constants.TMDBResponseKeys.StatusCode] as? Int else {
                print("Could not find key \(Constants.TMDBResponseKeys.StatusCode) in \(parsedData)")
                return
            }
            
            if shouldFavorite && !(tmdbStatusCode == 1 || tmdbStatusCode == 12) {
                print("Unrecognized '\(Constants.TMDBResponseKeys.StatusCode)' in  \(parsedData)")
                return
            } else if !shouldFavorite && tmdbStatusCode != 13 {
                print("Unrecognized '\(Constants.TMDBResponseKeys.StatusCode)' in  \(parsedData)")
                return
            }
            
            
            /* 6. Use the data! */
            // reset isFavorite after user toggle
            self.isFavorite = shouldFavorite
            
            // If the favorite/unfavorite request completes, then use this code to update the UI...
             
             performUIUpdatesOnMain {
                self.favoriteButton.tintColor = (shouldFavorite) ? nil : .black
             }
        }
        
        /* 7. Start the request */
        task.resume()
        
    }
}










