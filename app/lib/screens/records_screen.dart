import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isUploading = false; // Tracks upload state

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

  // ── THE FIREBASE STORAGE UPLOAD LOGIC ──
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
        double fileSize = result.files.single.size / (1024 * 1024); // Convert bytes to MB
        final uid = AuthService.currentUserId!;

        // 2. Upload to Firebase Storage
        final storageRef = FirebaseStorage.instance.ref().child('users/$uid/records/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await storageRef.putFile(file);
        
        // 3. Get the secure download link
        final downloadUrl = await storageRef.getDownloadURL();

        // 4. Save the file information to Firestore so it shows in the app
        await FirebaseFirestore.instance.collection('users').doc(uid).collection('records').add({
          'name': fileName,
          'url': downloadUrl,
          'size_mb': double.parse(fileSize.toStringAsFixed(2)),
          'uploaded_at': FieldValue.serverTimestamp(),
          'category': 'Document',
        });

        setState(() => _isUploading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File uploaded successfully! ✓'), backgroundColor: AppColors.success)
          );
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

  // ── HISTORY TAB (LIVE FROM FIREBASE) ──
  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId!).collection('history').orderBy('taken_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data!.docs;
        if (logs.isEmpty) return const Center(child: Text('No history yet. Take a pill!'));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            final date = log['taken_at'] != null ? (log['taken_at'] as Timestamp).toDate() : DateTime.now();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: const Border(left: BorderSide(color: AppColors.success, width: 3))),
              child: Row(children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(log['name'] ?? 'Medication', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(log['dosage'] ?? '', style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted)),
                  ]),
                ),
                Text(DateFormat('MMM d, h:mm a').format(date), style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
              ]),
            );
          },
        );
      },
    );
  }

  // ── LOCKER TAB (LIVE FROM FIREBASE STORAGE) ──
  Widget _buildLockerTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Recent Files List ──
        Text('Your Uploaded Records', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(AuthService.currentUserId!).collection('records').orderBy('uploaded_at', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
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
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.cardShadow),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.tealPale, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(file['name'] ?? 'Document', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${DateFormat('dd MMM yyyy').format(date)} · ${file['size_mb']} MB', style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textMuted)),
                      ]),
                    ),
                  ]),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 20),
        
        // ── Upload Button ──
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