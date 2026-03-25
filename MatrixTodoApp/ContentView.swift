//
//  ContentView.swift
//  MatrixTodoApp
//
//  Created by Jingon Lee on 3/6/26.
//

import SwiftUI

struct ContentView: View {
    @State private var tasks: [TodoTask] = []
    @State private var newTaskTitle = ""
    @State private var isTrashHovered = false
    
    var body: some View {
        NavigationSplitView {
            // --- 좌측: 할 일 보관함 ---
            GeometryReader { geo in
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("할 일")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        List {
                            ForEach(tasks.filter { !$0.isCompleted }) { task in
                                TaskRowView(task: task)
                                    .draggable(task.id.uuidString)
                            }
                            .onMove(perform: moveTasks)
                        }
                        .listStyle(.sidebar) // 사이드바 스타일 유지
                    }
                    .frame(height: geo.size.height * 0.55)
                    .contentShape(Rectangle())
                    .dropDestination(for: String.self) { items, _ in
                        resetTask(idString: items.first)
                        return true
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("마친 일")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        List {
                            ForEach(tasks.filter { $0.isCompleted }.sorted(by: { $0.completionDate ?? Date() > $1.completionDate ?? Date() })) { task in
                                TaskRowView(task: task)
                                    .draggable(task.id.uuidString)
                            }
                        }
                        .listStyle(.sidebar)
                    }
                    .frame(height: geo.size.height * 0.25)
                    .contentShape(Rectangle())
                    .background(Color.green.opacity(0.03))
                    .dropDestination(for: String.self) { items, _ in
                        completeTask(idString: items.first)
                        return true
                    }
                    
                    Button(action: clearCompletedTasks) {
                        Label("마친 일 정리", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    
                    // --- 컨트롤 메뉴 ---
                    VStack(spacing: 8) {
                        
                        Label("드래그하여 삭제", systemImage: isTrashHovered ? "trash.fill" : "trash")
                            .font(.caption)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(isTrashHovered ? Color.red.opacity(0.1) : Color.clear)
                            .dropDestination(for: String.self) { items, _ in
                                deleteTask(idString: items.first)
                            } isTargeted: { isTargeted in
                                isTrashHovered = isTargeted
                            }
                    }
                }
            }
        } detail: {
            // --- 우측: 아이젠하워 매트릭스 캔버스 ---
            GeometryReader { geo in
                ZStack {
                    // 1. 배경 사분면 가이드 라인 (십자선)
                    QuadrantBox()
                    
                    // 2. 배치된 할 일들
                    ForEach($tasks) { $task in
                        if task.isPlaced && !task.isCompleted {
                            TaskTag(task: task)
                                .position(task.position)
                                .draggable(task.id.uuidString)
                                .contextMenu {
                                    Button {
                                        completeTask(idString: task.id.uuidString)
                                    } label: {
                                        Label("완료하기", systemImage: "checkmark.circle")
                                    }
                                    
                                    Button(role: .destructive) {
                                        deleteTask(idString: task.id.uuidString)
                                    } label: {
                                        Label("삭제하기", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .dropDestination(for: String.self) { items, location in
                    updateTaskPosition(idString: items.first, location: location, size: geo.size)
                    return true
                }
            }
        }
        .onAppear {
            loadTasks()
        }
        .onChange(of: tasks) { oldValue, newValue in
            saveTasks()
        }
    }
    
    func addTask() {
        if !newTaskTitle.isEmpty {
            tasks.append(TodoTask(title: newTaskTitle))
            newTaskTitle = ""
        }
    }
    
    func deleteTask(idString: String?) -> Bool {
        guard let idString = idString, let id = UUID(uuidString: idString) else { return false }
        withAnimation {
            tasks.removeAll { $0.id == id }
        }
        return true
    }
    
    func updateTaskPosition(idString: String?, location: CGPoint, size: CGSize) {
        guard let idString = idString, let id = UUID(uuidString: idString) else { return }
        
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring()) {
                tasks[index].position = location
                tasks[index].isPlaced = true
                tasks[index].isCompleted = false
                tasks[index].completionDate = nil
                
                let isLeft = location.x < size.width / 2
                let isTop = location.y < size.height / 2
                
                if isLeft && isTop { tasks[index].quadrant = .urgentImportant }
                else if !isLeft && isTop { tasks[index].quadrant = .importantNotUrgent }
                else if isLeft && !isTop { tasks[index].quadrant = .urgentNotImportant }
                else { tasks[index].quadrant = .neither }
            }
        }
    }
    
    func moveTasks(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
    }
    
    func resetTask(idString: String?) {
        guard let idString = idString, let id = UUID(uuidString: idString) else { return }
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            withAnimation {
                tasks[index].isPlaced = false
                tasks[index].quadrant = .inbox
                tasks[index].position = .zero
                tasks[index].isCompleted = false
                tasks[index].completionDate = nil
            }
        }
    }
    
    func completeTask(idString: String?) {
        guard let idString = idString, let id = UUID(uuidString: idString) else { return }
        
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            withAnimation {
                tasks[index].isCompleted = true
                tasks[index].isPlaced = false
                tasks[index].quadrant = .completed
                tasks[index].completionDate = Date()
                
                let completedTasks = tasks.filter { $0.isCompleted }
                
                if completedTasks.count > 50 {
                    if let oldestTask = completedTasks.sorted(by: { ($0.completionDate ?? Date()) < ($1.completionDate ?? Date()) }).first {
                        tasks.removeAll { $0.id == oldestTask.id }
                    }
                }
            }
        }
    }
    
    func clearCompletedTasks() {
        withAnimation {
            tasks.removeAll() { $0.isCompleted }
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("tasks.json")
    }
    
    func saveTasks() {
        do {
            let data = try JSONEncoder().encode(tasks)
            try data.write(to: getDocumentsDirectory())
        } catch {
            print("저장 실패: \(error.localizedDescription)")
        }
    }
    
    func loadTasks() {
        let url = getDocumentsDirectory()
        
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let data = try Data(contentsOf: url)
                let decodedTasks = try JSONDecoder().decode([TodoTask].self, from: data)
                self.tasks = decodedTasks
            } catch {
                print("불러오기 실패: \(error.localizedDescription)")
            }
        }
    }
}

struct TaskRowView: View {
    let task: TodoTask
    var body: some View {
        HStack {
            Circle()
                .fill(task.quadrant.color)
                .frame(width: 8, height: 8)
            Text(task.title)
        }
        .padding(8)
        .background(task.quadrant.color.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
