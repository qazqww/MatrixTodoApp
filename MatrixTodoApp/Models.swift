//
//  Models.swift
//  MatrixTodoApp
//
//  Created by Jingon Lee on 3/6/26.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// 사분면 종류
enum Quadrant: String, CaseIterable, Codable {
    case inbox = "보관함"
    case urgentImportant = "긴급 & 중요"
    case urgentNotImportant = "긴급 (위임)"
    case importantNotUrgent = "중요 (계획)"
    case neither = "비중요"
    case completed = "완료됨"
    
    var color: Color {
        switch self {
        case .inbox: return .secondary
        case .urgentImportant: return .red
        case .urgentNotImportant: return .orange
        case .importantNotUrgent: return .blue
        case .neither: return .gray
        case .completed: return .green
        }
    }
}

// 할 일 모델
struct TodoTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var position: CGPoint = .zero
    var isPlaced: Bool = false
    var isCompleted: Bool = false
    var completionDate: Date? = nil
    var quadrant: Quadrant = .inbox
}
