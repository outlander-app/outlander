//
//  NSColorExtensions.swift
//  Outlander
//
//  Created by Joseph McBride on 7/26/19.
//  Copyright © 2019 Joe McBride. All rights reserved.
//

import Foundation
import Cocoa

extension NSColor {
    public convenience init?(hex: String) {
        
        guard hex.hasPrefix("#") else {
            return nil
        }
        
        let start = hex.index(hex.startIndex, offsetBy: 1)
        let hexColor = String(hex[start...])

        var rgbValue:UInt32 = 0
        Scanner(string: hexColor).scanHexInt32(&rgbValue)
        
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func getHexString() -> String {
        let red = Int(round(self.redComponent * 0xFF))
        let grn = Int(round(self.greenComponent * 0xFF))
        let blu = Int(round(self.blueComponent * 0xFF))
        let hexString = NSString(format: "#%02X%02X%02X", red, grn, blu).lowercased
        return hexString as String
    }
}
