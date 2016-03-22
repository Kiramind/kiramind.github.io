import 'dart:html';
import 'package:HexPeriment/game/game_info.dart';
import 'package:HexPeriment/game/hex_renderer.dart';
import 'package:HexPeriment/algorithm/visibilityalgorithm.dart';
import 'package:Hex/hex.dart';
import 'package:logging/logging.dart';

class VisibilityApp {
  
  static final String HTML_ACTIVE_CLASS="active";
  
  final Logger log = new Logger('VisibilityApp');
  
  CanvasElement theCanvas;
  CanvasRenderingContext2D context;
  MapInfo hexMap;
  final int halfNbHex_Q=4;
  static final TextAreaElement logElement=querySelector('#log');
  SelectionMode selectionMode=SelectionMode.LAND;
  Hex tempHex=null;
  int visibilityRadius=3;
  
  
  VisibilityApp() {
    // Initialize the canvas and context
    theCanvas = document.querySelector('#canvas');
    context = theCanvas.getContext('2d');
    context.globalCompositeOperation='source-over';
    
    //Initialize hexMap
    HexRenderer rdr= new HexRenderer(context);
    rdr.fog=true;
    hexMap= new MapInfo(theCanvas.width, theCanvas.height, halfNbHex_Q, rdr);
    
    //init first visibility computing
    tempHex=hexMap.idToHex[hexMap.fromHexId];
    computeVisibility(tempHex);
    
    //init Interaction
    _initInteraction();
    
  }
  
  void drawScreen() {    
    hexMap.drawMap();
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
      
      GameHex selectedHex=hexMap.getSelectedHexFromPixel(x, y);
      if(selectedHex!=null){
        
        _onHexSelected(selectedHex);
        //selectedHex.drawHexOnMap(context, hexMap.mapCenter);
        clearScreen();
        drawScreen();
        
      }      
    });
    
    //selection buttons
    List<SelectionMode> selMode=SelectionMode.values;
    selMode.forEach((mode){
      _getButtonFromMode(mode).onClick.listen((e)=>_onButtonSelection(mode));
    });
    
    //slider
    InputElement sliderLabel=querySelector('#viewRangeLabel');
    InputElement slider=querySelector('#viewRange');
    slider.onInput.listen((e){
      String newValue=slider.value;
      sliderLabel.value=newValue;
      
      int newVal=int.parse(newValue);
      if(newVal!=visibilityRadius){
        visibilityRadius=newVal;
        
        //compute visibility
        computeVisibility(tempHex);
        
      }

    });
    
    //clear debug
    InputElement btn=querySelector('#clearButton');
    btn.onClick.listen((e)=>logElement.text='');  
    
    //compute visibility on move when hex change
    theCanvas.onMouseMove.listen((MouseEvent e){
      //mouse point 
      var mousex = e.offset.x;
      var mousey = e.offset.y;
      
      Hex currentHex=hexMap.getSelectedHexFromPixel(mousex, mousey);
      
      if(currentHex!=tempHex){
        tempHex=currentHex;
        computeVisibility(currentHex);
      }
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
      case SelectionMode.LAND:
        ret=querySelector('#landButton');
        break;
      case SelectionMode.MOUNTAIN:
        ret=querySelector('#mountainButton');
        break;
      case SelectionMode.HILL:
        ret=querySelector('#hillButton');
        break;
    }
    
    return ret;
  }
  
  _onHexSelected(GameHex hex){
    switch(selectionMode){
      case SelectionMode.LAND:
        hexMap.changeType(hex, HexType.LAND);
        break;
      case SelectionMode.MOUNTAIN:
        hexMap.changeType(hex, HexType.MOUNTAIN);
        break;
      case SelectionMode.HILL:
        hexMap.changeType(hex, HexType.HILL);
        break;
    }
  }
  
  void computeVisibility(Hex startHex){
    if(startHex==null){
      return;
    }
    GameHex vHex=hexMap.idToHex[startHex.id];
    hexMap.clearVisibility();
    if(vHex!=null){
      VisibilityAlgorithm vAlgo= new VisibilityAlgorithm(vHex);
      
      hexMap.applyToHexRing(startHex, visibilityRadius, (hex){
        vAlgo.visibleRayTo(hex,visibilityRadius);
      });
 
      clearScreen();
      drawScreen();
    }
  }
  
}



void main() {
  var canvasApp = new VisibilityApp();
  
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
  static const HILL = const SelectionMode._("Hill");
  static const MOUNTAIN = const SelectionMode._("Mountain");
  static const LAND = const SelectionMode._("Land");

  static get values => [HILL, MOUNTAIN,LAND];
  
  final String name;

  const SelectionMode._(this.name);
}
