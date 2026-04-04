import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isUploading = false; 

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── THE NEW CLOUDINARY UPLOAD LOGIC ──
  Future<void> _uploadRecord() async {
    try {
      // 1. Open the phone's file picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() => _isUploading = true);
        
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;
        double fileSize = result.files.single.size / (1024 * 1024); 
        final uid = AuthService.currentUserId!;

        // 2. Prepare the Cloudinary API Request
        final cloudName = 'dpfatzeoo';
        final uploadPreset = 'arogya_records';
        
        // Using 'auto' allows Cloudinary to handle both Images and PDFs automatically
        final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/auto/upload');
        
        var request = http.MultipartRequest('POST', uri);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(await http.MultipartFile.fromPath('file', file.path));

        // 3. Send to Cloudinary
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);

        if (response.statusCode == 200) {
          // 4. Extract the secure download link from Cloudinary
          String secureUrl = jsonResponse['secure_url'];

          // 5. Save the file metadata & URL to your existing Firestore database
          await FirebaseFirestore.instance.collection('users').doc(uid).collection('records').add({
            'name': fileName,
            'url': secureUrl,
            'size_mb': double.parse(fileSize.toStringAsFixed(2)),
            'uploaded_at': FieldValue.serverTimestamp(),
            'category': 'Document',
          });

          setState(() => _isUploading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully! ✓'), backgroundColor: AppColors.success)
            );
          }
        } else {
          throw Exception(jsonResponse['error']['message']);
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.danger)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── HEADER ──
          Container(
            color: AppColors.navy,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Medical Records', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('Your secure health vault', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white38)),
                        ]),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tab,
                    indicatorColor: AppColors.tealLight,
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    tabs: const [Tab(text: 'Medication History'), Tab(text: 'Health Locker')],
                  ),
                ],
              ),
            ),
          ),

          // ── TAB CONTENT ──
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildHistoryTab(),
                _buildLockerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HISTORY TAB ──
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId!).collection('history').orderBy('taken_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        
        final logs = snapshot.data!.docs;
        if (logs.isEmpty) return Center(child: Text('No history yet.', style: GoogleFonts.outfit(color: AppColors.textMuted)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final date = log['taken_at'] != null ? (log['taken_at'] as Timestamp).toDate() : DateTime.now();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(kRadiusSm),
                boxShadow: const [
                  BoxShadow(color: Color(0x050C1E35), blurRadius: 10, offset: Offset(0, 4)),
                ],
                border: const Border(left: BorderSide(color: AppColors.success, width: 4)),
              ),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(log['name'] ?? 'Medication', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(log['dosage'] ?? '', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ),
                Text(DateFormat('MMM d, h:mm a').format(date), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
              ]),
            );
          },
        );
      },
    );
  }

  // ── LOCKER TAB ──
  Widget _buildLockerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your Uploaded Records', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId!).collection('records').orderBy('uploaded_at', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.teal));
            
            final files = snapshot.data!.docs;
            if (files.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Your locker is empty.', style: GoogleFonts.outfit(color: AppColors.textMuted))),
              );
            }

            return Column(
              children: files.map((doc) {
                final file = doc.data() as Map<String, dynamic>;
                final date = file['uploaded_at'] != null ? (file['uploaded_at'] as Timestamp).toDate() : DateTime.now();
                
                // ── REPLACE YOUR EXISTING CONTAINER WITH THIS ──
                return GestureDetector(
                  onTap: () async {
                    final fileUrl = file['url'];
                    if (fileUrl != null) {
                      final uri = Uri.parse(fileUrl);
                      if (await canLaunchUrl(uri)) {
                        // This opens the file in the phone's default browser or PDF viewer
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open file'), backgroundColor: AppColors.danger)
                          );
                        }
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(kRadius),
                      boxShadow: const [
                        BoxShadow(color: Color(0x050C1E35), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(kRadiusSm)),
                        child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.teal, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(file['name'] ?? 'Document', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('${DateFormat('dd MMM yyyy').format(date)} · ${file['size_mb']} MB', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary)),
                        ]),
                      ),
                      // Added a little icon to indicate it is clickable!
                      const Icon(Icons.open_in_new, color: AppColors.textMuted, size: 20),
                    ]),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 20),
        
        GestureDetector(
          onTap: _isUploading ? null : _uploadRecord,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal, width: 1.5),
            ),
            child: _isUploading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
              : Column(children: [
                  const Icon(Icons.upload_outlined, color: AppColors.teal, size: 24),
                  const SizedBox(height: 6),
                  Text('Upload New Record', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal)),
                ]),
          ),
        ),
      ],
    );
  }
}