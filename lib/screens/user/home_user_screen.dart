import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_campsite_screen.dart';

class HomeUserScreen extends StatefulWidget {
  const HomeUserScreen({super.key});

  @override
  State<HomeUserScreen> createState() => _HomeUserScreenState();
}

class _HomeUserScreenState extends State<HomeUserScreen> {
  final CollectionReference campsites =
      FirebaseFirestore.instance.collection('campsites');

  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';
  String selectedLocation = 'Tất cả'; // ✨ Bộ lọc địa điểm
  double minPrice = 0;
  double maxPrice = 1000000;
  double selectedMin = 0;
  double selectedMax = 1000000;

  bool priceRangeInitialized = false;
  List<String> allLocations = ['Tất cả']; // ✨ Danh sách địa điểm

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBE7),
      appBar: AppBar(
        title: const Text('Danh sách khu cắm trại'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔍 Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên khu cắm trại...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),

          // 💰 Thanh lọc theo giá
          if (priceRangeInitialized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    'Lọc theo giá (${selectedMin.toInt()} đ - ${selectedMax.toInt()} đ)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  RangeSlider(
                    activeColor: Colors.green,
                    inactiveColor: Colors.green[100],
                    values: RangeValues(selectedMin, selectedMax),
                    min: minPrice,
                    max: maxPrice,
                    divisions: 20,
                    labels: RangeLabels(
                      '${selectedMin.toInt()}',
                      '${selectedMax.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() {
                        selectedMin = values.start;
                        selectedMax = values.end;
                      });
                    },
                  ),
                ],
              ),
            ),

          // 📍 Dropdown chọn địa điểm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.place, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLocation,
                    items: allLocations
                        .map((loc) => DropdownMenuItem(
                              value: loc,
                              child: Text(loc),
                            ))
                        .toList(),
                    decoration: InputDecoration(
                      labelText: 'Lọc theo địa điểm',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value ?? 'Tất cả';
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // 📜 Danh sách khu cắm trại (StreamBuilder riêng)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: campsites.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có khu cắm trại nào.'));
                }

                final allDocs = snapshot.data!.docs;

                // ✅ Lấy giá min/max một lần
                if (!priceRangeInitialized) {
                  final prices = allDocs
                      .map((doc) => (doc['price'] ?? 0) as int)
                      .where((p) => p > 0)
                      .toList();
                  if (prices.isNotEmpty) {
                    prices.sort();
                    minPrice = prices.first.toDouble();
                    maxPrice = prices.last.toDouble();
                    selectedMin = minPrice;
                    selectedMax = maxPrice;
                    priceRangeInitialized = true;
                  }
                }

                // ✅ Lấy danh sách địa điểm duy nhất
                final locations = allDocs
                    .map((doc) => (doc['location'] ?? 'Không xác định') as String)
                    .toSet()
                    .toList();
                locations.sort();
                if (!allLocations.contains('Tất cả')) {
                  allLocations.insert(0, 'Tất cả');
                }
                for (var loc in locations) {
                  if (!allLocations.contains(loc)) {
                    allLocations.add(loc);
                  }
                }

                // ✅ Lọc dữ liệu theo tên, giá, địa điểm
                final filtered = allDocs.where((doc) {
                  final name =
                      (doc['name'] ?? '').toString().toLowerCase().trim();
                  final price = (doc['price'] ?? 0) as int;
                  final location = (doc['location'] ?? '').toString().trim();

                  final matchName = name.contains(searchQuery);
                  final matchPrice =
                      price >= selectedMin && price <= selectedMax;
                  final matchLocation = selectedLocation == 'Tất cả' ||
                      location == selectedLocation;

                  return matchName && matchPrice && matchLocation;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không tìm thấy khu cắm trại phù hợp.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // ✅ Hiển thị danh sách khu cắm trại
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final name = doc['name'] ?? 'Không có tên';
                    final location = doc['location'] ?? 'Không xác định';
                    final price = doc['price'] ?? 0;
                    final image = doc['image'] ??
                        'https://firebasestorage.googleapis.com/v0/b/flutter-camping-app.appspot.com/o/default_camp.jpg?alt=media';
                    final description = doc['description'] ?? '';

                    final shortDesc = description.length > 100
                        ? '${description.substring(0, 100)}...'
                        : description;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailCampsiteScreen(
                                id: doc.id,
                                name: name,
                                location: location,
                                price: price,
                                image: image,
                                description: description,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.network(
                                image,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(location,
                                      style: TextStyle(color: Colors.grey[700])),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${price.toString()} đ/đêm',
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(shortDesc,
                                      style: const TextStyle(
                                          color: Colors.black87)),
                                ],
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
    );
  }
}
