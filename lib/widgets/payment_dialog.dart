import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../providers/restaurant_provider.dart';
import '../theme/app_theme.dart';
import '../utils/vnd_format.dart';
import 'package:intl/intl.dart';
import '../services/error_handler.dart';

class PaymentDialog extends StatefulWidget {
  final TableModel table;
  final List<OrderModel> orders;

  const PaymentDialog({
    super.key,
    required this.table,
    required this.orders,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  double _discount = 0.0;
  double _receivedAmount = 0.0;
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _receivedController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final ErrorHandler _errorHandler = ErrorHandler();

  @override
  void dispose() {
    _discountController.dispose();
    _receivedController.dispose();
    super.dispose();
  }

  double get _subtotal => widget.orders.fold(0.0, (sum, order) => sum + order.total);
  double get _discountAmount => _subtotal * (_discount / 100);
  double get _total => _subtotal - _discountAmount;
  double get _change => _receivedAmount > _total ? _receivedAmount - _total : 0.0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HÓA ĐƠN THANH TOÁN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bàn ${widget.table.name}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Orders List
                    ...widget.orders.map((order) => _buildOrderCard(order)),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Discount Section
                    _buildDiscountSection(),

                    const SizedBox(height: 20),

                    // Payment Method
                    _buildPaymentMethodSection(),

                    const SizedBox(height: 20),

                    // Received Amount (for cash)
                    if (_selectedPaymentMethod == PaymentMethod.cash)
                      _buildReceivedAmountSection(),

                    const SizedBox(height: 20),
                    const Divider(),

                    // Summary
                    _buildSummarySection(),
                  ],
                ),
              ),
            ),

            // Footer with payment button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TỔNG CỘNG:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _total.toVnd(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canProcessPayment() ? () => _processPayment(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'THANH TOÁN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn #${order.id.toString().substring(order.id.toString().length - 4)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  DateFormat('HH:mm - dd/MM/yyyy').format(order.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.menuItem.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.menuItem.price.toVnd()} x ${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        (item.menuItem.price * item.quantity).toVnd(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng đơn:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  order.total.toVnd(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Giảm giá',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  hintText: 'Nhập % giảm giá',
                  suffixText: '%',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _discount = double.tryParse(value) ?? 0.0;
                    if (_discount > 100) _discount = 100;
                    if (_discount < 0) _discount = 0;
                    _discountController.value = TextEditingValue(
                      text: _discount.toStringAsFixed(0),
                      selection: _discountController.selection,
                    );
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 100,
              child: Text(
                _discountAmount.toVnd(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryOrange,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức thanh toán',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodOption(
                PaymentMethod.cash,
                'Tiền mặt',
                Icons.money,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodOption(
                PaymentMethod.card,
                'Thẻ',
                Icons.credit_card,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPaymentMethodOption(
                PaymentMethod.transfer,
                'Chuyển khoản',
                Icons.account_balance,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethod method,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
          if (method != PaymentMethod.cash) {
            _receivedAmount = _total;
            _receivedController.text = _total.toStringAsFixed(0);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryOrange.withValues(alpha: 0.1)
              : Colors.grey[100],
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryOrange : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryOrange : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiền nhận',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _receivedController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          decoration: InputDecoration(
            hintText: 'Nhập số tiền nhận',
            prefixText: '₫ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _receivedAmount = double.tryParse(value) ?? 0.0;
            });
          },
        ),
        if (_change > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiền thừa:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _change.toVnd(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        _buildSummaryRow('Tạm tính:', _subtotal.toVnd()),
        if (_discount > 0)
          _buildSummaryRow('Giảm giá:', '-${_discountAmount.toVnd()}'),
        const Divider(),
        _buildSummaryRow(
          'THÀNH TIỀN:',
          _total.toVnd(),
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppTheme.primaryOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  bool _canProcessPayment() {
    if (_selectedPaymentMethod == PaymentMethod.cash) {
      return _receivedAmount >= _total;
    }
    return true;
  }

  Future<void> _processPayment(BuildContext context) async {
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await provider.processPayment(
        widget.table.id,
        _total,
        _discount,
        _selectedPaymentMethod,
      );

      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Close payment dialog
        Navigator.pop(context);
        
        // Show result message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Thanh toán thành công!'
                  : (provider.errorMessage != null && provider.errorMessage!.isNotEmpty)
                      ? provider.errorMessage!
                      : 'Lỗi khi thanh toán. Vui lòng thử lại.',
            ),
            backgroundColor: success ? AppTheme.statusGreen : AppTheme.statusRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      final message = _errorHandler.getUserMessage(
        e,
        fallbackMessage: 'Lỗi khi thanh toán',
      );
      _errorHandler.logError(
        e,
        stackTrace,
        context: 'Error processing payment',
      );
      if (context.mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message without closing payment dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
            ),
            backgroundColor: AppTheme.statusRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

enum PaymentMethod { cash, card, transfer }

