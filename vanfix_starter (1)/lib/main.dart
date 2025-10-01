
// main.dart - VanFix Estimator (starter demo)
// NOTE: This is the same compact file provided earlier to you. Save under lib/main.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => EstimateModel(),
    child: VanFixApp(),
  ));
}

class VanFixApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VanFix Estimator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

/* ---------- App State (simple) ---------- */
class EstimateModel extends ChangeNotifier {
  Map<String, dynamic> van = {};
  List<String> images = [];
  String location = '';
  String severity = 'Minor';
  List<Map<String,dynamic>> saved = [];

  void setVan(Map<String,dynamic> v){ van = v; notifyListeners(); }
  void addImage(String p){ images.add(p); notifyListeners(); }
  void setLocation(String l){ location = l; notifyListeners(); }
  void setSeverity(String s){ severity = s; notifyListeners(); }
  void clear(){ van = {}; images = []; location=''; severity='Minor'; notifyListeners(); }

  Future<void> saveEstimate(Map<String,dynamic> est) async {
    saved.add(est);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('savedEstimates', jsonEncode(saved));
    notifyListeners();
  }
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('savedEstimates');
    if(raw!=null){
      final List l = jsonDecode(raw);
      saved = l.map((e)=>Map<String,dynamic>.from(e)).toList();
      notifyListeners();
    }
  }
}

/* ---------- Simple parts DB & Pricing logic ---------- */
final partsDb = {
  'front bumper': 300,
  'rear bumper': 280,
  'left door': 450,
  'right door': 450,
  'roof': 600,
  'hood': 400,
  'headlight': 120,
  'taillight': 90,
  'panel': 350
};

double severityMultiplier(String severity){
  switch(severity.toLowerCase()){
    case 'minor': return 0.6;
    case 'moderate': return 1.0;
    case 'severe': return 1.6;
    default: return 1.0;
  }
}

Map<String,dynamic> calculateEstimate({
  required String location,
  required String severity,
  required Map<String,dynamic> van
}){
  final partKey = partsDb.keys.contains(location.toLowerCase()) ? location.toLowerCase() : 'panel';
  final partCost = partsDb[partKey] ?? 300;
  final laborBaseHours = 2.0;
  final laborPerSeverity = {'minor':1.0, 'moderate':1.5, 'severe':2.2};
  final laborHours = laborBaseHours * (laborPerSeverity[severity.toLowerCase()] ?? 1.0);
  final regionalRate = 45.0;
  final laborCost = laborHours * regionalRate;
  final multiplier = severityMultiplier(severity);
  final subtotal = (partCost * multiplier) + laborCost;
  final vat = subtotal * 0.20;
  final total = subtotal + vat;

  return {
    'partKey': partKey,
    'partCost': partCost,
    'laborHours': laborHours,
    'laborRate': regionalRate,
    'laborCost': laborCost,
    'severityMultiplier': multiplier,
    'subtotal': double.parse(subtotal.toStringAsFixed(2)),
    'vat': double.parse(vat.toStringAsFixed(2)),
    'total': double.parse(total.toStringAsFixed(2)),
  };
}

/* Screens */
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState(){
    super.initState();
    final model = Provider.of<EstimateModel>(context, listen:false);
    model.loadSaved();
  }
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<EstimateModel>(context);
    return Scaffold(
      appBar: AppBar(title: Text('VanFix Estimator')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children:[
            ElevatedButton.icon(
              icon: Icon(Icons.add_a_photo),
              label: Text('New Estimate'),
              onPressed: (){
                model.clear();
                Navigator.push(context, MaterialPageRoute(builder: (_) => VanDetailsScreen()));
              }
            ),
            SizedBox(height:12),
            Text('Saved Estimates', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: model.saved.isEmpty
                ? Center(child: Text('No saved estimates yet'))
                : ListView.builder(
                    itemCount: model.saved.length,
                    itemBuilder: (_,i){
                      final s = model.saved[i];
                      return ListTile(
                        title: Text('Estimate - ${s['van']['make'] ?? 'Unknown'} ${s['van']['model'] ?? ''}'),
                        subtitle: Text('Total: £${s['result']['total']} — ${s['location'] ?? ''}'),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EstimateViewScreen(est: s))),
                      );
                    }),
            )
          ]
        ),
      ),
    );
  }
}

class VanDetailsScreen extends StatefulWidget {
  @override
  State<VanDetailsScreen> createState() => _VanDetailsScreenState();
}
class _VanDetailsScreenState extends State<VanDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtl = TextEditingController();
  final _modelCtl = TextEditingController();
  final _yearCtl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<EstimateModel>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Van Details')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Form(
          key:_formKey,
          child: Column(children:[
            TextFormField(controller: _makeCtl, decoration: InputDecoration(labelText:'Make (e.g. Ford)'), validator: (v)=>v==null||v.isEmpty?'Required':null),
            TextFormField(controller: _modelCtl, decoration: InputDecoration(labelText:'Model (e.g. Transit)'), validator: (v)=>v==null||v.isEmpty?'Required':null),
            TextFormField(controller: _yearCtl, decoration: InputDecoration(labelText:'Year (e.g. 2018)'), keyboardType: TextInputType.number, validator: (v)=>v==null||v.isEmpty?'Required':null),
            SizedBox(height:12),
            ElevatedButton(
              child: Text('Continue to Capture'),
              onPressed: (){
                if(_formKey.currentState!.validate()){
                  model.setVan({'make':_makeCtl.text, 'model':_modelCtl.text, 'year':_yearCtl.text});
                  Navigator.push(context, MaterialPageRoute(builder: (_) => CaptureScreen()));
                }
              })
          ]),
        ),
      ),
    );
  }
}

class CaptureScreen extends StatefulWidget {
  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}
class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<EstimateModel>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Capture Damage')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children:[
          Wrap(spacing:8, children:[
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Take Photo'),
              onPressed: () async {
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if(photo!=null){
                  final saved = await _saveToLocal(photo);
                  model.addImage(saved);
                }
              }),
            ElevatedButton.icon(
              icon: Icon(Icons.video_call),
              label: Text('Record Video'),
              onPressed: () async {
                final XFile? vid = await _picker.pickVideo(source: ImageSource.camera, maxDuration: Duration(seconds:20));
                if(vid!=null){
                  final saved = await _saveToLocal(vid);
                  model.addImage(saved);
                }
              }),
            ElevatedButton.icon(
              icon: Icon(Icons.photo_library),
              label: Text('Pick from Gallery'),
              onPressed: () async {
                final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
                if(photo!=null){
                  final saved = await _saveToLocal(photo);
                  model.addImage(saved);
                }
              }),
          ]),
          SizedBox(height:12),
          Text('Captured Media', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: model.images.map((p){
                final isVideo = p.toLowerCase().endsWith('.mp4');
                return Card(
                  child: InkWell(
                    onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_) => MediaPreviewScreen(path: p))),
                    child: Stack(children:[
                      Positioned.fill(child: Image.file(File(p), fit: BoxFit.cover)),
                      if(isVideo) Positioned(top:8,right:8, child: Icon(Icons.videocam, color: Colors.white))
                    ])
                  ),
                );
              }).toList(),
            ),
          ),
          ElevatedButton(
            child: Text('Next: Mark Location'),
            onPressed: model.images.isEmpty ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationSelectorScreen())),
          )
        ]),
      ),
    );
  }

  Future<String> _saveToLocal(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.name;
    final dest = File('${dir.path}/$name');
    await File(file.path).copy(dest.path);
    return dest.path;
  }
}

class MediaPreviewScreen extends StatelessWidget {
  final String path;
  MediaPreviewScreen({required this.path});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Image.file(File(path))),
    );
  }
}

class LocationSelectorScreen extends StatefulWidget {
  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}
class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  String selected = '';
  String severity = 'Minor';
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<EstimateModel>(context);
    final areas = ['Front Bumper','Left Door','Right Door','Roof','Rear Bumper','Hood','Headlight','Taillight','Panel'];
    return Scaffold(
      appBar: AppBar(title: Text('Select Damage Location')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children:[
          Container(
            height: 160,
            color: Colors.grey[200],
            child: Center(child: Text('Van diagram (replace with SVG)', style: TextStyle(color: Colors.grey[700]))),
          ),
          SizedBox(height:8),
          Wrap(spacing:8, children: areas.map((a) => ChoiceChip(
            label: Text(a),
            selected: selected==a,
            onSelected: (sel){ setState(()=>selected = sel? a : ''); }
          )).toList()),
          SizedBox(height:12),
          Row(children:[
            Text('Severity: '),
            DropdownButton<String>(
              value: severity,
              items: ['Minor','Moderate','Severe'].map((s)=>DropdownMenuItem(child: Text(s), value: s)).toList(),
              onChanged: (v)=>setState(()=>severity = v ?? 'Minor'),
            )
          ]),
          Spacer(),
          ElevatedButton(
            child: Text('Get Estimate'),
            onPressed: selected.isEmpty ? null : (){
              model.setLocation(selected);
              model.setSeverity(severity);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EstimateScreen()));
            })
        ]),
      ),
    );
  }
}

class EstimateScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final model = Provider.of<EstimateModel>(context);
    final result = calculateEstimate(location: model.location, severity: model.severity, van: model.van);
    return Scaffold(
      appBar: AppBar(title: Text('Estimate')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children:[
          ListTile(title: Text('${model.van['make'] ?? ''} ${model.van['model'] ?? ''} (${model.van['year'] ?? ''})')),
          ListTile(title: Text('Location'), subtitle: Text(model.location)),
          ListTile(title: Text('Severity'), subtitle: Text(model.severity)),
          Divider(),
          ListTile(title: Text('Part'), subtitle: Text('${result['partKey']} — £${result['partCost']}')),
          ListTile(title: Text('Labor'), subtitle: Text('${result['laborHours']} hrs @ £${result['laborRate']}/hr = £${result['laborCost'].toStringAsFixed(2)}')),
          ListTile(title: Text('Subtotal'), trailing: Text('£${result['subtotal']}')),
          ListTile(title: Text('VAT (20%)'), trailing: Text('£${result['vat']}')),
          ListTile(title: Text('Total'), trailing: Text('£${result['total']}', style: TextStyle(fontWeight: FontWeight.bold))),
          Spacer(),
          ElevatedButton(
            child: Text('Save Estimate'),
            onPressed: () async {
              final est = {
                'timestamp': DateTime.now().toIso8601String(),
                'van': model.van,
                'location': model.location,
                'severity': model.severity,
                'images': model.images,
                'result': result
              };
              await model.saveEstimate(est);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved')));
              Navigator.popUntil(context, (route) => route.isFirst);
            }),
        ]),
      ),
    );
  }
}

class EstimateViewScreen extends StatelessWidget {
  final Map<String,dynamic> est;
  EstimateViewScreen({required this.est});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saved Estimate')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(children:[
          ListTile(title: Text('${est['van']['make']} ${est['van']['model']}')),
          ListTile(title: Text('Location'), subtitle: Text(est['location'] ?? '')),
          ListTile(title: Text('Total'), trailing: Text('£${est['result']['total']}')),
          ElevatedButton(child: Text('View Images'), onPressed: (){
            if((est['images'] as List).isEmpty) return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => GalleryViewer(paths: List<String>.from(est['images']))));
          })
        ]),
      ),
    );
  }
}

class GalleryViewer extends StatelessWidget {
  final List<String> paths;
  GalleryViewer({required this.paths});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: PageView(children: paths.map((p)=>Image.file(File(p))).toList()),
    );
  }
}
