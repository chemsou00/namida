import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:namida/controller/current_color.dart';
import 'package:namida/controller/player_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/icon_fonts/broken_icons.dart';
import 'package:namida/core/namida_converter_ext.dart';
import 'package:namida/core/translations/language.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/widgets/settings/extra_settings.dart';
import 'package:namida/youtube/class/youtube_id.dart';
import 'package:namida/youtube/class/youtube_item_download_config.dart';
import 'package:namida/youtube/controller/youtube_controller.dart';
import 'package:namida/youtube/widgets/yt_thumbnail.dart';
import 'package:namida/youtube/yt_utils.dart';

class YTDownloadTaskItemCard extends StatelessWidget {
  final List<YoutubeItemDownloadConfig> videos;
  final int index;
  final String groupName;

  const YTDownloadTaskItemCard({
    super.key,
    required this.videos,
    required this.index,
    required this.groupName,
  });
  Widget _getChip({
    required BuildContext context,
    required IconData icon,
    required String title,
    String betweenBrackets = '',
    bool displayTitle = false,
    void Function()? onTap,
  }) {
    final textWidget = RichText(
      text: TextSpan(
        children: [
          TextSpan(text: title, style: context.textTheme.displayMedium?.copyWith(fontSize: 13.0.multipliedFontScale)),
          if (betweenBrackets != '')
            TextSpan(
              text: " ($betweenBrackets)",
              style: Get.textTheme.displaySmall?.copyWith(fontSize: 11.0.multipliedFontScale),
            ),
        ],
      ),
    );
    return NamidaInkWell(
      borderRadius: 6.0,
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, top: 6.0, bottom: 6.0),
      onTap: onTap,
      child: Tooltip(
        message: title,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: displayTitle ? 16.0 : 17.0),
            if (displayTitle) ...[
              const SizedBox(width: 4.0),
              textWidget,
            ],
          ],
        ),
      ),
    );
  }

  void _onPauseDownloadTap(List<YoutubeItemDownloadConfig> itemsConfig, bool isDownloading, BuildContext context) {
    isDownloading
        ? YoutubeController.inst.pauseDownloadTask(
            itemsConfig: itemsConfig,
            groupName: groupName,
          )
        : YoutubeController.inst.downloadYoutubeVideos(
            useCachedVersionsIfAvailable: true,
            autoExtractTitleAndArtist: settings.ytAutoExtractVideoTagsFromInfo.value,
            keepCachedVersionsIfDownloaded: settings.downloadFilesKeepCachedVersions.value,
            downloadFilesWriteUploadDate: settings.downloadFilesWriteUploadDate.value,
            itemsConfig: itemsConfig,
            groupName: groupName,
            onFileDownloaded: (downloadedFile) async {
              if (downloadedFile != null) {
                build(context);
              }
            },
            onOldFileDeleted: (deletedFile) async {
              build(context);
            },
          );
  }

  void _onCancelDeleteDownloadTap(List<YoutubeItemDownloadConfig> itemsConfig) {
    YoutubeController.inst.cancelDownloadTask(itemsConfig: itemsConfig, groupName: groupName);
  }

  @override
  Widget build(BuildContext context) {
    final directory = groupName == '' ? Directory(AppDirs.YOUTUBE_DOWNLOADS) : Directory("${AppDirs.YOUTUBE_DOWNLOADS}$groupName");
    final item = videos[index];
    final downloadedFile = File("${directory.path}/${item.filename}");

    const thumbHeight = 24.0 * 2.6;
    const thumbWidth = thumbHeight * 16 / 9;

    final video = videos[index];
    final info = YoutubeController.inst.fetchVideoDetailsFromCacheSync(video.id);
    final duration = info?.duration?.inSeconds.secondsLabel;
    final menuItems = YTUtils.getVideoCardMenuItems(
      videoId: video.id,
      url: info?.url,
      playlistID: null,
      idsNamesLookup: {video.id: info?.name},
      playlistName: '',
      videoYTID: null,
    );
    // final backupVideoInfo = YoutubeController.inst.getBackupVideoInfo(video.id);
    // final videoTitle = info?.name ?? backupVideoInfo?.title ?? video.id;
    // final videoSubtitle = info?.uploaderName ?? backupVideoInfo?.channel;
    return NamidaPopupWrapper(
      openOnTap: false,
      openOnLongPress: true,
      childrenDefault: menuItems,
      child: NamidaInkWell(
        borderRadius: 10.0,
        onTap: () {
          YTUtils.expandMiniplayer();
          Player.inst.playOrPause(index, videos.map((e) => YoutubeID(id: e.id, playlistID: null)), QueueSource.others);
        },
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        bgColor: context.theme.cardColor,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0.multipliedRadius),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4.0),
            YoutubeThumbnail(
              key: Key(video.id),
              borderRadius: 8.0,
              isImportantInCache: true,
              width: thumbWidth,
              height: thumbHeight,
              videoId: video.id,
              onTopWidgets: [
                if (duration != null)
                  Positioned(
                    bottom: 0.0,
                    right: 0.0,
                    child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0.multipliedRadius),
                        child: NamidaBgBlur(
                          blur: 2.0,
                          enabled: settings.enableBlurEffect.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                            color: Colors.black.withOpacity(0.2),
                            child: Text(
                              duration,
                              style: context.textTheme.displaySmall?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Obx(() {
                final isDownloading = YoutubeController.inst.isDownloading[item.id]?[item.filename] ?? false;
                final isFetchingData = YoutubeController.inst.isFetchingData[item.id]?[item.filename] ?? false;
                final audioP = YoutubeController.inst.downloadsAudioProgressMap[item.id]?[item.filename];
                final audioPerc = audioP == null ? null : audioP.progress / audioP.totalProgress;
                final videoP = YoutubeController.inst.downloadsVideoProgressMap[item.id]?[item.filename];
                final videoPerc = videoP == null ? null : videoP.progress / videoP.totalProgress;

                final speedB = YoutubeController.inst.currentSpeedsInByte[item.id]?[item.filename];
                final cp = videoP?.progress ?? audioP?.progress ?? 0;
                final ctp = videoP?.totalProgress ?? audioP?.totalProgress ?? 0;
                final speedText = speedB == null ? '' : ' (${speedB.fileSizeFormatted}/s)';
                final downloadInfoText = " • ${cp.fileSizeFormatted}/${ctp.fileSizeFormatted}$speedText";
                final canDisplayPercentage = audioPerc != null || videoPerc != null;

                final fileExists = downloadedFile.existsSync();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6.0),
                    Text(
                      item.filename,
                      style: context.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        if (canDisplayPercentage || isFetchingData || isDownloading) ...[
                          canDisplayPercentage
                              ? Text(
                                  audioPerc != null
                                      ? lang.AUDIO
                                      : videoPerc != null
                                          ? lang.VIDEO
                                          : '',
                                  style: context.textTheme.displaySmall,
                                )
                              : const LoadingIndicator(),
                          const SizedBox(width: 6.0),
                        ],
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 2.0,
                                    decoration: BoxDecoration(
                                      color: CurrentColor.inst.color.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(6.0.multipliedRadius),
                                    ),
                                    width: (fileExists ? 1.0 : (audioPerc ?? videoPerc ?? 0.0)) * constraints.maxWidth,
                                  ),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    height: 2.0,
                                    decoration: BoxDecoration(
                                      color: CurrentColor.inst.color.withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(6.0.multipliedRadius),
                                    ),
                                    width: 1.0 * constraints.maxWidth,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (canDisplayPercentage) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        "${audioPerc != null ? "${(audioPerc * 100).toStringAsFixed(0)}%" : videoPerc != null ? "${(videoPerc * 100).toStringAsFixed(0)}%" : ''}$downloadInfoText",
                        style: context.textTheme.displaySmall?.copyWith(fontSize: 11.0.multipliedFontScale),
                      ),
                    ],
                    const SizedBox(height: 4.0),
                    // -- ItemActionsRow
                    Row(
                      children: [
                        Obx(
                          () {
                            final isDownloading = YoutubeController.inst.isDownloading[item.id]?[item.filename] ?? false;
                            return isDownloading
                                ? _getChip(
                                    context: context,
                                    title: lang.PAUSE,
                                    icon: Broken.pause,
                                    onTap: () => _onPauseDownloadTap([video], isDownloading, context),
                                  )
                                : fileExists
                                    ? _getChip(
                                        context: context,
                                        title: lang.RESTART,
                                        icon: Broken.refresh,
                                        onTap: () => _onPauseDownloadTap([video], isDownloading, context),
                                      )
                                    : _getChip(
                                        context: context,
                                        title: lang.RESUME,
                                        icon: Broken.play,
                                        onTap: () => _onPauseDownloadTap([video], isDownloading, context),
                                      );
                          },
                        ),
                        fileExists
                            ? _getChip(
                                context: context,
                                title: lang.DELETE,
                                icon: Broken.trash,
                                betweenBrackets: fileExists ? downloadedFile.lengthSync().fileSizeFormatted : '',
                                onTap: () => _onCancelDeleteDownloadTap([video]),
                              )
                            : _getChip(
                                context: context,
                                title: lang.CANCEL,
                                icon: Broken.close_circle,
                                onTap: () => _onCancelDeleteDownloadTap([video]),
                              ),
                        _getChip(
                          context: context,
                          title: lang.EDIT,
                          icon: Broken.edit_2,
                          onTap: () {},
                        ),
                        _getChip(
                          context: context,
                          title: lang.INFO,
                          icon: Broken.info_circle,
                          onTap: () {},
                        ),
                        const Spacer(),
                        Text(
                          [
                            if (item.videoStream?.resolution != null) item.videoStream?.resolution ?? '',
                            fileExists ? downloadedFile.lengthSync().fileSizeFormatted : '',
                          ].join(' • '),
                          style: context.textTheme.displaySmall?.copyWith(fontSize: 11.0.multipliedFontScale),
                        ),
                        const SizedBox(width: 4.0),
                        fileExists
                            ? Icon(
                                Broken.tick_circle,
                                size: 16.0,
                                color: context.defaultIconColor(),
                              )
                            : Icon(
                                Broken.import,
                                size: 16.0,
                                color: context.defaultIconColor(),
                              ),
                      ],
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(width: 8.0),
          ],
        ),
      ),
    );
  }
}
