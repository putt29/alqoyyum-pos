import '../core/json.dart';

class ReceiptParty {
  const ReceiptParty({required this.label, required this.title, required this.name});

  final String label;
  final String title;
  final String name;

  factory ReceiptParty.fromJson(Map<String, dynamic> j) =>
      ReceiptParty(label: asStr(j['label']), title: asStr(j['title']), name: asStr(j['name']));
}

class ReceiptLine {
  const ReceiptLine({required this.name, required this.qty, required this.unit, required this.amountText});

  final String name;
  final int? qty;
  final String? unit;
  final String amountText;

  factory ReceiptLine.fromJson(Map<String, dynamic> j) => ReceiptLine(
        name: asStr(j['name']),
        qty: j['qty'] == null ? null : asInt(j['qty']),
        unit: asStrOrNull(j['unit']),
        amountText: asStr(j['amount_text']),
      );
}

class ReceiptGroup {
  const ReceiptGroup({required this.label, required this.lines});

  final String label;
  final List<ReceiptLine> lines;

  factory ReceiptGroup.fromJson(Map<String, dynamic> j) => ReceiptGroup(
        label: asStr(j['label']),
        lines: asList(j['lines']).map((e) => ReceiptLine.fromJson(asMap(e))).toList(),
      );
}

/// Isi struk dari server (mengikuti kwitansi Excel). Digambar oleh SATU template: ReceiptView.
class ReceiptDoc {
  const ReceiptDoc({
    required this.clinicName,
    required this.address,
    required this.sipdLine,
    required this.phoneLine,
    required this.title,
    required this.numberLine,
    required this.dateText,
    required this.receivedFrom,
    required this.patient,
    required this.doctor,
    required this.forPaymentLabel,
    required this.groups,
    required this.underlineLast,
    required this.currency,
    required this.totalLabel,
    required this.totalText,
    required this.paymentMethodLabel,
    required this.paymentMethod,
    required this.wordsLabel,
    required this.words,
    required this.signatureLabel,
    required this.signatureName,
    required this.stamp,
  });

  final String clinicName;
  final String address;
  final String sipdLine;
  final String phoneLine;
  final String title;
  final String numberLine;
  final String dateText;
  final ReceiptParty receivedFrom;
  final ReceiptParty patient;
  final ReceiptParty doctor;
  final String forPaymentLabel;
  final List<ReceiptGroup> groups;
  final bool underlineLast;
  final String currency;
  final String totalLabel;
  final String totalText;
  final String paymentMethodLabel;
  final String paymentMethod;
  final String wordsLabel;
  final String words;
  final String signatureLabel;
  final String signatureName;
  final String? stamp;

  factory ReceiptDoc.fromJson(Map<String, dynamic> j) {
    final clinic = asMap(j['clinic']);
    final signature = asMap(j['signature']);
    return ReceiptDoc(
      clinicName: asStr(clinic['name']),
      address: asStr(clinic['address']),
      sipdLine: asStr(clinic['sipd_line']),
      phoneLine: asStr(clinic['phone_line']),
      title: asStr(j['title']),
      numberLine: asStr(j['number_line']),
      dateText: asStr(j['date_text']),
      receivedFrom: ReceiptParty.fromJson(asMap(j['received_from'])),
      patient: ReceiptParty.fromJson(asMap(j['patient'])),
      doctor: ReceiptParty.fromJson(asMap(j['doctor'])),
      forPaymentLabel: asStr(j['for_payment_label']),
      groups: asList(j['groups']).map((e) => ReceiptGroup.fromJson(asMap(e))).toList(),
      underlineLast: asBool(j['underline_last']),
      currency: asStr(j['currency'], 'Rp'),
      totalLabel: asStr(j['total_label']),
      totalText: asStr(j['total_text']),
      paymentMethodLabel: asStr(j['payment_method_label']),
      paymentMethod: asStr(j['payment_method']),
      wordsLabel: asStr(j['words_label']),
      words: asStr(j['words']),
      signatureLabel: asStr(signature['label']),
      signatureName: asStr(signature['name']),
      stamp: asStrOrNull(j['stamp']),
    );
  }
}
