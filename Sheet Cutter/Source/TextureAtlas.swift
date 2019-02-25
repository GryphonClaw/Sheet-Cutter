//  TextureAtlas.swift
//  Sheet Cutter
//
//  Created by GryphonClaw Software on 2/25/19.
//  Copyright © 2019 GryphonClaw Software. All rights reserved.
//

import Cocoa

struct TextureAtlas {
    var imagePath:String = ""
    var imageSource:NSImage? = nil
    var subTexture:[SubTexture] = []
    
    var count:Int {
        get {
            return subTexture.count
        }
    }
    
    mutating func process() {
        if imageSource != nil {
            for i in 0 ..< subTexture.count {
                if let image = imageSource {
                    subTexture[i].createImage(from: image)
                }
            }
        }
    }
}

struct SubTexture {
    var name:String = ""
    var x:Int = 0
    var y:Int = 0
    var width:Int = 0
    var height:Int = 0
    var image:NSImage? = nil
    
    var size:NSSize {
        get {
            return NSSize(width: width, height: height)
        }
    }
    
    mutating func createImage(from source:NSImage) {
        image = NSImage(size: size, flipped: true) { rect in return true }
        image?.lockFocus()
        let trueY = Int(source.size.height - CGFloat(y)) - height
        let rect = NSRect(x: x, y: trueY, width: width, height: height)
        source.draw(at: NSPoint.zero, from: rect, operation: .sourceOut, fraction: 1.0)
        
        image?.unlockFocus()
    }
}
