import AppKit
import CoreServices
import Foundation
import UniformTypeIdentifiers

@MainActor
struct FileAssociationManager {
    private static let promptVersion = 1
    private let promptVersionKey = "fileAssociationPromptVersion"

    func requestSetupIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: promptVersionKey) < Self.promptVersion else {
            return
        }

        guard let bundleIdentifier = Bundle.main.bundleIdentifier, !bundleIdentifier.isEmpty else {
            defaults.set(Self.promptVersion, forKey: promptVersionKey)
            return
        }

        guard let selection = promptForFileTypes(), !selection.isEmpty else {
            defaults.set(Self.promptVersion, forKey: promptVersionKey)
            return
        }

        guard confirmDefaultApp(for: selection) else {
            defaults.set(Self.promptVersion, forKey: promptVersionKey)
            return
        }

        setDefaultApp(bundleIdentifier: bundleIdentifier, for: selection)
        defaults.set(Self.promptVersion, forKey: promptVersionKey)
    }

    private func promptForFileTypes() -> [FileAssociationGroup]? {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 18
        stackView.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

        let titleLabel = NSTextField(labelWithString: "Choose Default File Types")
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.maximumNumberOfLines = 0

        let descriptionLabel = NSTextField(labelWithString: "Select which files Forma should open by default.")
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .secondaryLabelColor
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.maximumNumberOfLines = 0

        let headerStackView = NSStackView()
        headerStackView.orientation = .vertical
        headerStackView.alignment = .leading
        headerStackView.spacing = 6
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(descriptionLabel)

        let checkboxStackView = NSStackView()
        checkboxStackView.orientation = .vertical
        checkboxStackView.alignment = .leading
        checkboxStackView.spacing = 10

        let checkboxes = FileAssociationGroup.allCases.map { group in
            let checkbox = NSButton(checkboxWithTitle: group.title, target: nil, action: nil)
            checkbox.state = group == .allFiles ? .on : .off
            checkbox.toolTip = group.detail
            return (group, checkbox)
        }

        for (_, checkbox) in checkboxes {
            checkboxStackView.addArrangedSubview(checkbox)
        }

        let notNowButton = NSButton(title: "Not Now", target: nil, action: nil)
        notNowButton.bezelStyle = .rounded

        let continueButton = NSButton(title: "Continue", target: nil, action: nil)
        continueButton.bezelStyle = .rounded
        continueButton.keyEquivalent = "\r"

        let buttonStackView = NSStackView()
        buttonStackView.orientation = .horizontal
        buttonStackView.alignment = .centerY
        buttonStackView.spacing = 10
        buttonStackView.addArrangedSubview(NSView())
        buttonStackView.addArrangedSubview(notNowButton)
        buttonStackView.addArrangedSubview(continueButton)

        stackView.addArrangedSubview(headerStackView)
        stackView.addArrangedSubview(checkboxStackView)
        stackView.addArrangedSubview(buttonStackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 300),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "Forma"
        window.contentView = stackView
        window.center()
        window.isReleasedWhenClosed = false

        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalToConstant: 460)
        ])

        var didContinue = false

        notNowButton.target = ModalButtonHandler.shared
        notNowButton.action = #selector(ModalButtonHandler.cancel)
        continueButton.target = ModalButtonHandler.shared
        continueButton.action = #selector(ModalButtonHandler.confirm)
        ModalButtonHandler.shared.onCancel = {
            NSApp.stopModal()
        }
        ModalButtonHandler.shared.onConfirm = {
            didContinue = true
            NSApp.stopModal()
        }

        NSApp.runModal(for: window)
        window.close()
        ModalButtonHandler.shared.reset()

        return didContinue ? checkboxes.compactMap { group, checkbox in
            checkbox.state == .on ? group : nil
        } : nil
    }

    private func confirmDefaultApp(for selection: [FileAssociationGroup]) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Make Forma the Default App?"
        alert.informativeText = "Forma will become the default app for: \(selection.map(\.title).joined(separator: ", "))."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Set as Default")
        alert.addButton(withTitle: "Not Now")

        return alert.runModal() == .alertFirstButtonReturn
    }

    private func setDefaultApp(bundleIdentifier: String, for selection: [FileAssociationGroup]) {
        let typeIdentifiers = Set(selection.flatMap(\.typeIdentifiers))

        for typeIdentifier in typeIdentifiers {
            _ = LSSetDefaultRoleHandlerForContentType(typeIdentifier as NSString, .viewer, bundleIdentifier as NSString)
        }
    }
}

@MainActor
private final class ModalButtonHandler: NSObject {
    static let shared = ModalButtonHandler()

    var onCancel: (() -> Void)?
    var onConfirm: (() -> Void)?

    @objc func cancel() {
        onCancel?()
    }

    @objc func confirm() {
        onConfirm?()
    }

    func reset() {
        onCancel = nil
        onConfirm = nil
    }
}

private enum FileAssociationGroup: CaseIterable {
    case allFiles
    case pdf
    case images
    case text
    case tables

    var title: String {
        switch self {
        case .allFiles:
            "All files"
        case .pdf:
            "PDF files"
        case .images:
            "Images"
        case .text:
            "Text, Markdown, JSON, XML, and YAML"
        case .tables:
            "CSV and TSV files"
        }
    }

    var detail: String {
        switch self {
        case .allFiles:
            "Use Forma as a general viewer for any file macOS can route to it."
        case .pdf:
            "Open PDF documents in Forma by default."
        case .images:
            "Open image files in Forma by default."
        case .text:
            "Open common text-based files in Forma by default."
        case .tables:
            "Open comma-separated and tab-separated files in Forma by default."
        }
    }

    var typeIdentifiers: [String] {
        switch self {
        case .allFiles:
            [
                UTType.item.identifier,
                UTType.content.identifier,
                UTType.data.identifier
            ]
        case .pdf:
            [
                UTType.pdf.identifier
            ]
        case .images:
            [
                UTType.image.identifier
            ]
        case .text:
            [
                UTType.text.identifier,
                UTType.plainText.identifier,
                UTType.rtf.identifier,
                "public.markdown",
                UTType.json.identifier,
                UTType.xml.identifier,
                "public.yaml"
            ]
        case .tables:
            [
                UTType.commaSeparatedText.identifier,
                "public.tab-separated-values-text"
            ]
        }
    }
}
