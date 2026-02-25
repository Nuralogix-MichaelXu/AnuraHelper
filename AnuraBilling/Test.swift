import SwiftUI

struct Item: Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

struct ContentView1: View {
    let items = [
        Item(name: "首页", description: "这是首页"),
        Item(name: "个人资料", description: "查看个人资料"),
        Item(name: "设置", description: "应用设置")
    ]
    
    var body: some View {
        NavigationView {
            List(items) { item in
                ZStack {
                    // 1. 隐藏的 NavigationLink，处理导航逻辑
                    NavigationLink(destination: DetailView(item: item)) {
                        EmptyView()
                    }
                    .opacity(0) // 完全隐藏
                    .buttonStyle(PlainButtonStyle())
                    
                    // 2. 自定义的行内容，无高亮效果
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 8))
                        
                        Text(item.name)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle()) // 确保整个区域可点击
                }
                .listRowBackground(Color.clear) // 清除默认背景
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .listStyle(PlainListStyle())
            .navigationTitle("无高亮列表")
        }
    }
}

struct DetailView: View {
    let item: Item
    init(item: Item) {
        self.item = item
        // 可以在 init 中设置，影响整个应用
        UINavigationBar.appearance().isHidden = true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text(item.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(item.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView1()
}
