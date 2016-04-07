//
//  Service.swift
//  car
//
//  Created by Unpublished on 10/18/15.
//  Copyright © 2015 2rba. All rights reserved.
//

import Starscream
import Foundation
import UIKit
import CoreLocation

class Service: NSObject, WebSocketDelegate, CLLocationManagerDelegate {
//    var newWebSocket:SRWebSocket?
#if DEVELOPMENT
    var socket = WebSocket(url: NSURL(string: "ws://drider.dev:4000/chat")!, protocols: ["chat", "superchat"])
#else
    var socket = WebSocket(url: NSURL(string: "ws://drider.io/chat")!, protocols: ["chat", "superchat"])
#endif
//    var socket: WebSocket(url: NSURL(string: "ws://drider.dev:4000/chat")!)
//    override init(){
//        
//    }
    internal weak var delegate: ViewController?

    var started = false;

    func connect(){
        let token = NSUserDefaults.standardUserDefaults().stringForKey("authentication_token")
        if (token != nil){
            connectWebSocket(token)
        }
    }
    
    func start(){
        UIApplication.sharedApplication().idleTimerDisabled = true
        let token = NSUserDefaults.standardUserDefaults().stringForKey("authentication_token")
        if (token != nil){
//          connectWebSocket(token)
          delegate?.locationManager.startUpdatingLocation()
        }
    }
    
    func stop(){
        UIApplication.sharedApplication().idleTimerDisabled = false
        socket.disconnect();
        delegate?.locationManager.stopUpdatingLocation()
        delegate?.TSActive.tintColor = UIColor.redColor();
        started = false;
    }
    
    
    func connectWebSocket(token: String?) {
//        webSocket.delegate = nil
//        webSocket = nil
        NSLog("connection init")
//        let urlString: String = "ws://drider.dev:4000/chat"
//        socket =
        socket.delegate = self
        
        socket.headers["Auth-Token"] = token
        socket.connect()
        
//        newWebSocket = SRWebSocket(URLRequest: NSURLRequest(URL: NSURL(string: urlString)!))
//        newWebSocket = SRWebSocket(URL: NSURL(string:urlString))
//        newWebSocket!.delegate = self
//        newWebSocket!.open()
//        newWebSocket?.send("aa")

        
    }
    func websocketDidConnect(socket: WebSocket) {
        NSLog("websocket is connected1")
        delegate?.TSInternet.tintColor = UIColor.greenColor();
//        if self.socket.isConnected {
//            NSLog("websocket is connected2")
////            delete.setInternetIndicator(UIColor.greenColor());
//            
//        }
    }
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        started = false;
        delegate?.TSInternet.tintColor = UIColor.redColor();
        delegate?.TSActive.tintColor = UIColor.redColor();
        NSLog("websocket is disconnected: \(error?.localizedDescription)")
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(Service.connect), userInfo: nil, repeats: false)
    }
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
//        let json = JSON(data: text)
        let data: NSData = text.dataUsingEncoding(NSUTF8StringEncoding)!
        NSLog("got some text: \(text)")
        do{
            
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments);

        delegate?.processMessage(json)
    } catch {
    print("error serializing JSON: \(error)")
    }
    }
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        NSLog("got some data: \(data.length)")
    }
    
//    @objc func webSocketDidOpen(newWebSocket: SRWebSocket) {
////        webSocket = newWebSocket
////        webSocket.send("Hello from \(UIDevice.currentDevice().name)")
//                NSLog("didOpen")
//    }
//    
//    func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSErrorPointer!) {
////        self.connectWebSocket()
//        NSLog("didFail")
//    }
//    
//    @objc func webSocket(webSocket: SRWebSocket, didCloseWithCode code: Int, reason: String, wasClean: Bool) {
////        self.connectWebSocket()
//                NSLog("didClose")
//    }
    
//    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
////        self.messagesTextView.text = "\(self.messagesTextView.text)\n\(message)"
//        NSLog("message ")
//    }
    func locationManager(manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation])
    {
        let latestLocation: CLLocation = locations[locations.count - 1]
        NSLog("Latest location:%@", latestLocation)

        if self.socket.isConnected {
            // if handshake sent
            if (!started){
                do {
                    let uuid = UIDevice.currentDevice().identifierForVendor?.UUIDString;
                    let jsonObject: [String: AnyObject] = [
                        "type": "handshake",
                        "ios": "true",
                        "client_version":  NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as! String,
                        "client_version_code": NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String,
                        "client_os_version": UIDevice.currentDevice().systemVersion,
                        "device_identifier": uuid!
                    ]
                    let jsonData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions.PrettyPrinted)
                    // here "jsonData" is the dictionary encoded in JSON data
                    let jsonText = String(data: jsonData,
                        encoding: NSASCIIStringEncoding)
                    self.socket.writeString(jsonText!)
                    started=true
                } catch let error as NSError {
                    print(error)
                }
            }


            let jsonObject: [String: AnyObject] = [
                "type": "location",
                "lat":  latestLocation.coordinate.latitude,
                "long": latestLocation.coordinate.longitude,
                "accy": latestLocation.horizontalAccuracy,
                "time_ms": 111,
                "session_id": "TODO"
            ]
            do {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: NSJSONWritingOptions.PrettyPrinted)
                // here "jsonData" is the dictionary encoded in JSON data
                let jsonText = String(data: jsonData,
                    encoding: NSASCIIStringEncoding)
                self.socket.writeString(jsonText!)
            } catch let error as NSError {
                print(error)
            }

//            self.socket.writeString("mylocation")
        } else {
            connect();
        }
    }

}