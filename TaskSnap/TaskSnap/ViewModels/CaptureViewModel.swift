import Foundation
import UIKit
import Combine

class CaptureViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var suggestedTitle: String = ""
    @Published var selectedCategory: TaskCategory = .other
    @Published var isAnalyzing = false
    @Published var taskTitle: String = ""
    @Published var taskDescription: String = ""
    @Published var isUrgent = false
    @Published var dueDate: Date?
    @Published var showDatePicker = false
    
    private let imageClassifier: ImageClassificationService
    private var cancellables = Set<AnyCancellable>()
    
    init(imageClassifier: ImageClassificationService = ImageClassificationService()) {
        self.imageClassifier = imageClassifier
    }
    
    func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        suggestedTitle = ""
        
        imageClassifier.classifyImage(image) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                
                switch result {
                case .success(let classification):
                    self?.suggestedTitle = classification.suggestedTitle
                    self?.selectedCategory = classification.category
                    if self?.taskTitle.isEmpty == true {
                        self?.taskTitle = classification.suggestedTitle
                    }
                case .failure(let error):
                    print("Classification error: \(error)")
                    self?.suggestedTitle = "New Task"
                }
            }
        }
    }
    
    func reset() {
        capturedImage = nil
        suggestedTitle = ""
        selectedCategory = .other
        taskTitle = ""
        taskDescription = ""
        isUrgent = false
        dueDate = nil
        showDatePicker = false
    }
    
    func createTask(using viewModel: TaskViewModel) -> TaskEntity? {
        guard let image = capturedImage else { return nil }
        
        let title = taskTitle.isEmpty ? suggestedTitle : taskTitle
        let finalTitle = title.isEmpty ? "New Task" : title
        
        let task = viewModel.createTask(
            title: finalTitle,
            description: taskDescription,
            category: selectedCategory,
            beforeImage: image,
            dueDate: dueDate,
            isUrgent: isUrgent
        )
        
        return task
    }
}
