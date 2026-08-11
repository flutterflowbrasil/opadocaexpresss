import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

enum CaptureMode { selfie, document }

class CameraCaptureScreen extends StatefulWidget {
  final CaptureMode mode;

  const CameraCaptureScreen({
    super.key,
    required this.mode,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  String? _errorMessage;
  bool _isCapturing = false;
  int _cameraInitToken = 0;

  bool get _isSelfie => widget.mode == CaptureMode.selfie;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFuture = _initializeCamera();
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<void> _initializeCamera() async {
    final token = ++_cameraInitToken;
    try {
      _errorMessage = null;
      await _disposeController();
      await Future<void>.delayed(const Duration(milliseconds: 150));

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'Nenhuma câmera disponível.');
      }

      final desiredDirection =
          _isSelfie ? CameraLensDirection.front : CameraLensDirection.back;
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == desiredDirection,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted || token != _cameraInitToken) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      setState(() {});
    } on CameraException catch (e) {
      await _disposeController();
      _errorMessage = _cameraErrorMessage(e);
      if (mounted) setState(() {});
    } on PlatformException catch (e) {
      await _disposeController();
      _errorMessage = _platformCameraErrorMessage(e);
      if (mounted) setState(() {});
    } catch (e) {
      await _disposeController();
      _errorMessage = 'Não foi possível abrir a câmera.\nDetalhe: $e';
      if (mounted) setState(() {});
    }
  }

  Future<void> _pickWithImagePicker() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice:
            _isSelfie ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 85,
      );
      if (!mounted || file == null) return;
      await _disposeController();
      if (!mounted) return;
      Navigator.pop(context, file.path);
    } catch (e) {
      if (!mounted) return;
      _showError('Não foi possível obter a foto: $e');
    }
  }

  String _cameraErrorMessage(CameraException error) {
    final description = error.description;
    final detail = description == null || description.isEmpty
        ? 'Código: ${error.code}'
        : '$description\nCódigo: ${error.code}';

    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        'Permissão da câmera negada.\nLibere o acesso à câmera nas configurações do app.\n$detail',
      'no_camera' =>
        'Nenhuma câmera disponível neste dispositivo.\nNo emulador, confira se a câmera virtual está habilitada.\n$detail',
      _ => 'Não foi possível abrir a câmera.\n$detail',
    };
  }

  String _platformCameraErrorMessage(PlatformException error) {
    final detail = [
      if (error.message != null && error.message!.isNotEmpty) error.message,
      if (error.details != null) 'Detalhe: ${error.details}',
      'Código: ${error.code}',
    ].whereType<String>().join('\n');

    if (error.code == 'channel-error') {
      return 'Plugin da câmera não foi carregado no app instalado.\n'
          'Pare o app e rode uma instalação completa novamente.\n$detail';
    }

    return 'Não foi possível abrir a câmera.\n$detail';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraInitToken++;
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isCapturing) return;

    if (state == AppLifecycleState.paused) {
      _cameraInitToken++;
      unawaited(_disposeController());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _initializeFuture = _initializeCamera();
      if (mounted) setState(() {});
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (_isCapturing ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      final path = file.path;
      _cameraInitToken++;
      await _disposeController();
      if (!mounted) return;
      Navigator.pop(context, path);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showError(e.description ?? 'Não foi possível capturar a foto.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCapturing = false);
      _showError('Não foi possível capturar a foto.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red[700],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSelfie
        ? 'Encaixe seu rosto na área indicada'
        : 'Encaixe o documento dentro da moldura';

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          final controller = _controller;
          final isReady = snapshot.connectionState == ConnectionState.done &&
              controller != null &&
              controller.value.isInitialized &&
              _errorMessage == null;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (isReady)
                _FullscreenCameraPreview(controller: controller)
              else if (_errorMessage == null)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              if (_errorMessage != null)
                Positioned.fill(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 112, 24, 112),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _initializeFuture = _initializeCamera();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _pickWithImagePicker,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white54),
                            ),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Usar câmera do sistema'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isReady)
                CustomPaint(
                  painter: _CaptureOverlayPainter(mode: widget.mode),
                  child: const SizedBox.expand(),
                ),
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const Spacer(),
                      if (_errorMessage == null) ...[
                        _CaptureButton(
                          enabled: isReady && !_isCapturing,
                          isCapturing: _isCapturing,
                          onPressed: _capturePhoto,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FullscreenCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _FullscreenCameraPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final bool enabled;
  final bool isCapturing;
  final VoidCallback onPressed;

  const _CaptureButton({
    required this.enabled,
    required this.isCapturing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : .55,
        duration: const Duration(milliseconds: 160),
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureOverlayPainter extends CustomPainter {
  final CaptureMode mode;

  const _CaptureOverlayPainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: .62);
    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, overlayPaint);

    if (mode == CaptureMode.selfie) {
      final ovalRect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .45),
        width: size.width * .68,
        height: size.height * .42,
      );
      canvas.drawOval(ovalRect, clearPaint);
      canvas.drawOval(
        ovalRect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.white,
      );
    } else {
      final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .45),
        width: size.width * .84,
        height: size.width * .54,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        clearPaint,
      );
      _drawDocumentCorners(canvas, rect);
    }

    canvas.restore();
  }

  void _drawDocumentCorners(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const length = 34.0;

    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(length, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, length), paint);

    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-length, 0),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, length),
      paint,
    );

    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(length, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -length),
      paint,
    );

    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-length, 0),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CaptureOverlayPainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}
