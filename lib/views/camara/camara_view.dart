import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/permissions_service.dart';
import '../../widgets/base_view.dart';

// Filtros de color predefinidos usando matrices RGBA 5x4
class _ColorFilter {
  final String name;
  final IconData icon;
  final List<double>? matrix;
  const _ColorFilter(this.name, this.icon, this.matrix);
}

const _filters = [
  _ColorFilter('Original', Icons.image, null),
  _ColorFilter('B/N', Icons.contrast, [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  _ColorFilter('Sepia', Icons.wb_sunny_outlined, [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  _ColorFilter('Cálido', Icons.wb_sunny, [
    1.2, 0, 0, 0, 0,
    0, 1.0, 0, 0, 0,
    0, 0, 0.8, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  _ColorFilter('Frío', Icons.ac_unit, [
    0.8, 0, 0, 0, 0,
    0, 1.0, 0, 0, 0,
    0, 0, 1.2, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  _ColorFilter('Invertir', Icons.invert_colors, [
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]),
];

const _green = Color.fromARGB(255, 20, 165, 97);

class CamaraView extends StatefulWidget {
  const CamaraView({super.key});

  @override
  State<CamaraView> createState() => _CamaraViewState();
}

class _CamaraViewState extends State<CamaraView> {
  File? _image;
  int _selectedFilter = 0;
  final _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final granted = await PermissionsService.requestCamera();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de cámara denegado. '
                'Actívalo en Configuración > Aplicaciones.'),
          ),
        );
      }
      return;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo != null && mounted) {
      setState(() {
        _image = File(photo.path);
        _selectedFilter = 0;
      });
    }
  }

  Future<void> _editPhoto() async {
    if (_image == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: _image!.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Editar Foto',
          toolbarColor: _green,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: _green,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Editar Foto',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );

    if (cropped != null && mounted) {
      setState(() => _image = File(cropped.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView(
      title: 'Cámara',
      body: Column(
        children: [
          Expanded(child: _buildPreview()),
          if (_image != null) _buildFilterStrip(),
          _buildActionBar(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_image == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, size: 96, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Sin foto',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca "Tomar foto" para comenzar',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final filter = _filters[_selectedFilter];
    Widget img = Image.file(
      _image!,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
    );

    if (filter.matrix != null) {
      img = ColorFiltered(
        colorFilter: ColorFilter.matrix(filter.matrix!),
        child: img,
      );
    }

    return ClipRect(child: img);
  }

  Widget _buildFilterStrip() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              decoration: BoxDecoration(
                color: selected ? _green : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? _green : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _filters[i].icon,
                    color: selected ? Colors.white : Colors.grey[600],
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _filters[i].name,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? Colors.white : Colors.grey[600],
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionButton(
            icon: Icons.camera_alt,
            label: _image == null ? 'Tomar foto' : 'Nueva foto',
            color: _green,
            onTap: _takePhoto,
          ),
          if (_image != null)
            _actionButton(
              icon: Icons.crop,
              label: 'Recortar',
              color: Colors.indigo,
              onTap: _editPhoto,
            ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
