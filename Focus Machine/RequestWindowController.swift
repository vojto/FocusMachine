//
//  RequestWindowController.swift
//  Focus Machine
//
//  Created by Vojtech Rinik on 11/03/2017.
//  Copyright © 2017 Vojtech Rinik. All rights reserved.
//

import Cocoa
import ReactiveSwift
import ReactiveCocoa
import SwiftyTimer


class RequestWindowController: NSWindowController {
    
    // Outlets
    @IBOutlet weak var timeSlider: NSSlider!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var reasonField: NSTextField!
    @IBOutlet weak var requestButton: NSButton!
    
    

    override func windowDidLoad() {
        super.windowDidLoad()

        updateTimeLabel()
        
        requestButton.reactive.isEnabled <~
            reasonField.reactive.continuousStringValues.map { $0 != "" }
        
        reasonField.stringValue = ""
        requestButton.isEnabled = false
    }
    
    // MARK: - Handling events in "Request window"
    // -------------------------------------------
    
    @IBAction func changeTime(_ sender: Any) {
        updateTimeLabel()
    }
    
    
    func updateTimeLabel() {
        timeLabel.stringValue = "\(sliderMinutes)m"
    }
    
    var sliderMinutes: Int {
        return Int(timeSlider.intValue * (5 as Int32))
    }
    
    @IBAction func requestTime(_ sender: Any) {
        AppDelegate.instance.startException(minutes: sliderMinutes)
        
        self.close()
    }
}
