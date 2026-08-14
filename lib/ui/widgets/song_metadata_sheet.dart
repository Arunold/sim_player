import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import '../../core/constants/theme_constants.dart';
import '../../data/models/song.dart';
import '../../data/models/rich_metadata.dart';
import '../../services/metadata_service.dart';

/// Full screen elegant display of song metadata with glassy effect
class SongMetadataSheet extends StatefulWidget {
  final Song song;

  const SongMetadataSheet({super.key, required this.song});

  /// Show metadata as a full screen modal with slide-up animation
  static void show(BuildContext context, Song song) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: context.colors.backgroundSecondary,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SongMetadataSheet(song: song);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<SongMetadataSheet> createState() => _SongMetadataSheetState();
}

class _SongMetadataSheetState extends State<SongMetadataSheet> {
  final MetadataService _metadataService = MetadataService();
  RichMetadata? _richMetadata;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      final file = File(widget.song.filePath);
      final metadata = _metadataService.extractMetadata(file, getImage: false);
      if (mounted) {
        setState(() {
          _richMetadata = metadata;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load rich metadata: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred album art background
          if (widget.song.artworkPath != null)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Image.file(
                  File(widget.song.artworkPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: context.colors.backgroundPrimary),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(color: context.colors.backgroundPrimary),
            ),
          // Gradient overlay
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding: const EdgeInsets.all(
                            ThemeConstants.spacingLg,
                          ),
                          children: [
                            // Album art and basic info
                            _buildHeaderSection(context),
                            const SizedBox(height: ThemeConstants.spacingXl),
                            // Metadata cards
                            _buildMetadataSection(context),
                            const SizedBox(height: ThemeConstants.spacingLg),
                            // Credits section (if available)
                            if (_hasCredits()) ...[
                              _buildCreditsSection(context),
                              const SizedBox(height: ThemeConstants.spacingLg),
                            ],
                            // Technical info
                            _buildTechnicalSection(context),
                            const SizedBox(height: ThemeConstants.spacingLg),
                            // File info
                            _buildFileInfoSection(context),
                            const SizedBox(height: ThemeConstants.spacingLg),
                            // Statistics
                            _buildStatsSection(context),
                            // Lyrics section (if available)
                            if (_richMetadata?.lyrics != null &&
                                _richMetadata!.lyrics!.isNotEmpty) ...[
                              const SizedBox(height: ThemeConstants.spacingLg),
                              _buildLyricsSection(context),
                            ],
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

  bool _hasCredits() {
    final m = _richMetadata;
    if (m == null) return false;
    return m.composer != null ||
        m.lyricist != null ||
        m.conductor != null ||
        m.band != null ||
        m.performer != null ||
        m.publisher != null;
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
          Icon(Icons.info_outline_rounded, color: context.colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Song Details',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Show format badge
          if (_richMetadata?.audioFormat != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(ThemeConstants.radiusSm),
              ),
              child: Text(
                _richMetadata!.audioFormat.displayName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
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
                color: context.colors.backgroundTertiary.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
            child: widget.song.artworkPath != null
                ? Image.file(
                    File(widget.song.artworkPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildArtPlaceholder(context),
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
                widget.song.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildQuickInfo(
                context,
                Icons.person_rounded,
                widget.song.artist,
              ),
              const SizedBox(height: 6),
              _buildQuickInfo(context, Icons.album_rounded, widget.song.album),
              if (widget.song.genre != null) ...[
                const SizedBox(height: 6),
                _buildQuickInfo(
                  context,
                  Icons.music_note_rounded,
                  widget.song.genre!,
                ),
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
        Icon(icon, size: 18, color: context.colors.textSecondary),
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
    final m = _richMetadata;
    return _buildSection(context, 'Metadata', Icons.label_rounded, [
      _MetadataItem(label: 'Title', value: m?.title ?? widget.song.title),
      _MetadataItem(label: 'Artist', value: m?.artist ?? widget.song.artist),
      _MetadataItem(label: 'Album', value: m?.album ?? widget.song.album),
      if (m?.albumArtist != null)
        _MetadataItem(label: 'Album Artist', value: m!.albumArtist!),
      if (m?.genres.isNotEmpty == true)
        _MetadataItem(label: 'Genre', value: m!.genres.join(', ')),
      if (m?.year != null)
        _MetadataItem(label: 'Year', value: m!.year.toString()),
      if (m?.trackNumber != null)
        _MetadataItem(
          label: 'Track',
          value: m!.trackTotal != null
              ? '${m.trackNumber} of ${m.trackTotal}'
              : m.trackNumber.toString(),
        ),
      if (m?.discNumber != null)
        _MetadataItem(
          label: 'Disc',
          value: m!.discTotal != null
              ? '${m.discNumber} of ${m.discTotal}'
              : m.discNumber.toString(),
        ),
      _MetadataItem(
        label: 'Duration',
        value: m?.durationFormatted ?? widget.song.durationFormatted,
      ),
      if (m?.bpm != null) _MetadataItem(label: 'BPM', value: m!.bpm!),
    ]);
  }

  Widget _buildCreditsSection(BuildContext context) {
    final m = _richMetadata!;
    return _buildSection(context, 'Credits', Icons.people_rounded, [
      if (m.composer != null)
        _MetadataItem(label: 'Composer', value: m.composer!),
      if (m.lyricist != null)
        _MetadataItem(label: 'Lyricist', value: m.lyricist!),
      if (m.conductor != null)
        _MetadataItem(label: 'Conductor', value: m.conductor!),
      if (m.band != null) _MetadataItem(label: 'Band', value: m.band!),
      if (m.performer != null)
        _MetadataItem(label: 'Performer', value: m.performer!),
      if (m.publisher != null)
        _MetadataItem(label: 'Publisher', value: m.publisher!),
      if (m.copyright != null)
        _MetadataItem(label: 'Copyright', value: m.copyright!),
    ]);
  }

  Widget _buildTechnicalSection(BuildContext context) {
    final m = _richMetadata;
    return _buildSection(context, 'Technical', Icons.tune_rounded, [
      _MetadataItem(
        label: 'Format',
        value:
            m?.audioFormat.displayName ??
            widget.song.fileExtension?.toUpperCase() ??
            'Unknown',
      ),
      if (m?.bitrateFormatted != null || widget.song.bitrate != null)
        _MetadataItem(
          label: 'Bitrate',
          value:
              m?.bitrateFormatted ??
              '${(widget.song.bitrate! / 1000).round()} kbps',
        ),
      if (m?.sampleRateFormatted != null)
        _MetadataItem(label: 'Sample Rate', value: m!.sampleRateFormatted!),
      if (m?.encoder != null)
        _MetadataItem(label: 'Encoder', value: m!.encoder!),
      if (m?.encodedBy != null)
        _MetadataItem(label: 'Encoded By', value: m!.encodedBy!),
      if (m?.isrc != null) _MetadataItem(label: 'ISRC', value: m!.isrc!),
    ]);
  }

  Widget _buildFileInfoSection(BuildContext context) {
    return _buildSection(context, 'File Information', Icons.folder_rounded, [
      _MetadataItem(
        label: 'File Size',
        value: _formatFileSize(widget.song.fileSize),
      ),
      _MetadataItem(
        label: 'Location',
        value: widget.song.filePath,
        isPath: true,
      ),
    ]);
  }

  Widget _buildStatsSection(BuildContext context) {
    return _buildSection(context, 'Statistics', Icons.analytics_rounded, [
      _MetadataItem(
        label: 'Added to Library',
        value: _formatDate(widget.song.dateAdded),
      ),
      if (widget.song.lastPlayed != null)
        _MetadataItem(
          label: 'Last Played',
          value: _formatDate(widget.song.lastPlayed!),
        ),
      _MetadataItem(
        label: 'Play Count',
        value: widget.song.playCount.toString(),
      ),
      _MetadataItem(
        label: 'Favorite',
        value: widget.song.isFavorite ? 'Yes' : 'No',
      ),
    ]);
  }

  Widget _buildLyricsSection(BuildContext context) {
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
                  Icons.lyrics_rounded,
                  size: 20,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Lyrics',
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
          // Lyrics content
          Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingMd),
            child: Text(
              _richMetadata!.lyrics!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textPrimary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<_MetadataItem> items,
  ) {
    // Filter out items with empty values
    final filteredItems = items.where((item) => item.value.isNotEmpty).toList();
    if (filteredItems.isEmpty) return const SizedBox.shrink();

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
                Icon(icon, size: 20, color: context.colors.primary),
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
          ...filteredItems.map((item) => _buildMetadataRow(context, item)),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
