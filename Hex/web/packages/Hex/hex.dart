// Copyright (c) 2015, <Mathias Aboudou>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library hex;

import 'dart:html';
import 'dart:math';

class Hex{
  static const double TWOPI_SIXTH=(2 * PI / 6);
  
  static final List<List<int>> neighbors=
      [
       [1,  0], [1, -1], [ 0, -1],
       [-1,  0], [-1, 1], [ 0, 1]
      ];
  
  static final diagonals = 
        [
               [2, -1],//0 EAST 
               [1, -2], //1 NORTH_EAST
               [-1, -1],//2 NORTH_WEST
               [-2, 1], //3 WEST
               [-1, 2],//4 SOUTH_WEST               
               [1, 1]  //5 SOUTH_EAST
          ];
  
  String id;
  
  //size in pixel
  final num pixelSize;
  num _pixelWidth=-1;
  num _pixelHeight=-1;
  
  //q and r are coordinate in axial coordinates
  final int q_coord; //x in cube coordinate
  final int r_coord; //z in cube coordinate
  
  //y is the third coordinate for cube coordinate system 
  //(always setted for computation purpose)
  int y_coord;
  
  Point _relativeCenter=null;
  
  Hex(this.pixelSize,this.q_coord, this.r_coord){
    this.y_coord=-q_coord-r_coord;
    this.id=_computeId(r_coord, q_coord);
  }
  
  
  
  Hex.cube(this.pixelSize, int x_coord, int y_coord, int z_coord):
    q_coord=x_coord,
    r_coord=z_coord
  {
    this.y_coord=y_coord;
    this.id=_computeId(r_coord, q_coord);
  }
  
  /**
   * Construct an hex adjacent to the one given in parameter 
   * in the provided direction, with the same size
   * 
   */
  Hex.next(Hex hex, HexDirection dir, int scale):
    q_coord=hex.q_coord + Hex.neighbors[dir.neighborsPosition][0]*scale,
    r_coord=hex.r_coord + Hex.neighbors[dir.neighborsPosition][1]*scale,
    pixelSize=hex.pixelSize
  {
    this.y_coord=y_coord;
    this.id=_computeId(r_coord, q_coord);
  }
  
  /**
   * Get pixel coordinates in a space where hex(0,0) is in 0,0.
   */
  Point get relativeCenter{
    if(_relativeCenter==null){
      _relativeCenter= Hex._getRelativeCenter(pixelSize, q_coord, r_coord);
    }
    return _relativeCenter;
  }
  
  num get width{
    if(_pixelWidth==-1){
      _pixelWidth=2*pixelSize;
    }
    return _pixelWidth;
  }
  
  num get height{
    if(_pixelHeight==-1){
      _pixelHeight=(sqrt(3)/2.0) * width;
    }
    return _pixelHeight;
  }
  
  static Point<num> _getRelativeCenter(num pixelSize, num q_coord, num r_coord){
    num x= pixelSize * 3.0/2.0 * q_coord.toDouble();
    num y= pixelSize * sqrt(3) * (r_coord.toDouble()+q_coord.toDouble() / 2.0);
    return new Point<num>(x,y);
  }
  
  /**
   * Indicate if the hex in parameter is ine diagonal of the current hex
   */
  HexDiagonal isDiagonal(Hex hex){
    HexDiagonal ret=null;
    
    int dq=hex.q_coord-q_coord;
    int dr=hex.r_coord-r_coord;
    
    if(dq!=0 && dr!=0){
      
      if(dq==dr){
        ret=dr>0?HexDiagonal.SOUTH_EAST:HexDiagonal.NORTH_WEST;
      }
      else{         
         //hexq= q+N*2
         if(dq%2==0){
           int n=(dq/2).floor();
           //EAST ?
           if(dq>0 && dr==-n){
             ret=HexDiagonal.EAST;
           }
           //WEST ?
           else if(dq<0 && dr==-n){
             ret=HexDiagonal.WEST;
           }
         }
         //hexq= q+N and 
         if(ret==null){
           //NORTH_EAST ?
           if(dq>0 && dr==-2*dq){
             ret=HexDiagonal.SOUTH_WEST;
           }
           //SOUTH_WEST
           else if(dq<0 && dr==-2*dq){
             ret=HexDiagonal.NORTH_EAST;
           }
         }
      }
    }    
    return ret;
  }
  
  //TODO changer en getAdjacentHexes
  Iterable<String> getAdjacentHexIds(){
    Iterable<String> ret=neighbors.map(
        (direction)=>_computeId(r_coord + direction[1],
            q_coord + direction[0]));
    return ret;
  }
  
  /**
   * Distance to the provided hex
   */
  int distanceTo(Hex otherHex){
      int q1=q_coord;
      int q2=otherHex.q_coord;
      int r1=r_coord;
      int r2=otherHex.r_coord;
      return (((q1 - q2).abs() + (r1 - r2).abs()
            + (q1 + r1 - q2 - r2).abs()) / 2).floor();
  }
  
  /**
   * Compute an unique id from the axial coordinates
   */
  static String _computeId(int r, int q){
    StringBuffer sb= new StringBuffer(q);
    sb.write("@");
    sb.write(r);
    return sb.toString();
  }
  
  /**
   * Find the nearest hex corresponding to the non integer coordinates
   */
  //TODO renvoyer un hex ou HexCoords
  static String findNearestHexId_round(num r,num q){
    
    //convert to cube coords
    num x=q;
    num z=r;
    num y=-q-r;
    
    //round coords
    num rx = x.round();
    num ry = y.round();
    num rz = z.round();
 
    //find diffs
    num x_diff = (rx - x).abs();
    num y_diff = (ry - y).abs();
    num z_diff = (rz - z).abs();
    
    /* reset the component with the largest change back to 
    what the constraint rx + ry + rz = 0 requires*/
    if (x_diff > y_diff && x_diff > z_diff){
        rx = (-ry-rz).round();
    }
    else if (y_diff > z_diff){
        ry = (-rx-rz).round();
    }
    else{
        rz = (-rx-ry).round();
    }
    num rCoord=rz;
    num qCoord=rx;
        
    return _computeId(rCoord, qCoord);
  }
}

/**
 * Represent a Direction for navigating between hexes
 */
class HexDirection {
  static const NORTH = const HexDirection._(2,4);
  static const NORTH_EAST = const HexDirection._(1,5);
  static const SOUTH_EAST = const HexDirection._(0,0);
  static const SOUTH = const HexDirection._(5,1);
  static const SOUTH_WEST = const HexDirection._(4,2);
  static const NORTH_WEST = const HexDirection._(3,3);

  static List<HexDirection> get values => [
                        SOUTH_EAST,SOUTH,SOUTH_WEST,
                        NORTH_WEST,NORTH, NORTH_EAST
                        ];

  HexDirection opposite(){
    return values[(drawOrder+3)%6];
  }
  
  HexDirection next(){
    return values[(drawOrder+1)%6];
  }
  
  HexDirection prev(){
    return values[(drawOrder-1)%6];
  }
  
  final int neighborsPosition;
  //TODO : changer de nom
  final int drawOrder;
  
  String toString(){
    switch(drawOrder){
      case 0:
        return "SOUTH_EAST";
      case 1:
        return "SOUTH";
      case 2:
        return "SOUTH_WEST";
      case 3:
        return "NORTH_WEST";
      case 4:
        return "NORTH";
      case 5:
        return "NORTH_EAST";
    }
    
    return "";
  }
  
  
  
  /**
   * Get the edge of an hex in the defined direction. Computed from its absolute center and drawsize
   */
  //TODO retirer param size. prendre celle de l'hex
  List<Point> getEdge(Point center, num size){
    return  [
             new Point(center.x+cos(Hex.TWOPI_SIXTH*drawOrder)*size,center.y+sin(Hex.TWOPI_SIXTH*drawOrder)*size),
             new Point(center.x+cos(Hex.TWOPI_SIXTH*(drawOrder+1))*size,center.y+sin(Hex.TWOPI_SIXTH*(drawOrder+1))*size),
             ];
  }
  
  const HexDirection._(this.neighborsPosition, this.drawOrder);
}

/**
 * Represent a diagonal to navigate between hexes
 */
class HexDiagonal {
  static const WEST = const HexDiagonal._(3);
  static const NORTH_EAST = const HexDiagonal._(1);
  static const SOUTH_EAST = const HexDiagonal._(5);
  static const EAST = const HexDiagonal._(0);
  static const SOUTH_WEST = const HexDiagonal._(4);
  static const NORTH_WEST = const HexDiagonal._(2);

  static List<HexDiagonal> get values => [
                        SOUTH_EAST,EAST,SOUTH_WEST,
                        NORTH_WEST,WEST, NORTH_EAST
                        ];
  
  /**
   * Give the directions from the diagonal hex in which you can find the hexes you have to go across
   * in order to reach it
   */
  List<HexDirection> getPreviousDirections(){
    switch(position){
      case 5://south east
        return [HexDirection.NORTH_WEST,HexDirection.NORTH];
      case 0://east
        return [HexDirection.SOUTH_WEST,HexDirection.NORTH_WEST];
      case 4://south west
        return [HexDirection.NORTH_EAST,HexDirection.NORTH];
      case 2://north west
        return [HexDirection.SOUTH_EAST,HexDirection.SOUTH];
      case 3://west
        return [HexDirection.SOUTH_EAST,HexDirection.NORTH_EAST];
      case 1://north east
        return [HexDirection.SOUTH_WEST,HexDirection.SOUTH];
    }
    
    return null;
  }
  
  final int position;
  
  String toString(){
    switch(position){
      case 5:
        return "SOUTH_EAST";
      case 0:
        return "EAST";
      case 4:
        return "SOUTH_WEST";
      case 2:
        return "NORTH_WEST";
      case 3:
        return "WEST";
      case 1:
        return "NORTH_EAST";
    }
    
    return "";
  }

  const HexDiagonal._(this.position);
}
