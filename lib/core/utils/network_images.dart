class NetworkImages {
  static const String defaultProfile = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop';
  
  static const String pizza = 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=600&auto=format&fit=crop';
  static const String burger = 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop';
  static const String biryani = 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?q=80&w=600&auto=format&fit=crop';
  static const String dosa = 'https://images.unsplash.com/photo-1668236543090-82eba5ee5976?q=80&w=600&auto=format&fit=crop';
  static const String cake = 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?q=80&w=600&auto=format&fit=crop';
  static const String sweetCorner = 'https://images.unsplash.com/photo-1587314168485-3236d6710814?q=80&w=600&auto=format&fit=crop';
  static const String beverages = 'https://images.unsplash.com/photo-1543007630-9710e4a00a20?q=80&w=600&auto=format&fit=crop';
  static const String freshVegetables = 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?q=80&w=600&auto=format&fit=crop';
  static const String frozenFood = 'https://images.unsplash.com/photo-1584269600464-37b1b58a9fe7?q=80&w=600&auto=format&fit=crop';
  static const String hairCare = 'https://images.unsplash.com/photo-1526947425960-945c6e72858f?q=80&w=600&auto=format&fit=crop';
  static const String homeFurnishing = 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?q=80&w=600&auto=format&fit=crop';
  static const String iceCreams = 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?q=80&w=600&auto=format&fit=crop';
  static const String kitchenDining = 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=600&auto=format&fit=crop';
  static const String noodlesPasta = 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=600&auto=format&fit=crop';
  static const String paratha = 'https://images.unsplash.com/photo-1626132647523-66f5bf380027?q=80&w=600&auto=format&fit=crop';
  static const String riceAttaDals = 'https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=600&auto=format&fit=crop';
  static const String deliveryBoyRating = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop';
  static const String freshFood = 'https://images.unsplash.com/photo-1498837167922-ddd27525d352?q=80&w=600&auto=format&fit=crop';
  static const String googleLogo = 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png';
  static const String grocery = 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=600&auto=format&fit=crop';
  static const String groceryEssentials = 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?q=80&w=600&auto=format&fit=crop';
  static const String masalas = 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?q=80&w=600&auto=format&fit=crop';
  static const String meatSeafood = 'https://images.unsplash.com/photo-1532597311687-5c2dc87ffa51?q=80&w=600&auto=format&fit=crop';
  static const String oilsGhee = 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?q=80&w=600&auto=format&fit=crop';
  static const String organic = 'https://images.unsplash.com/photo-1506084868230-bb9d95c24759?q=80&w=600&auto=format&fit=crop';
  static const String topPicksFallback = 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=600&auto=format&fit=crop';
  static const String dairy = 'https://images.unsplash.com/photo-1550583724-b2692b85b150?q=80&w=600&auto=format&fit=crop';

  static final Map<String, String> _assetToNetworkMap = {
    'assets/Pizza.png': pizza,
    'assets/Burger.png': burger,
    'assets/Biryani.png': biryani,
    'assets/Dosa.png': dosa,
    'assets/Cake.png': cake,
    'assets/SweetCorner.png': sweetCorner,
    'assets/beverages.png': beverages,
    'assets/Fresh_vegetables.png': freshVegetables,
    'assets/FrozenFood.png': frozenFood,
    'assets/HairCare.png': hairCare,
    'assets/HomeFurnishing.png': homeFurnishing,
    'assets/IceCreams.png': iceCreams,
    'assets/KitchenDining.png': kitchenDining,
    'assets/NoodlesPasta.png': noodlesPasta,
    'assets/Paratha.png': paratha,
    'assets/RiceAttaDals.png': riceAttaDals,
    'assets/delivery_boy_rating_celebration.png': deliveryBoyRating,
    'assets/fresh_food.jpg': freshFood,
    'assets/google_logo.png': googleLogo,
    'assets/grocery.jpg': grocery,
    'assets/grocery Essentials.png': groceryEssentials,
    'assets/masalas.jpg': masalas,
    'assets/meatSeafood.png': meatSeafood,
    'assets/oilsGhee.png': oilsGhee,
    'assets/organic.png': organic,
    'assets/Top_Picks.jpeg': topPicksFallback,
    'assets/Dairy.png': dairy,
  };

  static String mapAssetToNetwork(String path) {
    if (path.startsWith('http')) return path;
    final mapped = _assetToNetworkMap[path];
    if (mapped != null) return mapped;
    
    // Check if the path contains any of the known asset filenames
    for (final entry in _assetToNetworkMap.entries) {
      final filename = entry.key.split('/').last;
      if (path.contains(filename)) {
        return entry.value;
      }
    }

    return topPicksFallback;
  }
}
