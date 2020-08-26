# videocall-ios-swift

This example demonstrates how to use DeepAR SDK to add face filters and masks to your video call using [Agora](https://www.agora.io/) video calling SDK

To run the example

* Go to https://developer.deepar.ai, sign up, create the project and the iOS app, copy the license key and paste it to ViewController.swift (instead of your_license_key_goes_here string)
* Download the SDK from https://developer.deepar.ai and copy the DeepAR.framework into videocall-ios-swift/Frameworks folder
* Sign up on [Agora](https://www.agora.io/), get the App Id, [download](https://docs.agora.io/en/Agora%20Platform/downloads) the Video Call SDK (AgoraRtcKit.framework) and put it in the videocall-ios-swift/Frameworks folder
* In ViewController.swift, replace your_agora_app_id_here with your agora app id
* Run the app on 2 devices and initiate the call on both of them. You should be streaming from one device to another using Agora Video SDK and DeepAR.