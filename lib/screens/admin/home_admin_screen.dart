import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  final campsites = FirebaseFirestore.instance.collection('campsites');
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String? selectedLocation;
  bool sortAscending = true;

  void _showCampsiteDialog({DocumentSnapshot? doc}) {
    final nameCtrl = TextEditingController(text: doc?['name'] ?? '');
    final locCtrl = TextEditingController(text: doc?['location'] ?? '');
    final priceCtrl = TextEditingController(text: doc?['price']?.toString() ?? '');
    final imgCtrl = TextEditingController(text: doc?['image'] ?? '');
    final descCtrl = TextEditingController(text: doc?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(doc == null ? 'Thêm khu mới' : 'Chỉnh sửa khu cắm trại'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên khu')),
              TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Vị trí')),
              TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Giá (VNĐ/đêm)'),
                  keyboardType: TextInputType.number),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Link hình ảnh')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'name': nameCtrl.text,
                'location': locCtrl.text,
                'price': int.tryParse(priceCtrl.text) ?? 0,
                'image': imgCtrl.text.isNotEmpty ? imgCtrl.text : 'https://picsum.photos/400',
                'description': descCtrl.text,
              };
              if (doc == null) {
                await campsites.add(data);
              } else {
                await campsites.doc(doc.id).update(data);
              }
              Navigator.pop(context);
            },
            child: Text(doc == null ? 'Thêm' : 'Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteCampsite(String id) async {
    await campsites.doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá khu cắm trại')),
    );
  }
    void _showCampsiteDetailDialog(DocumentSnapshot doc) {
    final name = doc['name'] ?? '';
    final location = doc['location'] ?? '';
    final price = doc['price'] ?? 0;
    final image = doc['image'] ?? 'https://picsum.photos/400';
    final description = doc['description'] ?? 'Không có mô tả.';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(image, width: double.infinity, height: 200, fit: BoxFit.cover),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 4),
                        Text(location, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('$price VNĐ/đêm',
                        style: const TextStyle(color: Colors.green, fontSize: 16)),
                    const SizedBox(height: 12),
                    const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showCampsiteDialog(doc: doc);
                          },
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          label: const Text('Sửa', style: TextStyle(color: Colors.blue)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteCampsite(doc.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Xoá', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất')),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _shortenDescription(String text) {
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Quản lý khu cắm trại'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm khu cắm trại...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 🔽 Bộ lọc & Sắp xếp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Bộ lọc địa điểm
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: campsites.snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final locations = docs.map((d) => d['location']?.toString() ?? '').toSet().toList();
                      locations.removeWhere((e) => e.isEmpty);
                      locations.sort();

                      return DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          hintText: 'Lọc theo địa điểm',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        value: selectedLocation,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tất cả')),
                          ...locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedLocation = value;
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Sắp xếp theo giá
                IconButton(
                  icon: Icon(
                    sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.green,
                  ),
                  tooltip: sortAscending ? 'Sắp xếp tăng dần' : 'Sắp xếp giảm dần',
                  onPressed: () {
                    setState(() {
                      sortAscending = !sortAscending;
                    });
                  },
                ),
              ],
            ),
          ),

          // 📋 Danh sách khu cắm trại
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: campsites.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];

                // Lọc theo tên
                docs = docs.where((doc) {
                  final name = (doc['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery);
                }).toList();

                // Lọc theo địa điểm
                if (selectedLocation != null) {
                  docs = docs.where((doc) => doc['location'] == selectedLocation).toList();
                }

                // Sắp xếp theo giá
                docs.sort((a, b) {
                  final priceA = a['price'] ?? 0;
                  final priceB = b['price'] ?? 0;
                  return sortAscending ? priceA.compareTo(priceB) : priceB.compareTo(priceA);
                });

                if (docs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy khu nào.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final name = doc['name'] ?? '';
                    final location = doc['location'] ?? '';
                    final price = doc['price'] ?? 0;
                    final image = doc['image'] ?? 'https://picsum.photos/400';
                    final desc = doc['description'] ?? '';

                    return InkWell(
                      onTap: () => _showCampsiteDetailDialog(doc),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.network(image, height: 120, width: double.infinity, fit: BoxFit.cover),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(location, style: const TextStyle(color: Colors.grey)),
                                  Text('$price VNĐ/đêm', style: const TextStyle(color: Colors.green)),
                                  const SizedBox(height: 6),
                                  Text(
                                    _shortenDescription(desc),
                                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCampsite(doc.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCampsiteDialog(),
        label: const Text('Thêm khu mới'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
