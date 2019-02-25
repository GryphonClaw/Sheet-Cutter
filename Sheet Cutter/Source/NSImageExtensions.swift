//  NSImageExtensions.swift
//  Sheet Cutter
//
//  Created by GryphonClaw Software on 2/25/19.
//  Copyright © 2019 GryphonClaw Software. All rights reserved.
//

import Cocoa

//The following code is from a Stackoverflow answer located at the following URL:
//https://stackoverflow.com/a/45042611/4902036
public extension NSImage {
    public func writePNG(toURL url: URL) {
        
        guard let data = tiffRepresentation,
            let rep = NSBitmapImageRep(data: data),
            let imgData = rep.representation(using: .png, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)]) else {
                
                Swift.print("\(self) Error Function '\(#function)' Line: \(#line) No tiff rep found for image writing to \(url)")
                return
        }
        
        do {
            try imgData.write(to: url)
        }catch let error {
            Swift.print("\(self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
        }
    }
}
