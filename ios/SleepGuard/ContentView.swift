import FamilyControls
import SwiftUI

struct ContentView: View {
    @StateObject private var model = GuardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    statusCard
                    setupCard
                    rulesCard
                }
                .padding(20)
            }
            .background(Color(red: 0.055, green: 0.06, blue: 0.09))
            .navigationTitle("睡眠守卫")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .familyActivityPicker(isPresented: $model.showingPicker, selection: $model.selection)
            .onChange(of: model.selection) { _, _ in model.persistSelection() }
            .onAppear { model.refresh() }
            .alert("没有启动", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
        .preferredColorScheme(.dark)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: model.state.isActive ? "lock.fill" : "moon.stars.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(model.state.isActive ? .mint : .purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.state.isActive ? "守卫中" : "今晚还没锁好")
                        .font(.title2.bold())
                    Text(statusSubtitle)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if model.state.isActive {
                Button(role: .destructive) { model.stopGuard() } label: {
                    Label("结束睡眠守卫", systemImage: "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            } else {
                Button { model.startGuard() } label: {
                    Label("说晚安，锁到明早 8:00", systemImage: "lock.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .cardStyle()
    }

    private var setupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("第一次设置").font(.headline)

            Button {
                Task { await model.requestAuthorization() }
            } label: {
                HStack {
                    Label("允许系统拦截", systemImage: authorizationIcon)
                    Spacer()
                    Text(authorizationLabel).foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Divider()

            Button { model.showingPicker = true } label: {
                HStack {
                    Label("选择娱乐 App", systemImage: "square.grid.2x2")
                    Spacer()
                    Text("已选 \(model.selectedItemCount) 项").foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今晚的家规").font(.headline)
            Label("打开选中的 App 会看到系统 Shield", systemImage: "nosign")
            Label("回去睡觉：立即关闭当前 App", systemImage: "bed.double.fill")
            Label("申请解锁：留下记录并回到守卫 App", systemImage: "clock.badge.questionmark")
            Label("第三次尝试后取消当晚解锁资格", systemImage: "3.circle.fill")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .cardStyle()
    }

    private var statusSubtitle: String {
        guard model.state.isActive else { return "选好 App，按一下就开始" }
        let attempts = model.state.attemptCount
        return attempts == 0 ? "很好，还没有偷开" : "今晚已经抓到 \(attempts) 次"
    }

    private var authorizationIcon: String {
        model.authorizationStatus == .approved ? "checkmark.shield.fill" : "shield.lefthalf.filled"
    }

    private var authorizationLabel: String {
        switch model.authorizationStatus {
        case .approved: "已允许"
        case .denied: "已拒绝"
        case .notDetermined: "未设置"
        @unknown default: "未知"
        }
    }
}

private extension View {
    func cardStyle() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08)))
    }
}

