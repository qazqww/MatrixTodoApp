//
//  ContentView.swift
//  MatrixTodoApp
//
//  Created by Jingon Lee on 3/6/26.
//

import SwiftUI

struct ContentView: View {
    @State private var tasks: [TodoTask] = [
        TodoTask(title: "보고서 작성"),
        TodoTask(title: "운동하기"),
        TodoTask(title: "메일 확인")
    ]
    @State private var newTaskTitle = ""
    @State private var isTrashHovered = false

    var body: some View {
        NavigationSplitView {
            // --- 좌측: 할 일 보관함 ---
            VStack(spacing: 0) {
                List {
                    ForEach(tasks) { task in
                        HStack {
                            Circle()
                                .fill(task.quadrant.color)
                                .frame(width: 8, height: 8)
                            Text(task.title)
                        }
                            .padding(8)
                            .background(task.quadrant.color.opacity(0.2))
                            .cornerRadius(8)
                            .draggable(task.id.uuidString)
                    }
                    .onMove(perform: moveTasks)
                }
                .dropDestination(for: String.self) { items, _ in
                    resetTask(idString: items.first)
                    return true
                }
                .navigationTitle("보관함")
                .safeAreaInset(edge: .bottom) {
                    TextField("새 할 일...", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTask() }
                        .padding()
                }
                
                // --- 쓰레기통 ---
                VStack {
                    Divider()
                    Label("쓰레기통으로 드래그하여 삭제", systemImage: isTrashHovered ? "trash.fill" : "trash")
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isTrashHovered ? Color.red.opacity(0.1) : Color.clear)
                        .dropDestination(for: String.self) { items, _ in
                            deleteTask(idString: items.first)
                        } isTargeted: { isTargeted in
                            isTrashHovered = isTargeted
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
                            if task.isPlaced {
                                TaskTag(task: task)
                                    .position(task.position)
                                    .offset(x: 0, y: 0)
                                    .draggable(task.id.uuidString)
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
                }
            }
        }
    }

#Preview {
    ContentView()
}
