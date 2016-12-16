//
//  LoginViewController.swift
//  MyFavoriteMovies
//
//  Created by Jarrod Parkes on 1/23/15.
//  Copyright (c) 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - LoginViewController: UIViewController

class LoginViewController: UIViewController {
    
    // MARK: Properties
    
    var appDelegate: AppDelegate!
    var keyboardOnScreen = false
    
    // MARK: Outlets
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: BorderedButton!
    @IBOutlet weak var debugTextLabel: UILabel!
    @IBOutlet weak var movieImageView: UIImageView!
        
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // get the app delegate
        appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        configureUI()
        
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Login
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        
        userDidTapView(self)
        
        if usernameTextField.text!.isEmpty || passwordTextField.text!.isEmpty {
            debugTextLabel.text = "Username or Password Empty."
        } else {
            setUIEnabled(false)
            
            /*
                Steps for Authentication...
                https://www.themoviedb.org/documentation/api/sessions
                
                Step 1: Create a request token
                Step 2: Ask the user for permission via the API ("login")
                Step 3: Create a session ID
                
                Extra Steps...
                Step 4: Get the user id ;)
                Step 5: Go to the next view!            
            */
            getRequestToken()
        }
    }
    
    private func completeLogin() {
        performUIUpdatesOnMain {
            self.debugTextLabel.text = ""
            self.setUIEnabled(true)
            let controller = self.storyboard!.instantiateViewController(withIdentifier: "MoviesTabBarController") as! UITabBarController
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    // MARK: TheMovieDB
    
    private func getRequestToken() {
        
        /* TASK: Get a request token, then store it (appDelegate.requestToken) and login with the token */
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey
        ]
        
        /* 2/3. Build the URL, Configure the request */
        // let request = URLRequest(url: urlstring) -> format
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String:AnyObject], withPathExtension: "/authentication/token/new"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            
            /* 5. Parse the data  - check if everything looks fine */
            guard (error == nil) else {
                self.debugTextLabel.text = "error occur at url \(self.appDelegate.tmdbURLFromParameters(methodParameters as [String:AnyObject], withPathExtension: "/authentication/token/new"))"
                return
            }
            
            func displayError(_ error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed (Request Token)"
                }
            }

            // check if response code is within 200
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!, statuscode is \((response as? HTTPURLResponse)?.statusCode) \((response as? HTTPURLResponse))")
                return
            }
            
            // check if data = data
            guard let data = data else {
                displayError("there is no data retrieved from MovieDB")
                return
            }
            
            /* 5. Parse the data  w/ jsonSerialization */
            let parsedData: [String: AnyObject]! // "!" here means it can be nil or AnyObject
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                displayError("Coud not parse the data as JSON: '\(data)'")
                return
            }
            
            /* 6. Use the data! - get request token...*/
//            guard let success = parsedData[Constants.TMDBResponseKeys.Success] as? Bool, success == true else {
//                displayError("Response for this request \(request) is not successful")
//                return
//            }
            
            if let _ = parsedData[Constants.TMDBResponseKeys.StatusCode] as? Int {
                displayError("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedData)")
                return
            }

            guard let requestToken = parsedData[Constants.TMDBResponseKeys.RequestToken] as? String else {
                displayError("Cannot find key '\([Constants.TMDBResponseKeys.RequestToken])' in data \(parsedData)")
                return
            }
            
            // add request token to appdelegate' property that is already listening to this view controller to pass over this value
            print("requesttoken is \(requestToken)")
            self.appDelegate.requestToken = requestToken
            self.loginWithToken(self.appDelegate.requestToken!)
        }

        /* 7. Start the request */
        task.resume()
    }
    
    private func loginWithToken(_ requestToken: String) {
        
        /* TASK: Login, then get a session id */
        
        /* 1. Set the parameters */
        /* 2/3. Build the URL, Configure the request */
        /* 4. Make the request */
        /* 5. Parse the data */
        /* 6. Use the data! */
        /* 7. Start the request */
        
        
        /* 1. Set the parameters - use keys/ value from Constants.swift*/
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.Username: usernameTextField.text!,
            Constants.TMDBParameterKeys.Password: passwordTextField.text!,
            Constants.TMDBParameterKeys.RequestToken: requestToken
            ]
        
        /* 2/3. Build the URL, Configure the request - with func tmdbURLFromParameters @ Appdelegate */
        // session, dataTask, url
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String: AnyObject], withPathExtension: "/authentication/token/validate_with_login"))
        
        print("request url is \(request.url!)")
        
        // completion handler
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
           
            // set up a displayError() with UI for debugging
            func displayError(_ error: String) {
                print(error) // @ console
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login failed @ func loginWithToken" // on UI
                }
            }
            
            // check if any error
            guard (error == nil) else {
                displayError("Error occurs at your request \(error)") // @ console
                return
            }
            
            // check response.statuscode within 2xx
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else{
                 displayError("Your request returned a status code other than 2xx!, statuscode is \((response as? HTTPURLResponse)?.statusCode) \((response as? HTTPURLResponse))") // console
                return
            }
            
            // check data is not nil
            guard let data = data else {
                displayError("There is no data from this request")
                return
            }
            
            /* 5. Parse the data */
            let parsedData: [String: AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: AnyObject]
            } catch {
                displayError("Cannot parse data")
                return
            }
            
            // before using data, need to check status code + success or not - if success -boolean + status_code == nil, then all good!
            // check status code -
            if let _ = parsedData[Constants.TMDBResponseKeys.StatusCode] as? Int {
                displayError("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)'")
                return
            }
            
            // if success is nil - means not successful
            guard let success = parsedData[Constants.TMDBResponseKeys.Success] as? Bool, success == true else {
                displayError("Cannot find key '\(parsedData[Constants.TMDBResponseKeys.Success]) in \(parsedData)")
                return
            }
            
            // print to console -nikki's
            if success { // if true
                print("success is \(success)") // not nil if success~
            } else {
                print("StatusMessage is \(parsedData[Constants.TMDBResponseKeys.StatusMessage])") // nil success
            }
            
            /* 6. Use the data! - if successful, just call next func*/
            self.getSessionID(self.appDelegate.requestToken!)
            
        }
        /* 7. Start the request */
        task.resume()
    }
    
    private func getSessionID(_ requestToken: String) {
        
        /* TASK: Get a session ID, then store it (appDelegate.sessionID) and get the user's id */
        
        /* 1. Set the parameters */
        /* 2/3. Build the URL, Configure the request */
        /* 4. Make the request */
        /* 5. Parse the data */
        /* 6. Use the data! */
        /* 7. Start the request */
        
        /* 1. Set the parameters - look at API doc, check para is required*/
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.RequestToken: requestToken
            ]
        
        /* 2/3. Build the URL, Configure the request - using appDelegate's tmdbURLFromParameters*/
        
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String: AnyObject], withPathExtension: "/authentication/session/new"))
        
        /* 4. Make the request */
        let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            
            /* 5. Parse the data */
            // make displayError func - to print out error + show on UI
            func displayError(_ error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login Failed - Error @ func getSessionID "
                }
            }
            
            // First, need to check data, response, error
            guard (error == nil) else {
                displayError("There is an error here at request \(error)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                 displayError("Your request returned a status code other than 2xx!, statuscode is \((response as? HTTPURLResponse)?.statusCode) \((response as? HTTPURLResponse))")
                return
            }
            
            guard let data = data else { // ok if data != nil
                displayError("there is no data coming back")
                return
            }
            
            // Finally. parse the data
            let parsedData : [String: AnyObject]!
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                displayError("Data cannot be parsed \(data)")
                return
            }
            
            // if statusCode is int type -> means error from "data" - show error
            if let _ = parsedData[Constants.TMDBResponseKeys.StatusCode] as? Int {
                displayError("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedData)")
                return
            }
            
            // get session_id from parsedData
            guard let sessionId = parsedData[Constants.TMDBResponseKeys.SessionID] as? String else {
                print("there is no key \(Constants.TMDBResponseKeys.SessionID) from parsedData \(parsedData) ")
                return
            }
            
            
            /* 6. Use the data! - pass sessionID to getUserID by storing to appdelegate, then pass it over */
            self.appDelegate.sessionID = sessionId
            self.getUserID(self.appDelegate.sessionID!)
            
        }
        /* 7. Start the request */
        task.resume()
    }
    
    private func getUserID(_ sessionID: String) {
        
        /* TASK: Get the user's ID, then store it (appDelegate.userID) for future use and go to next view! */
        
        /* 1. Set the parameters */
        /* 2/3. Build the URL, Configure the request */
        /* 4. Make the request */
        /* 5. Parse the data */
        /* 6. Use the data! */
        /* 7. Start the request */
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.TMDBParameterKeys.ApiKey: Constants.TMDBParameterValues.ApiKey,
            Constants.TMDBParameterKeys.SessionID: appDelegate.sessionID
                                ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = URLRequest(url: appDelegate.tmdbURLFromParameters(methodParameters as [String : AnyObject], withPathExtension: "/account"))
        
        /* 4. Make the request */
         let task = appDelegate.sharedSession.dataTask(with: request) { (data, response, error) in
            /* 5. Parse the data */
            // first write displayError() to show UI and print error @ console
            func displayError(_ error: String) {
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.debugTextLabel.text = "Login failed @ func getUserID"
                }
            }

            // first check data, response, error first
            guard (error == nil) else {
                displayError("There is an error - \(error)")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!, statuscode is \((response as? HTTPURLResponse)?.statusCode) \((response as? HTTPURLResponse))")
                return
            }
            
            guard let data = data else { // if data == nil, then let data = data fail, then will run the block
                displayError("There is no data from this request \(request)")
                return
            }
            
            // parse the data
            let parsedData : [String: AnyObject]! // dict
            do {
                parsedData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: AnyObject]
            } catch {
                // displayError("Data cannot be parsed - \(data)")
                print(("Data cannot be parsed - \(data)"))
                return
            }
            
            // check parsed Data if fail
            if let _ = parsedData[Constants.TMDBResponseKeys.StatusCode] as? Int {
                displayError("TheMovieDB returned an error. See the '\(Constants.TMDBResponseKeys.StatusCode)' and '\(Constants.TMDBResponseKeys.StatusMessage)' in \(parsedData)")
                return
            }
            
            
            // if there is no userId key
            guard let userId = parsedData![Constants.TMDBResponseKeys.UserID] as? Int else {
                displayError("There is no \(Constants.TMDBResponseKeys.UserID) as key in data - \(parsedData)")
                return
            }

            /* 6. Use the data! */
            // store user id to appDelegate + go to next view
            self.appDelegate.userID = userId
            self.completeLogin()
            
        }
        
        /* 7. Start the request */
        task.resume()
        
    }
}

// MARK: - LoginViewController: UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
            movieImageView.isHidden = true
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
            movieImageView.isHidden = false
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }
    
    private func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    private func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(_ sender: AnyObject) {
        resignIfFirstResponder(usernameTextField)
        resignIfFirstResponder(passwordTextField)
    }
}

// MARK: - LoginViewController (Configure UI)

private extension LoginViewController {
    
    func setUIEnabled(_ enabled: Bool) {
        usernameTextField.isEnabled = enabled
        passwordTextField.isEnabled = enabled
        loginButton.isEnabled = enabled
        debugTextLabel.text = ""
        debugTextLabel.isEnabled = enabled
        
        // adjust login button alpha
        if enabled {
            loginButton.alpha = 1.0
        } else {
            loginButton.alpha = 0.5
        }
    }
    
    func configureUI() {
        
        // configure background gradient
        let backgroundGradient = CAGradientLayer()
        backgroundGradient.colors = [Constants.UI.LoginColorTop, Constants.UI.LoginColorBottom]
        backgroundGradient.locations = [0.0, 1.0]
        backgroundGradient.frame = view.frame
        view.layer.insertSublayer(backgroundGradient, at: 0)
        
        configureTextField(usernameTextField)
        configureTextField(passwordTextField)
    }
    
    func configureTextField(_ textField: UITextField) {
        let textFieldPaddingViewFrame = CGRect(x: 0.0, y: 0.0, width: 13.0, height: 0.0)
        let textFieldPaddingView = UIView(frame: textFieldPaddingViewFrame)
        textField.leftView = textFieldPaddingView
        textField.leftViewMode = .always
        textField.backgroundColor = Constants.UI.GreyColor
        textField.textColor = Constants.UI.BlueColor
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSForegroundColorAttributeName: UIColor.white])
        textField.tintColor = Constants.UI.BlueColor
        textField.delegate = self
    }
}

// MARK: - LoginViewController (Notifications)

private extension LoginViewController {
    
    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
