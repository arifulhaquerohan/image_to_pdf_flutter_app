import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ThemeNotifier Class (Manages theme changes and persistence) ---
class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier(ThemeMode initialMode) : super(initialMode);
  static const String _themePersistenceKey = 'app_theme_mode';

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeModeString = prefs.getString(_themePersistenceKey);
    if (themeModeString == ThemeMode.dark.toString()) {
      value = ThemeMode.dark;
    } else if (themeModeString == ThemeMode.light.toString()) {
      value = ThemeMode.light;
    } else {
      value = ThemeMode.system; // Default to system theme
    }
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (value == newMode) return;
    value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePersistenceKey, newMode.toString());
    notifyListeners();
  }

  void toggleTheme() {
    if (value == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

// Global instance of ThemeNotifier
final ThemeNotifier themeNotifier = ThemeNotifier(ThemeMode.system);

// --- Main Function ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for SharedPreferences
  await themeNotifier
      ._loadThemeMode(); // Load saved theme before running the app
  runApp(const MyApp());
}

// --- MyApp Widget (Root of the application) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Image to PDF Converter',
          debugShowCheckedModeBanner: false, // Optional: hide debug banner
          theme: ThemeData(
              brightness: Brightness.light,
              primarySwatch: Colors.teal,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.teal,
                brightness: Brightness.light,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                foregroundColor: Colors.teal,
                side: const BorderSide(color: Colors.teal),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              )),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.teal, width: 2.0)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 15.0),
              ),
              expansionTileTheme: ExpansionTileThemeData(
                iconColor: Colors.teal,
                textColor: Colors.teal,
                collapsedTextColor:
                    Theme.of(context).textTheme.titleMedium?.color,
              )),
          darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch:
                  Colors.teal, // Using teal for dark too, can be changed
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor:
                    Colors.tealAccent, // A slightly different seed for dark
                brightness: Brightness.dark,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.tealAccent[700],
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                  style: OutlinedButton.styleFrom(
                foregroundColor: Colors.tealAccent[100],
                side: BorderSide(color: Colors.tealAccent[100]!),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              )),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        BorderSide(color: Colors.tealAccent[100]!, width: 2.0)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 15.0),
              ),
              expansionTileTheme: ExpansionTileThemeData(
                iconColor: Colors.tealAccent[100],
                textColor: Colors.tealAccent[100],
                collapsedTextColor:
                    Theme.of(context).textTheme.titleMedium?.color,
              )),
          themeMode: currentMode,
          home: const ImageToPdfConverterScreen(),
        );
      },
    );
  }
}

// --- ImageToPdfConverterScreen Widget (Main screen of the app) ---
class ImageToPdfConverterScreen extends StatefulWidget {
  const ImageToPdfConverterScreen({super.key});

  @override
  _ImageToPdfConverterScreenState createState() =>
      _ImageToPdfConverterScreenState();
}

class _ImageToPdfConverterScreenState extends State<ImageToPdfConverterScreen> {
  List<File> _selectedImages = [];
  String? _pdfPath;
  bool _isConverting = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _filenameController = TextEditingController();

  // PDF settings state variables
  String _selectedPageSizeKey = 'A4';
  final Map<String, PdfPageFormat> _pageSizes = {
    'A4': PdfPageFormat.a4,
    'Letter': PdfPageFormat.letter,
    'A5': PdfPageFormat.a5,
  };

  String _selectedOrientationKey = 'Portrait';
  final List<String> _orientations = ['Portrait', 'Landscape'];

  pw.BoxFit _selectedBoxFit = pw.BoxFit.contain;
  final Map<String, pw.BoxFit> _boxFitOptions = {
    'Contain (show whole image)': pw.BoxFit.contain,
    'Cover (fill page, may crop)': pw.BoxFit.cover,
    'Fill (stretch to fill page)': pw.BoxFit.fill,
    'Fit Width (match page width)': pw.BoxFit.fitWidth,
    'Fit Height (match page height)': pw.BoxFit.fitHeight,
    'Scale Down (if larger than page)': pw.BoxFit.scaleDown,
  };

  final TextEditingController _marginController =
      TextEditingController(text: '20.0'); // Default margin

  @override
  void initState() {
    super.initState();
    _filenameController.text =
        "converted_pdf_${DateTime.now().millisecondsSinceEpoch ~/ 1000}";
  }

  @override
  void dispose() {
    _filenameController.dispose();
    _marginController.dispose();
    super.dispose();
  }

  // --- Image Picking and Management Methods ---
  Future<void> _pickMultipleImages() async {
    if (_isConverting) return;
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
          imageQuality: 85); // Optional: compress a bit
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages
              .addAll(pickedFiles.map((xfile) => File(xfile.path)).toList());
          _pdfPath = null;
        });
        _showFeedback('${pickedFiles.length} image(s) selected!');
      } else {
        _showFeedback('No images selected.');
      }
    } catch (e) {
      _handleError("Error picking images: $e");
    }
  }

  Future<void> _captureImageFromCamera() async {
    if (_isConverting) return;
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
          _pdfPath = null;
        });
        _showFeedback('Image captured!');
      } else {
        _showFeedback('No image captured.');
      }
    } catch (e) {
      _handleError("Error capturing image: $e");
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (_selectedImages.isEmpty) _pdfPath = null;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  // --- PDF Conversion, Opening, Sharing Methods ---
  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) {
      _showFeedback('Please select at least one image first!');
      return;
    }
    if (_isConverting) return;

    final double pageMargin =
        double.tryParse(_marginController.text.trim()) ?? 20.0;

    setState(() {
      _isConverting = true;
      _pdfPath = null;
    });
    _showFeedback('Converting to PDF... Please wait.');

    final pdf = pw.Document();
    try {
      PdfPageFormat baseFormat =
          _pageSizes[_selectedPageSizeKey] ?? PdfPageFormat.a4;
      PdfPageFormat finalPageFormat = _selectedOrientationKey == 'Landscape'
          ? baseFormat.landscape
          : baseFormat.portrait;

      for (var imageFile in _selectedImages) {
        final imageBytes = await imageFile.readAsBytes();
        final imageProvider = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: finalPageFormat,
            margin: pw.EdgeInsets.all(pageMargin),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(imageProvider, fit: _selectedBoxFit),
              );
            },
          ),
        );
      }

      final Directory directory = await getApplicationDocumentsDirectory();
      final String baseFilename = _filenameController.text.trim().isNotEmpty
          ? _filenameController.text.trim()
          : 'pdf_${DateTime.now().millisecondsSinceEpoch}';
      final String sanitizedFilename = baseFilename
          .replaceAll(RegExp(r'[^\w\s-]'), '_')
          .replaceAll(' ', '_');
      final String filePath = '${directory.path}/$sanitizedFilename.pdf';
      final File file = File(filePath);

      await file.writeAsBytes(await pdf.save());
      setState(() {
        _pdfPath = filePath;
      });

      _showFeedback(
        'PDF Saved: $sanitizedFilename.pdf',
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'OPEN', onPressed: _openPdf),
      );
    } catch (e) {
      _handleError("Error converting to PDF: $e");
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<void> _openPdf() async {
    if (_pdfPath == null) {
      _showFeedback('No PDF generated or path is invalid!');
      return;
    }
    try {
      final OpenResult result = await OpenFile.open(_pdfPath!);
      if (result.type != ResultType.done) {
        _showFeedback('Could not open PDF: ${result.message}');
      }
    } catch (e) {
      _handleError("Error opening PDF: $e");
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfPath == null) {
      _showFeedback('No PDF generated to share!');
      return;
    }
    try {
      await Share.shareXFiles([XFile(_pdfPath!)],
          text: 'Check out this PDF I created!');
    } catch (e) {
      _handleError("Error sharing PDF: $e");
    }
  }

  // --- Helper Methods for UI Feedback ---
  void _showFeedback(String message,
      {Duration duration = const Duration(seconds: 3),
      SnackBarAction? action}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  void _handleError(String errorMessage) {
    print(errorMessage); // For debug console
    _showFeedback(errorMessage.length > 150
        ? 'An unexpected error occurred. Check logs for details.'
        : errorMessage);
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image to PDF Converter'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, child) {
              return IconButton(
                icon: Icon(currentMode == ThemeMode.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined),
                tooltip: currentMode == ThemeMode.dark
                    ? 'Switch to Light Mode'
                    : 'Switch to Dark Mode',
                onPressed: () => themeNotifier.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined),
                      onPressed: _isConverting ? null : _pickMultipleImages,
                      label: const Text('Gallery'))),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: _isConverting ? null : _captureImageFromCamera,
                      label: const Text('Camera'))),
            ]),
            const SizedBox(height: 16),

            if (_selectedImages.isNotEmpty)
              Text('Selected Images (${_selectedImages.length}):',
                  style: Theme.of(context).textTheme.titleSmall),
            if (_selectedImages.isNotEmpty)
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(8.0)),
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(4.0),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final imageFile = _selectedImages[index];
                    return Card(
                      key: ValueKey(imageFile.path +
                          index.toString()), // Ensure unique key
                      elevation: 2.0,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4.0, vertical: 4.0),
                      child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4.0),
                              child: Image.file(imageFile,
                                  width: 100, height: 100, fit: BoxFit.cover),
                            ),
                            Positioned(
                                top: 2,
                                right: 2,
                                child: InkWell(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                )),
                          ])),
                    );
                  },
                  onReorder: _onReorder,
                ),
              ),
            if (_selectedImages.isEmpty)
              Container(
                height: 120, margin: const EdgeInsets.symmetric(vertical: 8.0),
                decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(
                        8.0)), // Corrected: removed dashPattern
                child: Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.image_search_outlined,
                          size: 40, color: Theme.of(context).hintColor),
                      const SizedBox(height: 8),
                      Text('No images selected.',
                          style: TextStyle(color: Theme.of(context).hintColor)),
                    ])),
              ),
            const SizedBox(height: 16),

            TextField(
              controller: _filenameController,
              decoration: InputDecoration(
                labelText: 'PDF Filename',
                hintText: 'e.g., my_document',
                prefixIcon: const Icon(Icons.file_present_rounded),
                suffixIcon: _filenameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _filenameController.clear())
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            ExpansionTile(
              title: const Text('PDF Output Settings'),
              key: const PageStorageKey<String>(
                  'pdf_settings_tile'), // For maintaining expanded state
              initiallyExpanded: false,
              childrenPadding:
                  const EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
              children: <Widget>[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Page Size',
                      prefixIcon: Icon(Icons.aspect_ratio)),
                  value: _selectedPageSizeKey,
                  items: _pageSizes.keys
                      .map((String key) => DropdownMenuItem<String>(
                          value: key, child: Text(key)))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null)
                      setState(() => _selectedPageSizeKey = newValue);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Page Orientation',
                      prefixIcon: Icon(Icons.screen_rotation_outlined)),
                  value: _selectedOrientationKey,
                  items: _orientations
                      .map((String value) => DropdownMenuItem<String>(
                          value: value, child: Text(value)))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null)
                      setState(() => _selectedOrientationKey = newValue);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<pw.BoxFit>(
                  decoration: const InputDecoration(
                      labelText: 'Image Fit Mode',
                      prefixIcon: Icon(Icons.fit_screen_outlined)),
                  value: _selectedBoxFit,
                  isExpanded: true,
                  items: _boxFitOptions.entries
                      .map((entry) => DropdownMenuItem<pw.BoxFit>(
                          value: entry.value,
                          child:
                              Text(entry.key, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (pw.BoxFit? newValue) {
                    if (newValue != null)
                      setState(() => _selectedBoxFit = newValue);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _marginController,
                  decoration: const InputDecoration(
                      labelText: 'Page Margin (all sides)',
                      prefixIcon: Icon(Icons.space_bar_rounded),
                      hintText: 'e.g., 20.0'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => (value == null ||
                          value.isEmpty ||
                          double.tryParse(value) == null)
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 8),
              ],
            ),
            const SizedBox(height: 20),

            if (_isConverting)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Converting...")
                      ])))
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: _selectedImages.isNotEmpty ? _convertToPdf : null,
                label: const Text('Create PDF'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15)),
              ),
            const SizedBox(height: 10),

            if (_pdfPath != null && !_isConverting)
              Row(children: [
                Expanded(
                    child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new_outlined),
                        onPressed: _openPdf,
                        label: const Text('Open'))),
                const SizedBox(width: 10),
                Expanded(
                    child: OutlinedButton.icon(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: _sharePdf,
                        label: const Text('Share'))),
              ]),
            const SizedBox(height: 20), // Footer padding
          ],
        ),
      ),
    );
  }
}
