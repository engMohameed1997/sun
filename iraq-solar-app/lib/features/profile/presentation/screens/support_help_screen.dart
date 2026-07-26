import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';

class SupportHelpScreen extends StatefulWidget {
  const SupportHelpScreen({Key? key}) : super(key: key);

  @override
  State<SupportHelpScreen> createState() => _SupportHelpScreenState();
}

class _SupportHelpScreenState extends State<SupportHelpScreen> {
  final _msgController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {
      'q': 'ما هي المنظومة الهجينة (Hybrid Solar System)؟',
      'a': 'هي منظومة تجمع بين طاقة الألواح الشمسية، والبطاريات للخزن، مع إمكانية السحب والتصدير للشبكة الوطنية أو المولد عند الحاجة.'
    },
    {
      'q': 'هل تضمنون البطاريات والألواح؟',
      'a': 'نعم، جميع المنتجات من المتاجر المعتمدة مشمولة بضمان الوكيل الرسمي (25 سنة للألواح و 5 سنوات لبطاريات الليثيوم).'
    },
    {
      'q': 'كيف يتم الشحن والتوصيل للمحافظات؟',
      'a': 'يتم التوصيل الميداني مع كادر فني متخصص لمعاينة الموقع والتركيب والتراخيص الرسمية في كافة المحافظات العراقية.'
    },
  ];

  void _sendTicket() {
    if (_msgController.text.trim().isEmpty) {
      AppNotification.showError(context, 'يرجى كتابة تفاصيل استفسارك أو مشكلتك');
      return;
    }
    _msgController.clear();
    AppNotification.showSuccess(context, 'تم إرسال تذكرة الدعم الفني، سيتواصل معك مهندس الدعم خلال دقائق 💬');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('الدعم الفني وخدمة العملاء'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Channels Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppTheme.darkNavy, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.headset_mic_rounded, color: AppTheme.primaryGold, size: 36),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('مركز الدعم الميداني 24/7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              SizedBox(height: 4),
                              Text('فريق هندسي متخصص للإجابة على استفسارات الطاقة الشمسية.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppNotification.showInfo(context, 'الاتصال الفوري بالخط الساخن: 07701234567 📞');
                            },
                            icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                            label: const Text('اتصال مباشر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppNotification.showInfo(context, 'فتح محادثة واتساب الدعم الهندسي المباشرة 🟢');
                            },
                            icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                            label: const Text('واتساب الدعم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // FAQ Section
              const Text('الأسئلة الشائعة (FAQ)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
              const SizedBox(height: 10),
              ..._faqs.map((faq) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: ExpansionTile(
                      title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkNavy)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(faq['a']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
                        )
                      ],
                    ),
                  )),

              const SizedBox(height: 20),

              // Ticket Form
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إرسال استفسار أو تذكرة بلاغ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _msgController,
                      maxLines: 4,
                      decoration: const InputDecoration(hintText: 'اكتب تفاصيل سؤالك أو مشكلتك هنا...'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _sendTicket,
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        label: const Text('إرسال التذكرة للفنيين', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
