//
//  ProjectsView.swift
//  VideoSpeed
//

import SwiftUI
import SwiftData
import UIKit

struct ProjectsView: View {
    @Query(sort: \VideoProject.createdAt, order: .reverse) private var projects: [VideoProject]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let floatingButtonBottomPadding: CGFloat = 28
    private let floatingButtonSize: CGFloat = 60

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if projects.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(projects, id: \.persistentModelID) { project in
                            ProjectGridCell(project: project) {
                                presentProjectActions(for: project)
                            }
                            .onTapGesture {
                                Task {
                                    await openProject(project)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, floatingButtonSize + floatingButtonBottomPadding + 16)
                }
            }

            VStack {
                Spacer()
                newProjectButton
                    .padding(.bottom, floatingButtonBottomPadding)
            }
        }
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var newProjectButton: some View {
        Button(action: createNewProject) {
            Text("+ New Project")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: floatingButtonSize)
                .background(Color.blue)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        }
        .accessibilityLabel("New Project")
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "film.stack")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.white.opacity(0.45))
            Text("No Projects Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            Text("Tap the + button to create your first project")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding()
        .padding(.bottom, floatingButtonSize)
    }

    // MARK: - Navigation

    private func createNewProject() {
        let mainViewController = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        navigationController?.pushViewController(mainViewController, animated: true)
    }

    private func openProject(_ project: VideoProject) async {
        UserDataManager.main.currentProject = project
        print("project.labelViewModels: \(project.labelViewModels)")
        let sortedModels = project.spidAssets.sorted { $0.sortIndex < $1.sortIndex }
        guard !sortedModels.isEmpty else { return }

        let assets = await SwiftDataManager.shared.makeSpidAssets(from: sortedModels)
        guard !assets.isEmpty else { return }

        UserDataManager.main.spidAssets = assets
        UserDataManager.main.currentSpidAsset = assets.first
        SwiftDataManager.shared.applyCaptionsFromProject(from: project)
        
        let editVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        editVC.asset = await assets[0].getAsset()
        editVC.speed = await assets[0].speed
        editVC.soundOn = await assets[0].soundOn

        Task { @MainActor in
            navigationController?.pushViewController(editVC, animated: true)
        }
    }

    private func presentProjectActions(for project: VideoProject) {
        guard let presenter = UIApplication.shared.topViewController() else { return }

        let sheetView = ProjectActionsSheetView(
            onDuplicate: {
                presenter.dismiss(animated: true) {
                    SwiftDataManager.shared.duplicateVideoProject(project)
                }
            },
            onDelete: {
                presenter.dismiss(animated: true) {
                    SwiftDataManager.shared.deleteVideoProject(project)
                }
            }
        )

        let sheetVC = UIHostingController(rootView: sheetView)
        sheetVC.modalPresentationStyle = .pageSheet

        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.custom(resolver: { _ in 160 })]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 16
        }

        presenter.present(sheetVC, animated: true)
    }

    private var navigationController: UINavigationController? {
        UIApplication.shared.topViewController()?.navigationController
    }
}

private struct ProjectActionsSheetView: View {
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            actionRow(title: "Duplicate", systemImage: "plus.square.on.square", isDestructive: false, action: onDuplicate)
            Divider().padding(.leading, 52)
            actionRow(title: "Delete", systemImage: "trash", isDestructive: true, action: onDelete)
            Spacer(minLength: 0)
        }
        .padding(.top, 20)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private func actionRow(
        title: String,
        systemImage: String,
        isDestructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isDestructive ? Color.red : Color.blue)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundStyle(isDestructive ? Color.red : Color.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct ProjectGridCell: View {
    let project: VideoProject
    let onMenuTap: () -> Void

    var body: some View {
        Color.clear
            .aspectRatio(1/1.5, contentMode: .fit)
            .overlay {
                ZStack {
                    if let uiImage = UIImage(data: project.thumbnailImage), !project.thumbnailImage.isEmpty {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(white: 0.18)
                        Image(systemName: "video")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: onMenuTap) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel("Project options")
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

#Preview {
    let schema = Schema([
        VideoProject.self,
        SpidAssetModel.self
    ])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])

    let placeholder = UIImage(systemName: "film")!
        .jpegData(compressionQuality: 0.8) ?? Data()
    container.mainContext.insert(VideoProject(thumbnailImage: placeholder))
    container.mainContext.insert(VideoProject(thumbnailImage: Data()))

    return NavigationStack {
        ProjectsView()
    }
    .modelContainer(container)
    .preferredColorScheme(.dark)
}
