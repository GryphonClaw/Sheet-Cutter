//  ViewController.swift
//  Sheet Cutter
//
//  Created by GryphonClaw Software on 2/25/19.
//  Copyright © 2019 GryphonClaw Software. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var xmlDataFileSelector:NSPathControl?
    @IBOutlet var sheetSourceFileSelector:NSPathControl?
    @IBOutlet var outputFolderSelector:NSPathControl?
    
    @IBOutlet var clearDataFileButton:NSButton?
    @IBOutlet var clearSourceFileButton:NSButton?
    @IBOutlet var clearOutputFolderButton:NSButton?
    
    @IBOutlet var saveImagesButton:NSButton?
    
    
    @IBOutlet var processButton:NSButton?
    
    @IBOutlet var spriteCountLabel:NSTextField?
    
    @IBOutlet var tableView:NSTableView?
    
    @IBOutlet var imagePreview:NSImageView?
    
    @IBOutlet var saveProgressView:NSView?
    
    @IBOutlet var saveLabel:NSTextField?
    @IBOutlet var saveProgress:NSProgressIndicator?
    
    var textureAtlas:TextureAtlas = TextureAtlas()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func clearPath(sender:NSButton){
        switch sender.identifier?.rawValue {
        case "data":
            xmlDataFileSelector?.url = nil
        case "source":
            sheetSourceFileSelector?.url = nil
        case "output":
            outputFolderSelector?.url = nil
        default:
            print("uknown tag")
        }
        updateButtons()
    }
    
    func updateButtons() {
        clearDataFileButton?.isEnabled = false
        clearSourceFileButton?.isEnabled = false
        clearOutputFolderButton?.isEnabled = false
        processButton?.isEnabled = false
        saveImagesButton?.isEnabled = false
        
        var enabledCount = 0
        if xmlDataFileSelector?.url != nil {
            clearDataFileButton?.isEnabled = true
            enabledCount += 1
        }
        if sheetSourceFileSelector?.url != nil {
            clearSourceFileButton?.isEnabled = true
            enabledCount += 1
        }
        if outputFolderSelector?.url != nil {
            clearOutputFolderButton?.isEnabled = true
            enabledCount += 1
        }
        
        if enabledCount == 3 {
            processButton?.isEnabled = true
        }
    }
    
    @IBAction func fileSelected(_ sender:NSPathControl) {
        updateButtons()
    }
    
    @IBAction func processImage(_ sender:NSButton) {
        let sourceXMLURL = xmlDataFileSelector?.url
        let sheetURL = sheetSourceFileSelector?.url
        
        //clear the current texture atlas
        textureAtlas = TextureAtlas()
        
        do {
            let xmlString = try String(contentsOf: sourceXMLURL!, encoding: .utf8)
            let xmlData:Data = xmlString.data(using: .utf8)!
            let parser:XMLParser = XMLParser(data: xmlData )
            
            parser.delegate = self
            
            var sheetImage:NSImage = NSImage()
            if let image:NSImage = NSImage(contentsOf: sheetURL!) {
                sheetImage = image
            }
            
            parser.parse()
            textureAtlas.imageSource = sheetImage
            textureAtlas.process()
            spriteCountLabel?.intValue = Int32(Int(textureAtlas.count))
            tableView?.reloadData()
            saveImagesButton?.isEnabled = true
            
        } catch { }
    }
    
    @IBAction func saveImages(_ sender:NSButton) {
        saveProgress?.maxValue = Double(textureAtlas.count)
        let outputPath = outputFolderSelector?.url
        DispatchQueue.global(qos: .background).async {
            for sub in self.textureAtlas.subTexture {
                if let url = outputPath {
                    let fileURL = URL(fileURLWithPath: sub.name, relativeTo: url)
                    let manager = FileManager.default
                    if !manager.fileExists(atPath: fileURL.path) {
                        DispatchQueue.main.async {
                            self.saveProgress?.increment(by: 1.0)
                            let progress = String(Int(self.saveProgress!.doubleValue))
                            self.saveLabel?.stringValue = "Saving Image \(progress) of \(self.textureAtlas.count)"
                        }
                        sub.image?.writePNG(toURL: fileURL)
                    }
                }
            }
        }
    }
}

extension ViewController:XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "TextureAtlas" {
            if let path = attributeDict["imagePath"] {
                textureAtlas.imagePath = path
            }
        }
        else if elementName == "SubTexture" {
            var subTexture:SubTexture = SubTexture()
            do {
                if let name:String = attributeDict["name"] {
                    subTexture.name = name
                }
                if let v = attributeDict["x"] {
                    if let x = Int(v) {
                        subTexture.x = x
                    }
                }
                if let v = attributeDict["y"] {
                    if let y = Int(v) {
                        subTexture.y = y
                    }
                }
                if let w = attributeDict["width"] {
                    if let width = Int(w) {
                        subTexture.width = width
                    }
                }
                if let h = attributeDict["height"] {
                    if let height = Int(h) {
                        subTexture.height = height
                    }
                }
                textureAtlas.subTexture.append(subTexture)
            }
        }
    }
}

extension ViewController:NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let row = tableView?.selectedRow {
            if row == -1 {
                //cleared the selection so lets show the source image
                imagePreview?.image = textureAtlas.imageSource
            }
            else {
                imagePreview?.image = textureAtlas.subTexture[row].image
            }
        }
    }
}

extension ViewController:NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return textureAtlas.subTexture.count
    }
    
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        let cell = NSCell(textCell: textureAtlas.subTexture[row].name)
        cell.title = textureAtlas.subTexture[row].name
        return cell
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellID = NSUserInterfaceItemIdentifier(rawValue:"Cell")
        if let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = textureAtlas.subTexture[row].name
            return cell
        }
        return NSTableCellView()
    }
    
    
}
