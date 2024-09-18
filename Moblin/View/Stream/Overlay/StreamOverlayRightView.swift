import Charts
import SwiftUI

private struct CollapsedBondingView: View {
    @EnvironmentObject var model: Model
    var show: Bool
    var color: Color

    var body: some View {
        if show {
            HStack(spacing: 1) {
                Image(systemName: "phone.connection")
                    .frame(width: 17, height: 17)
                    .font(smallFont)
                    .padding([.leading, .trailing], 2)
                    .foregroundColor(color)
                if #available(iOS 17.0, *) {
                    if !model.bondingPieChartPercentages.isEmpty {
                        Chart(model.bondingPieChartPercentages) { item in
                            SectorMark(angle: .value("", item.percentage))
                                .foregroundStyle(by: .value("", item.id))
                        }
                        .chartLegend(.hidden)
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .padding([.trailing], 2)
                    }
                }
            }
            .background(backgroundColor)
            .cornerRadius(5)
            .padding(20)
            .contentShape(Rectangle())
            .padding(-20)
        }
    }
}

private struct CollapsedBitrateView: View {
    @EnvironmentObject var model: Model
    var show: Bool
    var color: Color

    var body: some View {
        if show {
            HStack(spacing: 1) {
                Image(systemName: "speedometer")
                    .frame(width: 17, height: 17)
                    .padding([.leading], 2)
                    .foregroundColor(color)
                if !model.speedMbpsNoDecimals.isEmpty {
                    Text(model.speedMbpsNoDecimals)
                        .foregroundColor(.white)
                        .padding([.trailing], 2)
                }
            }
            .font(smallFont)
            .background(backgroundColor)
            .cornerRadius(5)
            .padding(20)
            .contentShape(Rectangle())
            .padding(-20)
        }
    }
}

private struct StatusesView: View {
    @EnvironmentObject var model: Model
    let textPlacement: StreamOverlayIconAndTextPlacement

    private func netStreamColor() -> Color {
        if model.isStreaming() {
            switch model.streamState {
            case .connecting:
                return .white
            case .connected:
                return .white
            case .disconnected:
                return .red
            }
        } else {
            return .white
        }
    }

    private func remoteControlColor() -> Color {
        if model.isRemoteControlStreamerConfigured() && !model.isRemoteControlStreamerConnected() {
            return .red
        } else if model.isRemoteControlAssistantConfigured() && !model.isRemoteControlAssistantConnected() {
            return .red
        }
        return .white
    }

    var body: some View {
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusServers(),
            icon: "server.rack",
            text: model.serversSpeedAndTotal,
            textPlacement: textPlacement,
            color: .white
        )
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusRemoteControl(),
            icon: "appletvremote.gen1",
            text: model.remoteControlStatus,
            textPlacement: textPlacement,
            color: remoteControlColor()
        )
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusGameController(),
            icon: "gamecontroller",
            text: model.gameControllersTotal,
            textPlacement: textPlacement,
            color: .white
        )
        if textPlacement == .hide {
            CollapsedBitrateView(show: model.isShowingStatusBitrate(), color: netStreamColor())
        } else {
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusBitrate(),
                icon: "speedometer",
                text: model.speedAndTotal,
                textPlacement: textPlacement,
                color: netStreamColor()
            )
        }
        if textPlacement == .hide {
            CollapsedBondingView(show: model.isShowingStatusBonding(), color: netStreamColor())
        } else {
            StreamOverlayIconAndTextView(
                show: model.isShowingStatusBonding(),
                icon: "phone.connection",
                text: model.bondingStatistics,
                textPlacement: textPlacement,
                color: netStreamColor()
            )
        }
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusUptime(),
            icon: "deskclock",
            text: model.uptime,
            textPlacement: textPlacement,
            color: netStreamColor()
        )
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusLocation(),
            icon: "location",
            text: model.location,
            textPlacement: textPlacement,
            color: .white
        )
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusRecording(),
            icon: "record.circle",
            text: model.recordingLength,
            textPlacement: textPlacement,
            color: .white
        )
        StreamOverlayIconAndTextView(
            show: model.isShowingStatusBrowserWidgets(),
            icon: "globe",
            text: model.browserWidgetsStatus,
            textPlacement: textPlacement,
            color: .white
        )
    }
}

struct RightOverlayView: View {
    @EnvironmentObject var model: Model
    let width: CGFloat

    private var database: Database {
        model.settings.database
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            VStack(alignment: .trailing, spacing: 1) {
                if model.isShowingStatusAudioLevel() {
                    AudioLevelView(
                        showBar: database.show.audioBar,
                        level: model.audioLevel,
                        channels: model.numberOfAudioChannels
                    )
                    .padding(20)
                    .contentShape(Rectangle())
                    .padding(-20)
                }
                if model.verboseStatuses {
                    StatusesView(textPlacement: .beforeIcon)
                } else {
                    HStack(spacing: 1) {
                        StatusesView(textPlacement: .hide)
                    }
                }
            }
            .onTapGesture {
                model.toggleVerboseStatuses()
            }
            Spacer()
            if !(model.showDrawOnStream || model.showFace) {
                if model.showMediaPlayerControls {
                    StreamOverlayRightMediaPlayerControlsView()
                } else {
                    if model.showingCamera {
                        StreamOverlayRightCameraSettingsControlView()
                    }
                    if database.show.zoomPresets && model.hasZoom {
                        StreamOverlayRightZoomPresetSelctorView(width: width)
                    }
                }
                StreamOverlayRightSceneSelectorView(width: width)
            }
        }
    }
}
