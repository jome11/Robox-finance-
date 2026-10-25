import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/finance/services/image_api_service.dart';
import '../theme/app_theme.dart';

/// Shows one attachment (square thumbnail).
class AttachmentImage extends StatelessWidget {
  final String reference;
  final double size;
  final BoxFit fit;

  const AttachmentImage({
    super.key,
    required this.reference,
    this.size = 100,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder(IconData icon, String text) {
    return Container(
      width: size,
      height: size,
      color: AppTheme.lightBlueBackground,
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.textMuted),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ImageApiService.isRemote(reference)) {
      return _placeholder(
        Icons.phone_android,
        'Old photo, only on the original phone',
      );
    }
    return Image.network(
      ImageApiService.urlFor(reference),
      headers: ImageApiService.authHeaders,
      width: size,
      height: size,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: size,
          height: size,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) =>
          _placeholder(Icons.broken_image_outlined, 'Could not load'),
    );
  }
}

/// Full-screen zoomable viewer.
void showAttachmentViewer(BuildContext context, String reference) {
  if (!ImageApiService.isRemote(reference)) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  ImageApiService.urlFor(reference),
                  headers: ImageApiService.authHeaders,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Add / remove photos. Each photo uploads as soon as it is picked.
class AttachmentPicker extends StatefulWidget {
  final List<String> references;
  final ValueChanged<List<String>> onChanged;
  final ValueChanged<bool>? onBusyChanged;

  const AttachmentPicker({
    super.key,
    required this.references,
    required this.onChanged,
    this.onBusyChanged,
  });

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker> {
  final ImagePicker _picker = ImagePicker();
  int _uploading = 0;

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mimeFor(XFile file) {
    final declared = file.mimeType;
    if (declared == 'image/png' || declared == 'image/webp' || declared == 'image/jpeg') {
      return declared!;
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _add(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
      );
      if (file == null) return;

      setState(() => _uploading++);
      widget.onBusyChanged?.call(true);

      final bytes = await file.readAsBytes();
      final ref = await ImageApiService.upload(bytes, mime: _mimeFor(file));
      if (!mounted) return;
      widget.onChanged([...widget.references, ref]);
    } on ImageUploadException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Could not add the photo: $e');
    } finally {
      if (mounted && _uploading > 0) {
        setState(() => _uploading--);
        widget.onBusyChanged?.call(_uploading > 0);
      }
    }
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _add(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _add(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _thumb(int index, String ref) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => showAttachmentViewer(context, ref),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AttachmentImage(reference: ref, size: 100),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                final next = [...widget.references]..removeAt(index);
                widget.onChanged(next);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.dangerRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile({required Widget child, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refs = widget.references;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (var i = 0; i < refs.length; i++) _thumb(i, refs[i]),
        for (var i = 0; i < _uploading; i++)
          _tile(
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        _tile(
          onTap: _chooseSource,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue),
              SizedBox(height: 6),
              Text(
                'Add photo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
