//
//  QuadrantBox.swift
//  MatrixTodoApp
//
//  Created by Jingon Lee on 3/6/26.
//

import SwiftUI

// 사분면 배경 가이드라인
struct QuadrantBox: View {
    var body: some View {
        ZStack {
            // 1. 4사분면 배경색 (2x2 그리드)
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Color.red.opacity(0.08)    // 1사분면 (긴급&중요)
                    Color.blue.opacity(0.08)   // 2사분면 (중요)
                }
                HStack(spacing: 0) {
                    Color.orange.opacity(0.08) // 3사분면 (긴급)
                    Color.gray.opacity(0.1)    // 4사분면 (미루기)
                }
            }
            
            // 가로선 (중요도 축)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 2)
            // 세로선 (긴급도 축)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 2)
            
            // 축 라벨
            VStack {
                Text("중요").font(.caption).bold().padding(8)
                Spacer()
                Text("중요하지 않음").font(.caption).foregroundColor(.secondary).padding(8)
            }
            HStack {
                Text("긴급").font(.caption).bold().padding(8)
                Spacer()
                Text("긴급하지 않음").font(.caption).foregroundColor(.secondary).padding(8)
            }
        }
    }
}

// 보드에 붙는 포스트잇 스타일 태그
struct TaskTag: View {
    let task: TodoTask
    var body: some View {
        Text(task.title)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(task.quadrant.color.opacity(0.8)) // 포스트잇 느낌
            .foregroundColor(.white)
            .cornerRadius(4)
            .shadow(radius: 2)
    }
}

