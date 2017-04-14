//
//  AppDelegate.swift
//  Focus Machine
//
//  Created by Vojtech Rinik on 11/03/2017.
//  Copyright © 2017 Vojtech Rinik. All rights reserved.
//

import Cocoa
import SwiftyTimer

enum FocusStatus {
    case focused
    case distracted
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var instance: AppDelegate!
    
    // Constants
    let blockStartMark = "# Focus Machine Starts Here"
    let blockEndMark = "# Focus Machine Ends Here"
    
    // Status
    var status: FocusStatus = .focused {
        didSet {
            applyStatus()
        }
    }
    
    // Menu items
    var systemItem: NSStatusItem?
    var statusItem: NSMenuItem?
    var requestItem: NSMenuItem?
    
    // Controllers
    var requestController: RequestWindowController?
    
    let launch = LaunchAtLoginController()
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.instance = self
        
        setupStatusItem()
        
        applyStatus()
        
        launch.launchAtLogin = true
    }

    // MARK: - Menu items
    // -----------------------------------------------------------------------
    
    
    func setupStatusItem() {
        let systemItem = NSStatusBar.system().statusItem(withLength: 50)
        systemItem.title = "FoMa"
        self.systemItem = systemItem
        
        setupMenu()
    }
    
    func updateStatusItem() {
        switch status {
        case .focused:
            statusItem?.title = "Status: Focused"
            requestItem?.isHidden = false
        case .distracted:
            statusItem?.title = "Status: Distracted"
            requestItem?.isHidden = true
        }
    }
    
    func setupMenu() {
        // Create the menu
        let menu = NSMenu()
        
        let statusItem = NSMenuItem(title: "Status: Focused", action: nil, keyEquivalent: "")
        menu.addItem(statusItem)
        self.statusItem = statusItem
        
        let requestItem = NSMenuItem(title: "Request an exception", action: #selector(requestException(_:)), keyEquivalent: "")
        menu.addItem(requestItem)
        self.requestItem = requestItem
        
        self.systemItem!.menu = menu
        
    }
    
    // MARK: - Requesting an exception
    // -----------------------------------------------------------------------
    
    func requestException(_ sender: Any) {
        if requestController == nil {
            requestController = RequestWindowController(windowNibName: "RequestWindowController")
        }
        
        requestController!.window?.makeKeyAndOrderFront(self)
    }

    var exception: (startedAt: Date, minutes: Int, timer: Timer)?
    
    func startException(minutes: Int) {
        status = .distracted
        
        if let exception = self.exception {
            exception.timer.invalidate()
            self.exception = nil
        }
        
        let timer = Timer(timeInterval: 1, repeats: true) { (_) in
            self.updateProgress()
        }
        
        timer.start(runLoop: RunLoop.main, modes: .commonModes)
        
        exception = (startedAt: Date(), minutes: minutes, timer: timer)
        
        updateProgress()
    }
    
    func stopException() {
        guard let exception = self.exception else {
            return
        }
        
        exception.timer.invalidate()
        
        self.exception = nil
        self.status = .focused
        
        updateProgress()
    }
    
    func updateProgress() {
        guard let exception = self.exception else {
            systemItem?.title = "FM"
            return
        }
        
        let endsAt = exception.startedAt.addingTimeInterval(TimeInterval(exception.minutes * 60))
        
        let remainingSeconds = round(endsAt.timeIntervalSinceNow)
        
        
        systemItem?.title = remainingSeconds.timeIntervalAsString("mm:ss")
        
        if remainingSeconds <= 0 {
            self.stopException()
            return
        }
    }
    
    // MARK: - Applying status
    // -----------------------------------------------------------------------
    
    func applyStatus() {
        updateHostsFile()
        updateStatusItem()
    }
    
    func updateHostsFile() {
        Swift.print("Applying status...")
        
        // Read the file
        let hosts = try! String(contentsOfFile: "/etc/hosts")
        var lines = hosts.components(separatedBy: "\n")
        
        // Delete all entries inside Focus Machine block
        var shouldDeleteLine = false
        lines = lines.filter { line in
            if line == blockStartMark {
                shouldDeleteLine = true
                return false
            }
            
            if line == blockEndMark {
                shouldDeleteLine = false
                return false
            }
            
            if shouldDeleteLine {
                return false
            }
            
            return true
        }
        
        // Add Focus Machine section, if focused atm
        lines.append(blockStartMark)
        if status == .focused {
            lines += hostsEntries
        }
        lines.append(blockEndMark)
        
        // Write the file
        let newHosts = lines.joined(separator: "\n")
        try! newHosts.write(toFile: "/etc/hosts", atomically: true, encoding: .utf8)
        
        // Done!
        Swift.print("Changes applied!")
    }
    
    var hostsEntries: [String] {
        let domains = [
            // Social media
            "m.facebook.com",
            "facebook.com",
            "prod.facebook.com",
            "messenger.com",
            "twitter.com",
            "m.twitter.com",
            "reddit.com",
            "m.reddit.com",
            "zoznamko.sk",
            "linkedin.com",
            "katrande.org",
            
            // Travel
            "airbnb.com",
            "booking.com",
            "pelikan.sk",
            "couchsurfing.com",
            
            // Startups
            "producthunt.com",
            "news.ycombinator.com",
            "techcrunch.com",
            
            // Tech
            "macrumors.com",
            "theverge.net",
            "gizmodo.com",
            
            
            // Entertainment
            "youtube.com",
            "gfycat.com",
            
            // Blogs
            "tumblr.com",
            "medium.com",
            
            // News
            "dsl.sk",
            "sme.sk",
            "dennikn.sk",
            
            // Eshops
            "alza.cz",
            "alza.sk",
            "heureka.sk",
            "ebay.com",
            "ebay.co.uk",
            "ebay.de",
            "ebay.fr",
            "amazon.com",
            "amazon.co.uk",
            "amazon.ca",
            "amazon.de",
            "amazon.fr",
            "swp.sk",
            "mzone.sk",
            "istores.sk",
            "bazos.sk",
            "abercrombie.com",
            "hollisterco.com",
            
            
            // SK
            "emefka.sk",
            "demotivacia.com",
            
            // Chart
            "slack.com",
            "rinik.slack.com"
        ]
        
        var entries = [String]()
        for domain in domains {
            entries.append("0.0.0.0 \(domain)")
            entries.append("0.0.0.0 www.\(domain)")
        }
        
        return entries
    }
    
    
    
}



extension TimeInterval {
    func timeIntervalAsString(_ format : String = "dd days, hh hours, mm minutes, ss seconds, sss ms") -> String {
        var asInt   = NSInteger(self)
        let ago = (asInt < 0)
        if (ago) {
            asInt = -asInt
        }
        let ms = Int(self.truncatingRemainder(dividingBy: 1) * (ago ? -1000 : 1000))
        let s = asInt % 60
        let m = (asInt / 60) % 60
        let h = ((asInt / 3600))%24
        let d = (asInt / 86400)
        
        var value = format
        value = value.replacingOccurrences(of: "hh", with: String(format: "%0.2d", h))
        value = value.replacingOccurrences(of: "mm",  with: String(format: "%0.2d", m))
        value = value.replacingOccurrences(of: "sss", with: String(format: "%0.3d", ms))
        value = value.replacingOccurrences(of: "ss",  with: String(format: "%0.2d", s))
        value = value.replacingOccurrences(of: "dd",  with: String(format: "%d", d))
        if (ago) {
            value += " ago"
        }
        return value
    }
    
}
