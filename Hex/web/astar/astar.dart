import 'dart:html';
import 'package:HexPeriment/game/game_info.dart';
import 'package:HexPeriment/game/hex_renderer.dart';
import 'package:logging/logging.dart';

class AStarApp {  
  static final String HTML_ACTIVE_CLASS="active";
  
  final Logger log = new Logger('AStarApp');
  
  CanvasElement theCanvas;
  CanvasRenderingContext2D context;
  MapInfo mapInfo;
  final int halfNbHex_Q=4;
  static final TextAreaElement logElement=querySelector('#log');
  SelectionMode selectionMode=SelectionMode.START;
  
  
  AStarApp() {
    // Initialize the canvas and context
    theCanvas = document.querySelector('#canvas');
    context = theCanvas.getContext('2d');
    context.globalCompositeOperation='source-over';
    
    //Initialize MapInfo    
    HexRenderer rdr= new HexRenderer(context);
    rdr.fog=false;
    //rdr.drawId=true;
    mapInfo= new MapInfo(theCanvas.width, theCanvas.height, halfNbHex_Q,rdr,false);
    
    //init Interaction
    _initInteraction();
    
    
  }
  
  void drawScreen() {    
    mapInfo.drawMap();
//    ImageElement em=new ImageElement(src: "images/m_rois_1.png");
//    em.onLoad.listen((e){
//      context.drawImage(em, 0, 0);
//    });
  }
  
  void clearScreen(){
    context.clearRect(0, 0, theCanvas.width, theCanvas.height);
  }
  
  _initInteraction(){
    //Click Interaction
    theCanvas.onClick.listen((e){
      
      //find selected hex
      var x = e.offset.x;
      var y = e.offset.y;
      
      //log('Click x :'+x.toString()+'  -- y : '+y.toString());
      
      GameHex selectedHex=mapInfo.getSelectedHexFromPixel(x, y);
      if(selectedHex!=null){
        
        _onHexSelected(selectedHex);
        //selectedHex.drawHexOnMap(context, MapInfo.mapCenter);
        clearScreen();
        drawScreen();
        
      }      
    });
    
    //selection buttons
    List<SelectionMode> selMode=SelectionMode.values;
    selMode.forEach((mode){
      _getButtonFromMode(mode).onClick.listen((e)=>_onButtonSelection(mode));
    });
    
    //clear debug
    InputElement btn=querySelector('#clearButton');
    btn.onClick.listen((e)=>logElement.text='');
    
    
    //pathFind
    InputElement btnFind=querySelector('#pathfindButton');
    btnFind.onClick.listen((e){
      mapInfo.clearSelection();

      
      Stopwatch stopwatch = new Stopwatch()..start();
      mapInfo.selectCurrentPath();
      log.info('AStar Algo executed in ${stopwatch.elapsed}');
      stopwatch.stop();
      
      clearScreen();
      drawScreen();
    });
    
  }
  
  void _onButtonSelection(SelectionMode newSelMode){
    
    log.info("Change selection mode :"+newSelMode.name);
    
    if(selectionMode!=newSelMode){
      InputElement old=_getButtonFromMode(selectionMode);
      old.classes.remove(HTML_ACTIVE_CLASS);
      
      InputElement active=_getButtonFromMode(newSelMode);
      active.classes.add(HTML_ACTIVE_CLASS);
      
      selectionMode=newSelMode;
    }
  }
  
  InputElement _getButtonFromMode(SelectionMode mode){
    InputElement ret=null;
    switch(mode){
      case SelectionMode.START:
        ret=querySelector('#startButton');
        break;
      case SelectionMode.END:
        ret=querySelector('#endButton');
        break;
      case SelectionMode.LAND:
        ret=querySelector('#landButton');
        break;
      case SelectionMode.FOREST:
        ret=querySelector('#forestButton');
        break;
      case SelectionMode.SAND:
        ret=querySelector('#sandButton');
        break;
    }
    
    return ret;
  }
  
  _onHexSelected(GameHex hex){
    switch(selectionMode){
      case SelectionMode.START:
        mapInfo.selectStartHex(hex);
        break;
      case SelectionMode.END:
        mapInfo.selectEndHex(hex);
        break;
      case SelectionMode.LAND:
        mapInfo.changeType(hex, HexType.LAND);
        break;
      case SelectionMode.FOREST:
        mapInfo.changeType(hex, HexType.FOREST);
        break;
      case SelectionMode.SAND:
        mapInfo.changeType(hex, HexType.SAND);
        break;
    }
  }
}



void main() {
  
  var canvasApp = new AStarApp();
  
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((LogRecord rec) {
    String message='[${rec.loggerName}] ${rec.level.name}: ${rec.message}';
    print(message);
  });
  
  GameImage.load(ImageType.values).then((_){
    canvasApp.drawScreen();
  });
  
  
}

/**
 * Enum describing the selection mode for map clicks
 */
class SelectionMode {
  static const SAND = const SelectionMode._("Sand");
  static const FOREST = const SelectionMode._("Forest");
  static const LAND = const SelectionMode._("Land");
  static const START = const SelectionMode._("Start");
  static const END = const SelectionMode._("End");

  static get values => [SAND, FOREST,LAND,START,END];
  
  final String name;

  const SelectionMode._(this.name);
}
