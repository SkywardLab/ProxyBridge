import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: ProxyBridgeViewModel
    @State private var selectedTab = 0
    @State private var connectionSearchText = ""
    @State private var activitySearchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            tabSelector
            Divider()
            contentView
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private var headerView: some View {
        HStack {
            Text("ProxyBridge")
                .font(.headline)
                .padding(.leading)
            Spacer()
        }
        .frame(height: 44)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Connections", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            TabButton(title: "Activity Logs", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            Spacer()
        }
        .frame(height: 40)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var contentView: some View {
        Group {
            if selectedTab == 0 {
                ConnectionsView(
                    connections: filteredConnections,
                    searchText: $connectionSearchText,
                    onClear: viewModel.clearConnections
                )
            } else {
                ActivityLogsView(
                    logs: filteredActivityLogs,
                    searchText: $activitySearchText,
                    onClear: viewModel.clearActivityLogs
                )
            }
        }
    }
    
    private var filteredConnections: [ProxyBridgeViewModel.ConnectionLog] {
        if connectionSearchText.isEmpty {
            return viewModel.connections
        }
        return viewModel.connections.filter {
            $0.process.localizedCaseInsensitiveContains(connectionSearchText) ||
            $0.destination.localizedCaseInsensitiveContains(connectionSearchText) ||
            $0.proxy.localizedCaseInsensitiveContains(connectionSearchText)
        }
    }
    
    private var filteredActivityLogs: [ProxyBridgeViewModel.ActivityLog] {
        if activitySearchText.isEmpty {
            return viewModel.activityLogs
        }
        return viewModel.activityLogs.filter {
            $0.message.localizedCaseInsensitiveContains(activitySearchText) ||
            $0.level.localizedCaseInsensitiveContains(activitySearchText)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct ConnectionsView: View {
    let connections: [ProxyBridgeViewModel.ConnectionLog]
    @Binding var searchText: String
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            connectionsList
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search connections...", text: $searchText)
                .textFieldStyle(.plain)
            Spacer()
            Button("Clear", action: onClear)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var connectionsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(connections) { connection in
                        connectionRow(connection)
                            .id(connection.id)
                    }
                }
                .onChange(of: connections.count) { _ in
                    scrollToLast(proxy: proxy)
                }
            }
        }
    }
    
    private func connectionRow(_ connection: ProxyBridgeViewModel.ConnectionLog) -> some View {
        // one concatenated Text instead of an HStack of seven, far fewer view
        // nodes to build and diff while the list streams. split into locals so
        // the type checker doesn't choke on one giant expression
        let ts = Text(verbatim: "[\(connection.timestamp)] ").foregroundColor(.gray)
        let proto = Text(verbatim: "[\(connection.connectionProtocol)] ").foregroundColor(.blue)
        let proc = Text(verbatim: connection.process).foregroundColor(.green)
        let arrow1 = Text(verbatim: " → ").foregroundColor(.gray)
        let dest = Text(verbatim: "\(connection.destination):\(connection.port)").foregroundColor(.orange)
        let arrow2 = Text(verbatim: " → ").foregroundColor(.gray)
        let proxy = Text(verbatim: connection.proxy).foregroundColor(connection.proxy == "Direct" ? .gray : .purple)
        return (ts + proto + proc + arrow1 + dest + arrow2 + proxy)
            .font(.system(.body, design: .monospaced))
            .padding(.horizontal)
            .padding(.vertical, 4)
    }

    private func scrollToLast(proxy: ScrollViewProxy) {
        // no animation, this fires on every poll and animating a long list burns cpu
        if let last = connections.last {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

struct ActivityLogsView: View {
    let logs: [ProxyBridgeViewModel.ActivityLog]
    @Binding var searchText: String
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            logsList
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search logs...", text: $searchText)
                .textFieldStyle(.plain)
            Spacer()
            Button("Clear", action: onClear)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var logsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(logs) { log in
                        logRow(log)
                            .id(log.id)
                    }
                }
                .onChange(of: logs.count) { _ in
                    scrollToLast(proxy: proxy)
                }
            }
        }
    }
    
    private func logRow(_ log: ProxyBridgeViewModel.ActivityLog) -> some View {
        (
            Text(verbatim: "[\(log.timestamp)] ").foregroundColor(.gray)
            + Text(verbatim: "[\(log.level)] ").foregroundColor(log.level == "ERROR" ? .red : .blue)
            + Text(verbatim: log.message).foregroundColor(.primary)
        )
        .font(.system(.body, design: .monospaced))
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private func scrollToLast(proxy: ScrollViewProxy) {
        // no animation, this fires on every poll and animating a long list burns cpu
        if let last = logs.last {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}
