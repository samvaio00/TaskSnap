import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    @StateObject private var camera = CameraModel()
    @State private var showPhotoPicker = false
    @State private var usePhotoLibrary = false
    
    var body: some View {
        ZStack {
            // Camera Preview or Photo Library
            if usePhotoLibrary {
                PhotoPickerView(capturedImage: $capturedImage, isPresented: $isPresented)
            } else if camera.isReady, let session = camera.captureSession {
                CameraPreview(session: session)
                    .ignoresSafeArea()
            } else {
                // Loading or error state
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    if camera.showPermissionAlert {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Camera Access Required")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text("Please enable camera access in Settings to take photos.")
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Use Photo Library Instead") {
                                usePhotoLibrary = true
                            }
                            .foregroundColor(.accentColor)
                            .padding()
                        }
                    } else if let error = camera.errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            Text("Camera Error")
                                .font(.title2)
                                .foregroundColor(.white)
                            Text(error)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Use Photo Library Instead") {
                                usePhotoLibrary = true
                            }
                            .foregroundColor(.accentColor)
                            .padding()
                        }
                    } else {
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            Text("Starting Camera...")
                                .foregroundColor(.white)
                            
                            // Timeout fallback button
                            Button("Use Photo Library Instead") {
                                usePhotoLibrary = true
                            }
                            .foregroundColor(.accentColor)
                            .padding()
                        }
                    }
                }
            }
            
            // Overlay controls (only show for camera, not photo library)
            if !usePhotoLibrary {
                VStack {
                    // Top Bar
                    HStack {
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        Spacer()
                        
                        // Photo library toggle button
                        Button {
                            usePhotoLibrary = true
                        } label: {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Bottom Controls
                    if camera.isReady {
                        HStack(spacing: 60) {
                            Spacer()
                            
                            // Capture Button
                            Button {
                                camera.capturePhoto { image in
                                    capturedImage = image
                                    isPresented = false
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 80, height: 80)
                                    
                                    Circle()
                                        .stroke(Color.white, lineWidth: 4)
                                        .frame(width: 70, height: 70)
                                }
                            }
                            
                            // Flip Camera Button
                            Button {
                                camera.switchCamera()
                            } label: {
                                Image(systemName: "camera.rotate")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            print("CameraView appeared")
            // Check if we're on simulator
            #if targetEnvironment(simulator)
            print("Running on simulator")
            #endif
            camera.checkPermissions()
        }
        .onDisappear {
            print("CameraView disappeared")
            camera.stopSession()
        }
    }
}

// MARK: - Photo Picker View (Fallback)
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        
        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider else {
                parent.isPresented = false
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        self.parent.capturedImage = image as? UIImage
                        self.parent.isPresented = false
                    }
                }
            } else {
                parent.isPresented = false
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewControllerRepresentable {
    let session: AVCaptureSession
    
    func makeUIViewController(context: Context) -> CameraPreviewViewController {
        let controller = CameraPreviewViewController()
        controller.session = session
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraPreviewViewController, context: Context) {
        uiViewController.session = session
    }
}

class CameraPreviewViewController: UIViewController {
    var session: AVCaptureSession? {
        didSet {
            if oldValue !== session {
                configurePreview()
            }
        }
    }
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurePreview()
    }
    
    private func configurePreview() {
        guard let session = session else { return }
        
        previewLayer?.removeFromSuperlayer()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        previewLayer.connection?.videoOrientation = .portrait
        view.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}

// MARK: - Camera Model
class CameraModel: NSObject, ObservableObject {
    @Published var isReady = false
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?
    
    private(set) var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var completion: ((UIImage?) -> Void)?
    
    func checkPermissions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func setupCamera() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let session = AVCaptureSession()
            
            // Use lower quality for simulator
            #if targetEnvironment(simulator)
            session.sessionPreset = .vga640x480
            #else
            session.sessionPreset = .photo
            #endif
            
            session.beginConfiguration()
            
            // Discover available devices
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                mediaType: .video,
                position: .unspecified
            )
            
            let availableDevices = discoverySession.devices
            
            // Get video device
            let videoDevice: AVCaptureDevice?
            
            if availableDevices.isEmpty {
                // Fallback for simulator
                videoDevice = AVCaptureDevice.default(for: .video)
            } else {
                videoDevice = availableDevices.first
            }
            
            guard let device = videoDevice else {
                DispatchQueue.main.async {
                    self.errorMessage = "No camera device found"
                }
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Cannot add video input"
                    }
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error configuring camera: \(error.localizedDescription)"
                }
                return
            }
            
            // Add photo output
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                self.photoOutput = photoOutput
            }
            
            session.commitConfiguration()
            
            self.captureSession = session
            session.startRunning()
            
            DispatchQueue.main.async {
                self.isReady = true
            }
        }
    }
    
    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    func switchCamera() {
        guard let session = captureSession else { return }
        
        session.beginConfiguration()
        
        if let currentInput = videoDeviceInput {
            session.removeInput(currentInput)
        }
        
        let currentPosition = videoDeviceInput?.device.position ?? .unspecified
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) ?? AVCaptureDevice.default(for: .video) else {
            if let currentInput = videoDeviceInput {
                session.addInput(currentInput)
            }
            session.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if session.canAddInput(newInput) {
                session.addInput(newInput)
                videoDeviceInput = newInput
            }
        } catch {
            print("Error switching camera: \(error)")
        }
        
        session.commitConfiguration()
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil)
            return
        }
        
        self.completion = completion
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            completion?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completion?(nil)
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.completion?(image)
        }
    }
}

#Preview {
    CameraView(capturedImage: .constant(nil), isPresented: .constant(true))
}
