//
//  Constants.swift
//  CutTheVerlet
//
//  Created by Nick Lockwood on 14/09/2014.
//  Copyright (c) 2014 Nick Lockwood. All rights reserved.
//

/*

Global constants help to make your code more readable
and maintainable by avoiding repetition of hard-coded 
strings or magic numbers throughout your codebase

things like sprite image names, sound files, 
the z-order or zPosition of your sprites 
and the category defined for each sprite

*/

import UIKit

//MARK: constants

// these constants are declared outside of any class,
// they are globally available anywhere in the program.
let BackgroundImage = "Background"
let GroundImage = "Ground"
let WaterImage = "Water"
let RopeTextureImage = "RopeTexture"
let RopeHolderImage = "RopeHolder"
let CrocMouthClosedImage = "CrocMouthClosed"
let CrocMouthOpenImage = "CrocMouthOpen"
let CrocMaskImage = "CrocMask"
let PrizeImage = "Pineapple"
let PrizeMaskImage = "PineappleMask"

let BackgroundMusicSound = "CheeZeeJungle.caf"
let SliceSound = "Slice.caf"
let SplashSound = "Splash.caf"
let NomNomSound = "NomNom.caf"

let RopeDataFile = "RopeData.plist"

// Declares two structs, each containing a bunch of 
// static CGFloat and UInt32 properties respectively. 
// Use these to specify the zPosition and collision category of a sprite when you add it to the scene

// In Swift, enum values are unique types in their own right, 
// and to use them as a number requires them to be converted using toRaw(), 
// which makes them unwieldy to use for the purpose intended here. 
// Structs containing static properties are a better way to create groups of numeric constants in Swift
struct Layer {
    static let Background: CGFloat = 0
    static let Crocodile: CGFloat = 1
    static let Rope: CGFloat = 1
    static let Prize: CGFloat = 2
    static let Foreground: CGFloat = 3
}

struct Category {
    static let Crocodile: UInt32 = 1
    static let RopeHolder: UInt32 = 2
    static let Rope: UInt32 = 4
    static let Prize: UInt32 = 8
}

//MARK: game configuration

// In addition to avoiding “magic” values,
// constants also allow you to easily make certain parts of the game configurable.
// Constants give a simple way to flip a switch to swap between different approaches
// and see which works best in practice.

// Swift doesn’t support macros yet though (and may never), 
// so you’ll have to use ordinary if statements to enable and disable code at runtime.

let PrizeIsDynamicsOnStart = false
let CanCutMultipleRopesAtOnce = false
