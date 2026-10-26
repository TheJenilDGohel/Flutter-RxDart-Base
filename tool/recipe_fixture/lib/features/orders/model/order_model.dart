class OrderModel {
  const OrderModel({required this.title, this.invoiceId = ''});

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        title: json['title']?.toString() ?? '',
        invoiceId: json['invoice_id']?.toString() ?? '',
      );

  final String title;
  final String invoiceId;
}
