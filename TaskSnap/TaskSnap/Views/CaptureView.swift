import SwiftUI
import PhotosUI

struct CaptureView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var isPresented: Bool
    
    @StateObject private var captureViewModel = CaptureViewModel()
    @State private var showPhotoLibrary = false
    @State private var showCameraPicker = false
    @State private var showCameraView = false
    @State private var showLimitAlert = false
    
    private var activeTaskCount: Int {
        taskViewModel.todoTasks.count + taskViewModel.doingTasks.count
    }
    
    private var canCreateTask: Bool {
        TaskLimitManager.shared.canCreateTask(currentTaskCount: activeTaskCount)
    }
    
    private var remainingTasks: Int {
        TaskLimitManager.shared.remainingTasks(currentTaskCount: activeTaskCount)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if captureViewModel.capturedImage == nil {
                    // Capture Options
                    captureOptionsView
                } else {
                    // Task Creation Form
                    taskCreationForm
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        captureViewModel.reset()
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $showPhotoLibrary) {
                PhotoLibraryPicker(
                    image: $captureViewModel.capturedImage,
                    isPresented: $showPhotoLibrary
                )
            }
            .fullScreenCover(isPresented: $showCameraView) {
                CameraView(
                    capturedImage: $captureViewModel.capturedImage,
                    isPresented: $showCameraView
                )
            }
            .onChange(of: captureViewModel.capturedImage) { newImage in
                if newImage != nil {
                    captureViewModel.analyzeImage(newImage!)
                }
            }
            .alert("Task Limit Reached", isPresented: $showLimitAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You've reached the free tier limit of \(TaskLimitManager.shared.freeTierLimit) active tasks. Complete some tasks or upgrade to Pro for unlimited tasks.")
            }
        }
    }
    
    // MARK: - Capture Options View
    private var captureOptionsView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Hero Image/Icon
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                }
                
                Text("Capture Your Chaos")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Take a photo of something that needs your attention")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Capture Buttons
            VStack(spacing: 16) {
                Button {
                    showCameraView = true
                    Haptics.shared.buttonTap()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title3)
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
                
                Button {
                    showPhotoLibrary = true
                    Haptics.shared.buttonTap()
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                        Text("Choose from Library")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
    }
    
    // MARK: - Task Creation Form
    private var taskCreationForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Captured Image Preview
                if let image = captureViewModel.capturedImage {
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .cornerRadius(16)
                        
                        Button {
                            captureViewModel.capturedImage = nil
                            captureViewModel.reset()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }
                }
                
                // AI Analysis Indicator
                if captureViewModel.isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                }
                
                // Task Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("What needs to be done?")
                        .font(.headline)
                    
                    TextField("Task title", text: $captureViewModel.taskTitle)
                        .font(.body)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                // Category Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: captureViewModel.selectedCategory == category
                            ) {
                                captureViewModel.selectedCategory = category
                                Haptics.shared.selectionChanged()
                            }
                        }
                    }
                }
                
                // Optional Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details (Optional)")
                        .font(.headline)
                    
                    // Due Date Toggle
                    Toggle("Set due date", isOn: $captureViewModel.showDatePicker)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    if captureViewModel.showDatePicker {
                        DatePicker(
                            "Due date",
                            selection: Binding(
                                get: { captureViewModel.dueDate ?? Date() },
                                set: { captureViewModel.dueDate = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.graphical)
                        .padding()
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // Urgent Toggle
                    Toggle("Mark as urgent", isOn: $captureViewModel.isUrgent)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    // Description
                    TextField("Add description (optional)", text: $captureViewModel.taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                
                // Task Limit Warning (if applicable)
                if !canCreateTask {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Task limit reached (\(TaskLimitManager.shared.freeTierLimit) tasks). Complete tasks to add more.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                } else if remainingTasks <= 3 {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("\(remainingTasks) task slots remaining on free tier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Create Button
                Button {
                    if canCreateTask {
                        createTask()
                    } else {
                        showLimitAlert = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Create Task")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreateTask ? Color.accentColor : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(captureViewModel.capturedImage == nil || !canCreateTask)
                .opacity(captureViewModel.capturedImage == nil || !canCreateTask ? 0.6 : 1)
            }
            .padding()
        }
    }
    
    private func createTask() {
        Haptics.shared.success()
        captureViewModel.createTask(using: taskViewModel)
        captureViewModel.reset()
        isPresented = false
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.displayName)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : Color(category.color))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(category.color) : Color(category.color).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(category.color) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Photo Library Picker (Modern PHPicker)
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
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
        let parent: PhotoLibraryPicker
        
        init(_ parent: PhotoLibraryPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let image = image as? UIImage {
                            self.parent.image = image
                            Haptics.shared.cameraShutter()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Camera Picker (UIImagePicker for camera only)
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        
        init(_ parent: CameraImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            parent.isPresented = false
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                Haptics.shared.cameraShutter()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

#Preview {
    CaptureView(
        taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext),
        isPresented: .constant(true)
    )
}
