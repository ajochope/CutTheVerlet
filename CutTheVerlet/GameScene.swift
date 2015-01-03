//
//  GameScene.swift
//  CutTheVerlet
//
//  Created by Nick Lockwood on 07/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

import SpriteKit
import AVFoundation

private var backgroundMusicPlayer: AVAudioPlayer!

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    /*
    
    properties will store references to the main actors in the scene: 
    the crocodile 
    and the prize (pineapple).
    private, because they won’t be accessed outside of the scene itself,
    and it’s always good practice to keep your class data private 
    unless there’s a good reason to be directly visible to other classes.
     
    type for these properties has been defined as SKSpriteNode!. 
    The “!” means that these are implicitly unwrapped optionals, 
    which tells Swift that they don’t need to be initialized right away,
    but that we confident that they won’t be nil when we try to access them
    
    */
    private var crocodile: SKSpriteNode!
    private var prize: SKSpriteNode!
    private var sliceSoundAction: SKAction!
    private var splashSoundAction: SKAction!
    private var nomNomSoundAction: SKAction!
    private var levelOver = false
    private var ropeCut = false

    override func didMoveToView(view: SKView) {
        
        setUpPhysics()
        setUpScenery()
        setUpPrize()
        setUpRopes()
        setUpCrocodile()
        
        setUpAudio()
    }
    
    //MARK: Level setup
    
    private func setUpPhysics() {
        /*
        
        Sprite Kit makes use of iOS’ built-in physics engine 
        (which, open-source Box 2D physics engine running behind the scenes).
        Apple has fully encapsulated the library in a Cocoa wrapper, 
        so you won’t need to use C++ to interact with it.
        
        SKPhysicsContactDelegate protocol. Fix that by adding that protocol to the class definition
        gravity and speed values actually match the defaults for their respective properties
        */
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVectorMake(0.0,-9.8)
        physicsWorld.speed = 1.0
    }
    
    private func setUpScenery() {
        
        /*
        anchorPoint property uses the unit coordinate system, where:
        
        (0,0) represents the bottom-left corner of the sprite image
        (1,1) represents the top-right corner
        
        always measured from 0 to 1, these coordinates are independent 
        of the image dimensions or aspect ratio
        
        */

        
        let background = SKSpriteNode(imageNamed: BackgroundImage)
        // changed the anchorPoint of the background from the default value of (0.5, 0.5) to (0, 1). 
        // This means that it is positioned relative to the top-left corner of the sprite image, 
        // instead of its center, which is a bit easier to work
        background.anchorPoint = CGPointMake(0, 1)
        background.position = CGPointMake(0, size.height)
        background.zPosition = Layer.Background
        background.size = CGSize(width: self.view!.bounds.size.width, height:self.view!.bounds.size.height)
        addChild(background)
        
        let water = SKSpriteNode(imageNamed: WaterImage)
        // set the anchorPoint to (0, 0), which makes it easier to align with the bottom of the background image.
        water.anchorPoint = CGPointMake(0, 0)
        water.position = CGPointMake(0, size.height - background.size.height)
        water.zPosition = Layer.Foreground
        water.size = CGSize(width: self.view!.bounds.size.width, height: self.view!.bounds.size.height * 0.2139)
        
        addChild(water)

    }
    
    private func setUpPrize() {
        
        /*
        pineapple sprite uses a physics body. 
        we want the pineapple to fall and bounce around realistically.
        Instead of merely setting dynamic = true though (which would be redundant anyway, since that’s the default), 
        it’s set to the constant PrizeIsDynamicsOnStart, set earlier Constants.swift.
        
        
        */
        
        prize = SKSpriteNode(imageNamed: PrizeImage)
        //prize.position = CGPointMake(size.width * 0.5, size.height * 0.7)
        
        prize.position = CGPointMake(171.87234497070313, 389.350830078125)
        prize.zPosition = Layer.Prize
        
        prize.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: PrizeImage), size: prize.size)
        prize.physicsBody?.categoryBitMask = Category.Prize
        prize.physicsBody?.collisionBitMask = Category.Prize | Category.Crocodile
        prize.physicsBody?.contactTestBitMask = Category.Rope
        prize.physicsBody?.dynamic = PrizeIsDynamicsOnStart
        
        addChild(prize)

    }
    
    //MARK: Rope methods
    
    private func setUpRopes() {
        // load rope data
        /*
        loads the rope data from a property list at the RopeData.plist file
        (inside Resources/Data, the file contains an array of dictionaries, 
        each containing a relAnchorPoint and length
        
        */
        
        let dataFile = NSBundle.mainBundle().pathForResource(RopeDataFile, ofType: nil)!
        let ropes = NSArray(contentsOfFile: dataFile) as [NSDictionary]
        
        // add ropes
        /*
        
        loop iterates over the indexes in the array.
        The reason for iterating over the indexes instead of 
        just the array objects is that we need the index value 
        in order to generate a unique name string for each rope. 
        This will be important later.
        
        */

        for i in 0..<ropes.count {
            
            // create rope
            let ropeData = ropes[i] as NSDictionary
            let length = Int(ropeData["length"] as NSNumber) * Int(UIScreen.mainScreen().scale)
            let relAnchorPoint = CGPointFromString(ropeData["relAnchorPoint"] as String)
            let anchorPoint = CGPoint(x: relAnchorPoint.x * self.view!.bounds.size.width,
                y: relAnchorPoint.y * self.view!.bounds.size.height)
            let rope = RopeNode(length: length, anchorPoint: anchorPoint, name: "\(i)")
            
            // add to scene
            rope.addToScene(self)
            

            // connect the other end of the rope to the prize
            rope.attachToPrize(prize)
        }
    }
    
    //MARK: Croc methods
    
    private func setUpCrocodile() {
        /*
        
        constants you set up earlier:
        CrocMouthClosedImage 
        Layer.Crocodile
        
        sets the position of the crocodile node relative to the scene bounds.
        
        zPosition to place the crocodile node on top of the background. 
        By default, Sprite Kit will layer nodes based on the order 
        in which they’re added to their parent, 
        but you can control the ordering yourself by providing a different zPosition.
        
        croc has an SKPhysicsBody, which means it can interact physically with other objects in the world.
        This will be useful later for detecting when the pineapple lands in its mouth.
        
        croc to get knocked over, or fall off the bottom of the screen though,
        set dynamic = false 
        which prevents it from being affected by physical forces.
        
        category bitmask defines a collision group for the sprite,
        collision bitmask is used for modelling realistic collisions, cero value -> do not want the property
        contact bitmask defines which other groups this sprite can collide with.
        
        */
        
        crocodile = SKSpriteNode(imageNamed: CrocMouthClosedImage)
        crocodile.position = CGPointMake(size.width * 0.75, size.height * 0.312)
        crocodile.zPosition = Layer.Crocodile
        /*
        
        In iOS 8, Sprite Kit added the option to specify the collision shape using a texture image.
        Sprite Kit automatically uses this image to generate a collision detection polygon
        that closely matches the desired shape.
        in this case, by using a separate mask image you can finely tune the collidable area to improve the gameplay
        
        */
        crocodile.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: CrocMaskImage), size: crocodile.size)
        crocodile.physicsBody?.categoryBitMask = Category.Crocodile
        crocodile.physicsBody?.collisionBitMask = Category.Prize | Category.Crocodile
        crocodile.physicsBody?.contactTestBitMask = Category.Prize
        crocodile.physicsBody?.dynamic = false
        
        addChild(crocodile)
        
        animateCrocodile()
    }
    
    private func animateCrocodile() {
        /*
        array of SKTexture frames which you then animate using SKActions
        
        SKAction.sequence() constructor creates a sequence of actions from an array.
        In this case, the texture animation is combined in sequence with 
        a randomly-chosen delay period between 2 and 4 seconds.
        
        sequence action is wrapped in a repeatActionForever() action, 
        so that it will repeat indefinitely for the duration of the level.
        It is then run on the crocodile node using the node’s runAction(action:) method.
        
        */
        
        
        let frames = [
            SKTexture(imageNamed: CrocMouthClosedImage),
            SKTexture(imageNamed: CrocMouthOpenImage),
        ]
        
        let duration = 2.0 + drand48() * 2.0
        
        let move = SKAction.animateWithTextures(frames, timePerFrame:0.25)
        let wait = SKAction.waitForDuration(duration)
        let rest = SKAction.setTexture(frames[0])
        let sequence = SKAction.sequence([wait, move, wait, rest])
        
        crocodile.runAction(SKAction.repeatActionForever(sequence))
    }
    
    private func runNomNomAnimationWithDelay(delay: NSTimeInterval) {
        //crocodile.removeAllActions()
        
        let openMouth = SKAction.setTexture(SKTexture(imageNamed: CrocMouthOpenImage))
        let wait = SKAction.waitForDuration(delay)
        let closeMouth = SKAction.setTexture(SKTexture(imageNamed: CrocMouthClosedImage))
        let sequence = SKAction.sequence([openMouth, wait, closeMouth])
        
        crocodile.runAction(sequence)
        
        animateCrocodile()
        
    }
    
    private func runFadePriceSequence(){
        // fade the pineapple away
        let shrink = SKAction.scaleTo(0, duration: 0.1)
        let removeNode = SKAction.removeFromParent()
        let sequence = SKAction.sequence([shrink, removeNode])
        prize.runAction(sequence)
    }
    
    // ---- Special Effects ----
    
    /**
    * Colorizes the node for a brief moment and then fades back to
    * the original color.
    */
    private func flashSpriteNode(spriteNode: SKSpriteNode, withColor color: SKColor) {
        
        let action = SKAction.sequence([
            SKAction.colorizeWithColor(color, colorBlendFactor: 1.0, duration: 0.025),
            SKAction.waitForDuration(0.05),
            SKAction.colorizeWithColorBlendFactor(0.0, duration:0.1)])
        
        spriteNode.runAction(action)
    }

    
    
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        runAction(sliceSoundAction)
        runNomNomAnimationWithDelay(0.1)
        ropeCut = false
    }
    
    //MARK: Touch handling
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {

        for touch in touches {
            
            let startPoint = touch.locationInNode(self)
            let endPoint = touch.previousLocationInNode(self)
            
            // check if rope cut
            scene?.physicsWorld.enumerateBodiesAlongRayStart(
                startPoint,
                end: endPoint,
                usingBlock: { (body, point, normal, stop) -> Void in
                
                self.checkIfRopeCutWithBody(body)
                }
            )
            
            // produce some nice particles
            let emitter = SKEmitterNode(fileNamed: "Particle.sks")
            emitter.position = startPoint
            emitter.zPosition = Layer.Rope
            addChild(emitter)
        }
    }
    

    
    //MARK: Game logic
    
    override func update(currentTime: CFTimeInterval) {
        if levelOver {
            return
        }
        
        if prize.position.y <= 0 {
            levelOver = true
            runAction(splashSoundAction)
            
            let transitions = [
                SKTransition.doorsOpenHorizontalWithDuration(1.0),
                SKTransition.doorsOpenVerticalWithDuration(1.0),
                SKTransition.doorsCloseHorizontalWithDuration(1.0),
                SKTransition.doorsCloseVerticalWithDuration(1.0),
                SKTransition.flipHorizontalWithDuration(1.0),
                SKTransition.flipVerticalWithDuration(1.0),
                SKTransition.moveInWithDirection(.Left, duration:1.0),
                SKTransition.pushWithDirection(.Right, duration:1.0),
                SKTransition.revealWithDirection(.Down, duration:1.0),
                SKTransition.crossFadeWithDuration(1.0),
                SKTransition.fadeWithColor(UIColor.darkGrayColor(), duration:1.0),
                SKTransition.fadeWithDuration(1.0),
            ]
            
            // transition to next level
            let randomIndex = arc4random_uniform(UInt32(transitions.count))
            switchToNewGameWithTransition(transitions[Int(randomIndex)])
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        if levelOver {
            return
        }
        
        if ((contact.bodyA.node == crocodile && contact.bodyB.node == prize)||(contact.bodyA.node == prize && contact.bodyB.node == crocodile)){
            
                levelOver = true
            
                runFadePriceSequence()
                flashSpriteNode(crocodile, withColor: SKColor.greenColor())
            
                runNomNomAnimationWithDelay(0.2)
                runAction(nomNomSoundAction)
            
            // transition to next level
            switchToNewGameWithTransition(SKTransition.doorwayWithDuration(1.0))
            
        }
    }
    
    private func checkIfRopeCutWithBody(body: SKPhysicsBody) {
        
        if ropeCut && !CanCutMultipleRopesAtOnce {
            return
        }
        
        let node = body.node!
        
        // if it has a name it must be a rope node
        if let name = node.name {
            
            //enable prize dynamics
            prize.physicsBody?.dynamic = true
            
            // cut the rope
            node.removeFromParent()
            
            // fade out all nodes matching name
            self.enumerateChildNodesWithName(name, usingBlock: { (node, stop) in
                
                let fadeAway = SKAction.fadeOutWithDuration(0.25)
                let removeNode = SKAction.removeFromParent()
                let sequence = SKAction.sequence([fadeAway, removeNode])
                
                node.runAction(sequence)
            })
            ropeCut = true
        }
    }
    
    private func switchToNewGameWithTransition(transition: SKTransition) {
        
        let delay = SKAction.waitForDuration(1)
        let transition = SKAction.runBlock({
            let scene = GameScene(size: self.size)
            self.view?.presentScene(scene, transition: transition)
        })
        
        runAction(SKAction.sequence([delay, transition]))
        
    }
    
    //MARK: Audio
    
    private func setUpAudio() {
        
        if (backgroundMusicPlayer == nil) {
            let backgroundMusicURL = NSBundle.mainBundle().URLForResource(BackgroundMusicSound, withExtension: nil)
            backgroundMusicPlayer = AVAudioPlayer(contentsOfURL: backgroundMusicURL, error:nil)
            backgroundMusicPlayer.numberOfLoops = -1
        }
        
        if (!backgroundMusicPlayer.playing) {
            backgroundMusicPlayer.play()
        }
        
        sliceSoundAction = SKAction.playSoundFileNamed(SliceSound, waitForCompletion: false)
        splashSoundAction = SKAction.playSoundFileNamed(SplashSound, waitForCompletion: false)
        nomNomSoundAction = SKAction.playSoundFileNamed(NomNomSound, waitForCompletion: false)
    }
}
