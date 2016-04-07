//
//  ViewController.swift
//  wrapper
//
//  Created by Unpublished on 10/16/15.
//  Copyright © 2015 2rba. All rights reserved.
//

import UIKit
import WebKit
import CoreLocation
import FBSDKCoreKit
import FBSDKLoginKit
import AMPopTip

class ViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    
    @IBAction func actionBack(sender: AnyObject) {
        self.webView?.goBack()
    }
    @IBAction func actionReload(sender: AnyObject) {
        self.webView?.reload()
    }
    @IBOutlet weak var navBar: UINavigationItem!
    @IBOutlet weak var reloadBtn: UIBarButtonItem!
    @IBOutlet weak var containerView: UIView! = nil
    
//    @IBOutlet weak var webView: UIWebView!
    var webView: WKWebView?

    @IBOutlet weak var TSPower: UIBarButtonItem!
    
    @IBOutlet weak var TSInternet: UIBarButtonItem!
    
    @IBOutlet weak var TSActive: UIBarButtonItem!
    
    var service: Service=Service()
    var locationManager: CLLocationManager = CLLocationManager()
    
    var popTip: AMPopTip?

    @IBAction func TSPowerClick(sender: AnyObject?) {
        popTip?.hide()
        popTip?.showText("Індикатор живлення\nЗапис маршруту відбувається тільки при включеному живленні", direction: .Down, maxWidth: 200, inView: self.view, fromFrame: TSPower.valueForKey("view")!.frame)
    }
    @IBAction func TSInternetClick(sender: AnyObject) {
        popTip?.hide()
        popTip?.showText("Індикатор з’єднання з сервером", direction: .Down, maxWidth: 200, inView: self.view, fromFrame: TSInternet.valueForKey("view")!.frame)
    }

    @IBAction func TSActiveClick(sender: AnyObject) {
        popTip?.hide()
        popTip?.showText("Індикатор запису маршрута\nВказує чи відбувається запис маршрута", direction: .Down, maxWidth: 200, inView: self.view, fromFrame: TSActive.valueForKey("view")!.frame)
    }
    
    override func loadView() {
        super.loadView()
        if #available(iOS 9.0, *) {
            locationManager.allowsBackgroundLocationUpdates = true
        }
        
        let contentController = WKUserContentController();

        contentController.addScriptMessageHandler(
            self,
            name: "callbackHandler"
        )
        
        let config = WKWebViewConfiguration()
        config.processPool = WKProcessPool()
        config.userContentController = contentController
        
        
        self.containerView.sizeToFit()
        
//        let bounds = CGRectMake(0, 0,
//            self.view.bounds.width, self.view.bounds.height - 100)
        
        self.webView = WKWebView(
            frame: CGRectZero,
            configuration: config
        )
        self.containerView.addSubview(webView!)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view, typically from a nib.

//        if (FBSDKAccessToken.currentAccessToken() != nil)
//        {
//            // User is already logged in, do work such as go to next view controller.
//        }
//        else
//        {
//            let loginView : FBSDKLoginButton = FBSDKLoginButton()
//            self.view.addSubview(loginView)
//            loginView.center = self.view.center
//            loginView.readPermissions = ["public_profile", "email", "user_friends"]
//            loginView.delegate = self
//        }


        service.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.delegate = service
        if #available(iOS 8.0, OSX 10.10, *) {
            locationManager.requestWhenInUseAuthorization()
        }
        service.connect()
        // Do any additional setup after loading the view, typically from a nib.
        UIDevice.currentDevice().batteryMonitoringEnabled = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.batteryStateDidChange(_:)), name: UIDeviceBatteryStateDidChangeNotification, object: nil)
        TSPower.tintColor = UIColor.yellowColor();
        NSNotificationCenter.defaultCenter().postNotificationName(UIDeviceBatteryStateDidChangeNotification, object: nil)
        let url = NSURL (string:getHomeURL());
        let requestObj = NSURLRequest(URL: url!);
//        UIView.setAnimationsEnabled(false)
        webView!.navigationDelegate = self
        webView!.loadRequest(requestObj)

//        [[UIBarButtonItem appearance] setTintColor:[UIColor greenColor]];
        
        webView!.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView!, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1, constant: -70)
        let width = NSLayoutConstraint(item: webView!, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0)
        let myConstraint =
            NSLayoutConstraint(item: webView!,
                               attribute: NSLayoutAttribute.Top,
                               relatedBy: NSLayoutRelation.Equal,
                               toItem: containerView,
                               attribute: NSLayoutAttribute.Top,
                               multiplier: 1.0,
                               constant: 0)
        view.addConstraints([height, width, myConstraint])
        popTip = AMPopTip()
        popTip?.shouldDismissOnTap = true
        popTip?.offset = 17
        popTip?.popoverColor = UIColor.orangeColor()
    }

    func batteryStateDidChange(notification: NSNotification) {
//        self.view.backgroundColor = UIColor.yellowColor()
        NSLog("power connection event");
        let currentState: UIDeviceBatteryState = UIDevice.currentDevice().batteryState;
        if (currentState == UIDeviceBatteryState.Unplugged || currentState == UIDeviceBatteryState.Unknown) {
           TSPower.tintColor = UIColor.redColor();
            service.stop()
        } else {
           TSPower.tintColor = UIColor.greenColor();
           service.start()
        }

//        self.scheduleAlarmForDate(NSDate.date())
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setInternetIndicator(color: UIColor){
        TSInternet.tintColor = color;
    }
    
    func save_fb_token(token: String){
        let exec: String = String(format: "save_fb_token('%@');", token)
        webView!.evaluateJavaScript(exec, completionHandler: nil)
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        if(message.name == "callbackHandler") {
            print("JavaScript is sending a message \(message.body)")
            
            let fbLogin = message.body.objectForKey("fb_login")
            
            if (fbLogin != nil){
            
            let token = FBSDKAccessToken.currentAccessToken()
            if ( token != nil)
            {
                NSLog("token ")
                save_fb_token(token.tokenString)
            } else {
            
            let loginManager = FBSDKLoginManager()
            loginManager.logInWithReadPermissions(["public_profile", "email"], fromViewController: self, handler: { (result, error) -> Void in
                if error != nil {
                    print("unknown")
                } else if result.isCancelled {
                    print("Cancelled")
                    FBSDKLoginManager().logOut()
                } else {
                    print("LoggedIn")
                    self.save_fb_token(FBSDKAccessToken.currentAccessToken().tokenString)
                    print(FBSDKAccessToken.currentAccessToken())
                }
            })
            }
            }
            
            let authentication_token = message.body.objectForKey("authentication_token")
            if ( authentication_token != nil){
                print(authentication_token)
                NSUserDefaults.standardUserDefaults().setObject(authentication_token as? String, forKey: "authentication_token")
                service.connect()
                NSNotificationCenter.defaultCenter().postNotificationName(UIDeviceBatteryStateDidChangeNotification, object: nil)
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.registerTokenOnServer()
                let url = NSURL (string:getHomeURL());
                let requestObj = NSURLRequest(URL: url!);
                webView!.loadRequest(requestObj)
            }

            let badge_value = message.body.objectForKey("badge_value")
            if ( badge_value != nil ){
                UIApplication.sharedApplication().applicationIconBadgeNumber = (badge_value as? Int)!
            }
        }
    }
    
    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }

    func processMessage(json : AnyObject!){
        let webview = json["webview"] as? String
        if (webview != nil) {
            NSLog("got some name: \(webview)")
            let url = NSURL (string: webview!)
            let requestObj = NSURLRequest(URL: url!);
            webView!.loadRequest(requestObj)
        };

        let offClient = json["off_client"] as? Bool
        if (offClient != nil){
            service.stop()
        }

        let handshakeReply = json["handshake_reply"] as? Bool;
        if (handshakeReply != nil) {
            TSActive.tintColor = UIColor.greenColor();
        }

        let exec_js = json["exec_js"] as? String;
        if (exec_js != nil){
            webView!.evaluateJavaScript(exec_js!, completionHandler: nil)
        }
    }


    func getHomeURL()->String{
#if DEVELOPMENT
        let url = "http://drider.dev:4000/?client=ios"
#else
        let url = "http://drider.io/?client=ios"
#endif
        return url+"&location="+locationStatus()+"&notifications="+alertStatus()
    }

    func locationStatus()->String{
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .NotDetermined:
               return "NotDetermined"
            case .Restricted:
                 return "Restricted"
            case .Denied:
                 return "Denied"
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                return "Authorized"
            }
        } else {
            return "NotAvailable";
        }
    }
    
    func alertStatus()->String{
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        var result = ""
        if settings!.types.contains([.Alert]) {result += ".Alert"}
        if settings!.types.contains([.Sound]) {result += ".Sound"}
        if settings!.types.contains([.Badge]) {result += ".Badge"}
        return result;
    }
}

