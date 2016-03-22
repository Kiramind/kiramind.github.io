library hexmap;

import 'dart:math';
import 'dart:convert';
import 'dart:collection';
import 'dart:html';
import 'package:Hex/hex.dart';
import 'package:HexPeriment/algorithm/visibilityalgorithm.dart';
import 'package:HexPeriment/algorithm/astarAlgorithm.dart';
import './hex_renderer.dart';
import 'package:logging/logging.dart';
import 'dart:async';

class MapInfo{
  
  final Logger log = new Logger('MapInfo');
  
  /**
   * The hex renderer
   */
  HexRenderer _rdr;
  /*
   * Map caracteristics
   */
  String name="NO_NAME";
  int widthPixel;
  int height_pixel;
  int halfNbHex_Q;
  Point<num> mapCenter;
  num hexSize;
  
  String fromHexId=null;
  String toHexId=null;
  
  int coinCollected=0;
  int moveCost=0;
  int visibilityRadius=2;
  bool fog;
  
  Map<String,GameHex> idToHex=new SplayTreeMap<String,GameHex>();
  Map<String,GameObject> idToObjects=new SplayTreeMap<String,GameObject>();
  CharacterType character=CharacterType.KING_MIZU;
  
  final Map<String,AStarObject> _astarPool=new SplayTreeMap<String,AStarObject>();
  
  MapInfo(int width, int height, int hNbHexQ, this._rdr,[bool this.fog=false,bool randomHex=false]){
    this.widthPixel=width;
    this.height_pixel=height;
    this.halfNbHex_Q=hNbHexQ;
    this.hexSize=computeSize(widthPixel, halfNbHex_Q);
    this.mapCenter=_computeMapCenter();
    
    log.info("Create MapInfo - width : "+widthPixel.toString()+"\theight : "+height_pixel.toString()
        +"\thexSize : "+hexSize.toString()+"\tmapCenter : "+mapCenter.toString());
    
    _rdr.fog=fog;    
    _generateHexes(randomHex);
  }
  
  resize(int width, int height){
    
    this.widthPixel=width;
    this.height_pixel=height;
    this.hexSize=computeSize(widthPixel, halfNbHex_Q);
    this.mapCenter=_computeMapCenter();
    
    idToHex.forEach((id,hexGame)=>hexGame.mapInfo=this);
    
    log.info("Resize MapInfo - width : "+widthPixel.toString()+"\theight : "+height_pixel.toString()
        +"\thexSize : "+hexSize.toString()+"\tmapCenter : "+mapCenter.toString());
  }
  
  String toJson(){
    Map ret= new Map();
    //GameHexInfos
    ret["name"]=name;
    ret["halfNbHex_Q"]=halfNbHex_Q;
    ret["fromHexId"]=fromHexId;
    ret["toHexId"]=toHexId;
    
    Map hexes=new Map();
    idToHex.values.forEach((gh)=>hexes[gh.id]=gh.toJson());
    ret["hexes"]=hexes;
    
    Map objects=new Map();
    idToObjects.forEach((id,go)=>hexes[id]=go.toJson());
    ret["objects"]=objects;
    
    return JSON.encode(ret);
  }
  
  updateFromJson(String json){
    Map parsedMap = JSON.decode(json);
    
    name=parsedMap["name"];
    halfNbHex_Q=parsedMap["halfNbHex_Q"];
    fromHexId=parsedMap["fromHexId"];
    toHexId=parsedMap["toHexId"];
    
    Map mapHex=parsedMap["hexes"];
    mapHex.forEach((id,jsonHex){
      idToHex[id].updateFromJson(jsonHex);
    });
    
    Map mapObj=parsedMap["objects"];
    idToObjects.clear();
    mapObj.forEach((id,jsonObj){
      idToObjects[id]=GameObject.fromJson(jsonObj);
    });
  }
  
  Point _computeMapCenter(){
    num x=widthPixel/2.0;
    num y=height_pixel/2.0;
    return new Point(x, y);
  }
  
  Future loadAllImages(){    
    return GameImage.load(ImageType.values);
  }
  
  /**
   * Generate all the hexes at distance halfNbHex_Q or less from
   * the center
   */
  void _generateHexes(bool rdm){
    
    //create all hexes
    for(int dx=-halfNbHex_Q; dx<=halfNbHex_Q; dx++){
      int min_dy=max(-halfNbHex_Q, -dx-halfNbHex_Q);
      int max_dy=min(halfNbHex_Q, -dx+halfNbHex_Q);
      for(int dy=min_dy; dy<=max_dy; dy++){
        int dz=(-dx-dy).round();
        GameHex hex= new GameHex.cube(hexSize, dx, dy, dz, this);
        if(rdm){
          hex.randomizeHexType();
        }
        idToHex.putIfAbsent(hex.id, () => hex );
      }
    }
    
    //initiate startPoint and endPoint
    fromHexId=new Hex(0, 0, -halfNbHex_Q).id;
    toHexId=new Hex(0, 0, (halfNbHex_Q/2).ceil()).id;
    
    GameHex startHex=idToHex[fromHexId];
    if(startHex!=null){
      startHex.startPoint=true;
      startHex.visible=true; 
    }
    
    GameHex endHex=idToHex[toHexId];
    if(endHex!=null){
      endHex.endPoint=true;
    } 
  }
  
  /**
   * apply the execute function to all the existing visibilityHex that belong to the ring of radius
   * <code>radius<code> and center <code>startHex</code>
   */
  void applyToHexRing(Hex startHex,int radius, void execute(Hex hex)){
    log.info("applyToHexRing startHex : "+startHex.id+"\tradius : "+radius.toString());
    Hex currentHex=new Hex.next(startHex, HexDirection.NORTH, radius);
    execute(currentHex);
    HexDirection.values.forEach((dir){
      for(int j=0; j<radius; j++){
        currentHex=new Hex.next(currentHex, dir, 1);
        execute(currentHex);
      }
    });
  }
  
  /**
   * Return the hex corresponding to the pixel coordinate or
   * null if we are on no hex
   */
  GameHex getSelectedHexFromPixel(num x, num y){
    
    //center x,y
    num cx=x-mapCenter.x;
    num cy=y-mapCenter.y;
    
    num q = 2.0/3.0 * cx / hexSize;
    num r = (-1.0/3.0 * cx + 1.0/3.0*sqrt(3) * cy) / hexSize;
    
    String id=Hex.findNearestHexId_round(r, q);    
    
    GameHex hex=idToHex[id];
    
    return hex;
  }
  
  static num computeSize(num width,int hNbHexQ ){
    return width/(4*hNbHexQ);
  }
  
  /**
   * Select an hex as the new starting hex
   */
  void selectStartHex(GameHex hex){
    if(!hex.startPoint){
      hex.startPoint=true;
      GameHex oldHex=idToHex[fromHexId];
      oldHex.startPoint=false;
      fromHexId=hex.id;
    }
    
    computePlayerVisibility();
  }
  
  void movePlayer(HexDirection hexDir){
    Hex current=idToHex[fromHexId];
    Hex next=new Hex.next(current, hexDir, 1);
    GameHex newHex=idToHex[next.id];
    if(newHex!=null){
      selectStartHex(newHex);
    }
  }
  
  /**
   * Select an hex as the new starting hex
   */
  void selectEndHex(GameHex hex){
    if(!hex.endPoint){
      hex.endPoint=true;
      GameHex oldHex=idToHex[toHexId];
      oldHex.endPoint=false;
      toHexId=hex.id;
    }
  }
  
  void changeType(GameHex hex,HexType type){
    hex.hexType=type;
    log.info("Hex "+hex.id+" changed to type : "+type.toString());
  }
  
  void putCoin(GameHex hex){
    String id=hex.id;
    if(idToObjects.containsKey(id)){
      idToObjects.remove(id);
      log.info("Removing coin from hex : "+hex.id);
    }
    else{
      idToObjects[id]=GameObject.COIN;
      log.info("Adding coin to hex : "+hex.id);
    }
  }
  
  /**
   * Clear the select attribute in all gameHex
   */
  void clearVisibility(){
    idToHex.forEach((id,hexGame){
      if(hexGame!=null){
        hexGame.visible=false;
      }    
    });
  }
  
  Queue<AStarObject> _findAstarPath(GameHex from, GameHex to){
    _astarPool.clear();
    
    AstarHex start= new AstarHex(from, to);
    AstarHex end= new AstarHex(to, to);
    _astarPool[start.model.id]=start;
    _astarPool[end.model.id]=end;
    
    AstarAlgorithm algo= new AstarAlgorithm(start, end);
    
    return algo.execute();
  }
  
  void applytoFoundPath(GameHex from, GameHex to,void apply(AstarHex starHex)){    
    Queue<AstarHex> path=_findAstarPath(from,to);
    path.forEach((starHex)=>apply(starHex));
    _astarPool.clear();    
  }
  
  void selectCurrentPath(){
    
    //reset moveCost and coinCollected
    coinCollected=0;
    moveCost=0;
    
    applytoFoundPath(idToHex[fromHexId], idToHex[toHexId],(AstarHex hex){
      hex.model.selected=true;
      if(hex.model.mapInfo.idToObjects.containsKey(hex.model.id)){
        coinCollected++;
      }
      if(hex.model.id!=fromHexId){
        moveCost+=hex.model.hexType.moveValue;
      }
      
    });
  }
  
  void computePlayerVisibility(){
    GameHex vHex=idToHex[fromHexId];
    clearVisibility();
    if(vHex!=null){
      VisibilityAlgorithm vAlgo= new VisibilityAlgorithm(vHex);
      
      applyToHexRing(vHex, visibilityRadius, (hex){
        vAlgo.visibleRayTo(hex,visibilityRadius);
      });
    }
  }
  
  /**
   * Clear the select attribute in all gameHex
   */
  void clearSelection(){
    idToHex.forEach((id,hexGame)=>hexGame.selected=false);
  }
  
  void drawMap(){
    idToHex.forEach((id,hex){
      if(hex!=null){
        _rdr.drawHexOnMap(hex,mapCenter,character);
      }
    });
    drawInfo();
  }
  
  void drawInfo(){
    CanvasRenderingContext2D c= _rdr.context;
    c.save();
    
    int heightCoinInfo=height_pixel-15;
    int coinImageSize=18;
    int heightMoveInfo=height_pixel-40;
    int bootImageSize=18;
    
    //draw coin image
    c.drawImageScaled(new GameImage(ImageType.COIN).img,5, heightCoinInfo-15,coinImageSize,coinImageSize);
    
    //draw nbr of coin info
    String line=": "+coinCollected.toString();
    c..lineWidth = 3
           ..strokeStyle = "black"
           ..font="14pt Roboto"
           ..strokeText(line, coinImageSize + 7, heightCoinInfo)
           ..fillStyle = "orange"
           ..fillText(line, coinImageSize + 7, heightCoinInfo);
    
    //draw boot image
    c.drawImageScaled(new GameImage(ImageType.BOOT).img,5, heightMoveInfo-15,coinImageSize,bootImageSize);
    
    //draw nbr of coin info
    line=": "+moveCost.toString() + " Steps";
    c..lineWidth = 3
           ..strokeStyle = "black"
           ..font="14pt Roboto"
           ..strokeText(line, bootImageSize + 7, heightMoveInfo)
           ..fillStyle = "orange"
           ..fillText(line, bootImageSize + 7, heightMoveInfo);    
    
    c.restore();
    
  }
}

/**
 * Class representing a game node from the map.
 * It contains all the information about its status and implement the class
 * necessary to manage visibility algorithms.
 */
class GameHex extends Hex implements  AbstractVisibilityHex {
  
  HexType hexType=HexType.LAND;
  bool visibility=false;
  bool startPoint=false;
  bool endPoint=false;
  bool selected=false;
  
  MapInfo mapInfo;
  
  String toJson(){
    Map ret= new Map();
    //GameHexInfos
    ret["visibility"]=visibility;
    ret["startPoint"]=startPoint;
    ret["endPoint"]=endPoint;
    ret["selected"]=selected;
    ret["hexType"]=hexType.toJson();
    
    return JSON.encode(ret);
  }
  
  updateFromJson(String json){
    Map parsedMap = JSON.decode(json);
    
    visibility=parsedMap["visibility"];
    startPoint=parsedMap["startPoint"];
    endPoint=parsedMap["endPoint"];
    selected=parsedMap["selected"];
    hexType=HexType.fromJson(parsedMap["hexType"]);
    
  }
  
  /**
   * Axial coordinates constructor
   */
  GameHex(double pixelSize, int q, int r, MapInfo visiMap):super(pixelSize, q, r){
    _initialize(visiMap);
  }
  
  /**
   * Cube coordinates constructor
   */
  GameHex.cube(double pixelSize, int x, int y, int z, MapInfo visiMap):super.cube(pixelSize, x, y, z){
    _initialize(visiMap);
  }
  
  /*
   * Factozize initialization
   */
  void _initialize(MapInfo visiMap){
    mapInfo=visiMap;
  }
  
  int get altitude => hexType.height;
  void set visible(bool v){
    visibility=v;
  }
  
  /**
   * Give the VisibilityHex in the direction provided or null if there isn't one
   */
  AbstractVisibilityHex getVisibilityHexInDir(HexDirection dir){
    List<int> direction=Hex.neighbors[dir.neighborsPosition];
    Hex hexInDir= new Hex.next(this, dir, 1);
    AbstractVisibilityHex ret= mapInfo.idToHex[hexInDir.id];
    return ret;
  }
  
  /**
   * Give the VisibilityHex in the direction provided or null if there isn't one
   */
  AbstractVisibilityHex getVisibilityHexInDiag(HexDiagonal dir){
    List<int> direction=Hex.diagonals[dir.position];
    Hex hexInDiag=new Hex(pixelSize,
        q_coord + direction[0],
        r_coord + direction[1]
                );
    AbstractVisibilityHex ret= mapInfo.idToHex[hexInDiag.id];
    return ret;
  }
  
  void randomizeHexType(){
    Random r= new Random();
    HexType type=HexType.values[r.nextInt(3)];
    hexType=type;
  }
}

class AstarHex implements AStarObject{
  
  int g;
  int _f;
  int _h;
  
  bool open=false;
  bool closed=false;
  AStarObject _parent=null;
  
  final GameHex model;
  
  final GameHex target;
  
  /**
   * Construct from GameHex
   */
  AstarHex(this.model, this.target){
    g=0;
    _h=_computeH();
    _f=g+h;
    
  }
  
  /**
   * retrieve an Iterable with all valid (meaning "walkable") adjacent element.
   */
  Iterable<AStarObject> getValidAdjacent(){
    Iterable<String> adj=model.getAdjacentHexIds();
   return  
       adj.where((id)=>model.mapInfo.idToHex[id]!=null)
       .map((id){
         AstarHex aHex=model.mapInfo._astarPool.putIfAbsent(id, ()=>new AstarHex(model.mapInfo.idToHex[id],target));
         return aHex;
       });
  }
  
  /**
   * Compute the heuristic H, which is the minimal distance to the target.
   * We make a slightly more accurate approximation by considering the hexType
   * of the target hex.
   */
  int _computeH(){
    int coinValue=model.mapInfo.character.coinValue;
    int minMove=HexType.minMoveValue;
    
    int ret=(model.distanceTo(target)*(minMove-coinValue));
    
    bool coinOntarget=model.mapInfo.idToObjects.containsKey(target.id);
    ret= (ret==0?0:ret -minMove + target.hexType.moveValue-(coinOntarget?coinValue:0));
    
    //if coin on the hex
    bool coinOnCurrent=model.mapInfo.idToObjects.containsKey(model.id);
    if(coinOnCurrent){
      ret=max(0,ret-coinValue);
    }
    return ret;
    
  }
  
  int get h{
    return _h;
  }
  
  int get f{
    return _f;
  }
  
  void set parent(AStarObject p){
    _parent=p;
    _updateValues();
  }
  
  AStarObject get parent{
    return _parent;
  }
  
  void _updateValues(){
    //g is parent g + minValue if fog and hex not visible.
    if(model.mapInfo.fog && !model.visibility){
      g=max(0,parent.g+HexType.minMoveValue);
    }
    //g is parent g + moveValue to this hex - eventual coin if no fog
    else{
      int coinValue=model.mapInfo.character.coinValue;
      bool coinOnCurrent=model.mapInfo.idToObjects.containsKey(model.id);
      g=max(0,parent.g+model.hexType.moveValue -(coinOnCurrent?coinValue:0));
    }

    _f=g+h;
  }
  
  bool equals(AStarObject other){
    bool ret=false;
    if(other is AstarHex){
      ret=(model.id==other.model.id);
    }
    return ret;
  }
  
  String toString(){
    return model.id+"\tf : "+f.toString()+"\tg : "+g.toString()+"\th : "+h.toString();
  }
  
}

class HexType {
  static const MOUNTAIN = const HexType._(10,26,'#d9534f',ImageType.MOUNTAIN);
  static const HILL = const HexType._(5,18,'#a4e9c1', ImageType.HILL);
  static const LAND = const HexType._(0,10,'#a47422',ImageType.LAND);
  static const FOREST = const HexType._(1,12,'#449d44',ImageType.FOREST);
  static const SAND = const HexType._(0,15,'#f0ad4e',ImageType.SAND);

  static get values => [MOUNTAIN, HILL,LAND, FOREST, SAND];
  
  static int minMoveValue=10;
  static int maxMoveValue=20;

  final int height;
  final int moveValue;
  final String color;
  final ImageType background;
  
  int toJson(){
    List<HexType> v=values;
    return v.indexOf(this);
  }
  
  static HexType fromJson(int j){
    return values[j];
  }
  const HexType._(this.height, this.moveValue,this.color,[this.background=null]);
}

class GameObject {
  static const COIN = const GameObject._(ImageType.COIN);
  static get values => [COIN];

  final ImageType image;
  
  int toJson(){
    List<GameObject> v=values;
    return v.indexOf(this);
  }
  
  static GameObject fromJson(int j){
    return values[j];
  }
  const GameObject._(this.image);
}

class CharacterType {
  static const KING_REIKON = const CharacterType._(5,ImageType.KING_REIKON,"Sly King");
  static const KING_SEIZON = const CharacterType._(9,ImageType.KING_SEIZON,"Greedy King");
  static const KING_TSUCHI = const CharacterType._(2,ImageType.KING_TSUCHI,"War King");
  static const KING_MIZU = const CharacterType._(0,ImageType.KING_MIZU,"Sage King");  
  static List<CharacterType> get values => [KING_REIKON,KING_SEIZON,KING_TSUCHI,KING_MIZU];

  final int coinValue;
  final ImageType image;
  final String name;
  
  const CharacterType._(this.coinValue, this.image,this.name);
}


