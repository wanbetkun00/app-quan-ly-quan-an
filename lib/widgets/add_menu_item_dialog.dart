import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/error_handler.dart';
import '../utils/input_sanitizer.dart';

class AddMenuItemDialog extends StatefulWidget {
  final MenuItem? itemToEdit; // Nếu có thì đây là chế độ sửa
  
  const AddMenuItemDialog({super.key, this.itemToEdit});

  @override
  State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  MenuCategory _selectedCategory = MenuCategory.food;
  File? _pickedImage;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  final ErrorHandler _errorHandler = ErrorHandler();

  @override
  void initState() {
    super.initState();
    // Nếu đang ở chế độ sửa, điền dữ liệu vào form
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit!;
      _nameController.text = item.name;
      _priceController.text = item.price.toStringAsFixed(0);
      _selectedCategory = item.category;
      if (item.imageUrl != null) {
        if (item.imageUrl!.startsWith('http')) {
          _imageUrl = item.imageUrl;
          _imageUrlController.text = item.imageUrl!;
        } else {
          // Nếu là file path, thử load file
          try {
            final file = File(item.imageUrl!);
            if (file.existsSync()) {
              _pickedImage = file;
            } else {
              _imageUrl = item.imageUrl;
              _imageUrlController.text = item.imageUrl!;
            }
          } catch (e) {
            _imageUrl = item.imageUrl;
            _imageUrlController.text = item.imageUrl!;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      // Kiểm tra và yêu cầu quyền truy cập
      PermissionStatus? status;
      if (Platform.isAndroid) {
        // Android 13+ sử dụng READ_MEDIA_IMAGES, còn lại dùng READ_EXTERNAL_STORAGE
        if (await Permission.photos.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
        }
      } else if (Platform.isIOS) {
        status = await Permission.photos.status;
        if (!status.isGranted) {
          status = await Permission.photos.request();
        }
      }
      
      if (status != null && !status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cần quyền truy cập thư viện ảnh để chọn ảnh'),
              backgroundColor: Colors.orange,
              action: SnackBarAction(
                label: 'Mở cài đặt',
                onPressed: () => openAppSettings(),
              ),
            ),
          );
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
          _imageUrl = null; // Clear URL when picking from gallery
          _imageUrlController.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã chọn ảnh thành công'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      final message = _errorHandler.getUserMessage(
        e,
        fallbackMessage: 'Lỗi khi chọn ảnh',
      );
      _errorHandler.logError(
        e,
        stackTrace,
        context: 'Error picking image',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useImageUrl() {
    final url = InputSanitizer.sanitizeUrl(_imageUrlController.text);
    if (url.isNotEmpty) {
      setState(() {
        _imageUrl = url;
        _pickedImage = null; // Clear picked image when using URL
      });
    } else {
      setState(() {
        _imageUrl = null;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _imageUrl = null;
      _imageUrlController.clear();
    });
  }

  void _showImageUrlDialog() {
    final urlController = TextEditingController(text: _imageUrlController.text);
    String? previewUrl;
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nhập link ảnh'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hướng dẫn:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  '1. Vào Google Images\n'
                  '2. Click chuột phải vào ảnh\n'
                  '3. Chọn "Copy image address"\n'
                  '4. Dán vào ô bên dưới',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    hintText: 'https://example.com/image.jpg',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                    helperText: 'URL phải bắt đầu bằng http:// hoặc https://',
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    final trimmed = value.trim();
                    setDialogState(() {
                      if (trimmed.isEmpty) {
                        previewUrl = null;
                        errorMessage = null;
                      } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
                        previewUrl = trimmed;
                        errorMessage = null;
                      } else {
                        previewUrl = null;
                        errorMessage = 'URL phải bắt đầu bằng http:// hoặc https://';
                      }
                    });
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (previewUrl != null) ...[
                  const Text(
                    'Preview:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      previewUrl!,
                      width: 200,
                      height: 150,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 32),
                              SizedBox(height: 4),
                              Text('Không thể tải ảnh', style: TextStyle(fontSize: 12)),
                              Text('Kiểm tra lại URL', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                urlController.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                final url = InputSanitizer.sanitizeUrl(urlController.text);
                if (url.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vui lòng nhập URL'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL phải bắt đầu bằng http:// hoặc https://'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
                _imageUrlController.text = url;
                urlController.dispose();
                if (mounted) {
                  Navigator.pop(dialogContext);
                  _useImageUrl();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm ảnh từ URL'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    // Hiển thị ảnh đã chọn từ gallery
    if (_pickedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _pickedImage!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
              onPressed: _clearImage,
            ),
          ),
        ],
      );
    } 
    // Hiển thị ảnh từ URL hoặc ảnh cũ khi edit
    else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 48),
                        SizedBox(height: 8),
                        Text('Không thể tải ảnh'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
              onPressed: _clearImage,
            ),
          ),
        ],
      );
    }
    // Hiển thị ảnh cũ nếu đang edit và chưa chọn ảnh mới
    else if (widget.itemToEdit?.imageUrl != null && widget.itemToEdit!.imageUrl!.isNotEmpty) {
      final existingImageUrl = widget.itemToEdit!.imageUrl!;
      if (existingImageUrl.startsWith('http')) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                existingImageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 48),
                          SizedBox(height: 8),
                          Text('Không thể tải ảnh'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
                onPressed: _clearImage,
              ),
            ),
          ],
        );
      } else {
        // File path
        try {
          final file = File(existingImageUrl);
          if (file.existsSync()) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                    ),
                    onPressed: _clearImage,
                  ),
                ),
              ],
            );
          }
        } catch (e) {
          // Fall through to empty state
        }
      }
    }
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Chưa có hình ảnh',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = InputSanitizer.sanitizeName(_nameController.text);
      final price = double.tryParse(_priceController.text.trim());
      
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập giá hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Determine image source
      String? finalImageUrl;
      if (_pickedImage != null) {
        // For now, we'll use the file path. In production, you'd upload to server/storage
        finalImageUrl = _pickedImage!.path;
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        finalImageUrl = _imageUrl;
      } else if (widget.itemToEdit?.imageUrl != null) {
        // Giữ nguyên ảnh cũ nếu không thay đổi
        finalImageUrl = widget.itemToEdit!.imageUrl;
      }

      final updatedItem = MenuItem(
        id: widget.itemToEdit?.id ?? DateTime.now().millisecondsSinceEpoch,
        name: name,
        price: price,
        category: _selectedCategory,
        imageUrl: finalImageUrl,
      );

      Navigator.of(context).pop(updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.itemToEdit == null ? 'Thêm món mới' : 'Sửa món ăn',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Image Preview
                _buildImagePreview(),
                const SizedBox(height: 16),
                
                // Image Source Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Chọn từ thư viện'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showImageUrlDialog(),
                        icon: const Icon(Icons.link),
                        label: const Text('Link Google'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên món ăn',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  validator: (value) {
                    final sanitized =
                        value == null ? '' : InputSanitizer.sanitizeName(value);
                    if (sanitized.isEmpty) {
                      return 'Vui lòng nhập tên món ăn';
                    }
                    if (sanitized.length < 2) {
                      return 'Tên món ăn quá ngắn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Price Field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Giá (VNĐ)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập giá';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Giá không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                DropdownButtonFormField<MenuCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: MenuCategory.food,
                      child: Text('Món ăn'),
                    ),
                    DropdownMenuItem(
                      value: MenuCategory.drink,
                      child: Text('Thức uống'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Hủy'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(widget.itemToEdit == null ? 'Thêm món' : 'Cập nhật'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

