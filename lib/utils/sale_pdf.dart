import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SalePdf {
  static Future<pw.Document> generateSalePdf(
      Map<String, dynamic> sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "INVOICE",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 12),

              _row("Product", sale['product_name']),
              _row("Category", sale['category_name']),
              _row("Quantity", sale['quantity'].toString()),
              _row("Unit Price", "৳${sale['unit_price']}"),
              _row("Total", "৳${sale['total_price']}"),
              _row("Date", sale['date'].toString()),

              pw.SizedBox(height: 30),
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Total Amount: ৳${sale['total_price']}",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _row(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }
}
