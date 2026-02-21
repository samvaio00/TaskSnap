import SwiftUI
import PhotosUI

struct CaptureView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var isPresented: Bool
    
    @StateObject private var captureViewModel = CaptureViewModel()
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
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
            .onChange(of: captureViewModel.capturedImage) { _, newImage in
                if newImage != nil {
                    captureViewModel.analyzeImage(newImage!)
                    // Play capture success animation
                    AnimationManager.shared.play(.captureSuccess)
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
                    .accessibleText()
                
                Text("Take a photo of something that needs your attention")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .accessibleText()
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
                            .accessibilityHidden(true)
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(16)
                }
                .accessibilityLabel("Take Photo")
                .accessibilityHint("Opens camera to capture a new task photo")
                
                Button {
                    showPhotoLibrary = true
                    Haptics.shared.buttonTap()
                } label: {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .accessibilityHidden(true)
                        Text("Choose from Library")
                            .font(.headline)
                    }
                    .foregroundColor(.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(16)
                }
                .accessibilityLabel("Choose from Photo Library")
                .accessibilityHint("Opens photo library to select an existing image")
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
                            .accessibilityLabel("Captured task photo")
                        
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
                        .accessibilityLabel("Remove photo")
                        .accessibilityHint("Clears the captured photo")
                    }
                }
                
                // AI Analysis Indicator
                if captureViewModel.isAnalyzing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .accessibilityLabel("Analyzing")
                        Text("Analyzing image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Analyzing image")
                    .accessibilityValue("Please wait while we analyze your photo")
                }
                
                // Clutter Analysis Button
                if let image = captureViewModel.capturedImage {
                    ClutterScoreButton(image: image)
                }
                
                // Task Title
                VStack(alignment: .leading, spacing: 8) {
                    Text("What needs to be done?")
                        .font(.headline)
                        .accessibleText()
                    
                    TextField("Task title", text: $captureViewModel.taskTitle)
                        .font(.body)
                        .padding()
                        .background(HighContrastColors.secondaryBackground)
                        .cornerRadius(12)
                        .highContrastBorder(cornerRadius: 12, lineWidth: 1)
                        .accessibilityLabel("Task title")
                        .accessibilityHint("Enter a descriptive name for this task")
                }
                
                // Smart Category Suggestions
                if let image = captureViewModel.capturedImage {
                    SmartCategorySuggestionView(image: image) { category in
                        captureViewModel.selectedCategory = category
                        Haptics.shared.selectionChanged()
                    }
                }
                
                // Category Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .accessibleText()
                        .accessibilityAddTraits(.isHeader)
                    
                    CategoryGridView(
                        selectedCategory: $captureViewModel.selectedCategory
                    )
                    .accessibilityLabel("Category picker")
                    .accessibilityValue("Selected: \(captureViewModel.selectedCategory.displayName)")
                }
                
                // Optional Details
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details (Optional)")
                        .font(.headline)
                        .accessibleText()
                    
                    // Due Date Toggle
                    Toggle("Set due date", isOn: $captureViewModel.showDatePicker)
                        .padding()
                        .background(HighContrastColors.secondaryBackground)
                        .cornerRadius(12)
                        .accessibleTouchTarget()
                    
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
                        .background(HighContrastColors.tertiaryBackground)
                        .cornerRadius(12)
                        .highContrastBorder(cornerRadius: 12, lineWidth: 1)
                    }
                    
                    // Urgent Toggle
                    Toggle("Mark as urgent", isOn: $captureViewModel.isUrgent)
                        .padding()
                        .background(HighContrastColors.secondaryBackground)
                        .cornerRadius(12)
                        .accessibleTouchTarget()
                    
                    // Description
                    TextField("Add description (optional)", text: $captureViewModel.taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(HighContrastColors.secondaryBackground)
                        .cornerRadius(12)
                        .highContrastBorder(cornerRadius: 12, lineWidth: 1)
                }
                
                // Task Limit Warning (if applicable)
                if !canCreateTask {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text("Task limit reached (\(TaskLimitManager.shared.freeTierLimit) tasks). Complete tasks to add more.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Task limit reached")
                    .accessibilityValue("\(TaskLimitManager.shared.freeTierLimit) tasks maximum. Complete tasks to add more.")
                } else if remainingTasks <= 3 {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentColor)
                            .accessibilityHidden(true)
                        Text("\(remainingTasks) task slots remaining on free tier")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Task slots remaining")
                    .accessibilityValue("\(remainingTasks) out of \(TaskLimitManager.shared.freeTierLimit)")
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
                            .accessibilityHidden(true)
                        Text("Create Task")
                            .accessibleText(lineLimit: 1)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreateTask ? HighContrastColors.accent : Color.gray)
                    .cornerRadius(16)
                    .highContrastButton(isPrimary: true)
                }
                .disabled(captureViewModel.capturedImage == nil || !canCreateTask)
                .opacity(captureViewModel.capturedImage == nil || !canCreateTask ? 0.6 : 1)
                .accessibleTouchTarget()
                .accessibilityLabel("Create Task")
                .accessibilityHint(canCreateTask ? "Saves the new task to your dashboard" : "Cannot create task. Limit reached or no photo captured.")
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
    
    @StateObject private var accessibilitySettings = AccessibilitySettings.shared
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(category.displayName)
                    .font(.caption)
                    .accessibleText(lineLimit: 1)
            }
            .foregroundColor(isSelected ? .white : Color(category.color))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color(category.color) : Color(category.color).opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color(category.color) : (accessibilitySettings.highContrast ? Color(category.color).opacity(0.5) : Color.clear),
                        lineWidth: accessibilitySettings.highContrast ? 2 : 2
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibleTouchTarget()
        .accessibilityLabel("\(category.displayName) category")
        .accessibilityHint("Select this category for the task")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
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

// MARK: - Category Grid View
struct CategoryGridView: View {
    @Binding var selectedCategory: TaskCategory
    @Environment(\.sizeCategory) var sizeCategory
    @EnvironmentObject var accessibilitySettings: AccessibilitySettings
    
    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: adaptiveMinimumWidth))],
            spacing: 12
        ) {
            ForEach(TaskCategory.allCases, id: \.self) { category in
                CategoryButton(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    selectedCategory = category
                    Haptics.shared.selectionChanged()
                }
            }
        }
    }
    
    private var adaptiveMinimumWidth: CGFloat {
        accessibilitySettings.isAccessibilitySize(sizeCategory) ? 100 : 80
    }
}

#Preview {
    CaptureView(
        taskViewModel: TaskViewModel(context: PersistenceController.preview.container.viewContext),
        isPresented: .constant(true)
    )
}
