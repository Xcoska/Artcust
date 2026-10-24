import SwiftUI
import SwiftData
import PainTrackerKit

struct MoreView: View {
    @Query(sort: \TrackedCondition.createdAt) private var conditions: [TrackedCondition]
    @State private var exportFiles: Exporter.Files?
    @State private var exportError: String?

    var body: some View {
        List {
            Section {
                if let exportFiles {
                    ShareLink(item: exportFiles.assessments) {
                        Label("Questionnaire results (CSV)", systemImage: "tablecells")
                    }
                    ShareLink(item: exportFiles.painLog) {
                        Label("Pain log (CSV)", systemImage: "list.bullet.rectangle")
                    }
                } else if let exportError {
                    Text(exportError)
                        .foregroundStyle(.red)
                } else {
                    ProgressView()
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Send your history to your doctor or physiotherapist, or open it in Numbers or Excel. Your data stays on this device unless you share it.")
            }

            Section("Questionnaires") {
                ForEach(InstrumentCatalog.all) { instrument in
                    NavigationLink {
                        InstrumentInfoView(instrument: instrument)
                    } label: {
                        Label(instrument.name, systemImage: instrument.region.systemImage)
                    }
                }
            }

            Section("About") {
                Text(Disclaimer.text)
                    .font(.footnote)
            }
        }
        .navigationTitle("Export & Info")
        .onAppear(perform: refreshExport)
    }

    private func refreshExport() {
        do {
            exportFiles = try Exporter.writeFiles(for: conditions)
            exportError = nil
        } catch {
            exportFiles = nil
            exportError = "Couldn’t prepare export: \(error.localizedDescription)"
        }
    }
}

struct InstrumentInfoView: View {
    let instrument: Instrument

    var body: some View {
        List {
            Section {
                Text(instrument.summary)
                Text(instrument.instructions)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Source") {
                switch instrument.provenance {
                case .validated(let citation):
                    Label("Validated questionnaire", systemImage: "checkmark.seal")
                    Text(citation)
                        .font(.footnote)
                case .custom(let modelledOn):
                    Label("Not validated", systemImage: "info.circle")
                    Text("Written for this app, modelled on \(modelledOn). Good for following your own trend; not for comparing with published research.")
                        .font(.footnote)
                }
                if let notes = instrument.notes {
                    Text(notes)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Score bands") {
                ForEach(instrument.bands) { band in
                    HStack {
                        Circle()
                            .fill(Color.severity(band.level))
                            .frame(width: 10, height: 10)
                        Text(band.label)
                        Spacer()
                        Text(range(for: band))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }

            ForEach(Array(instrument.items.enumerated()), id: \.element.id) { index, item in
                Section("\(index + 1). \(item.title)") {
                    Text(item.prompt)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if case .choices = item.presentation {
                        ForEach(item.options) { option in
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(option.points)")
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Text(option.text)
                            }
                            .font(.subheadline)
                        }
                    } else {
                        Text("Rated 0–10")
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle(instrument.shortName)
    }

    private func range(for band: SeverityBand) -> String {
        let bands = instrument.bands
        let upper = bands.first { $0.lowerBound > band.lowerBound }?.lowerBound
        switch instrument.display {
        case .percent:
            if let upper { return "\(Int(band.lowerBound))–\(Int(upper) - 1)%" }
            return "\(Int(band.lowerBound))–100%"
        case .mean(let maximum):
            let scale = Double(maximum) / 100
            let low = band.lowerBound * scale
            guard let upper else { return String(format: "%.1f–%d", low, maximum) }
            let high = upper * scale - 0.1
            return high <= low ? String(format: "%.1f", low) : String(format: "%.1f–%.1f", low, high)
        }
    }
}
