import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import '../../core/constants/theme_constants.dart';
import '../../data/models/song.dart';

/// Full screen elegant display of song metadata with glassy effect
class SongMetadataSheet extends StatelessWidget {
  final Song song;

  const SongMetadataSheet({super.key, required this.song});

  /// Show metadata as a full screen modal with slide-up animation
  static void show(BuildContext context, Song song) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SongMetadataSheet(song: song);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred album art background
          if (song.artworkPath != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Image.file(
                  File(song.artworkPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: context.colors.backgroundPrimary,
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(color: context.colors.backgroundPrimary),
            ),
          // Dark gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.backgroundPrimary.withValues(alpha: 0.8),
                    context.colors.backgroundPrimary.withValues(alpha: 0.92),
                    context.colors.backgroundPrimary.withValues(alpha: 0.98),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(context),
                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(ThemeConstants.spacingLg),
                    children: [
                      // Album art and basic info
                      _buildHeaderSection(context),
                      const SizedBox(height: ThemeConstants.spacingXl),
                      // Metadata cards
                      _buildMetadataSection(context),
                      const SizedBox(height: ThemeConstants.spacingLg),
                      // File info
                      _buildFileInfoSection(context),
                      const SizedBox(height: ThemeConstants.spacingLg),
                      // Statistics
                      _buildStatsSection(context),
                      const SizedBox(height: ThemeConstants.spacingXl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingSm,
        vertical: ThemeConstants.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            iconSize: 28,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.info_outline_rounded,
            color: context.colors.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Song Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Album artwork
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            child: song.artworkPath != null
                ? Image.file(
                    File(song.artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildArtPlaceholder(context),
                  )
                : _buildArtPlaceholder(context),
          ),
        ),
        const SizedBox(width: ThemeConstants.spacingLg),
        // Basic info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildQuickInfo(context, Icons.person_rounded, song.artist),
              const SizedBox(height: 6),
              _buildQuickInfo(context, Icons.album_rounded, song.album),
              if (song.genre != null) ...[
                const SizedBox(height: 6),
                _buildQuickInfo(context, Icons.music_note_rounded, song.genre!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfo(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return _buildSection(
      context,
      'Metadata',
      Icons.label_rounded,
      [
        _MetadataItem(label: 'Title', value: song.title),
        _MetadataItem(label: 'Artist', value: song.artist),
        _MetadataItem(label: 'Album', value: song.album),
        if (song.albumArtist != null)
          _MetadataItem(label: 'Album Artist', value: song.albumArtist!),
        if (song.genre != null) _MetadataItem(label: 'Genre', value: song.genre!),
        if (song.year != null)
          _MetadataItem(label: 'Year', value: song.year.toString()),
        if (song.trackNumber != null)
          _MetadataItem(label: 'Track #', value: song.trackNumber.toString()),
        _MetadataItem(label: 'Duration', value: song.durationFormatted),
      ],
    );
  }

  Widget _buildFileInfoSection(BuildContext context) {
    return _buildSection(
      context,
      'File Information',
      Icons.folder_rounded,
      [
        _MetadataItem(
          label: 'Format',
          value: song.fileExtension?.toUpperCase() ?? 'Unknown',
        ),
        if (song.bitrate != null)
          _MetadataItem(
            label: 'Bitrate',
            value: '${song.bitrate} kbps',
          ),
        _MetadataItem(
          label: 'File Size',
          value: _formatFileSize(song.fileSize),
        ),
        _MetadataItem(
          label: 'Location',
          value: song.filePath,
          isPath: true,
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return _buildSection(
      context,
      'Statistics',
      Icons.analytics_rounded,
      [
        _MetadataItem(
          label: 'Added to Library',
          value: _formatDate(song.dateAdded),
        ),
        if (song.lastPlayed != null)
          _MetadataItem(
            label: 'Last Played',
            value: _formatDate(song.lastPlayed!),
          ),
        _MetadataItem(
          label: 'Play Count',
          value: song.playCount.toString(),
        ),
        _MetadataItem(
          label: 'Favorite',
          value: song.isFavorite ? 'Yes' : 'No',
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<_MetadataItem> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.card.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
        border: Border.all(
          color: context.colors.divider.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.primary,
                      ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: context.colors.divider.withValues(alpha: 0.15),
          ),
          // Items
          ...items.map((item) => _buildMetadataRow(context, item)),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, _MetadataItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMd,
        vertical: ThemeConstants.spacingSm + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              item.value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: item.isPath ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtPlaceholder(BuildContext context) {
    return Container(
      color: context.colors.card,
      child: Icon(
        Icons.music_note_rounded,
        size: 56,
        color: context.colors.textTertiary,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _MetadataItem {
  final String label;
  final String value;
  final bool isPath;

  const _MetadataItem({
    required this.label,
    required this.value,
    this.isPath = false,
  });
}
