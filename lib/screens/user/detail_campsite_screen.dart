import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DetailCampsiteScreen extends StatefulWidget {
  final String id;
  final String name;
  final String location;
  final int price;
  final String image;
  final String description;

  const DetailCampsiteScreen({
    super.key,
    required this.id,
    required this.name,
    required this.location,
    required this.price,
    required this.image,
    required this.description,
  });

  @override
  State<DetailCampsiteScreen> createState() => _DetailCampsiteScreenState();
}

class _DetailCampsiteScreenState extends State<DetailCampsiteScreen> {
  DateTime? checkInDate;
  DateTime? checkOutDate;

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          checkInDate = picked;
          if (checkOutDate != null && checkOutDate!.isBefore(checkInDate!)) {
            checkOutDate = null;
          }
        } else {
          checkOutDate = picked;
        }
      });
    }
  }

  int _calculateTotalPrice() {
    if (checkInDate == null || checkOutDate == null) return 0;
    final days = checkOutDate!.difference(checkInDate!).inDays;
    if (days <= 0) return 0;
    return days * widget.price;
  }

  Future<void> _bookCampsite() async {
    if (checkInDate == null || checkOutDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày Check-in/Check-out!')),
      );
      return;
    }

    final total = _calculateTotalPrice();
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày không hợp lệ!')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để đặt chỗ.')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': user.uid,
      'campId': widget.id,
      'campName': widget.name,
      'checkIn': checkInDate,
      'checkOut': checkOutDate,
      'total': total,
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Đặt chỗ thành công! Tổng tiền: ${NumberFormat("#,###").format(total)} đ'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final total = _calculateTotalPrice();

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(widget.image,
                width: double.infinity, height: 220, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(widget.location,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(widget.description),
                  const SizedBox(height: 16),
                  Text('Giá: ${widget.price} đ/đêm',
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.green,
                          fontWeight: FontWeight.bold)),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.date_range),
                        label: Text(checkInDate == null
                            ? 'Chọn Check-in'
                            : 'Check-in: ${dateFormat.format(checkInDate!)}'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.event),
                        label: Text(checkOutDate == null
                            ? 'Chọn Check-out'
                            : 'Check-out: ${dateFormat.format(checkOutDate!)}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (total > 0)
                    Text(
                      'Tổng tiền: ${NumberFormat("#,###").format(total)} đ',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.shopping_cart_checkout),
                      onPressed: _bookCampsite,
                      label: const Text('Xác nhận đặt chỗ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 40),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
