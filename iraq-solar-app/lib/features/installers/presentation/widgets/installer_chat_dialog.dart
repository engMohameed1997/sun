import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class InstallerChatDialog extends StatefulWidget {
  final String installerName;
  final String installerRole;
  final String governorate;

  const InstallerChatDialog({
    Key? key,
    required this.installerName,
    required this.installerRole,
    required this.governorate,
  }) : super(key: key);

  static void show(BuildContext context, {required String name, required String role, required String location}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstallerChatDialog(
        installerName: name,
        installerRole: role,
        governorate: location,
      ),
    );
  }

  @override
  State<InstallerChatDialog> createState() => _InstallerChatDialogState();
}

class _InstallerChatDialogState extends State<InstallerChatDialog> {
  final TextEditingController _msgController = TextEditingController();
  late List<Map<String, dynamic>> _messages;

  final List<String> _quickInquiries = [
    'أود حجز موعد معاينة وفحص ميداني لمنزلي',
    'ما هي كلفة تركيب انفيرتر 8kW مع البطاريات؟',
    'هل تقدم ضمان وكفالة على سلامة التثبيت الهيكلي؟',
    'استفسار عن اختيار زاوية الألواح المناسبة في منطقتي',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'sender': 'installer',
        'text': 'أهلاً بك! أنا ${widget.installerName} (${widget.installerRole}). يسعدني تقديم الاستشارة والمسح الميداني لمنظومتك الشمسية في ${widget.governorate}. كيف أستطيع خدمتك اليوم؟',
        'time': '01:40 م',
      },
    ];
  }

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

    // Auto Response from Engineer
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'installer',
            'text': 'أهلاً بك! تم استلام طلبك وملاحظاتك. سأقوم بتأكيد موعد المعاينة الميدانية وإجراء حسابات الاحمال معك عبر الهاتف فوراً.',
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
                    backgroundColor: AppTheme.accentGreen,
                    radius: 20,
                    child: const Icon(Icons.engineering_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.installerName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${widget.installerRole} • ${widget.governorate}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
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
                        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.4)),
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

            // Messages History
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
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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

            // Input Bar
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
                        hintText: 'اطلب استشارة أو حدد موقع المعاينة...',
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
