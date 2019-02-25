//  TextureAtlas.swift
//  Sheet Cutter
//
//  Created by GryphonClaw Software on 2/25/19.
//  Copyright © 2019 GryphonClaw Software. All rights reserved.
//

import Cocoa

//The main TextureAtlas container, modeled after the XML file. This struct has an extra
//Image field to work with it easier
struct TextureAtlas {
    //The path to the image source as pulled from the selected XML data file
    var imagePath:String = ""
    //Once the image path is loaded, this will contain the main sheet file
    var imageSource:NSImage? = nil
    //All of the sub textures as defined by the selected XML data file
    var subTexture:[SubTexture] = []
    //Convenience read-only property that just returns the length of the subTexture array
    var count:Int {
        get {
            return subTexture.count
        }
    }
    
    //This processes the sub textures and creates the images in memory from the selected source sprite sheet
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

//The sub texture structure
struct SubTexture {
    //The name of the sub texture as defined by the Source XML Data
    var name:String = ""
    //The X position of the sub texture as defined by the Source XML Data
    var x:Int = 0
    //The Y position of the sub texture as defined by the Source XML Data
    var y:Int = 0
    //The Width of the sub texture as defined by the Source XML Data
    var width:Int = 0
    //The Height of the sub texture as defined by the Source XML Data
    var height:Int = 0
    //After createImage has been called, this should contain the sub texture as defined by the properties
    var image:NSImage? = nil
    
    //Convenience read-onky property that reeturns the size of the image as an NSSize
    var size:NSSize {
        get {
            return NSSize(width: width, height: height)
        }
    }
    
    //Creates the sub texture from the passed source image file, after the function is done, image will contain the sub texture as defined by the properties
    mutating func createImage(from source:NSImage) {
        image = NSImage(size: size, flipped: true) { rect in return true }
        image?.lockFocus()
        let trueY = Int(source.size.height - CGFloat(y)) - height
        let rect = NSRect(x: x, y: trueY, width: width, height: height)
        source.draw(at: NSPoint.zero, from: rect, operation: .sourceOut, fraction: 1.0)
        
        image?.unlockFocus()
    }
}
