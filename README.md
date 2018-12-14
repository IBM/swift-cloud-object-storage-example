[![Build Status](https://travis-ci.com/IBM/swift-cloud-object-storage-example.svg?branch=master)](https://travis-ci.com/IBM/swift-cloud-object-storage-example)

# About Code Pattern
In this Code Pattern, we will look at comparing downloading Atlantic Hurricane Season images from a traditional server ([Wikipedia](https://en.wikipedia.org/wiki/Atlantic_hurricane_season ) in this case) and Cloud Object Storage.

# Steps for Setting up Environment

## Carthage

1. Run `brew install carthage` if you do not have Carthage already
2. Run `carthage update --platform iOS` in the directory where the Cartfile is located
3. Contact Max Shapiro on Slack or email for API Key and IBM Service Instance ID to include in a `Data.plist` file
4. Build and run the app on the simulator

## CocoaPods 

1. Run `sudo gem install cocoapods` if you do not have CocoaPods already
2. Run `pod install` in the directory where the Podfile is located
3. Contact Max Shapiro on Slack or email for API Key and IBM Service Instance ID to include in a `Data.plist` file
4. Build and run the app on the simulator

# Notes about Interacting with the App
* Pressing the `URL` button will start the downloading of images from a traditional server. In this case that is Wikipedia.
* Pressing the `COS No Zip` button will start the downloading of images from Cloud Object Storage
* Pressing the `COS Zip` button will start the downloading of the zip file containing the images from Cloud Object Storage
* Pressing the Clear button will clear the images that have been downloaded.
> NOTE: You must wait for one test to finish downloading and displaying the images before beginning another test. Info about the progress of downloads can be found in the console.
