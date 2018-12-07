# About Code Pattern
In this Code Pattern, we will look at comparing downloading Atlantic Hurricane Season images from a traditional server ([Wikipedia](https://en.wikipedia.org/wiki/Atlantic_hurricane_season ) in this case) and Cloud Object Storage.

# Steps for Setting up Environment

1. Run `brew install carthage` if you do not have Carthage already
2. Run `carthage update` in the direcotry where the Cartfile is located
3. Open the Xcode project and copy the 	`Alamofire` and `Kanna` framework files from `Carthage/Build/iOS` to the Xcode project. (Can be done by clicking and dragging them into the Xcode project navigator)
4. Build and run the app on the simulator

# Notes about Interacting with the App
* Pressing the URL button will start the downloading of images from a traditional server. In this case that is Wikipedia.
* Pressing the COS button will start the downloading of images from Cloud Object Storage
* Pressing the Clear button will clear the images that have been downloaded.
> NOTE: You must wait for one test to finish downloading and displaying the images before beginning another test.
