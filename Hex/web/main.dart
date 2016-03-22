// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'package:HexPeriment/game/game_info.dart';
import 'package:HexPeriment/game/hex_renderer.dart';
import 'package:logging/logging.dart';
import 'package:Hex/hex.dart';

class HexPerimentApp{
  
  static final String HTML_ACTIVE_CLASS="active";
  static final String HTML_SEL_CHAR_LI_CLASS="selectedCharLi";
  static final String HTML_HIDDEN_CLASS="hidden";
  
  static final String LABEL_ACTIVE_FOG="Fog Active";
  static final String LABEL_INACTIVE_FOG="Fog Inactive";
  
  static final String GLYPH_INFO="glyphicon-info-sign";
  static final String GLYPH_CLOSE="glyphicon-remove";
  
  
  final Logger log = new Logger('HexPerimentApp');
  
  
  CanvasElement theCanvas;
  CanvasRenderingContext2D context;
  MapInfo hexMap;
  int halfNbHex_Q=5;
  SelectionMode selectionMode=SelectionMode.NONE;
  Map<String,String> maps= new Map();
  Point startDrag;
  HexRenderer rdr;
  
  HexPerimentApp(){
    
    //logger
    Logger.root.level = Level.OFF;
    Logger.root.onRecord.listen((LogRecord rec) {
      String message='[${rec.loggerName}] ${rec.level.name}: ${rec.message}';
      print(message);
    });
    
    DivElement canvaContainer=document.querySelector('#canvaContainer');
    Rectangle rec=canvaContainer.client;
    
    
    // Initialize the canvas and context
    theCanvas= new CanvasElement(width: rec.width, height: rec.width);
    theCanvas.id="canvas";
    canvaContainer.children.insert(0,theCanvas);
    
    //theCanvas = document.querySelector('#canvas');
    context = theCanvas.getContext('2d');
    context.globalCompositeOperation='source-over';
    
//  compute nb hexes
    if(theCanvas.width<=400){
      halfNbHex_Q=4;
    }
    
    //Initialize hexMap
    rdr= new HexRenderer(context);
    hexMap= new MapInfo(theCanvas.width, theCanvas.height, halfNbHex_Q, rdr);
    
    //save initial map
    _saveMap("DEFAULT_MAP", hexMap.toJson());
    
    //init character combo
    UListElement ul=querySelector("#characters");
    CharacterType.values.forEach((ch){
      LIElement li= new LIElement();
      li.classes.add("listking");
      ImageElement im=new ImageElement(src:ch.image.path,width : 30,height : 30);

      li.append(im);
      li.innerHtml+=ch.name;
      
      //initial selected char
      if(ch==hexMap.character){
        li.classes.add(HTML_SEL_CHAR_LI_CLASS);
      }
      
      li.onClick.listen((_){
        
        //change character in the model
        _changeCharacter(ch);
        
        //remove previous selected char (html)
        List<LIElement> lis=ul.querySelectorAll("li");
        lis.forEach((l){
          l.classes.remove(HTML_SEL_CHAR_LI_CLASS);
        });
        
        //put current as selected char (html)
        li.classes.add(HTML_SEL_CHAR_LI_CLASS);
        
      });
      ul.append(li);
    });
  }
  
  void drawScreen() {    
    hexMap.drawMap();
  }
  
  void clearScreen(){
    context.clearRect(0, 0, theCanvas.width, theCanvas.height);
  }
  
  _initInteraction(){
    //Click Canvas Interaction
    theCanvas.onClick.listen((e){
      
      //find selected hex
      var x = e.offset.x;
      var y = e.offset.y;
      
      log.info('Click x :'+x.toString()+'  -- y : '+y.toString());
      
      GameHex selectedHex=hexMap.getSelectedHexFromPixel(x, y);
      if(selectedHex!=null){
        
        _onHexSelected(selectedHex);
      }      
    });

    /*
     * SAVE MAP
     */ 
    InputElement saveBtn=querySelector('#saveButton');//save button
    InputElement nameInput=querySelector('#nameInput');//save button
    saveBtn.onClick.listen((e){
      String text=nameInput.value;
      String export=hexMap.toJson();
      _saveMap(text, export);
    });
    
    /*
     * InfoButtons
     */
    ElementList<SpanElement> infoSpans=querySelectorAll(".info");
    ElementList<ParagraphElement> infoDescs=querySelectorAll(".infodesc");
    int index=0;
    infoSpans.forEach((sp){
      ParagraphElement p=infoDescs.elementAt(index);
      sp.onClick.listen((_){
        bool hidden=p.classes.toggle(HTML_HIDDEN_CLASS);
        sp.classes.toggleAll([GLYPH_CLOSE,GLYPH_INFO]);
      });
      index++;
    });
    
    /*
     * Map buttons
     */ 
    List<SelectionMode> selMode=SelectionMode.values;
    selMode.where((mode)=>(mode!=SelectionMode.NONE)).forEach((mode){
      _getButtonFromMode(mode).onClick.listen((e)=>_onButtonSelection(mode));
    });
    
    /*
     * Change fog
     */
    InputElement fogButton=querySelector("#fogButton");
    ElementList visiComponents=querySelectorAll(".visiComponent");
    fogButton.onClick.listen((_){
      
      //change visi of hideable components
      visiComponents.classes.toggle(HTML_HIDDEN_CLASS);
      //change activation state
      fogButton.classes.toggle(HTML_ACTIVE_CLASS);
      
      //change text value
      bool isFog=hexMap.fog;
      if(isFog){
        fogButton.value=LABEL_ACTIVE_FOG;
      }
      else{
        fogButton.value=LABEL_INACTIVE_FOG;
      }
      
      //change fog value
      hexMap.fog=!isFog;
      rdr.fog=!isFog;
      
      _updateMap();
    });
    
    /*
     * KEY INTERACTION
     */
    window.onKeyUp.listen((KeyboardEvent e) {
      bool hitKey=false;
      switch(e.keyCode){
        case KeyCode.NUM_ONE:
          hexMap.movePlayer(HexDirection.SOUTH_WEST);
          hitKey=true;
          break;
        case KeyCode.NUM_TWO:
          hexMap.movePlayer(HexDirection.SOUTH);
          hitKey=true;
          break;
        case KeyCode.NUM_THREE:
          hexMap.movePlayer(HexDirection.SOUTH_EAST);
          hitKey=true;
          break;
        case KeyCode.NUM_SEVEN:
          hexMap.movePlayer(HexDirection.NORTH_WEST);
          hitKey=true;
          break;
        case KeyCode.NUM_EIGHT:
          hexMap.movePlayer(HexDirection.NORTH);
          hitKey=true;
          break;
        case KeyCode.NUM_NINE:
          hexMap.movePlayer(HexDirection.NORTH_EAST);
          hitKey=true;
          break;
      }
      if(hitKey){
        _updateMap();
      }
      

    });
    /*
     * VISIBILITY RANGE
     */
    
    //slider
    InputElement sliderLabel=querySelector('#viewRangeLabel');
    InputElement slider=querySelector('#viewRange');
    slider.onInput.listen((e){
      String newValue=slider.value;
      sliderLabel.value=newValue;
      
      int newVal=int.parse(newValue);
      if(newVal!=hexMap.visibilityRadius){
        hexMap.visibilityRadius=newVal;
        
        //update visibility
        _updateMap();
        
      }
    });
  }
  
  _saveMap(String name, String json){
    log.info("Save map  :"+name);
    bool overwrite =maps.containsKey(name);
    
    maps[name]=json;
    if(!overwrite){
      UListElement ul=querySelector("#savedMaps");
      LIElement li= new LIElement();
      li.setAttribute("id", name);
      li.setInnerHtml(name);
      li.onClick.listen((_)=>_loadMap(name));
      ul.append(li);
    }

  }
  
  _loadMap(String name){
    log.info("Load map  :"+name);
    String json=maps[name];
    if(json!=null){
      hexMap.updateFromJson(json);
      _updateMap();
    }
    else{
      log.warning("map does not exist : "+name);
    }
  }
  
  _changeCharacter(CharacterType ch){
    hexMap.character=ch;
    _updateMap();
  }
  
  _updateMap(){
    hexMap.clearSelection();
    Stopwatch stopwatch = new Stopwatch()..start();
    hexMap.selectCurrentPath();
    log.info('AStar Algo executed in ${stopwatch.elapsed}');
    stopwatch.stop();
    
    hexMap.computePlayerVisibility();
    
    clearScreen();
    drawScreen();
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
      case SelectionMode.FOREST:
        hexMap.changeType(hex, HexType.FOREST);
        break;
      case SelectionMode.SAND:
        hexMap.changeType(hex, HexType.SAND);
        break;
      case SelectionMode.CHEST:
        hexMap.selectEndHex(hex);
        break;
      case SelectionMode.PLAYER:
        hexMap.selectStartHex(hex);
        break;
      case SelectionMode.COIN:
        hexMap.putCoin(hex);
        break;
    }
    
    //update path
    if(selectionMode!=SelectionMode.NONE){
      _updateMap();
    }
  }
  
  void _onButtonSelection(SelectionMode newSelMode){
    
    if(newSelMode==selectionMode){
      newSelMode=SelectionMode.NONE;
    }
    
    log.info("Change selection mode :"+newSelMode.name);
    
    if(selectionMode!=newSelMode){
 
      if(selectionMode!=SelectionMode.NONE){
        InputElement old=_getButtonFromMode(selectionMode);
        old.classes.remove(HTML_ACTIVE_CLASS);
      }
      
      if(newSelMode!=SelectionMode.NONE){
        InputElement active=_getButtonFromMode(newSelMode);
        active.classes.add(HTML_ACTIVE_CLASS); 
      }
      
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
      case SelectionMode.FOREST:
        ret=querySelector('#forestButton');
        break;
      case SelectionMode.CHEST:
        ret=querySelector('#chestButton');
        break;
      case SelectionMode.SAND:
        ret=querySelector('#sandButton');
        break;
      case SelectionMode.PLAYER:
        ret=querySelector('#playerButton');
        break;
      case SelectionMode.COIN:
        ret=querySelector('#coinButton');
        break;
    }
    return ret;
  }
  
}

/**
 * Enum describing the selection mode for map clicks
 */
class SelectionMode {
  static const NONE = const SelectionMode._("None");
  static const HILL = const SelectionMode._("Hill");
  static const MOUNTAIN = const SelectionMode._("Mountain");
  static const LAND = const SelectionMode._("Land");
  static const CHEST = const SelectionMode._("Chest");
  static const FOREST = const SelectionMode._("Forest");
  static const SAND = const SelectionMode._("Sand");
  static const PLAYER = const SelectionMode._("PLAYER");
  static const COIN = const SelectionMode._("COIN");

  static get values => [NONE,HILL, MOUNTAIN,LAND,CHEST,FOREST,SAND,PLAYER,COIN];
  
  final String name;

  const SelectionMode._(this.name);
}

void main() {
  
  var canvasApp = new HexPerimentApp();
  
  canvasApp.hexMap.loadAllImages().then((_){
    canvasApp._initInteraction();
    canvasApp._updateMap();
    canvasApp.drawScreen();
  });
}

