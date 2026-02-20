import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    func formattedString(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func relativeTimeString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func isToday() -> Bool {
        Calendar.current.isDateInToday(self)
    }
    
    func isTomorrow() -> Bool {
        Calendar.current.isDateInTomorrow(self)
    }
}

// MARK: - Color Extensions
extension Color {
    static let todoColor = Color("todoColor")
    static let doingColor = Color("doingColor")
    static let doneColor = Color("doneColor")
    
    static let categoryClean = Color("categoryClean")
    static let categoryFix = Color("categoryFix")
    static let categoryBuy = Color("categoryBuy")
    static let categoryWork = Color("categoryWork")
    static let categoryOrganize = Color("categoryOrganize")
    static let categoryHealth = Color("categoryHealth")
    static let categoryOther = Color("categoryOther")
    
    static let urgencyLow = Color("urgencyLow")
    static let urgencyMedium = Color("urgencyMedium")
    static let urgencyHigh = Color("urgencyHigh")
    
    static let achievementBronze = Color("achievementBronze")
    static let achievementSilver = Color("achievementSilver")
    static let achievementGold = Color("achievementGold")
    
    static let plantWilted = Color("plantWilted")
    static let plantSprout = Color("plantSprout")
    static let plantGrowing = Color("plantGrowing")
    static let plantFlourishing = Color("plantFlourishing")
    static let plantMature = Color("plantMature")
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    func urgentGlow(color: Color, isActive: Bool) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color, lineWidth: isActive ? 3 : 0)
                    .opacity(isActive ? 1 : 0)
                    .shadow(color: color, radius: isActive ? 8 : 0)
            )
    }
}

// MARK: - Animation Extensions
extension Animation {
    static func gentleSpring() -> Animation {
        .spring(response: 0.4, dampingFraction: 0.7)
    }
    
    static func bouncy() -> Animation {
        .spring(response: 0.5, dampingFraction: 0.6)
    }
}

// MARK: - String Extensions
extension String {
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
}
