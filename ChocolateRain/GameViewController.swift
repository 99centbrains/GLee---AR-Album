//
//  GameViewController.swift
//  ChocolateRain
//
//  Created by Franky Aguilar on 5/29/16.
//  Copyright (c) 2016 99centbrains. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import Foundation
import AVFoundation
//import CoreLocation
import CoreMotion
import SpriteKit

class GameViewController: UIViewController, AVAudioPlayerDelegate {
    
    var captureSession = AVCaptureSession()
    let movieOutput = AVCaptureMovieFileOutput()
    var previewLayer: AVCaptureVideoPreviewLayer!
    @IBOutlet weak var camPreview: UIView!
    
    @IBOutlet weak var scnView:SCNView!
    var activeInput: AVCaptureDeviceInput!
    var destX:CGFloat  = 0.0
    
    let motionManager = CMMotionManager()
    
    var wave = WaveformView()
    
    var player:AVPlayer!
    
    
    var currentAlbum:Album!
    
    var scene:SCNScene!
    let cameraNode = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.setupSession() {

            self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            self.previewLayer.frame = self.view.bounds
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.view.layer.insertSublayer(self.previewLayer, atIndex: 0)
            
            UIView.animateWithDuration(0.3, delay: 0.5, options: .CurveEaseIn, animations: {
                //self.camPreview.alpha = 1
                }, completion: nil)
            
            self.startSession()
        } else {
            self.showErrorAlert(message: self.localizedString("camera_setup_error"), completion: {
            })
        }
        
        self.view.insertSubview(wave, atIndex: 1)
        wave.frame = self.view.frame
        wave.backgroundColor = UIColor.clearColor()
        
        // create a new scene
        scene = SCNScene()
        
        // create and add a camera to the scene
        cameraNode.camera = SCNCamera()
        cameraNode.pivot = SCNMatrix4MakeTranslation(0, 0, 0)
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 0)
        
        scene.rootNode.addChildNode(cameraNode)
        
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLightTypeAmbient
        ambientLightNode.light!.color = UIColor.darkGrayColor()
        scene.rootNode.addChildNode(ambientLightNode)
        
        createPlanes()

        
        // retrieve the ship node
        
        // ship.position = SCNVector3Make(0,0,0)
        
        //        let spin = CABasicAnimation(keyPath: "rotation")
        //        // Use from-to to explicitly make a full rotation around z
        //        spin.fromValue = NSValue(SCNVector4: SCNVector4(x: 0, y: 0, z: 0, w: 0))
        //        spin.toValue = NSValue(SCNVector4: SCNVector4(x: 0, y: 1, z: 0, w: Float(2 * M_PI)))
        //        spin.duration = 3
        //        spin.repeatCount = .infinity
        //cameraNode.addAnimation(spin, forKey: "spin around")
        
        
        // animate the 3d object
        //ship.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.backgroundColor = UIColor.clearColor()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        //TRACK DEVICE GAZE
        if motionManager.deviceMotionAvailable {
            
            motionManager.deviceMotionUpdateInterval = 0.010
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue(), withHandler: deviceDidMove)
            
        }
        
        
        
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setUpUI()
        setupSession()
        
        
        
    }

    func setupSession() -> Bool {
        
        do {
            
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions:[.MixWithOthers, .DefaultToSpeaker])
            //try AVAudioSession.sharedInstance().setActive(true)
            
        } catch {
            
            print("Cant Share Audio")
            
        }
        
        
        self.captureSession.sessionPreset = AVCaptureSessionPresetMedium
        let camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do {
            let defaultCameraInput = try AVCaptureDeviceInput(device: camera)
            if self.captureSession.canAddInput(defaultCameraInput) {
                self.captureSession.addInput(defaultCameraInput)
                self.activeInput = defaultCameraInput
            }
        } catch let error as NSError {
            print ("Error setting device video input: \(error)")
            return false
        }
        
        if !self.captureSession.canAddOutput(self.movieOutput) {
            print("Unable to add video Output")
            return false
        }
        captureSession.addOutput(self.movieOutput)
        
        
        
//        do {
//            let audioInputer = try AVCaptureDeviceInput(device: AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio))
//            if self.captureSession.canAddInput(audioInputer) {
//                self.captureSession.addInput(audioInputer)
//                self.activeInput = audioInputer
//            
//            }
//        } catch let error as NSError {
//            print ("Error setting device video input: \(error)")
//            return false
//        }
//        
       

        return true
    }
    
    func setUpUI() {
        
    }
    
    func startSession() {
        
        if !self.captureSession.running {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if self.captureSession.running {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.captureSession.stopRunning()
            }
        }
    }

    

    //SCENE KIT ACTION

    func createPlanes(){
        
        
        for i in 0 ..< 3 {
            
            
            self.createNode("cloud.png", orbit: -Float(i) * 90, pos:SCNVector3(x: 0, y: -10, z: 0), zoffset: 30)
            //self.createNode("cloud.png", orbit: -Float(i) * 90, pos:SCNVector3(x: 0, y: -10, z: 0), zoffset: 31)
            
        }
    
        
        //ROTATING CLOUDS
        let superNode = SCNNode()
        for i in 0 ... 10 {
            
            
            let sphere = SCNPlane(width: 20, height: 20)
            let material = SCNMaterial()
            material.doubleSided = true
            material.diffuse.contents = UIImage(named: "cloud.png")
            sphere.materials = [ material ]
            
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.position = SCNVector3(x: 0, y: 10, z: 0)
            sphereNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: 36 * Float(i))
            sphereNode.pivot = SCNMatrix4MakeTranslation(0, 0, -30)
            superNode.addChildNode(sphereNode)

        }
        scene.rootNode.addChildNode(superNode)
        
        superNode.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(0, y: 1, z: 0, duration: 5)))
        
        
        self.setupAlbums()
        
        
        
        
//        let pauseNode = SKLabelNode(text: "PAUSE")
//        self.pauseNode.text = "PAUSE"
//        self.pauseNode.fontSize = 24
//        self.pauseNode.position = CGPoint(x: spriteIndent + 5 , y: size.height - 40)
//        
//        scene.rootNode.ad
    
    }
    
    func setupAlbums(){
    
        let albumArt = ["image_bg_01.jpg",
                        "image_bg_02.jpg",
                        "image_bg_03.jpg",
                        "image_bg_04.jpg",
                        "image_bg_05.jpg",
                        "image_bg_06.jpg",
                        "image_bg_07.jpg",
                        "image_bg_08.jpg",
                        "image_bg_09.jpg"]
        
        let albumSounds = ["01 Would You Be There.mp3",
                           "02 Haunt Me ( marian x gianni ).mp3",
                           "03 HAZE.mp3",
                           "04 Far Away (It's a Wild, Wild World My Love).mp3",
                           "05 SpiderWebs.mp3",
                           "06 Burning Man 1.mp3",
                           "07 Carrots.mp3",
                           "08 Spacey (do dat shit).mp3"
        ]
        
        
        self.buildAlbums(albumArt, sounds: albumSounds)
        
    }
    
    func buildAlbums(image:[String], sounds:[String]){
        
        var albums = [Album]()
        
        for i in 0 ..< sounds.count {
            
            let a = Album()
            a.albumImage = image[i]
            a.albumSong = sounds[i]
            
            albums.append(a)
        
        }
        
        
        self.createAlbumNodes(albums, zoffset: 15)

    }
    
    func createAlbumNodes(album:[Album], zoffset:Float){
        
        let orbit = 180
        
        for i in 0 ..< album.count {
            
            let plane = Album(width: 5, height: 5)
            
            let material = SCNMaterial()
            material.doubleSided = true
            material.diffuse.contents = UIColor.clearColor()
            material.diffuse.contents = UIImage(named: album[i].albumImage)
            
            material.shininess = 1.0
            material.blendMode = SCNBlendMode.Alpha
            plane.materials = [ material ]
            
            plane.albumSong = album[i].albumSong
            plane.albumImage = album[i].albumImage
            
            let sphereNode = SCNNode(geometry: plane)
            sphereNode.position = SCNVector3(x: 0, y: 0, z: 0)
            sphereNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(orbit) + Float(i) / 2)
            sphereNode.pivot = SCNMatrix4MakeTranslation(0, 0, zoffset)
            scene.rootNode.addChildNode(sphereNode)

            
            
        }

    }
 
    
    func createNode(imgName:String, orbit:Float, pos:SCNVector3, zoffset:Float){
        
        let plane = SCNPlane(width: 40, height: 40)
        
        let material = SCNMaterial()
        material.doubleSided = true
        material.diffuse.contents = UIColor.clearColor()
        material.diffuse.contents = UIImage(named: imgName)
        
        material.shininess = 1.0
        material.blendMode = SCNBlendMode.Alpha
        plane.materials = [ material ]
        
        let sphereNode = SCNNode(geometry: plane)
        sphereNode.position = pos
        sphereNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: orbit)
        sphereNode.pivot = SCNMatrix4MakeTranslation(0, 0, zoffset)
        scene.rootNode.addChildNode(sphereNode)
        
        
        
    }
    
    
    func deviceDidMove(motion: CMDeviceMotion?, error: NSError?) {
        
        if let motion = motion {
            
            self.cameraNode.orientation = motion.gaze(atOrientation: UIApplication.sharedApplication().statusBarOrientation)
        }
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(scnView)
        let hitResults = scnView.hitTest(p, options: nil)
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result: AnyObject! = hitResults[0]
            
            print(result.node.geometry!.classForCoder)
            
            
            //let theNode = result.node
            if result.node.geometry!.isKindOfClass(Album) {
                
                let album = result.node.geometry! as! Album
                
                
                if currentAlbum != nil && currentAlbum == album {
                    self.scene.rootNode.removeAllAudioPlayers()
                    currentAlbum = nil
                    return
                }
                
                
                currentAlbum = album
                
                // get its material
                let material = result.node.geometry!.firstMaterial!
                
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    // highlight it
                    SCNTransaction.begin()
                    SCNTransaction.setAnimationDuration(0.5)
                    
                    // on completion - unhighlight
                    SCNTransaction.setCompletionBlock {
                        SCNTransaction.begin()
                        SCNTransaction.setAnimationDuration(0.5)
                        
                        material.emission.contents = UIColor.blackColor()
                        
                        SCNTransaction.commit()
                    }
                    
                    material.emission.contents = UIColor.redColor()

                    SCNTransaction.commit()
                    
//                    self.scene.rootNode.removeAllAudioPlayers()
//                    let audioSource = SCNAudioSource(named: album.albumSong)
//                    self.scene.rootNode.runAction(SCNAction.playAudioSource(audioSource!, waitForCompletion: false), forKey: "AudioPlay")
                    
                    self.playAudioFile(album.albumSong)
                    
                })
   
            }
            
            
        }
    }
    
    func playAudioFile(file:String){
        
        var filename = file.stringByReplacingOccurrencesOfString(".mp3", withString: "")
        let url = NSBundle.mainBundle().URLForResource(filename, withExtension: "mp3")!
        let playerItem = AVPlayerItem( URL:url )
        self.player = AVPlayer(playerItem: playerItem)
        self.player.play()
        
        
        
        
        do {
        
           
            

            
            // Stop playing with a fade out
        } catch {
            print("This sucks")
        }
        
        // Start playing
        
        
        
    
    }
    
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return .AllButUpsideDown
        } else {
            return .All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
//    func setupLocationManager(){
//    
//        self.locationManager = CLLocationManager()
//        
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//        
//        // setup delegate callbacks
//        self.locationManager.delegate = self;
//        
//        // Start location services to get the true heading.
//        self.locationManager.distanceFilter = 1000;
//        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
//        //self.locationManager.startUpdatingHeading()
//        
//        // heading service configuration
//        self.locationManager.headingFilter = 0.1;
//
//        
//    }
//    
    
//    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        
//        let currentHeading = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)
//        print(currentHeading)
//        
//        print(Float(-currentHeading / (180/M_PI)))
//
//    }
//    

    
    
    

}

extension UIViewController {
    
    func localizedString(string: String, usePrefix: Bool = true) -> String {
        var className = ""
        if usePrefix {
            className = NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
        }
        return NSLocalizedString("\(className)_\(string)", comment: "")
    }
    
    func showErrorAlert(message message: String, completion: (() -> Void)? = nil) {
        self.showAlert(title: "Oops...", message: message, completion: completion)
    }
    
    func showAlert(title title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (a) in
            if let completion = completion {
                completion()
            }
        }
        alertController.addAction(OKAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}




class Album:SCNPlane {
    
    var albumImage:String!
    var albumSong:String!
    
}

