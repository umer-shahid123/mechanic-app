import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicDocumentVerification extends StatefulWidget {
  const MechanicDocumentVerification({super.key});

  @override
  State<MechanicDocumentVerification> createState() =>
      _MechanicDocumentVerificationState();
}

class _MechanicDocumentVerificationState
    extends State<MechanicDocumentVerification> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  XFile? _cnicFront;
  XFile? _cnicBack;
  XFile? _license;
  XFile? _certification;

  bool _isUploading = false;

  Future<void> _pickImage(String type) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        if (type == 'cnic_front') _cnicFront = image;
        if (type == 'cnic_back') _cnicBack = image;
        if (type == 'license') _license = image;
        if (type == 'cert') _certification = image;
      });
    }
  }

  Future<String?> _uploadFile(XFile file, String folder) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final extensionStart = file.name.lastIndexOf('.');
    final fileExt = extensionStart == -1
        ? ''
        : file.name.substring(extensionStart);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
    final filePath = '${user.id}/$folder/$fileName';

    try {
      await _supabase.storage
          .from('mechanic_docs')
          .uploadBinary(
            filePath,
            await file.readAsBytes(),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return filePath;
    } catch (e) {
      debugPrint('Upload error ($folder): $e');
      return null;
    }
  }

  Future<void> _submitForReview() async {
    if (_cnicFront == null || _cnicBack == null || _license == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final cnicFrontUrl = await _uploadFile(_cnicFront!, 'cnic_front');
      final cnicBackUrl = await _uploadFile(_cnicBack!, 'cnic_back');
      final licenseUrl = await _uploadFile(_license!, 'license');
      String? certUrl;
      if (_certification != null) {
        certUrl = await _uploadFile(_certification!, 'certification');
      }

      await _supabase
          .from('profiles')
          .update({
            'cnic_front_url': cnicFrontUrl,
            'cnic_back_url': cnicBackUrl,
            'license_url': licenseUrl,
            'certification_url': certUrl,
            'verification_status': 'pending',
          })
          .eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        title: Text(
          'Verification',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Identity Verification',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please upload clear photos of your official documents to get verified.',
              style: TextStyle(
                color: isDark ? AppColors.darkGrey : AppColors.grey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),
            _DocUploadCard(
              title: 'CNIC / Identity Card (Front)',
              icon: Icons.badge_outlined,
              isDark: isDark,
              file: _cnicFront,
              onTap: () => _pickImage('cnic_front'),
            ),
            const SizedBox(height: 16),
            _DocUploadCard(
              title: 'CNIC / Identity Card (Back)',
              icon: Icons.badge_rounded,
              isDark: isDark,
              file: _cnicBack,
              onTap: () => _pickImage('cnic_back'),
            ),
            const SizedBox(height: 16),
            _DocUploadCard(
              title: 'Driving License',
              icon: Icons.drive_eta_outlined,
              isDark: isDark,
              file: _license,
              onTap: () => _pickImage('license'),
            ),
            const SizedBox(height: 16),
            _DocUploadCard(
              title: 'Mechanic Certification (Optional)',
              icon: Icons.verified_outlined,
              isDark: isDark,
              file: _certification,
              onTap: () => _pickImage('cert'),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _isUploading ? null : _submitForReview,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: isDark
                    ? AppColors.neonGreen
                    : AppColors.primary,
                foregroundColor: Colors.black,
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Submit for Review',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Approval typically takes 24-48 hours',
                style: TextStyle(
                  color: isDark ? AppColors.darkGrey : AppColors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocUploadCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final XFile? file;
  final VoidCallback onTap;

  const _DocUploadCard({
    required this.title,
    required this.icon,
    required this.isDark,
    this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: file != null
                ? (isDark ? AppColors.neonGreen : AppColors.primary)
                : (isDark ? Colors.white10 : AppColors.divider),
          ),
          boxShadow: isDark ? [] : AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    (file != null
                            ? (isDark ? AppColors.neonGreen : AppColors.primary)
                            : (isDark
                                  ? AppColors.neonGreen
                                  : AppColors.primary))
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                file != null ? Icons.check_circle_rounded : icon,
                color: file != null
                    ? (isDark ? AppColors.neonGreen : Colors.green)
                    : (isDark ? AppColors.neonGreen : AppColors.primary),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    file != null
                        ? 'File selected: ${file!.name}'
                        : 'Tap to upload',
                    style: TextStyle(
                      color: file != null
                          ? (isDark ? AppColors.neonGreen : Colors.green)
                          : (isDark ? AppColors.darkGrey : AppColors.grey),
                      fontSize: 11,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (file == null)
              Icon(
                Icons.cloud_upload_outlined,
                color: isDark ? AppColors.darkGrey : AppColors.grey,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
