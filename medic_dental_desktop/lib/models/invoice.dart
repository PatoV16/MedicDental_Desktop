class Invoice {
  final String invoiceNumber;
  final String date;

  Invoice({
    required this.invoiceNumber,
    required this.date,
  });
}
class InvoiceItem {
  final int quantity;
  final String description;
  final double unitPrice;

  InvoiceItem({
    required this.quantity,
    required this.description,
    required this.unitPrice,
  });
}
