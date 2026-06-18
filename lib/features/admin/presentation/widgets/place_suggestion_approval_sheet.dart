import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../places/domain/models/place_model.dart';
import '../../../places/domain/models/place_suggestion_model.dart';
import '../../../places/presentation/screens/place_location_picker_screen.dart';
import '../../../places/presentation/widgets/place_open_hours_picker.dart';

class PlaceSuggestionApprovalResult {
  final PlaceSuggestionModel approvedPlace;
  final String? adminNote;

  const PlaceSuggestionApprovalResult({
    required this.approvedPlace,
    this.adminNote,
  });
}

class PlaceSuggestionApprovalSheet extends StatefulWidget {
  final PlaceSuggestionModel suggestion;

  const PlaceSuggestionApprovalSheet({super.key, required this.suggestion});

  static Future<PlaceSuggestionApprovalResult?> show(
    BuildContext context,
    PlaceSuggestionModel suggestion,
  ) {
    return showModalBottomSheet<PlaceSuggestionApprovalResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PlaceSuggestionApprovalSheet(suggestion: suggestion),
    );
  }

  @override
  State<PlaceSuggestionApprovalSheet> createState() =>
      _PlaceSuggestionApprovalSheetState();
}

class _PlaceSuggestionApprovalSheetState
    extends State<PlaceSuggestionApprovalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _amenitiesController;
  late final TextEditingController _noteController;
  late PlaceType _type;
  late String _priceRange;
  String? _openHours;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final suggestion = widget.suggestion;
    _nameController = TextEditingController(text: suggestion.name);
    _descriptionController = TextEditingController(
      text: suggestion.description,
    );
    _addressController = TextEditingController(text: suggestion.address);
    _openHours = suggestion.openHours;
    _phoneController = TextEditingController(
      text: _digitsOnly(suggestion.phone ?? ''),
    );
    _amenitiesController = TextEditingController(
      text: suggestion.amenities.join(', '),
    );
    _noteController = TextEditingController();
    _type = suggestion.type;
    _priceRange = suggestion.priceRange ?? '';
    _latitude = suggestion.latitude;
    _longitude = suggestion.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _amenitiesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<PlaceLocationSelection>(
      MaterialPageRoute(
        builder: (_) => PlaceLocationPickerScreen(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialSearchQuery: [
            _addressController.text.trim(),
            widget.suggestion.universityName,
          ].where((item) => item.isNotEmpty).join(', '),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final amenities = _amenitiesController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(12)
        .toList();
    final note = _noteController.text.trim();

    Navigator.of(context).pop(
      PlaceSuggestionApprovalResult(
        approvedPlace: widget.suggestion.copyWith(
          name: _nameController.text.trim(),
          type: _type,
          description: _descriptionController.text.trim(),
          address: _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          priceRange: _priceRange,
          openHours: _openHours ?? '',
          phone: _phoneController.text.trim(),
          amenities: amenities,
        ),
        adminNote: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mekanı Düzenle ve Onayla',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Mekan adı'),
              maxLength: 100,
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 2) return 'En az 2 karakter gerekli';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlaceType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Mekan türü'),
              items: PlaceType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLength: 500,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Adres'),
              maxLength: 300,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.surfaceFor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.borderLightFor(context)),
              ),
              child: ListTile(
                onTap: _pickLocation,
                leading: const Icon(
                  Icons.map_rounded,
                  color: AppColors.primary,
                ),
                title: Text(_latitude == null ? 'Konum seç' : 'Konumu düzenle'),
                subtitle: _latitude == null
                    ? const Text('Henüz koordinat yok')
                    : Text(
                        '${_latitude!.toStringAsFixed(6)}, '
                        '${_longitude!.toStringAsFixed(6)}',
                      ),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priceRange,
              decoration: const InputDecoration(labelText: 'Fiyat aralığı'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Belirtilmedi')),
                DropdownMenuItem(value: '₺', child: Text('₺ - Uygun')),
                DropdownMenuItem(value: '₺₺', child: Text('₺₺ - Orta')),
                DropdownMenuItem(value: '₺₺₺', child: Text('₺₺₺ - Pahalı')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _priceRange = value);
              },
            ),
            const SizedBox(height: 12),
            PlaceOpenHoursPicker(
              value: _openHours,
              onChanged: (value) => setState(() => _openHours = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('place_phone_field'),
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 11,
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return null;
                if (phone.length < 10 || phone.length > 11) {
                  return 'Telefon 10 veya 11 haneli olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amenitiesController,
              decoration: const InputDecoration(
                labelText: 'Olanaklar',
                helperText: 'Virgülle ayır, en fazla 12 öğe',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Admin notu'),
              maxLength: 1000,
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Düzenlemeleri Onayla'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _digitsOnly(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 11 ? digits : digits.substring(0, 11);
  }
}
