import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:namida/class/track.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/dimensions.dart';
import 'package:namida/core/extensions.dart';
import 'package:namida/core/functions.dart';
import 'package:namida/ui/widgets/artwork.dart';
import 'package:namida/ui/widgets/custom_widgets.dart';
import 'package:namida/ui/dialogs/common_dialogs.dart';

class AlbumTile extends StatelessWidget {
  final String name;
  final List<Track> album;

  const AlbumTile({
    super.key,
    required this.name,
    required this.album,
  });

  @override
  Widget build(BuildContext context) {
    final albumThumbnailSize = SettingsController.inst.albumThumbnailSizeinList.value;
    final albumTileHeight = SettingsController.inst.albumListTileHeight.value;
    final finalYear = album.year.yearFormatted;
    final hero = 'album_$name';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0).add(const EdgeInsets.only(bottom: Dimensions.tileBottomMargin)),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: context.theme.shadowColor.withAlpha(20),
            blurRadius: 12.0,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: NamidaInkWell(
        borderRadius: 0.2 * albumTileHeight,
        bgColor: context.theme.cardColor,
        onTap: () => NamidaOnTaps.inst.onAlbumTap(album.album),
        onLongPress: () => NamidaDialogs.inst.showAlbumDialog(name),
        padding: const EdgeInsets.symmetric(vertical: Dimensions.tileVerticalPadding),
        child: SizedBox(
          height: Dimensions.inst.albumTileItemExtent,
          child: Row(
            children: [
              const SizedBox(width: 12.0),
              SizedBox(
                width: albumThumbnailSize,
                height: albumThumbnailSize,
                child: Hero(
                  tag: hero,
                  child: ArtworkWidget(
                    thumbnailSize: albumThumbnailSize,
                    track: album.trackOfImage,
                    path: album.pathToImage,
                    forceSquared: SettingsController.inst.forceSquaredAlbumThumbnail.value,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'line1_$hero',
                      child: Text(
                        album.album,
                        style: context.textTheme.displayMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (album.albumArtist != '')
                      Hero(
                        tag: 'line2_$hero',
                        child: Text(
                          album.albumArtist,
                          style: context.textTheme.displaySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Hero(
                      tag: 'line3_$hero',
                      child: Text(
                        [
                          album.displayTrackKeyword,
                          if (finalYear != '') finalYear,
                        ].join(' • '),
                        style: context.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                [
                  album.totalDurationFormatted,
                ].join(' - '),
                style: context.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 4.0),
              MoreIcon(
                padding: 6.0,
                onPressed: () => NamidaDialogs.inst.showAlbumDialog(name),
              ),
              const SizedBox(width: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
