import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../merchant/presentation/screens/store_detail_screen.dart';

class FavoriteStoresScreen extends StatefulWidget {
  const FavoriteStoresScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteStoresScreen> createState() => _FavoriteStoresScreenState();
}

class _FavoriteStoresScreenState extends State<FavoriteStoresScreen> {
  final List<Map<String, dynamic>> _favoriteStores = [];

  void _removeFavorite(int index) {
    final store = _favoriteStores[index];
    setState(() {
      _favoriteStores.removeAt(index);
    });
    AppNotification.showSuccess(context, 'تمت إزالة "${store['name']}" من المتاجر المفضلة');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('المتاجر المعتمدة المفضلة'),
          backgroundColor: AppTheme.darkNavy,
        ),
        body: _favoriteStores.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('لا توجد متاجر مفضلة حالياً', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkNavy)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favoriteStores.length,
                itemBuilder: (context, index) {
                  final store = _favoriteStores[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.darkNavy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppTheme.primaryGold, size: 28),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(store['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.darkNavy))),
                          if (store['verified'] == true) const Icon(Icons.verified_rounded, color: Colors.blue, size: 18),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(store['city'], style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('${store['productsCount']} منتج متوفر • ${store['rating']}', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.favorite_rounded, color: Colors.red),
                            onPressed: () => _removeFavorite(index),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => StoreDetailScreen(storeData: store)),
                        );
                      },
                    ),
                  ),
                );
                },
              ),
      ),
    );
  }
}
