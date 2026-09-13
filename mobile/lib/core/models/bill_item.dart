class BillItem {
  final String name;
  final int price;
  final int quantity;

  const BillItem({required this.name, required this.price, this.quantity = 1});

  int get subtotal => price * quantity;
}

class RealBill {
  final String id;
  final String billPhotoUrl;
  final DateTime date;
  final String contributorName;
  final int guestsCount;
  final List<BillItem> items;
  final int totalAmount;

  const RealBill({
    required this.id,
    required this.billPhotoUrl,
    required this.date,
    required this.contributorName,
    required this.guestsCount,
    required this.items,
    required this.totalAmount,
  });

  int get costPerPerson =>
      guestsCount > 0 ? (totalAmount / guestsCount).round() : totalAmount;
}
