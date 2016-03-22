library hexrenderer;

import 'package:Hex/hex.dart';
import 'game_info.dart';
import 'dart:html';
import 'package:logging/logging.dart';
import 'dart:math';
import 'dart:async';

/**
 * Class implementing raycasting in an hex grid, from a fixed point. 
 */
class HexRenderer{
  
  /*
   * COLORS
   */
  static final String SEL_STROKE_COLOR='#ff0000';
  static final String STROKE_COLOR='#000000';
  static final int STROKE_WIDTH=1;
  static final int SEL_STROKE_WIDTH=2;
  
  //Constant indicating the gap between hexes
  static final int _RENDERING_GAP=2 ;
  bool drawId=false;
  bool fog=false;
  final Logger log = new Logger('HexRenderer');
  CanvasRenderingContext2D context;
  
  HexRenderer(this.context);
  
  
  /**
   * Draw the Hex with the specified center on the context 
   */
  void drawHexWithCenter(GameHex hex, Point hexCenter){
    
    context..strokeStyle=hex.selected?SEL_STROKE_COLOR:STROKE_COLOR
        ..lineWidth=hex.selected?SEL_STROKE_WIDTH:STROKE_WIDTH;

            
    _fillHex(hex,hexCenter);     
    
    context.stroke();
    context.closePath();
    
    if(drawId){
      _drawId(hex,hexCenter);
    }
  }
  
  _fillHex(GameHex hex, Point hexCenter){
    ImageType it=hex.hexType.background;
    if(it==null){
      context.fillStyle=hex.hexType.color;
      _createHexPath(hex, hexCenter);
      context.fill();
    }
    else{
      clippedImage(hex,hexCenter,new GameImage(it));
    }
    
    //if fog acrivated and hex not visible
    if(fog && !hex.visibility){
      context..lineWidth=0
          ..globalAlpha=0.7
          ..fillStyle='#CCCCCC';
      _createHexPath(hex, hexCenter);
      context.fill();
    }
    
  }
  
  /*
   * begin a path and draw the hex shape. 
   */
  void _createHexPath(Hex hex, Point hexCenter){
    context.beginPath();
    double drawSize=hex.pixelSize - _RENDERING_GAP;
    //Point hexCenter=hex.relativeCenter;
    for (var i = 0; i < 7; i++) {
      double angle = Hex.TWOPI_SIXTH *i;//2 * pi / 6 * i
      double x=hexCenter.x + drawSize * cos(angle);
      double y=hexCenter.y + drawSize * sin(angle);
      
      if(i==0){
        context.moveTo(x, y);
      }
      else{
        context.lineTo(x, y);
      }
    }
  }
  
  /**
   * Draw the Hex on the Map centered on mapCenter according to its coordinates
   */
  void drawHexOnMap( GameHex hex, Point<num> mapCenter, CharacterType character){
    
    //compute hex center (relative position to map center + map center)
    Point center=hex.relativeCenter+mapCenter; 
    
    //draw hex
    context.save();
    
    drawHexWithCenter(hex,center);
    
    //if hex is start or endPoint, draw symbol
    context..strokeStyle='#000000'
        ..fillStyle='#000000';
    if(hex.startPoint){
      clippedImage(hex,center,new GameImage(character.image));
    }
    
    if(hex.endPoint){
      //full rectangle TREASURE
      clippedImage(hex,center,new GameImage(ImageType.TREASURE));
    }
    
    GameObject obj= hex.mapInfo.idToObjects[hex.id];
    if(obj!=null){
      drawObjectOnMap(hex, obj, mapCenter);
    }
    
    context.restore();
  }
  
  drawObjectOnMap(GameHex hex, GameObject obj, Point<num> mapCenter){
    //compute hex center (relative position to map center + map center)
    Point center=hex.relativeCenter+mapCenter; 
    clippedImage(hex,center,new GameImage(ImageType.COIN));
  }
  
  
  
  /*
   * Draw the Id of the hex. For debugging purpose
   */
  _drawId(Hex hex,Point<num> hexCenter){
    context..strokeStyle = '#cc8888'
      ..lineWidth=1
      ..font = '10px serif';
    
    var metrics = context.measureText(hex.id);
    var textWidth = metrics.width;
    var xPosition = hexCenter.x - (textWidth / 2);
    var yPosition =hexCenter.y - 5;
    context.strokeText(hex.id, xPosition, yPosition);
  }
  
  void clippedImage(Hex hex, Point hexCenter, GameImage gImage){
    context.save(); // Save the context before clipping
    
    //create a hex shaped path
    _createHexPath(hex,hexCenter);
    
    //clip to the hex path in the context
    context.clip();
    
    double destX=hexCenter.x - (hex.width/2.0) - hex.width * gImage.offset.x;
    double destY=hexCenter.y-(hex.height/2.0)- hex.height *gImage.offset.y;
    double destWidth=hex.width*gImage.scaleRatio;
    double destHeight=hex.height*gImage.scaleRatio;
    
    context.drawImageScaled(gImage.img,
        destX,
        destY,
        destWidth,
        destHeight);
    context.closePath();
    context.restore(); // Get rid of the clipping region
  }
}

class GameImage {
  ImageElement img;
  Point<double> offset;
  double scaleRatio;

  // _cache is library-private, thanks to the _ in front
  // of its name.
  static final Map<String, GameImage> _cache =
      <String, GameImage>{};

  factory GameImage(ImageType it) {
    if (_cache.containsKey(it.name)) {
      return _cache[it.name];
    } else {
      final gameImage = new GameImage._internal(it);
      _cache[it.name] = gameImage;
      return gameImage;
    }
  }

  GameImage._internal(ImageType it){
     img= new ImageElement(src : it.path);
     offset= new Point(it.offsetX, it.offsetY);
     scaleRatio=it.scaleRatio;
  }
  
  static Future load(List<ImageType> images){
    List<Future> toLoad=[];
    images.forEach((it){
      GameImage gim= new GameImage(it);
      toLoad.add(gim.img.onLoad.first);
    });
    
    return Future.wait(toLoad);
    
  }
  
}

class ImageType {
  
  static const double KING_OFFSET_RATIO=0.2;
  
  static const KING_MIZU= const ImageType._("mizuking","images/m_rois_1_trans.gif",1.5,KING_OFFSET_RATIO,KING_OFFSET_RATIO);
  static const KING_REIKON = const ImageType._("reikonking","images/m_rois_2_trans.gif",1.5,KING_OFFSET_RATIO,KING_OFFSET_RATIO);
  static const KING_TSUCHI = const ImageType._("tsuchiking","images/m_rois_4_trans.gif",1.5,KING_OFFSET_RATIO+0.1,KING_OFFSET_RATIO);
  static const KING_SEIZON = const ImageType._("seizonking","images/m_rois_3_trans.gif",1.5,KING_OFFSET_RATIO,KING_OFFSET_RATIO);
  
  static const TREASURE = const ImageType._("treasure","images/treasure_chest.png",0.5,-0.25,-0.25);
  static const COIN = const ImageType._("coin","images/coin_trans.gif",0.3,-0.5,-0.5);
  static const BOOT = const ImageType._("boot","images/boot2.jpg");
  
  static const SAND = const ImageType._("sand","images/Sand.png");
  static const LAND = const ImageType._("dirt","images/Dirt.png");
  static const MOUNTAIN = const ImageType._("mountain","images/Mountain3.png");
  static const FOREST = const ImageType._("forest","images/Forest2.png");
  static const HILL = const ImageType._("hill","images/Hill2.jpg");

  static get values => [KING_MIZU, KING_REIKON,KING_TSUCHI, KING_SEIZON,
                        TREASURE,COIN,BOOT,
                        SAND,LAND,MOUNTAIN,FOREST,HILL];

  final String path;
  final String name;
  final double scaleRatio;
  final double offsetX;
  final double offsetY;

  const ImageType._(this.name,this.path, [this.scaleRatio=1.0, this.offsetX=0.0, this.offsetY=0.0]);
}

