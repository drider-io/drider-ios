//
//  AppDelegate.swift
//  wrapper
//
//  Created by Unpublished on 10/16/15.
//  Copyright © 2015 2rba. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var apns_token: String?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        //App launch code
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        //Optionally add to ensure your credentials are valid:
        FBSDKLoginManager.renewSystemCredentials {
            (result: ACAccountCredentialRenewResult, error: NSError!) -> Void in
        }
            //
            if #available(iOS 8.0, *) {
                let pushSettings: UIUserNotificationSettings = UIUserNotificationSettings(
                forTypes:
                [UIUserNotificationType.Alert,
                        UIUserNotificationType.Badge,
                        UIUserNotificationType.Sound],
                        categories: nil)
                UIApplication.sharedApplication().registerUserNotificationSettings(pushSettings)
                UIApplication.sharedApplication().registerForRemoteNotifications()

            } else {
                UIApplication.sharedApplication().registerForRemoteNotificationTypes(
                [UIRemoteNotificationType.Badge,
                 UIRemoteNotificationType.Sound,
                 UIRemoteNotificationType.Alert])
            }

        return true
    }

// Successfully registered for push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let trimEnds = deviceToken.description.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
        apns_token = trimEnds.stringByReplacingOccurrencesOfString(" ", withString: "")
        NSLog("get token : %@", apns_token!)
        
        registerTokenOnServer() //theoretical method! Needs your own implementation
    }
    
    func registerTokenOnServer() {
        let authentication_token = NSUserDefaults.standardUserDefaults().stringForKey("authentication_token")
        if (authentication_token != nil && apns_token != nil){
        #if DEVELOPMENT
            let request = NSMutableURLRequest(URL: NSURL(string: "http://drider.dev:4000/api/token/apns")!)
        #else
            let request = NSMutableURLRequest(URL: NSURL(string: "http://drider.io/api/token/apns")!)
        #endif

//
        let session = NSURLSession.sharedSession()
//        session.configuration.HTTPShouldSetCookies = true
//        session.configuration.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicy.OnlyFromMainDocumentDomain
//        session.configuration.HTTPCookieStorage?.cookieAcceptPolicy = NSHTTPCookieAcceptPolicy.OnlyFromMainDocumentDomain
//
        request.HTTPMethod = "POST"
        request.setValue(authentication_token, forHTTPHeaderField: "Auth-Token")
        
        let params = ["token":apns_token!, "name":UIDevice.currentDevice().name+UIDevice.currentDevice().identifierForVendor!.UUIDString] as Dictionary<String, String>
        
            request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params, options: [])
        let task = session.dataTaskWithRequest(request) { data, response, error in
            guard data != nil else {
                print("no data found: \(error)")
                return
            }
            
            // this, on the other hand, can quite easily fail if there's a server error, so you definitely
            // want to wrap this in `do`-`try`-`catch`:
            
            do {
                if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary {
                    let success = json["success"] as? Int                                  // Okay, the `json` is here, let's get the value for 'success' out of it
                    print("Success: \(success)")
                } else {
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)    // No error thrown, but not NSDictionary
                    print("Error could not parse JSON: \(jsonStr)")
                }
            } catch let parseError {
                print(parseError)                                                          // Log the error thrown by `JSONObjectWithData`
                let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                print("Error could not parse JSON: '\(jsonStr)'")
            }
        }
        task.resume()
        }
    }
    

    // Failed to register for Push
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {

        NSLog("Failed to get token; error: %@", error) //Log an error for debugging purposes, user doesn't need to know
    }

    func application(application: UIApplication,  didReceiveRemoteNotification userInfo: [NSObject : AnyObject],  fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print(userInfo);
        if let viewController = self.window?.rootViewController as? ViewController {
            viewController.processMessage(userInfo)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

