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
    @State private var isTrashHovered = false // 쓰레기통 애니메이션용

    var body: some View {
        NavigationSplitView {
            // --- 좌측: 할 일 보관함 ---
            VStack(spacing: 0) {
                List {
                    ForEach(tasks.filter { !$0.isPlaced }) { task in
                        Text(task.title)
                            .padding(8)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                            .draggable(task.id.uuidString) // 리스트에서 드래그 시작
                    }
                }
                .navigationTitle("보관함")
                .safeAreaInset(edge: .bottom) {
                    TextField("새 할 일...", text: $newTaskTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTask() }
                        .padding()
                }
                
                // --- 3. 하단 쓰레기통 구역 ---
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
                // --- 우측: 자유 배치 캔버스 ---
                GeometryReader { geo in
                    ZStack {
                        // 1. 배경 사분면 가이드 라인 (십자선)
                        QuadrantBox()

                        // 2. 배치된 할 일들
                        ForEach($tasks) { $task in
                            if task.isPlaced {
                                TaskTag(task: task)
                                    .position(task.position) // 저장된 위치에 배치
                                    // 보드 내에서도 다시 드래그해서 옮길 수 있게 설정
                                    .offset(x: 0, y: 0)
                                    .draggable(task.id.uuidString)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.windowBackgroundColor)) // 맥 시스템 배경색
                    
                    // --- 핵심: 드롭 위치 계산 로직 ---
                    .dropDestination(for: String.self) { items, location in
                        guard let taskIDString = items.first,
                              let taskID = UUID(uuidString: taskIDString) else { return false }
                        
                        if let index = tasks.firstIndex(where: { $0.id == taskID }) {
                            withAnimation(.spring()) {
                                tasks[index].position = location // 마우스 커서 위치로 좌표 설정
                                tasks[index].isPlaced = true
                            }
                            return true
                        }
                        return false
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
                    
                    // 좌표 기반 사분면 및 색상 판별 로직
                    let isLeft = location.x < size.width / 2
                    let isTop = location.y < size.height / 2
                    
                    if isLeft && isTop { tasks[index].quadrant = .urgentImportant }
                    else if !isLeft && isTop { tasks[index].quadrant = .importantNotUrgent }
                    else if isLeft && !isTop { tasks[index].quadrant = .urgentNotImportant }
                    else { tasks[index].quadrant = .neither }
                }
            }
        }
    }

#Preview {
    ContentView()
}
