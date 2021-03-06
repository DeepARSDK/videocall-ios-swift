//
//  ViewController.swift
//  videocall-ios-swift
//
//  Created by Lara Vertlberg on 19/12/2019.
//  Copyright © 2019 Lara Vertlberg. All rights reserved.
//

import UIKit
import DeepAR
import AgoraRtcKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets -

    @IBOutlet weak var switchCameraButton: UIButton!
    
    @IBOutlet weak var masksButton: UIButton!
    @IBOutlet weak var effectsButton: UIButton!
    @IBOutlet weak var filtersButton: UIButton!
    
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var hangUpButton: UIButton!
    
    @IBOutlet weak var arViewContainer: UIView!
    @IBOutlet weak var remoteView: UIView!
    
    private var deepAr: DeepAR!
    private var arView: ARView!
    private var cameraController: CameraController!
    
    // MARK: - Private properties -
    
    private var maskIndex: Int = 0
    private var maskPaths: [String?] {
        return Masks.allCases.map { $0.rawValue.path }
    }
    
    private var effectIndex: Int = 0
    private var effectPaths: [String?] {
        return Effects.allCases.map { $0.rawValue.path }
    }
    
    private var filterIndex: Int = 0
    private var filterPaths: [String?] {
        return Filters.allCases.map { $0.rawValue.path }
    }
    
    private var buttonModePairs: [(UIButton, Mode)] = []
    private var currentMode: Mode! {
        didSet {
            updateModeAppearance()
        }
    }
    
    var agoraKit: AgoraRtcEngineKit!
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeAgoraEngine()
        setupVideo()
        
        setupDeepAR()
        setupHangUpButton()
        addTargets()
        
        buttonModePairs = [(masksButton, .masks), (effectsButton, .effects), (filtersButton, .filters)]
        currentMode = .masks
    }
    
    // MARK: - Private methods -
    
    func initializeAgoraEngine() {
        // init AgoraRtcEngineKit
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: AgoraAppID, delegate: self)
        //agoraKit.setChannelProfile(.liveBroadcasting)
        
    }

    func setupVideo() {
        // In simple use cases, we only need to enable video capturing
        // and rendering once at the initialization step.
        // Note: audio recording and playing is enabled by default.
        agoraKit.enableVideo()
        agoraKit.setExternalVideoSource(true, useTexture: true, pushMode: true)
        
       
        agoraKit.disableAudio()
        
        // Set video configuration
        // Please go to this page for detailed explanation
        // https://docs.agora.io/cn/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_rtc_engine.html#af5f4de754e2c1f493096641c5c5c1d8f
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: AgoraVideoDimension1280x720,
                                                                             frameRate: .fps15,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: .adaptative))
    }
    
    func joinChannel() {
        
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. One token is only valid for the channel name that
        // you use to generate this token.
        
        agoraKit.joinChannel(byToken: nil, channelId: "demoChannel1", info: nil, uid: 0) { [unowned self] (channel, uid, elapsed) -> Void in
            // Did join channel "demoChannel1"
            UIApplication.shared.isIdleTimerDisabled = true
            //self.arView.startFrameOutput(withXmin: 0, xmax: 1, ymin: 0, ymax: 1, scale: 1)
            self.deepAr.startCapture(withOutputWidth: 720, outputHeight: 1280, subframe: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0))
            
            self.remoteView.isHidden = false
            self.arViewContainer.isHidden = false
        }
    }
    
    func leaveChannel() {
        // leave channel and end chat
        arView.stopFrameOutput()
        agoraKit.leaveChannel(nil)
        
        UIApplication.shared.isIdleTimerDisabled = false
        remoteView.isHidden = true
        arViewContainer.isHidden = true
        print("***INFO*** did leave channel")
        
        agoraKit = nil
    }
    
    private func setupDeepAR() {
        self.deepAr = DeepAR()
        self.deepAr.setLicenseKey("your_license_key_here")
        self.deepAr.delegate = self
    }
    
    private func setupARCamera() {
        //let rect = CGRect(x: 0, y: 0, width: 720, height: 1280)
        self.arView = self.deepAr.createARView(withFrame: self.arViewContainer.frame) as! ARView
        self.arView.translatesAutoresizingMaskIntoConstraints = false
        self.arViewContainer.addSubview(self.arView)
        self.arView.leftAnchor.constraint(equalTo: self.arViewContainer.leftAnchor, constant: 0).isActive = true
        self.arView.rightAnchor.constraint(equalTo: self.arViewContainer.rightAnchor, constant: 0).isActive = true
        self.arView.topAnchor.constraint(equalTo: self.arViewContainer.topAnchor, constant: 0).isActive = true
        self.arView.bottomAnchor.constraint(equalTo: self.arViewContainer.bottomAnchor, constant: 0).isActive = true
       
        self.arViewContainer.isHidden = true
       
        self.cameraController = CameraController()
        self.cameraController.deepAR = self.deepAr
        self.cameraController.startCamera()
    }
    
    private func setupHangUpButton() {
        hangUpButton.imageView?.contentMode = .scaleAspectFit
        hangUpButton.setImage(#imageLiteral(resourceName: "call"), for: .selected)
        hangUpButton.setImage(#imageLiteral(resourceName: "end"), for: .normal)
        hangUpButton.isSelected = true
    }
    
    private func addTargets() {
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCameraButton), for: .touchUpInside)
        hangUpButton.addTarget(self, action: #selector(didClickHangUpButton(_:)), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(didTapPreviousButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        masksButton.addTarget(self, action: #selector(didTapMasksButton), for: .touchUpInside)
        effectsButton.addTarget(self, action: #selector(didTapEffectsButton), for: .touchUpInside)
        filtersButton.addTarget(self, action: #selector(didTapFiltersButton), for: .touchUpInside)
    }
    
    private func updateModeAppearance() {
        buttonModePairs.forEach { (button, mode) in
            button.isSelected = mode == currentMode
        }
    }
    
    private func switchMode(_ path: String?) {
        deepAr.switchEffect(withSlot: currentMode.rawValue, path: path)
    }
    
    @objc
    private func didTapSwitchCameraButton() {
        let position: AVCaptureDevice.Position = cameraController.position == .back ? .front : .back
        cameraController.position = position
    }
    
    @objc
    private func didClickHangUpButton(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            leaveChannel()
        } else {
            setupARCamera()
            initializeAgoraEngine()
            joinChannel()
        }
    }
    
    @objc
    private func didTapPreviousButton() {
        var path: String?
        
        switch currentMode! {
        case .effects:
            effectIndex = (effectIndex - 1 < 0) ? (effectPaths.count - 1) : (effectIndex - 1)
            path = effectPaths[effectIndex]
        case .masks:
            maskIndex = (maskIndex - 1 < 0) ? (maskPaths.count - 1) : (maskIndex - 1)
            path = maskPaths[maskIndex]
        case .filters:
            filterIndex = (filterIndex - 1 < 0) ? (filterPaths.count - 1) : (filterIndex - 1)
            path = filterPaths[filterIndex]
        }
        
        switchMode(path)
    }
    
    @objc
    private func didTapNextButton() {
        var path: String?
        
        switch currentMode! {
        case .effects:
            effectIndex = (effectIndex + 1 > effectPaths.count - 1) ? 0 : (effectIndex + 1)
            path = effectPaths[effectIndex]
        case .masks:
            maskIndex = (maskIndex + 1 > maskPaths.count - 1) ? 0 : (maskIndex + 1)
            path = maskPaths[maskIndex]
        case .filters:
            filterIndex = (filterIndex + 1 > filterPaths.count - 1) ? 0 : (filterIndex + 1)
            path = filterPaths[filterIndex]
        }
        
        switchMode(path)
    }
    
    @objc
    private func didTapMasksButton() {
        currentMode = .masks
    }
    
    @objc
    private func didTapEffectsButton() {
        currentMode = .effects
    }
    
    @objc
    private func didTapFiltersButton() {
        currentMode = .filters
    }
}

// MARK: - ARViewDelegate -

extension ViewController: DeepARDelegate {
    func didFinishPreparingForVideoRecording() {}
    
    func didStartVideoRecording() {}
    
    func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("*** NO BUFFER ERROR")
            return
        }

        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12
        videoFrame.time = time
        videoFrame.textureBuf = pixelBuffer
        videoFrame.rotation = 0
        
        agoraKit?.pushExternalVideoFrame(videoFrame)
    }
    
    func didFinishVideoRecording(_ videoFilePath: String!) {}
    
    func recordingFailedWithError(_ error: Error!) {}
    
    func didTakeScreenshot(_ screenshot: UIImage!) {}
    
    func didInitialize() {}
    
    func faceVisiblityDidChange(_ faceVisible: Bool) {
    }
}

extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = remoteView
        // Sets the remote video view
        agoraKit?.setupRemoteVideo(videoCanvas)
    }
    
    
    // first remote video frame
    func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid:UInt, size:CGSize, elapsed:Int) {
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid:UInt, reason:AgoraUserOfflineReason) {
        remoteView.isHidden = true
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted:Bool, byUid:UInt) {
        
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("did occur ***WARNING***, code: \(warningCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("did occur ***ERROR***, code: \(errorCode.rawValue)")
    }
}
