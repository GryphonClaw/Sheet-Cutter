//  ViewController.swift
//  Sheet Cutter
//
//  Created by GryphonClaw Software on 2/25/19.
//  Copyright © 2019 GryphonClaw Software. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    //The following 3 Outlets reference our data URLs
    @IBOutlet var xmlDataFileSelector:NSPathControl?
    @IBOutlet var sheetSourceFileSelector:NSPathControl?
    @IBOutlet var outputFolderSelector:NSPathControl?
    
    //The following 3 Outlets reference our clear buttons
    @IBOutlet var clearDataFileButton:NSButton?
    @IBOutlet var clearSourceFileButton:NSButton?
    @IBOutlet var clearOutputFolderButton:NSButton?
    
    //Save image button
    @IBOutlet var saveImagesButton:NSButton?
    
    //Process button (labeled 'Cut' in our UI)
    @IBOutlet var processButton:NSButton?
    //Reference to our count label
    @IBOutlet var spriteCountLabel:NSTextField?
    //Our table view that shows the names of our sprites
    @IBOutlet var tableView:NSTableView?
    //Reference to the image preview Image Well in the UI
    @IBOutlet var imagePreview:NSImageView?
    //Reference our generic View that contains our progress UI
    @IBOutlet var saveProgressView:NSView?
    //Reference to the save label
    @IBOutlet var saveLabel:NSTextField?
    //Reference to the Save Progress Indicator
    @IBOutlet var saveProgress:NSProgressIndicator?
    
    //The main Texture Atlas data structure
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
    
    //Clears the appropriate File Selector UI
    @IBAction func clearPath(sender:NSButton) {
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
    
    //Updates the buttons in the UI
    func updateButtons() {
        //Disable all buttons first
        clearDataFileButton?.isEnabled = false
        clearSourceFileButton?.isEnabled = false
        clearOutputFolderButton?.isEnabled = false
        processButton?.isEnabled = false
        //Disable the Save button, it will be enabled in another location if all the conditions are right
        saveImagesButton?.isEnabled = false
        
        //this helps us keep track of whether or not we should enable the process button
        var enabledCount = 0
        if xmlDataFileSelector?.url != nil {
            //we have an XML file selected, enable the associated clear button
            clearDataFileButton?.isEnabled = true
            enabledCount += 1
        }
        if sheetSourceFileSelector?.url != nil {
            //we have a Source File (sprite sheet image) selected, enable the associated clear button
            clearSourceFileButton?.isEnabled = true
            enabledCount += 1
        }
        if outputFolderSelector?.url != nil {
            //we have an Output folder selected, enable the associated clear button
            clearOutputFolderButton?.isEnabled = true
            enabledCount += 1
        }
        
        if enabledCount == 3 {
            //All 3 of the required items have been selected, enable the Process Button
            processButton?.isEnabled = true
        }
    }
    
    //All of our PathControls call this function when clicked
    @IBAction func fileSelected(_ sender:NSPathControl) {
        updateButtons()
    }
    
    @IBAction func processImage(_ sender:NSButton) {
        let sourceXMLURL = xmlDataFileSelector?.url
        let sheetURL = sheetSourceFileSelector?.url
        
        //clear the current texture atlas
        textureAtlas = TextureAtlas()
        
        do {
            //load the Source XML file as a string
            let xmlString = try String(contentsOf: sourceXMLURL!, encoding: .utf8)
            let xmlData:Data = xmlString.data(using: .utf8)!
            let parser:XMLParser = XMLParser(data: xmlData )
            
            //Set the delegate of our parser to self so we can process the XML when we call parse()
            parser.delegate = self
            
            //May be unnecessary but create the sheet image as a blank image
            var sheetImage:NSImage = NSImage()
            //attempt to load the source Sheet Image
            if let image:NSImage = NSImage(contentsOf: sheetURL!) {
                //if it's loaded, assign it to your sheet image variable
                sheetImage = image
            }
            
            //Parse our XML data file
            parser.parse()
            //set our property imageSource equal to the sheet image loaded from earlier
            textureAtlas.imageSource = sheetImage
            //Process the data loaded from the parser
            textureAtlas.process()
            //update our UI, this just tells us how many sub textures there are
            spriteCountLabel?.intValue = Int32(Int(textureAtlas.count))
            //Reload the table view to reflect the list of textures
            tableView?.reloadData()
            //We've now processed the XML Data file and cut the Sprite Sheet into sub textures/images, lets enable the save button
            saveImagesButton?.isEnabled = true
            
        } catch { }
    }
    
    @IBAction func saveImages(_ sender:NSButton) {
        //set the maximum value of the progress indicator to our sub texture count
        saveProgress?.maxValue = Double(textureAtlas.count)
        //reset the current value to 0.0
        saveProgress?.doubleValue = 0.0
        //the output path. This is where all the images are going to be saved
        let outputPath = outputFolderSelector?.url
        //Run this code on a background thread so we dont lock up our UI
        DispatchQueue.global(qos: .background).async {
            //Loop through our sub textures
            for sub in self.textureAtlas.subTexture {
                //Make sure our output path is a valid URL (unwrap it)
                if let url = outputPath {
                    //Create our Sub Texture File Path/URL based on the output path URL
                    let fileURL = URL(fileURLWithPath: sub.name, relativeTo: url)
                    //Get a file manager
                    let manager = FileManager.default
                    //If our file doesn't exist, lets create it.
                    if !manager.fileExists(atPath: fileURL.path) {
                        //To update UI elements we must do so on the main thread
                        DispatchQueue.main.async {
                            //Update our save progress indicator by 1
                            self.saveProgress?.increment(by: 1.0)
                            //convert the current value of the progress indicator to an Int, then a String
                            let progress = String(Int(self.saveProgress!.doubleValue))
                            //Update our Status label to show a text version of our progress
                            self.saveLabel?.stringValue = "Saving Image \(progress) of \(self.textureAtlas.count)"
                        }
                        //Save the image to our file URL
                        sub.image?.writePNG(toURL: fileURL)
                    }
                }
            }
        }
    }
}

extension ViewController:XMLParserDelegate {
    //Parses the passed in data, this is called a lot
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        //This is our root node and should contain the path to our sprite sheet
        if elementName == "TextureAtlas" {
            //check to see if imagePath property exists if so, assing the path to our TextureAtlas data structure
            if let path = attributeDict["imagePath"] {
                textureAtlas.imagePath = path
            }
        }
        else if elementName == "SubTexture" {//We have a SubTexture lets process it
            
            //crteate a new local SubTexture structure
            var subTexture:SubTexture = SubTexture()
            do {
                //if there is a Property named Name assign it to our SubTexture
                if let name:String = attributeDict["name"] {
                    subTexture.name = name
                }
                //if there is a Property named X assign it to our SubTexture
                if let v = attributeDict["x"] {
                    if let x = Int(v) {
                        subTexture.x = x
                    }
                }
                //if there is a Property named Y assign it to our SubTexture
                if let v = attributeDict["y"] {
                    if let y = Int(v) {
                        subTexture.y = y
                    }
                }
                //if there is a Property named width assign it to our SubTexture
                if let w = attributeDict["width"] {
                    if let width = Int(w) {
                        subTexture.width = width
                    }
                }
                //if there is a Property named height assign it to our SubTexture
                if let h = attributeDict["height"] {
                    if let height = Int(h) {
                        subTexture.height = height
                    }
                }
                //Add this texture to our TextureAtlas
                textureAtlas.subTexture.append(subTexture)
            }
        }
    }
}

extension ViewController:NSTableViewDelegate {
    //Should we be able to select the current row? For us and our uses, yes, return true on everything.
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
    
    //This allows us to update the Image preview when the selection changes. Also checks to see if the user
    //deselected a row, if so, show the source sprite sheet
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
    //Tells our table how many rows it has
    func numberOfRows(in tableView: NSTableView) -> Int {
        return textureAtlas.subTexture.count
    }
    
    //This is not
    func tableView(_ tableView: NSTableView, dataCellFor tableColumn: NSTableColumn?, row: Int) -> NSCell? {
        let cell = NSCell(textCell: textureAtlas.subTexture[row].name)
        cell.title = textureAtlas.subTexture[row].name
        return cell
    }
    
    //Creates the Table Cell view for display in our table and returns it.
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        //Our cell ID as defined in the storyboard
        let cellID = NSUserInterfaceItemIdentifier(rawValue:"Cell")
        //Make the cell from our cellID
        if let cell = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTableCellView {
            //Set the textField value to the name of our subTexture's name
            cell.textField?.stringValue = textureAtlas.subTexture[row].name
            return cell
        }
        return NSTableCellView()
    }
    
    
}
