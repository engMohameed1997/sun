import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StoreChatDialog extends StatefulWidget {
  final String storeName;
  final String storeCity;

  const StoreChatDialog({
    Key? key,
    required this.storeName,
    required this.storeCity,
  }) : super(key: key);

  static void show(BuildContext context, {required String storeName, required String storeCity}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoreChatDialog(storeName: storeName, storeCity: storeCity),
    );
  }

  @override
  State<StoreChatDialog> createState() => _StoreChatDialogState();
}

class _StoreChatDialogState extends State<StoreChatDialog> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'store',
      'text': 'أهلاً بك في منصة خدمة العملاء الخاصة بـ متجر بغداد للطاقة الشمولية! كيف يمكننا مساعدتك في اختيار المنظومة الشمسية اليوم؟',
      'time': '01:30 م',
    },
    {
      'sender': 'user',
      'text': 'السلام عليكم، هل تتوفر بطاريات ليثيوم Felicity 10.2kWh مع التوصيل والتركيب في الكرادة؟',
      'time': '01:32 م',
    },
    {
      'sender': 'store',
      'text': 'وعليكم السلام ورحمة الله! نعم متوفرة بالكامل مع كفالة 5 سنوات وتوصيل مجاني داخل بغداد الكرادة خلال 24 ساعة.',
      'time': '01:33 م',
    },
  ];

  final List<String> _quickInquiries = [
    'هل يشمل السعر التوصيل والتركيب؟',
    'ما هي كفالة الانفيرترات الهجينة؟',
    'هل تتوفر كادر فني للمعاينة الميدانية؟',
    'طلب الاستفسار عن باقات تقسيط كي كارد',
  ];

  void _sendMessage([String? customText]) {
    final text = customText ?? _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': 'الآن',
      });
      _msgController.clear();
    });

    // Simulate Merchant Auto Reply
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'store',
            'text': 'شكراً لتواصلك! ممثل المبيعات الفني لـ ${widget.storeName} يقوم بمراجعة استفسارك وسيجيبك بكل التفاصيل الحسابية فوراً.',
            'time': 'الآن',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          children: [
            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.darkNavy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryGold,
                    radius: 20,
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.storeName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppTheme.accentGreen, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            const Text('متصل الآن 🟢 — استجابة خلال دقائق', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Quick Inquiry Chips
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppTheme.backgroundLight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _quickInquiries.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _sendMessage(_quickInquiries[index]),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryGold.withOpacity(0.4)),
                      ),
                      child: Center(
                        child: Text(
                          _quickInquiries[index],
                          style: const TextStyle(fontSize: 11, color: AppTheme.darkNavy, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isUser ? AppTheme.primaryGold : AppTheme.backgroundLight,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 0 : 18),
                          bottomRight: Radius.circular(isUser ? 18 : 0),
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'] as String,
                            style: TextStyle(
                              color: isUser ? Colors.white : AppTheme.darkNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'] as String,
                            style: TextStyle(
                              color: isUser ? Colors.white70 : Colors.grey.shade500,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input TextField Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'اكتب استفسارك الفني للمتجر...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: AppTheme.backgroundLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: AppTheme.darkNavy, shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: AppTheme.primaryGold, size: 22),
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
